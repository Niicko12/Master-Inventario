<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Configurar encabezado para devolver JSON
header('Content-Type: application/json');

// Configurar archivo de log
$logFile = __DIR__ . '/log_api.log';

function logToFile($message) {
    global $logFile;
    $date = date('Y-m-d H:i:s');
    file_put_contents($logFile, "[$date] $message\n", FILE_APPEND);
}

try {
    // Validar método HTTP
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        http_response_code(405);
        logToFile("Error: Método HTTP no permitido.");
        echo json_encode(["error" => "Método HTTP no permitido."]);
        exit;
    }

    // Capturar datos recibidos
    $tabla_destino = $_POST['tabla_destino'] ?? null;
    $mapeoApi = $_POST['mapeoApi'] ?? null;
    $datosApi = json_decode($_POST['datosApi'] ?? '', true); // Datos enviados desde la API

    // Validar parámetros obligatorios
    if (!$tabla_destino || !$mapeoApi || !$datosApi) {
        http_response_code(400);
        logToFile("Error: Faltan parámetros obligatorios.");
        logToFile("tabla_destino: " . json_encode($tabla_destino));
        logToFile("mapeoApi: " . json_encode($mapeoApi));
        logToFile("datosApi: " . json_encode($datosApi));
        echo json_encode(["error" => "Faltan parámetros obligatorios."]);
        exit;
    }

    // Decodificar mapeo si está en formato JSON
    if (is_string($mapeoApi)) {
        $mapeoApi = json_decode($mapeoApi, true);
        if (json_last_error() !== JSON_ERROR_NONE) {
            http_response_code(400);
            logToFile("Error al decodificar el mapeo JSON: " . json_last_error_msg());
            echo json_encode(["error" => "Error al decodificar el mapeo JSON: " . json_last_error_msg()]);
            exit;
        }
    }

    // Log para confirmar recepción de datos
    logToFile("Datos recibidos para procesar:");
    logToFile("Tabla destino: $tabla_destino");
    logToFile("Cabeceras de mapeo: " . json_encode($mapeoApi));
    logToFile("Datos recibidos: " . json_encode($datosApi));

    // Incluir configuración de la base de datos
    require_once 'config.php';

    // Validar conexión a la base de datos
    if (!$conn) {
        throw new Exception("Error al conectar a la base de datos.");
    }

    // Obtener columnas de la tabla destino
    $query = $conn->prepare("DESCRIBE `$tabla_destino`");
    if (!$query) {
        throw new Exception("Error al preparar la consulta para obtener columnas de la tabla.");
    }

    $query->execute();
    $result = $query->get_result();

    if (!$result) {
        throw new Exception("Error al ejecutar la consulta para obtener columnas de la tabla.");
    }

    // Recopilar las columnas de la base de datos
    $columnasBD = [];
    while ($fila = $result->fetch_assoc()) {
        $columnasBD[] = $fila['Field'];
    }

    if (empty($columnasBD)) {
        http_response_code(404);
        logToFile("Error: No se encontraron columnas para la tabla especificada.");
        echo json_encode(["error" => "No se encontraron columnas para la tabla especificada."]);
        exit;
    }

    // Validar mapeo
    $erroresMapeo = [];
    foreach ($mapeoApi as $columnaApi => $columnaBD) {
        if (!in_array($columnaBD, $columnasBD)) {
            $erroresMapeo[] = "La columna `$columnaBD` no es válida en la tabla `$tabla_destino`.";
        }
    }

    if (!empty($erroresMapeo)) {
        http_response_code(400);
        logToFile("Errores en el mapeo: " . json_encode($erroresMapeo));
        echo json_encode([
            "error" => "Errores en el mapeo.",
            "detalles" => $erroresMapeo,
        ]);
        exit;
    }

    // Preparar consulta de inserción
    $columnasInsert = implode(", ", array_values($mapeoApi)); // Nombres de columnas en la tabla
    $placeholders = implode(", ", array_fill(0, count($mapeoApi), "?")); // Placeholders para valores
    $sql = "INSERT INTO `$tabla_destino` ($columnasInsert) VALUES ($placeholders)";

    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        throw new Exception("Error al preparar la consulta SQL: " . $conn->error);
    }

    // Insertar datos en la tabla
    $filasInsertadas = 0;
    foreach ($datosApi as $fila) {
        $valores = [];
        foreach ($mapeoApi as $columnaApi => $columnaBD) {
            $valores[] = $fila[$columnaApi];
        }

        if ($stmt->execute($valores)) {
            $filasInsertadas++;
        } else {
            logToFile("Error al insertar fila: " . json_encode($fila));
        }
    }

    // Verificar resultado de la inserción
    if ($filasInsertadas > 0) {
        logToFile("Inserción exitosa: $filasInsertadas filas insertadas.");
        echo json_encode([
            "success" => true,
            "mensaje" => "$filasInsertadas filas insertadas correctamente en `$tabla_destino`.",
        ]);
    } else {
        http_response_code(500);
        logToFile("Error: No se pudieron insertar los datos en `$tabla_destino`.");
        echo json_encode(["error" => "No se pudieron insertar los datos en `$tabla_destino`."]);
    }

} catch (PDOException $e) {
    http_response_code(500);
    logToFile("Error en la base de datos: " . $e->getMessage());
    echo json_encode(["error" => "Error en la base de datos: " . $e->getMessage()]);
    exit;
} catch (Exception $e) {
    http_response_code(500);
    logToFile("Error inesperado: " . $e->getMessage());
    echo json_encode(["error" => "Error inesperado: " . $e->getMessage()]);
    exit;
}
?>
