<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

require_once 'config.php';

// Función para registrar logs
function log_message($message) {
    $logFile = __DIR__ . '/log.txt';
    file_put_contents($logFile, date('Y-m-d H:i:s') . " - $message\n", FILE_APPEND);
}

header('Content-Type: application/json');

try {
    // Obtener los datos enviados
    $tabla_destino = $_POST['tabla_destino'] ?? null;
    $datos = json_decode($_POST['datos'] ?? '', true);

    // Registrar datos en el log para depuración
    log_message("Tabla destino recibida: $tabla_destino");
    log_message("Datos recibidos: " . json_encode($datos));

    // Validar datos iniciales
    if (empty($tabla_destino) || empty($datos) || !is_array($datos)) {
        log_message("Error: Datos incompletos o inválidos.");
        echo json_encode(["error" => "Datos incompletos. Verifica la tabla destino, el mapeo y los datos enviados."]);
        http_response_code(400);
        exit;
    }

    // Verificar columnas válidas en la tabla destino
    $columnsQuery = "SHOW COLUMNS FROM `$tabla_destino`";
    $result = $conn->query($columnsQuery);
    if (!$result) {
        log_message("Error al obtener columnas de la tabla destino: " . $conn->error);
        echo json_encode(["error" => "Error al obtener columnas de la tabla destino."]);
        http_response_code(500);
        exit;
    }

    $columnasValidas = [];
    while ($row = $result->fetch_assoc()) {
        $columnasValidas[] = $row['Field'];
    }

    log_message("Columnas válidas en la tabla `$tabla_destino`: " . json_encode($columnasValidas));

    // Procesar y validar las filas antes de insertar
    foreach ($datos as $fila) {
        if (!is_array($fila)) {
            log_message("Error: La fila no es un array válido.");
            echo json_encode(["error" => "Fila inválida en los datos enviados."]);
            http_response_code(400);
            exit;
        }

        // Validar que las columnas mapeadas existan en la tabla destino
        $columnas = array_keys($fila);
        foreach ($columnas as $columna) {
            if (!in_array($columna, $columnasValidas)) {
                log_message("Error: La columna `$columna` no existe en la tabla `$tabla_destino`.");
                echo json_encode(["error" => "La columna `$columna` no es válida para la tabla `$tabla_destino`."]);
                http_response_code(400);
                exit;
            }
        }

        // Construir la consulta SQL
        $columnasSQL = implode(',', array_keys($fila));
        $valoresSQL = implode(',', array_map(function ($valor) use ($conn) {
            return "'" . $conn->real_escape_string($valor) . "'";
        }, array_values($fila)));

        $query = "INSERT INTO `$tabla_destino` ($columnasSQL) VALUES ($valoresSQL)";
        log_message("Ejecutando consulta: $query");

        // Ejecutar la consulta
        if (!$conn->query($query)) {
            log_message("Error al insertar: " . $conn->error);
            echo json_encode(["error" => "Error al guardar los datos en la base de datos. Consulta: $query. Error: " . $conn->error]);
            http_response_code(500);
            exit;
        }
    }

    // Confirmar éxito
    log_message("Datos guardados correctamente en la tabla $tabla_destino.");
    echo json_encode(["success" => "Todos los datos se guardaron correctamente."]);
} catch (Exception $e) {
    // Manejo de excepciones
    log_message("Excepción: " . $e->getMessage());
    echo json_encode(["error" => "Error interno del servidor: " . $e->getMessage()]);
    http_response_code(500);
    exit;
}
?>
