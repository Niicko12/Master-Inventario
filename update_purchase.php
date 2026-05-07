<?php
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['id_compra'])) {
    $id_compra = intval($_POST['id_compra']);
    $id_proveedor = intval($_POST['id_proveedor']);
    $nombre_producto = intval($_POST['nombre_producto']);
    $cantidad_comprada = intval($_POST['cantidad_comprada']);
    $monto_total = floatval($_POST['monto_total']);

    $sql = "UPDATE Compras SET id_proveedor = '$id_proveedor', monto_total = '$monto_total' WHERE id_compra = $id_compra";

    if ($conn->query($sql) === TRUE) {
        echo "Compra actualizada correctamente.";
        header('Location: gestion_compras.php');  // Redirigir después de actualizar
    } else {
        echo "Error al actualizar la compra: " . $conn->error;
    }
} else {
    echo "ID de compra no proporcionado.";
}
?>