<?php
session_start();

// Habilitar reporte de errores para depuración
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);
ini_set('error_log', 'php_errors.log');

// Verificar si se recibió un código
if (isset($_POST['code'])) {
    $code = $_POST['code'];
    
    // Guardar el código en la sesión
    $_SESSION['verification_code'] = $code;
    
    // Log para depuración
    error_log("Código guardado en sesión: " . $code);
    error_log("Sesión actual: " . print_r($_SESSION, true));
    
    // Retornar éxito
    echo "success";
} else {
    error_log("No se recibió código para guardar");
    echo "error";
}
?> 