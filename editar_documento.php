<?php
// editar_documento.php
include('header.php');  // Incluir el header con la barra de navegación

require_once 'config.php';  // Incluir la configuración de la base de datos

authRequire('Administrador');

// Establecer variables de usuario y IP para los triggers
$current_user = $conn->real_escape_string($_SESSION['username']);
$current_ip = $conn->real_escape_string($_SERVER['REMOTE_ADDR']);

// Configurar las variables de usuario en la conexión mysqli
$conn->query("SET @current_user = '$current_user'");
$conn->query("SET @current_ip = '$current_ip'");

$mensaje = "";

// Manejo de la edición del documento
if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['id_documento'])) {
    $id_documento = intval($_POST['id_documento']);
    $tipo_documento = $conn->real_escape_string($_POST['tipo_documento']);
    $descripcion = $conn->real_escape_string($_POST['descripcion']);
    $fecha_creacion = $conn->real_escape_string($_POST['fecha_creacion']);
    $version = $conn->real_escape_string($_POST['version']);
    $usuario_modifico = $conn->real_escape_string($_SESSION['username']); // Asumiendo que el nombre de usuario está en la sesión

    // Validar campos obligatorios
    if (empty($tipo_documento) || empty($descripcion) || empty($fecha_creacion) || empty($version)) {
        $mensaje = "<div class='alert alert-danger'>Todos los campos son obligatorios.</div>";
    } else {
        // Iniciar una transacción
        $conn->begin_transaction();

        try {
            // Obtener la ruta del archivo actual
            $stmt = $conn->prepare("SELECT ruta_archivo FROM Documentos WHERE id_documento = ?");
            if ($stmt) {
                $stmt->bind_param("i", $id_documento);
                $stmt->execute();
                $stmt->bind_result($file_path);
                if ($stmt->fetch()) {
                    $stmt->close();

                    // Verificar si se ha subido un nuevo archivo
                    if (isset($_FILES['documento']) && $_FILES['documento']['error'] == 0) {
                        $allowed = ['pdf', 'docx', 'xlsx', 'txt'];
                        $file_name = basename($_FILES['documento']['name']);
                        $file_size = $_FILES['documento']['size'];
                        $file_tmp = $_FILES['documento']['tmp_name'];
                        $file_ext = strtolower(pathinfo($file_name, PATHINFO_EXTENSION));

                        if (in_array($file_ext, $allowed)) {
                            // Verificar el tipo MIME
                            $finfo = finfo_open(FILEINFO_MIME_TYPE);
                            $mime = finfo_file($finfo, $file_tmp);
                            finfo_close($finfo);
                            $allowed_mimes = [
                                'application/pdf',
                                'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                                'text/plain'
                            ];

                            if (in_array($mime, $allowed_mimes)) {
                                // Generar un nombre único para el archivo
                                $new_filename = uniqid() . "." . $file_ext;
                                $upload_dir = 'uploads/';
                                if (!is_dir($upload_dir)) {
                                    mkdir($upload_dir, 0755, true);
                                }
                                $new_file_path = $upload_dir . $new_filename;

                                // Mover el archivo al directorio de subida
                                if (move_uploaded_file($file_tmp, $new_file_path)) {
                                    // Preparar la consulta para actualizar el documento con el nuevo archivo
                                    $stmt = $conn->prepare("UPDATE Documentos SET tipo_documento = ?, descripcion = ?, fecha_creacion = ?, version = ?, usuario_subio = ?, nombre_archivo = ?, ruta_archivo = ? WHERE id_documento = ?");
                                    if ($stmt) {
                                        $stmt->bind_param("sssssssi", $tipo_documento, $descripcion, $fecha_creacion, $version, $usuario_modifico, $file_name, $new_file_path, $id_documento);
                                        if ($stmt->execute()) {
                                            // Eliminar el archivo antiguo
                                            if (file_exists($file_path)) {
                                                unlink($file_path);
                                            }
                                        } else {
                                            throw new Exception("Error al actualizar el documento en la base de datos.");
                                        }
                                        $stmt->close();
                                    } else {
                                        throw new Exception("Error en la preparación de la consulta de actualización.");
                                    }
                                } else {
                                    throw new Exception("Error al mover el archivo.");
                                }
                            } else {
                                throw new Exception("Tipo MIME de archivo no válido.");
                            }
                        } else {
                            throw new Exception("Formato de archivo no válido. Solo se permiten PDF, DOCX, XLSX, TXT.");
                        }
                    } else {
                        // Preparar la consulta para actualizar el documento sin cambiar el archivo
                        $stmt = $conn->prepare("UPDATE Documentos SET tipo_documento = ?, descripcion = ?, fecha_creacion = ?, version = ?, usuario_subio = ? WHERE id_documento = ?");
                        if ($stmt) {
                            $stmt->bind_param("sssssi", $tipo_documento, $descripcion, $fecha_creacion, $version, $usuario_modifico, $id_documento);
                            if (!$stmt->execute()) {
                                throw new Exception("Error al actualizar el documento en la base de datos.");
                            }
                            $stmt->close();
                        } else {
                            throw new Exception("Error en la preparación de la consulta de actualización.");
                        }
                    }
                } else {
                    throw new Exception("Documento no encontrado.");
                }
            } else {
                throw new Exception("Error en la preparación de la consulta de selección.");
            }

            // Confirmar la transacción
            $conn->commit();
            $mensaje = "<div class='alert alert-success'>Documento actualizado correctamente.</div>";
        } catch (Exception $e) {
            // Revertir la transacción
            $conn->rollback();
            $mensaje = "<div class='alert alert-danger'>Error al actualizar el documento: " . $e->getMessage() . "</div>";
        }
    }

    // Redireccionar de vuelta a documentos.php con mensaje
    if (!empty($mensaje)) {
        $_SESSION['mensaje'] = $mensaje;
        header("Location: documentos.php");
        exit;
    }
?>
