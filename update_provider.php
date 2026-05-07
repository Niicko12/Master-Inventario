<?php
require_once 'config.php';

// Verificar si se recibieron todos los datos necesarios
if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['id_proveedor'])) {
    // Recibir datos del formulario
    $id_proveedor = intval($_POST['id_proveedor']);
    $nombre_proveedor = $_POST['nombre_proveedor'];
    $telefono = $_POST['telefono'];
    $email = $_POST['email'];
    $direccion = $_POST['direccion'];

    // Actualizar el proveedor en la base de datos
    $sql = "UPDATE Proveedores SET nombre_proveedor = ?, telefono = ?, email = ?, direccion = ? WHERE id_proveedor = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ssssi", $nombre_proveedor, $telefono, $email, $direccion, $id_proveedor);

    if ($stmt->execute()) {
        // Redirigir con mensaje de éxito
        header("Location: gestion_proveedores.php?success=Proveedor actualizado correctamente.");
        exit;
    } else {
        // Redirigir con mensaje de error
        header("Location: gestion_proveedores.php?error=Error al actualizar el proveedor: " . $conn->error);
        exit;
    }
} else {
    // Redirigir si faltan datos
    header("Location: gestion_proveedores.php?error=Datos incompletos para actualizar el proveedor.");
    exit;
}
