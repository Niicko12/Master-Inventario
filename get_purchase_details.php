<?php
require_once 'config.php';  // Incluir la configuración de la base de datos

if (isset($_GET['id_compra'])) {
    $id_compra = intval($_GET['id_compra']);
    $sql = "SELECT C.id_compra, C.fecha_compra,C.nombre_producto, C.monto_total, P.id_proveedor, C.cantidad_comprada, P.nombre_proveedor 
            FROM Compras C
            JOIN Proveedores P ON C.id_proveedor = P.id_proveedor
            WHERE C.id_compra = $id_compra";
    $result = $conn->query($sql);

    if ($result && $result->num_rows > 0) {
        $compra = $result->fetch_assoc();
        echo json_encode($compra);
    } else {
        echo json_encode(["error" => "Compra no encontrada"]);
    }
} else {
    echo json_encode(["error" => "ID de compra no proporcionado"]);
}
?>