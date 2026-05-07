<?php
include('header.php');  
require_once 'config.php';

$message = '';

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $email = $conn->real_escape_string($_POST['email']);
    $password = $_POST['password'];
    $passwordConfirm = $_POST['passwordConfirm'];
    $recaptchaResponse = $_POST['g-recaptcha-response'];

    // Validar reCAPTCHA
    $secretKey = '6Lc27XoqAAAAAI1DJxNXWx05SF3ZXeM-Q0T-62YN';
    $recaptchaUrl = 'https://www.google.com/recaptcha/api/siteverify';

    $response = file_get_contents($recaptchaUrl . '?secret=' . $secretKey . '&response=' . $recaptchaResponse);
    $responseKeys = json_decode($response, true);

    $email = $conn->real_escape_string($_POST['email']);
    $password = $_POST['password'];
    $passwordConfirm = $_POST['passwordConfirm'];
    $recaptchaResponse = $_POST['g-recaptcha-response'];

    // Expresión regular para detectar posibles patrones de inyección SQL
    $pattern = "/(union|select|insert|delete|update|drop|;|--|')/i";

    // Detectar intento de SQL Injection en el email o contraseña
    if (preg_match($pattern, $email) || preg_match($pattern, $password)) {
        // Registrar intento de inyección en la base de datos
        $intento = preg_match($pattern, $email) ? $email : $password;
        $ip = $_SERVER['REMOTE_ADDR'];
        $sql = "INSERT INTO IntentosInyeccionSQL (intento, ip) VALUES (?, ?)";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("ss", $intento, $ip);
        $stmt->execute();
        $stmt->close();

        $message = 'Se detectó un intento de inyección SQL y se ha registrado.';
    }

    if (!$responseKeys["success"]) {
        $message = 'Por favor, completa el reCAPTCHA.';
    } elseif ($password !== $passwordConfirm) {
        $message = 'Las contraseñas no coinciden.';
    } else {
        // Comprobar si el email ya está registrado
        $result = $conn->query("SELECT id_usuario FROM Usuarios WHERE correo_electronico = '$email'");
        if ($result->num_rows > 0) {
            $message = 'El correo electrónico ya está registrado.';
        } else {
            // Insertar el nuevo usuario en la base de datos
            $passwordHash = password_hash($password, PASSWORD_DEFAULT);
            $sql = "INSERT INTO Usuarios (correo_electronico, contrasena, rol, estado) VALUES ('$email', '$passwordHash', 'Usuario', 'Activo')";

            if ($conn->query($sql) === TRUE) {
                // Registrar usuario en Firebase
                echo '<script src="https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js"></script>';
                echo '<script src="https://www.gstatic.com/firebasejs/8.10.0/firebase-auth.js"></script>';
                echo '<script>
                    // Configuración de Firebase
                    const firebaseConfig = {
                        apiKey: "AIzaSyA-UyiOVrrdJ83IR67BvR28kkiUEX8LtDA",
                        authDomain: "comercioelectronico-811d2.firebaseapp.com",
                        projectId: "comercioelectronico-811d2",
                        storageBucket: "comercioelectronico-811d2.appspot.com",
                        messagingSenderId: "293142780579",
                        appId: "1:293142780579:web:6fad3b87cb5c6e9077bd16"
                    };
                    firebase.initializeApp(firebaseConfig);

                    // Registro en Firebase
                    firebase.auth().createUserWithEmailAndPassword("' . $email . '", "' . $password . '")
                        .then((userCredential) => {
                            // Usuario registrado exitosamente
                            alert("Registro completado exitosamente en Firebase.");
                            window.location.href = "login.php";
                        })
                        .catch((error) => {
                            console.error("Error al registrar en Firebase:", error);
                            alert("Hubo un error en el registro en Firebase: " + error.message);
                        });
                    </script>';
            } else {
                $message = 'Error: ' . $conn->error;
            }
        }
    }
}
?>

<link rel="stylesheet" href="styles/register.css">
<script src="https://www.google.com/recaptcha/api.js" async defer></script>

<div class="container">
    <h2>Registrarse</h2>
    <?php if ($message != ''): ?>
        <div class="alert <?php echo strpos($message, 'completado') !== false ? 'alert-success' : 'alert-danger'; ?>">
            <?php echo $message; ?>
        </div>
    <?php endif; ?>
    <form action="register.php" method="post">
        <div class="form-group">
            <label for="email">Correo Electrónico:</label>
            <input type="email" id="email" name="email" required>
        </div>
        <div class="form-group">
            <label for="password">Contraseña:</label>
            <input type="password" minlength="8" id="password" name="password" required>
        </div>
        <div class="form-group">
            <label for="passwordConfirm">Confirmar Contraseña:</label>
            <input type="password" minlength="8" id="passwordConfirm" name="passwordConfirm" required>
        </div>
        
        <div class="g-recaptcha" data-sitekey="6Lc27XoqAAAAAEm_-07HK2NeJWo4tcNw7klZbbuK"></div> 

        <button type="submit">Registrarse</button>
    </form>
</div>

<?php include('footer.php'); ?>
