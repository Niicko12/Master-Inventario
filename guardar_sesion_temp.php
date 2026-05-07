<?php
session_start();
require_once 'config.php';

// Obtener datos del POST
$data = json_decode(file_get_contents('php://input'), true);

if ($data) {
    $_SESSION['temp_user_id'] = $data['user_id'];
    $_SESSION['temp_email'] = $data['email'];
    $_SESSION['temp_telefono'] = $data['telefono'];
    $_SESSION['temp_rol'] = $data['rol'];
    
    echo json_encode(['success' => true]);
} else {
    echo json_encode(['success' => false, 'error' => 'No se recibieron datos']);
}
?> 