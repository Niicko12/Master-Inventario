<?php
// Habilitar errores para depuración
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Configurar el encabezado de la respuesta para JSON
header('Content-Type: application/json');

// Incluir configuración de la base de datos
require_once 'config.php';

try {
    // Validar el método HTTP
    if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
        http_response_code(405);
        echo json_encode(["error" => "Método HTTP no permitido."]);
        exit;
    }

    // Validar parámetros requeridos
    $tabla_destino = $_GET['tabla_destino'] ?? null;
    if (!$tabla_destino) {
        http_response_code(400);
        echo json_encode(["error" => "Falta el parámetro 'tabla_destino'."]);
        exit;
    }

    // Preparar y ejecutar la consulta para describir la tabla
    $query = $conn->prepare("DESCRIBE `$tabla_destino`");
    if (!$query) {
        throw new Exception("Error al preparar la consulta: " . $conn->error);
    }

    $query->execute();
    $result = $query->get_result();

    if (!$result) {
        throw new Exception("Error al ejecutar la consulta: " . $conn->error);
    }

    // Obtener las columnas de la tabla
    $columnas = [];
    while ($fila = $result->fetch_assoc()) {
        $columnas[] = $fila['Field']; // El campo 'Field' contiene el nombre de la columna
    }

    // Validar resultado
    if (empty($columnas)) {
        http_response_code(404);
        echo json_encode(["error" => "No se encontraron columnas para la tabla especificada."]);
        exit;
    }

    // Responder con las columnas en formato JSON
    echo json_encode($columnas);
} catch (mysqli_sql_exception $e) {
    // Manejar errores de MySQLi
    http_response_code(500);
    echo json_encode(["error" => "Error en la base de datos: " . $e->getMessage()]);
    error_log("Error MySQLi: " . $e->getMessage());
} catch (Exception $e) {
    // Manejar errores generales
    http_response_code(500);
    echo json_encode(["error" => "Error inesperado: " . $e->getMessage()]);
    error_log("Error general: " . $e->getMessage());
}
?>
