<?php
session_start();
require_once 'config.php';



$user_id = $_SESSION['temp_user_id'];
$email = $_SESSION['temp_email'];
$nombre = $_SESSION['temp_nombre'] ?? 'Usuario';


?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Verificación por Correo - Limber</title>
    <link rel="stylesheet" href="styles/verificacion_2fa.css">
    <style>
        .container {
            max-width: 500px;
            margin: 50px auto;
            padding: 20px;
            background-color: #fff;
            border-radius: 8px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
        .verification-box {
            text-align: center;
        }
        .form-group {
            margin-bottom: 20px;
        }
        input[type="text"] {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 16px;
        }
        .btn-verify {
            background-color: #007bff;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
        }
        .btn-verify:hover {
            background-color: #0056b3;
        }
        .error-message {
            color: #dc3545;
            margin-top: 10px;
        }
        .success-message {
            color: #28a745;
            margin-top: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="verification-box">
            <h2>Verificación por Correo</h2>
            <p>Se ha enviado un código de verificación a tu correo electrónico (<?php echo htmlspecialchars($email); ?>)</p>
            
            <form id="verificationForm" method="post" action="verificar_codigo.php">
                <div class="form-group">
                    <label for="verificationCode">Código de Verificación</label>
                    <input type="text" id="verificationCode" name="verificationCode" required maxlength="6">
                </div>
                
                <button type="submit" class="btn-verify">Verificar</button>
            </form>
            
            <div id="error-message" class="error-message"></div>
            <div id="success-message" class="success-message"></div>
        </div>
    </div>

    <script>
        // Mostrar el código de verificación en la consola de manera más visible
        console.log('%c=== CÓDIGO DE VERIFICACIÓN ===', 'background: #007bff; color: white; padding: 5px; border-radius: 5px;');
        console.log('%cCódigo almacenado en sesión:', 'font-size: 16px; font-weight: bold; color: #007bff;');
        console.log('<?php echo isset($_SESSION['verification_code']) ? $_SESSION['verification_code'] : "No hay código en la sesión"; ?>');
        console.log('%cDatos de la sesión:', 'font-size: 16px; font-weight: bold; color: #007bff;');
        console.log(<?php echo json_encode($_SESSION); ?>);
        console.log('%c=========================', 'background: #007bff; color: white; padding: 5px; border-radius: 5px;');

        document.getElementById('verificationForm').addEventListener('submit', function(e) {
            e.preventDefault();
            
            const code = document.getElementById('verificationCode').value;
            console.log('Código ingresado:', code);
            
            const formData = new FormData();
            formData.append('verificationCode', code);
            
            fetch('verificar_codigo.php', {
                method: 'POST',
                body: formData
            })
            .then(response => response.text())
            .then(text => {
                console.log('Respuesta del servidor:', text);
                if (text.includes('success')) {
                    // Redirigir al dashboard después de una verificación exitosa
                    window.location.href = 'index.php';
                } else if (text.includes('error_session')) {
                    document.getElementById('error-message').textContent = 'Error de sesión. Por favor, inicie sesión nuevamente.';
                } else if (text.includes('error_code')) {
                    document.getElementById('error-message').textContent = 'Código inválido. Por favor, intente nuevamente.';
                } else if (text.includes('error_mismatch')) {
                    document.getElementById('error-message').textContent = 'El código ingresado no coincide. Por favor, intente nuevamente.';
                } else {
                    document.getElementById('error-message').textContent = 'Error al verificar el código. Por favor, intente nuevamente.';
                }
            })
            .catch(error => {
                console.error('Error en la verificación:', error);
                document.getElementById('error-message').textContent = 'Error al verificar el código. Por favor, intente nuevamente.';
            });
        });
    </script>
</body>
</html> 