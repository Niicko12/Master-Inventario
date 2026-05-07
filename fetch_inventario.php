<?php
require_once 'config.php';

$sql = "SELECT id_producto, nombre_producto, cantidad_disponible, stock_minimo FROM Inventario";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        echo "<tr>
            <td>{$row['id_producto']}</td>
            <td>{$row['nombre_producto']}</td>
            <td>{$row['cantidad_disponible']}</td>
            <td>{$row['stock_minimo']}</td>
            <td>
                <button class='btn btn-primary btn-sm' onclick=\"openEditModal('{$row['id_producto']}', '{$row['nombre_producto']}', '{$row['cantidad_disponible']}', '{$row['stock_minimo']}')\">Editar</button>
                <a href='gestion_inventario.php?delete={$row['id_producto']}' class='btn btn-danger btn-sm' onclick=\"return confirm('¿Estás seguro de que deseas eliminar este producto?');\">Eliminar</a>
            </td>
        </tr>";
    }
} else {
    echo "<tr><td colspan='5' class='text-center'>No se encontraron productos en el inventario.</td></tr>";
}
$conn->close();
