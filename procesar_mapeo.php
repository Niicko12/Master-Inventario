<?php
require_once 'config.php';

header('Content-Type: application/json');

try {
    if (!isset($_GET['tabla_destino']) || empty($_GET['tabla_destino'])) {
        echo json_encode(['error' => 'No se especificó la tabla de destino']);
        exit;
    }

    $tabla_destino = $_GET['tabla_destino'];
    $query = "SHOW COLUMNS FROM `$tabla_destino`";
    $result = $conn->query($query);

    if (!$result || $result->num_rows === 0) {
        echo json_encode(['error' => "No se encontraron columnas para la tabla '$tabla_destino'."]);
        exit;
    }

    $columnas = [];
    while ($row = $result->fetch_assoc()) {
        $columnas[] = $row['Field'];
    }

    echo json_encode($columnas);
} catch (Exception $e) {
    echo json_encode(['error' => 'Error interno: ' . $e->getMessage()]);
    exit;
}
?>
