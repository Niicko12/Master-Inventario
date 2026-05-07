<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

require_once 'config.php';

// Encabezado para devolver respuestas en formato JSON
header('Content-Type: application/json');

// Función para registrar mensajes de log
function log_message($message) {
    $logFile = __DIR__ . '/log.txt';
    file_put_contents($logFile, date('Y-m-d H:i:s') . " - $message\n", FILE_APPEND);
}

// Función para validar datos según reglas específicas de cada columna
function validar_datos($dato, $columna) {
    if ($columna == 'email') {
        if (!filter_var($dato, FILTER_VALIDATE_EMAIL)) {
            return "El valor '$dato' no es un correo electrónico válido.";
        }
    }

    if ($columna == 'fecha') {
        $fecha = DateTime::createFromFormat('Y-m-d', $dato);
        if (!$fecha || $fecha->format('Y-m-d') !== $dato) {
            return "El valor '$dato' no es una fecha válida (formato: YYYY-MM-DD).";
        }
    }

    if ($columna == 'precio') {
        if (!is_numeric($dato) || $dato <= 0) {
            return "El valor '$dato' no es un precio válido.";
        }
    }

    // Agregar más validaciones según sea necesario
    return null; // Si no hay error, retorna null
}

// Verificar si la solicitud es POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    log_message("Método HTTP no permitido.");
    echo json_encode(["error" => "Método HTTP no permitido."]);
    http_response_code(405); // Código HTTP 405: Método no permitido
    exit;
}

try {
    $tabla_destino = $_POST['tabla_destino'] ?? null;
    $mapeo = $_POST['mapeo'] ?? null;
    $file = $_FILES['csv_file_modal']['tmp_name'] ?? null;

    // Validar si los datos requeridos están presentes
    if (empty($tabla_destino) || empty($mapeo) || !$file || !file_exists($file)) {
        log_message("Datos incompletos: tabla destino, mapeo o archivo CSV no proporcionados.");
        echo json_encode(["error" => "Datos incompletos. Verifica la tabla destino, el mapeo y el archivo CSV."]);
        http_response_code(400); // Código HTTP 400: Solicitud incorrecta
        exit;
    }

    $mapeo = json_decode($mapeo, true); // Decodificar el mapeo JSON
    if (json_last_error() !== JSON_ERROR_NONE) {
        log_message("Error al decodificar el mapeo JSON: " . json_last_error_msg());
        echo json_encode(["error" => "El mapeo enviado no es un JSON válido."]);
        exit;
    }

    // Leer el archivo CSV
    $handle = fopen($file, 'r');
    if (!$handle) {
        log_message("Error al abrir el archivo CSV.");
        echo json_encode(["error" => "No se pudo abrir el archivo CSV."]);
        http_response_code(500); // Código HTTP 500: Error interno del servidor
        exit;
    }

    // Leer las cabeceras del archivo CSV
    $cabeceras = fgetcsv($handle, 1000, ",");
    if (!$cabeceras) {
        log_message("El archivo CSV no contiene cabeceras.");
        echo json_encode(["error" => "El archivo CSV no contiene cabeceras."]);
        fclose($handle);
        exit;
    }

    $errores = [];
    $datos_validos = [];

    // Procesar cada fila del CSV
    while (($fila = fgetcsv($handle, 1000, ",")) !== false) {
        $filaAsociativa = array_combine($cabeceras, $fila);
        $filaInsertar = [];
        $erroresFila = [];

        // Validar y mapear columnas
        foreach ($mapeo as $columnaCsv => $columnaDb) {
            if (isset($filaAsociativa[$columnaCsv])) {
                $valor = $filaAsociativa[$columnaCsv];
                $validacionError = validar_datos($valor, $columnaDb);

                if ($validacionError) {
                    $erroresFila[$columnaDb] = $validacionError;
                } else {
                    $filaInsertar[$columnaDb] = $valor;
                }
            }
        }

        if (!empty($erroresFila)) {
            $errores[] = ["fila" => $filaAsociativa, "errores" => $erroresFila];
        } else {
            $datos_validos[] = $filaInsertar;
        }
    }

    fclose($handle);


if (empty($errores)) {
    // Devolver JSON indicando que todo está bien
    echo json_encode([
        "success" => "Datos agregados correctamente", // Indica que no hay errores
        "validos" => $datos_validos, // Enviar los datos válidos para ser procesados por el frontend
    ]);
} else {
    // Si hay errores, devolver JSON con los errores y datos válidos
    echo json_encode([
        "errores" => $errores,
        "validos" => $datos_validos,
    ]);
}

} catch (Exception $e) {
    log_message("Excepción: " . $e->getMessage());
    echo json_encode(["error" => "Error interno del servidor: " . $e->getMessage()]);
    http_response_code(500); // Código HTTP 500: Error interno del servidor
    exit;
}
