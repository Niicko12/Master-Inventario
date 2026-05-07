<?php
// Action handlers for documentos.php.
// Included early; exits on any matched action.
// Requires: $conn, $current_user (int), $can_add_documents (bool)

// AJAX: change history
if (isset($_GET['action']) && $_GET['action'] === 'get_history' && isset($_GET['doc_id'])) {
    header('Content-Type: application/json');
    echo json_encode(dbFetchAll($conn,
        "SELECT * FROM Historial_Documentos WHERE id_documento = ? ORDER BY fecha_modificacion DESC",
        "i", intval($_GET['doc_id'])
    ));
    exit;
}

// POST: edit document
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['editar_documento'])) {
    $ok = dbExecute($conn,
        "UPDATE Documentos SET tipo_documento=?, descripcion=?, version=? WHERE id_documento=?",
        "sssi",
        trim($_POST['tipo_documento'] ?? ''),
        trim($_POST['descripcion']    ?? ''),
        trim($_POST['version']        ?? ''),
        intval($_POST['doc_id'])
    );
    $_SESSION['mensaje'] = $ok
        ? "<div class='alert alert-success'>Documento actualizado correctamente.</div>"
        : "<div class='alert alert-danger'>Error al actualizar el documento.</div>";
    header("Location: documentos.php"); exit;
}

// POST: attach record
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['adjuntar_registro'])) {
    $ok = dbExecute($conn,
        "INSERT INTO Documentos_Registros (id_documento, tabla, registro_id) VALUES (?, ?, ?)",
        "isi",
        intval($_POST['doc_id']),
        trim($_POST['tabla'] ?? ''),
        intval($_POST['registro_id'])
    );
    $_SESSION['mensaje'] = $ok
        ? "<div class='alert alert-success'>Registro adjuntado correctamente.</div>"
        : "<div class='alert alert-danger'>Error al adjuntar el registro.</div>";
    header("Location: documentos.php"); exit;
}

// POST: upload document
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['subir_documento'])) {
    if (isset($_FILES['documento']) && $_FILES['documento']['error'] === UPLOAD_ERR_OK) {
        $nombre_orig = basename($_FILES['documento']['name']);
        $ruta        = 'uploads/' . $nombre_orig;
        if (move_uploaded_file($_FILES['documento']['tmp_name'], $ruta)) {
            $ok = dbExecute($conn,
                "INSERT INTO Documentos (tipo_documento, descripcion, fecha_creacion, version, usuario_subio, ruta_archivo, nombre_archivo, fecha_subida) VALUES (?, ?, NOW(), ?, ?, ?, ?, NOW())",
                "ssssss",
                trim($_POST['tipo_documento'] ?? ''),
                trim($_POST['descripcion']    ?? ''),
                trim($_POST['version']        ?? ''),
                $current_user,
                $ruta,
                $nombre_orig
            );
            $_SESSION['mensaje'] = $ok
                ? "<div class='alert alert-success'>Documento subido correctamente.</div>"
                : "<div class='alert alert-danger'>Error al guardar el documento en la base de datos.</div>";
        } else {
            $_SESSION['mensaje'] = "<div class='alert alert-danger'>Error al mover el archivo al directorio de destino.</div>";
        }
    } else {
        $_SESSION['mensaje'] = "<div class='alert alert-danger'>Selecciona un archivo válido.</div>";
    }
    header("Location: documentos.php"); exit;
}

// GET: delete document (admin only)
if ($can_add_documents && isset($_GET['delete'])) {
    $doc_id = intval($_GET['delete']);
    if (dbFetchOne($conn, "SELECT id_documento FROM Documentos WHERE id_documento = ?", "i", $doc_id)) {
        $conn->begin_transaction();
        try {
            dbExecute($conn, "DELETE FROM Historial_Documentos WHERE id_documento = ?",  "i", $doc_id);
            dbExecute($conn, "DELETE FROM Documentos_Registros WHERE id_documento = ?",  "i", $doc_id);
            if (!dbExecute($conn, "DELETE FROM Documentos WHERE id_documento = ?", "i", $doc_id)) {
                throw new \RuntimeException();
            }
            $conn->commit();
            $_SESSION['mensaje'] = "<div class='alert alert-success'>Documento eliminado correctamente.</div>";
        } catch (\Exception $e) {
            $conn->rollback();
            $_SESSION['mensaje'] = "<div class='alert alert-danger'>No se pudo eliminar el documento.</div>";
        }
    } else {
        $_SESSION['mensaje'] = "<div class='alert alert-danger'>El documento no existe.</div>";
    }
    header("Location: documentos.php"); exit;
}
