<?php
require_once 'config.php';  // Conexión a la base de datos

$tabla = $_POST['tabla'] ?? '';

// Consultar datos de la tabla seleccionada
$query = "SELECT * FROM $tabla";
$result = $conn->query($query);
?>

<h1>Reporte de <?php echo ucfirst($tabla); ?></h1>
<table border="1" cellpadding="5" cellspacing="0" width="100%">
    <thead>
        <tr>
            <?php
            $columns = array_keys($result->fetch_assoc());
            foreach ($columns as $column) {
                echo "<th>" . ucfirst($column) . "</th>";
            }
            $result->data_seek(0);  // Volver al inicio del resultado
            ?>
        </tr>
    </thead>
    <tbody>
        <?php while ($row = $result->fetch_assoc()): ?>
            <tr>
                <?php foreach ($columns as $column): ?>
                    <td><?php echo htmlspecialchars($row[$column]); ?></td>
                <?php endforeach; ?>
            </tr>
        <?php endwhile; ?>
    </tbody>
</table>
