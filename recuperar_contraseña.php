<?php
require_once 'config.php';

$message      = '';
$message_type = 'info';
$instance_name = (string)systemSetting('nombre_instancia', 'Master Inventario');
$instance_logo = appResolveLogoPath();
if (str_starts_with($instance_logo, '../')) {
    $instance_logo = substr($instance_logo, 3);
}
$instance_logo = ltrim($instance_logo, '/');
$instance_logo_abs = __DIR__ . '/' . $instance_logo;
$instance_logo_version = file_exists($instance_logo_abs)
    ? (string)filemtime($instance_logo_abs)
    : (string)time();

// Step 1 — send code
if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST['send_code'])) {
    $email = trim($_POST['email'] ?? '');

    $user = dbFetchOne($conn,
        "SELECT id_usuario, telefono FROM Usuarios WHERE correo_electronico = ? AND estado = 'Activo'",
        "s", $email
    );

    if ($user) {
        $verification_code = random_int(100000, 999999);
        $_SESSION['verification_code'] = $verification_code;
        $_SESSION['user_email'] = $email;
        mail($email, "Código de verificación — {$instance_name}", "Tu código de verificación es: $verification_code\n\nEste código expira en 15 minutos.");
    }

    // Generic message to avoid user enumeration
    $message = "Si el correo está registrado, recibirás un código de verificación en breve.";
    $message_type = 'success';
}

// Step 2 — verify code
if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST['verify_code'])) {
    $entered_code = trim($_POST['verification_code'] ?? '');

    if (!empty($_SESSION['verification_code']) && $entered_code == $_SESSION['verification_code']) {
        $_SESSION['code_verified'] = true;
        header("Location: cambiar_contraseña.php");
        exit;
    } else {
        $message = "El código de verificación es incorrecto. Inténtalo de nuevo.";
        $message_type = 'error';
    }
}

$step = isset($_SESSION['verification_code']) && !isset($_SESSION['code_verified']) ? 2 : 1;
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Recuperar Contraseña — <?= htmlspecialchars($instance_name, ENT_QUOTES, 'UTF-8') ?></title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600;9..40,700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css">
    <link rel="stylesheet" href="styles/template-theme.css">
</head>
<body>

<div class="auth-wrapper">
    <div class="auth-card">

        <!-- Back link -->
        <a href="login.php" style="display:inline-flex;align-items:center;gap:6px;font-size:13px;color:var(--text-muted);margin-bottom:20px;transition:color 0.18s;"
           onmouseover="this.style.color='var(--primary)'" onmouseout="this.style.color='var(--text-muted)'">
            <i class="fas fa-arrow-left"></i> Volver al inicio de sesión
        </a>

        <!-- Logo -->
        <div class="auth-logo">
            <img src="<?= htmlspecialchars($instance_logo, ENT_QUOTES, 'UTF-8') ?>?v=<?= htmlspecialchars($instance_logo_version, ENT_QUOTES, 'UTF-8') ?>" alt="<?= htmlspecialchars($instance_name, ENT_QUOTES, 'UTF-8') ?>">
            <span class="auth-logo-text"><?= htmlspecialchars($instance_name, ENT_QUOTES, 'UTF-8') ?></span>
        </div>

        <?php if ($step === 1): ?>

        <h2 class="auth-title">¿Olvidaste tu contraseña?</h2>
        <p class="auth-subtitle">Ingresa tu correo y te enviaremos un código de verificación</p>

        <?php if (!empty($message)): ?>
        <div class="alert alert-<?= $message_type === 'error' ? 'danger' : $message_type ?>">
            <i class="fas fa-<?= $message_type === 'success' ? 'circle-check' : 'circle-exclamation' ?>"></i>
            <span><?= htmlspecialchars($message, ENT_QUOTES, 'UTF-8') ?></span>
        </div>
        <?php endif; ?>

        <form class="auth-form" action="recuperar_contraseña.php" method="post">
            <div class="form-group">
                <label for="email">Correo electrónico</label>
                <div class="input-icon-wrap">
                    <i class="fas fa-envelope input-icon"></i>
                    <input type="email" id="email" name="email"
                           placeholder="tu@correo.com" required
                           value="<?= htmlspecialchars($_SESSION['user_email'] ?? '', ENT_QUOTES, 'UTF-8') ?>">
                </div>
            </div>

            <button type="submit" name="send_code" class="btn-auth">
                <i class="fas fa-paper-plane" style="margin-right:6px;"></i>
                Enviar código de verificación
            </button>
        </form>

        <?php else: ?>

        <h2 class="auth-title">Verifica tu código</h2>
        <p class="auth-subtitle">Ingresa el código de 6 dígitos que enviamos a<br>
            <strong style="color:var(--dark);"><?= htmlspecialchars($_SESSION['user_email'] ?? '', ENT_QUOTES, 'UTF-8') ?></strong>
        </p>

        <?php if (!empty($message)): ?>
        <div class="alert alert-<?= $message_type === 'error' ? 'danger' : $message_type ?>">
            <i class="fas fa-circle-exclamation"></i>
            <span><?= htmlspecialchars($message, ENT_QUOTES, 'UTF-8') ?></span>
        </div>
        <?php endif; ?>

        <form class="auth-form" action="recuperar_contraseña.php" method="post">
            <div class="form-group">
                <label for="verification_code">Código de verificación</label>
                <div class="input-icon-wrap">
                    <i class="fas fa-shield-halved input-icon"></i>
                    <input type="text" id="verification_code" name="verification_code"
                           placeholder="000000" maxlength="6"
                           style="letter-spacing:6px;font-size:18px;font-weight:600;text-align:center;"
                           required autocomplete="one-time-code">
                </div>
            </div>

            <button type="submit" name="verify_code" class="btn-auth">
                <i class="fas fa-check" style="margin-right:6px;"></i>
                Verificar código
            </button>
        </form>

        <div style="margin-top:16px;text-align:center;">
            <form action="recuperar_contraseña.php" method="post" style="display:inline;">
                <input type="hidden" name="email" value="<?= htmlspecialchars($_SESSION['user_email'] ?? '', ENT_QUOTES, 'UTF-8') ?>">
                <?php
                    // Reset session so user can re-send
                    if (isset($_GET['resend'])) {
                        unset($_SESSION['verification_code']);
                    }
                ?>
                <button type="submit" name="send_code"
                    style="background:none;border:none;color:var(--primary);font-size:13px;font-weight:500;cursor:pointer;font-family:inherit;">
                    <i class="fas fa-rotate-right" style="margin-right:4px;"></i>
                    Reenviar código
                </button>
            </form>
        </div>

        <?php endif; ?>

        <div class="auth-footer">
            ¿Recordaste tu contraseña?
            <a href="login.php">Iniciar sesión</a>
        </div>

    </div>
</div>

</body>
</html>
