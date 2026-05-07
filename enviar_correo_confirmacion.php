<?php
session_start();
require_once 'config.php';
require 'PHPMailer/src/Exception.php';
require 'PHPMailer/src/PHPMailer.php';
require 'PHPMailer/src/SMTP.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

// Code must come from session — never trust POST for the code
if (!isset($_SESSION['verification_code'])) {
    echo "error_no_code";
    exit;
}

$email  = $_SESSION['temp_email']  ?? ($_POST['email']  ?? '');
$nombre = $_SESSION['temp_nombre'] ?? ($_POST['nombre'] ?? 'Usuario');
$codigo = $_SESSION['verification_code'];

if (empty($email)) {
    echo "error_no_email";
    exit;
}

$mail = new PHPMailer(true);

try {
    $mail->isSMTP();
    $mail->Host       = $env['SMTP_HOST'] ?? 'smtp.gmail.com';
    $mail->SMTPAuth   = true;
    $mail->Username   = $env['SMTP_USER'] ?? '';
    $mail->Password   = $env['SMTP_PASS'] ?? '';
    $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
    $mail->Port       = (int)($env['SMTP_PORT'] ?? 587);
    $mail->CharSet    = 'UTF-8';

    $from_name = $env['SMTP_FROM_NAME'] ?? 'Sistema de Verificación';
    $mail->setFrom($mail->Username, $from_name);
    $mail->addAddress($email, $nombre);
    $mail->isHTML(true);
    $mail->Subject = 'Código de verificación 2FA';
    $mail->Body    = "
        <div style='font-family:Arial,sans-serif;max-width:600px;margin:0 auto;'>
            <h2 style='color:#333;'>Código de Verificación</h2>
            <p>Hola " . htmlspecialchars($nombre) . ",</p>
            <p>Tu código de verificación es:</p>
            <div style='background:#f5f5f5;padding:15px;text-align:center;font-size:28px;font-weight:bold;letter-spacing:6px;margin:20px 0;'>
                $codigo
            </div>
            <p>Válido por 10 minutos. No lo compartas con nadie.</p>
        </div>
    ";

    $mail->send();
    echo "success";
} catch (Exception $e) {
    echo "error_send";
}
