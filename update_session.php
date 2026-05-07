<?php
session_start();
header('Content-Type: application/json');

// Transferir los datos temporales a la sesión permanente
if (isset($_SESSION['temp_user_id']) && isset($_SESSION['temp_user_role'])) {
    $_SESSION['user_id'] = $_SESSION['temp_user_id'];
    $_SESSION['user_role'] = $_SESSION['temp_user_role'];

    // Eliminar datos temporales de la sesión
    unset($_SESSION['temp_user_id'], $_SESSION['temp_user_role'], $_SESSION['temp_telefono']);

    // Responder con éxito y el rol del usuario
    echo json_encode([
        'success' => true,
        'user_role' => $_SESSION['user_role']
    ]);
} else {
    // Si no existen datos temporales, responder con error
    echo json_encode(['success' => false]);
}
?>
