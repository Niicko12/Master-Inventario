<?php
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

require 'PHPMailer/src/Exception.php';
require 'PHPMailer/src/PHPMailer.php';
require 'PHPMailer/src/SMTP.php';

// Crear una nueva instancia de PHPMailer
$mail = new PHPMailer(true);

try {
    // Configuración del servidor SMTP
    $mail->isSMTP(); // Usar SMTP
    $mail->Host       = 'smtp.hostinger.com';  // Servidor SMTP de Hostinger
    $mail->SMTPAuth   = true; 
    $mail->Username   = 'limbermagana85@gmail.com'; // Tu correo de Hostinger
    $mail->Password   = 'm8xPQdem';  // Contraseña de tu correo
    $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;  // Seguridad TLS
    $mail->Port       = 587;  // Puerto SMTP (587 es común para TLS)

    // Remitente
    $mail->setFrom('limbermagana85@gmail.com', 'Tu Nombre o Empresa');

    // Obtener los correos electrónicos de todos los usuarios con correo registrado
    $sql = "SELECT correo_electronico FROM Usuarios WHERE correo_electronico IS NOT NULL";
    $result = $conn->query($sql);

    if ($result->num_rows > 0) {
        while ($row = $result->fetch_assoc()) {
            // Agregar cada correo de los usuarios
            $mail->addAddress($row['correo_electronico']);
        }
    }

    // Asunto del correo
    $mail->Subject = 'Reporte Semanal';

    // Cuerpo del correo (contenido en HTML)
    $mail->isHTML(true);
    $mail->Body    = '<h3>Hola,</h3><p>Adjunto encontrarás los reportes semanales generados en formato CSV o PDF.</p>';

    // Obtener todos los archivos en la carpeta 'reportes' y adjuntarlos
    $directory = 'reportes/';
    $files = glob($directory . '*'); // Obtener todos los archivos

    foreach ($files as $file) {
        if (is_file($file)) {
            // Adjuntar cada archivo encontrado
            $mail->addAttachment($file);
        }
    }

    // Enviar el correo
    $mail->send();
    echo 'Correo enviado exitosamente a todos los usuarios';
} catch (Exception $e) {
    echo "No se pudo enviar el correo. Error: {$mail->ErrorInfo}";
}
?>
