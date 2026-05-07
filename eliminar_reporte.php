<?php
require_once 'config.php';
// Auth is enforced globally by config.php -> includes/auth_check.php.
// Only Administrador role should reach this action; add role gate here as well.
requireRole('Administrador');

if (isset($_GET['id'])) {
    $id = intval($_GET['id']);

    // Fetch the file path using a prepared statement — never interpolate $id into SQL.
    $reporte = dbFetchOne($conn, "SELECT ruta_archivo FROM Reportes WHERE id = ?", "i", $id);

    if ($reporte) {
        $rutaArchivo = $reporte['ruta_archivo'];

        // Delete the physical file if it exists.
        if (file_exists($rutaArchivo)) {
            unlink($rutaArchivo);
        }

        // Delete the database record using a prepared statement.
        dbExecute($conn, "DELETE FROM Reportes WHERE id = ?", "i", $id);
    }
}

header("Location: reportes.php");
exit;
?>
