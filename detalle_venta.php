<?php
require_once 'config.php';

header('Content-Type: application/json');

// Verificar si se pasa el ID de la venta
if (isset($_GET['id_venta'])) {
    $id_venta = intval($_GET['id_venta']);

    // Consultar detalles de la venta
    $sql = "SELECT V.id_venta, U.nombre AS cliente, DV.cantidad_vendida, I.nombre_producto, V.monto_total, V.estado 
            FROM Ventas V 
            JOIN Usuarios U ON V.id_cliente = U.id_usuario 
            JOIN Detalle_Ventas DV ON V.id_venta = DV.id_venta 
            JOIN Inventario I ON DV.id_producto = I.id_producto 
            WHERE V.id_venta = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $id_venta);
    $stmt->execute();
    $result = $stmt->get_result();

    // Enviar datos de la venta o error en formato JSON
    if ($result->num_rows > 0) {
        echo json_encode($result->fetch_assoc());
    } else {
        echo json_encode(["error" => "No se encontraron detalles de la venta."]);
    }
} else {
    echo json_encode(["error" => "ID de venta no especificado."]);
}
