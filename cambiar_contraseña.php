<?php
include('header.php');  // Incluye el header
require_once 'config.php';


$message = '';
$instance_name = (string)systemSetting('nombre_instancia', 'Master Inventario');

if (!isset($_SESSION['code_verified']) || !$_SESSION['code_verified']) {
    // Si el código no ha sido verificado, redirige al usuario de regreso
    header("Location: recuperar_contraseña.php");
    exit;
}

if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST['change_password'])) {
    $new_password = $_POST['new_password'];
    $confirm_password = $_POST['confirm_password'];

    if ($new_password === $confirm_password) {
        $hashed_password = password_hash($new_password, PASSWORD_BCRYPT);
        $email = $_SESSION['user_email'] ?? '';

        // Prepared statement — never interpolate credentials into SQL
        $updated = dbExecute($conn,
            "UPDATE Usuarios SET contrasena = ? WHERE correo_electronico = ?",
            "ss", $hashed_password, $email
        );

        if ($updated) {
            session_destroy();
            echo "<script>
                alert('La contraseña se ha cambiado correctamente.');
                window.location.href = 'login.php';
                </script>";
        } else {
            $message = "Hubo un error al cambiar la contraseña. Intenta nuevamente.";
        }
    } else {
        $message = "Las contraseñas no coinciden.";
    }
}
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cambiar Contraseña — <?= htmlspecialchars($instance_name, ENT_QUOTES, 'UTF-8') ?></title>
    <link rel="stylesheet" href="styles/change_password.css">
</head>
<body>

<div class="container">
    <h2>Cambiar Contraseña — <?= htmlspecialchars($instance_name, ENT_QUOTES, 'UTF-8') ?></h2>
    <?php if (!empty($message)): ?>
        <div class="alert alert-danger"><?php echo htmlspecialchars($message, ENT_HTML5, 'UTF-8'); ?></div>
    <?php endif; ?>
    <form action="cambiar_contraseña.php" method="post">
        <div class="form-group">
            <label for="new_password">Nueva Contraseña:</label>
            <input type="password" id="new_password" name="new_password" required>
        </div>
        <div class="form-group">
            <label for="confirm_password">Confirmar Nueva Contraseña:</label>
            <input type="password" id="confirm_password" name="confirm_password" required>
        </div>
        <button type="submit" name="change_password" class="btn-primary">Cambiar Contraseña</button>
    </form>
</div>

<?php include('footer.php');  // Incluye el footer ?>

</body>
</html>
