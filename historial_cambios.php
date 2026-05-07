<?php
require_once 'config.php';

// Iniciar sesión si no está iniciada
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

// Verificar si el usuario está autenticado
if (!isset($_SESSION['user_id'])) {
    http_response_code(401); // Código de error de no autorizado
    echo json_encode(['error' => 'Usuario no autenticado']);
    exit;
}

// Validar que el parámetro `doc_id` esté presente en la solicitud
if (isset($_GET['doc_id'])) {
    $doc_id = intval($_GET['doc_id']);
    
    // Preparar la consulta para recuperar el historial de cambios
    $sql = "SELECT * FROM Historial_Documentos WHERE id_documento = ? ORDER BY fecha_modificacion DESC";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $doc_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    // Crear un array para almacenar el historial
    $historial = [];
    while ($row = $result->fetch_assoc()) {
        $historial[] = $row;
    }
    $stmt->close();
    
    // Devolver el historial en formato JSON
    header('Content-Type: application/json');
    echo json_encode($historial);
} else {
    http_response_code(400); // Código de error de solicitud incorrecta
    echo json_encode(['error' => 'Parámetro doc_id es obligatorio']);
}
