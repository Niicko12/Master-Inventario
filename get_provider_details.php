<?php
require_once 'config.php';

header('Content-Type: application/json');

// Verificar si se pasó un ID de proveedor
if (isset($_GET['id_proveedor'])) {
    $id_proveedor = intval($_GET['id_proveedor']);

    // Consulta para obtener los detalles del proveedor
    $sql = "SELECT id_proveedor, nombre_proveedor, telefono, email, direccion FROM Proveedores WHERE id_proveedor = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $id_proveedor);
    $stmt->execute();
    $result = $stmt->get_result();

    // Verificar si el proveedor existe y devolver los datos en JSON
    if ($result->num_rows > 0) {
        echo json_encode($result->fetch_assoc());
    } else {
        echo json_encode(["error" => "Proveedor no encontrado."]);
    }
} else {
    echo json_encode(["error" => "ID de proveedor no especificado."]);
}
