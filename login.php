<?php
header("X-Content-Type-Options: nosniff");
header("Referrer-Policy: strict-origin-when-cross-origin");
header("Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net https://cdnjs.cloudflare.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com https://cdnjs.cloudflare.com; font-src 'self' https://fonts.gstatic.com https://cdnjs.cloudflare.com; img-src 'self' data: https:; object-src 'none'; base-uri 'self';");

require_once 'config.php';
require_once 'functions/auth_rate_limit.php';

// Redirect if already logged in
if (!empty($_SESSION['user_id'])) {
    header('Location: index.php');
    exit;
}

$message = '';
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

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $email    = trim($_POST['email']    ?? '');
    $password = trim($_POST['password'] ?? '');
    $ip       = $_SERVER['REMOTE_ADDR'];

    // === RATE LIMITING ===
    if (!checkIPRateLimit($conn, $ip)) {
        $message = 'Demasiadas solicitudes desde tu red. Espera unos minutos.';
    }

    if (empty($message)) {
        $rl = checkAccountRateLimit($conn, $email);
        if (!$rl['allowed']) {
            $message = "Demasiados intentos fallidos. Tu cuenta estará disponible en {$rl['lockout_minutes']} minutos. <a href='recuperar_contraseña.php'>¿Olvidaste tu contraseña?</a>";
            if ($rl['attempts'] === 5) {
                $row_name = dbFetchOne($conn, "SELECT nombre FROM Usuarios WHERE correo_electronico = ? LIMIT 1", "s", $email);
                $nombre_bloqueado = $row_name['nombre'] ?? $email;
                notifyAdminAccountLocked($conn, $email, $nombre_bloqueado, $ip, $rl['lockout_minutes']);
            }
        }
    }

    if (empty($message)) {
        $pattern = "/(union|select|insert|delete|update|drop|;|--|')/i";
        if (preg_match($pattern, $email) || preg_match($pattern, $password)) {
            $intento = preg_match($pattern, $email) ? $email : $password;
            dbExecute($conn, "INSERT INTO IntentosInyeccionSQL (intento, ip) VALUES (?, ?)", "ss", $intento, $ip);
            $message = 'Se detectó un intento de inyección SQL y se ha registrado.';
        }
    }

    if (empty($message)) {
        $user = dbFetchOne($conn,
            "SELECT id_usuario, correo_electronico, contrasena, rol, telefono, nombre FROM Usuarios WHERE correo_electronico = ? AND estado = 'Activo'",
            "s", $email
        );

        if ($user && password_verify($password, $user['contrasena'])) {
            recordLoginAttempt($conn, $email, $ip, true);
            session_regenerate_id(true);
            $_SESSION['user_id']   = $user['id_usuario'];
            $_SESSION['user_role'] = $user['rol'];
            $_SESSION['telefono']  = $user['telefono'];
            $_SESSION['email']     = $user['correo_electronico'];
            $_SESSION['nombre']    = $user['nombre'];
            header("Location: index.php");
            exit;
        } else {
            password_verify('dummy', '$2y$12$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ01');
            recordLoginAttempt($conn, $email, $ip, false);
            $message = 'Credenciales incorrectas. Verifica tu correo y contraseña.';
        }
    }
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Iniciar Sesión — <?= htmlspecialchars($instance_name, ENT_QUOTES, 'UTF-8') ?></title>
    <link rel="shortcut icon" type="image/png" href="assets/images/logos/favicon.png">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600;9..40,700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css">
    <link rel="stylesheet" href="styles/template-theme.css">
    <style>
        /* ── Two-column auth layout (matching reference image 7) ── */
        body { margin: 0; padding: 0; }

        .auth-split {
            display: flex;
            min-height: 100vh;
        }

        /* Left panel — full photo background */
        .auth-split-left {
            flex: 1;
            background: #0a1228 url('assets/images/background/asas.png') center/cover no-repeat;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 48px;
            position: relative;
            overflow: hidden;
        }

        /* Dark overlay for text legibility */
        .auth-split-left::before {
            content: '';
            position: absolute;
            inset: 0;
            background: linear-gradient(165deg, rgba(10,18,40,0.62) 0%, rgba(10,18,40,0.42) 55%, rgba(5,12,32,0.68) 100%);
            z-index: 0;
        }

        .auth-split-left::after { display: none; }

        .auth-split-left-inner {
            max-width: 420px;
            text-align: center;
            z-index: 1;
            position: relative;
        }

        .auth-left-logo {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            gap: 10px;
            margin-bottom: 14px;
        }

        .auth-left-logo img {
            width: 168px;
            height: 168px;
            object-fit: contain;
            border-radius: 26px;
            background: rgba(255,255,255,0.95);
            padding: 14px;
            box-shadow: 0 22px 44px rgba(0,0,0,0.38);
            border: 1px solid rgba(255,255,255,0.22);
        }

        .auth-left-logo-name {
            font-size: 24px;
            font-weight: 800;
            color: #ffffff;
            line-height: 1.15;
            letter-spacing: 0.2px;
            text-shadow: 0 2px 8px rgba(0,0,0,0.4);
        }

        .auth-left-caption {
            margin: 0 0 14px;
            font-size: 13px;
            color: rgba(255,255,255,0.78);
            font-weight: 500;
            text-align: center;
        }

        /* Right panel — white form side */
        .auth-split-right {
            width: 480px;
            flex-shrink: 0;
            background: #fff;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 48px 56px;
        }

        .auth-split-right-inner {
            width: 100%;
            max-width: 380px;
        }

        .auth-split-title {
            font-size: 26px;
            font-weight: 700;
            color: var(--dark);
            margin-bottom: 6px;
            line-height: 1.2;
        }

        .auth-split-subtitle {
            font-size: 14px;
            color: var(--text-muted);
            margin-bottom: 32px;
        }

        /* Responsive — stack on mobile */
        @media (max-width: 900px) {
            .auth-split-left  { display: none; }
            .auth-split-right {
                width: 100%;
                padding: 32px 24px;
            }
        }
    </style>
</head>
<body>

<div class="auth-split">

    <!-- Left: Illustrated panel -->
    <div class="auth-split-left">
        <div class="auth-split-left-inner">
            <div class="auth-left-logo">
                <img src="<?= htmlspecialchars($instance_logo, ENT_QUOTES, 'UTF-8') ?>?v=<?= htmlspecialchars($instance_logo_version, ENT_QUOTES, 'UTF-8') ?>" alt="<?= htmlspecialchars($instance_name, ENT_QUOTES, 'UTF-8') ?>">
                <span class="auth-left-logo-name"><?= htmlspecialchars($instance_name, ENT_QUOTES, 'UTF-8') ?></span>
            </div>
            <p class="auth-left-caption">Plataforma central para control y operación de inventario</p>
            <!-- Feature chips -->
            <div style="display:flex;gap:10px;justify-content:center;margin-top:20px;flex-wrap:wrap;">
                <div style="background:rgba(255,255,255,0.14);backdrop-filter:blur(8px);border:1px solid rgba(255,255,255,0.22);border-radius:12px;padding:8px 16px;display:flex;align-items:center;gap:8px;">
                    <span style="width:8px;height:8px;border-radius:50%;background:#13deb9;display:inline-block;"></span>
                    <span style="font-size:12px;font-weight:600;color:#fff;">Control de Stock</span>
                </div>
                <div style="background:rgba(255,255,255,0.14);backdrop-filter:blur(8px);border:1px solid rgba(255,255,255,0.22);border-radius:12px;padding:8px 16px;display:flex;align-items:center;gap:8px;">
                    <span style="width:8px;height:8px;border-radius:50%;background:#5d87ff;display:inline-block;"></span>
                    <span style="font-size:12px;font-weight:600;color:#fff;">Ventas &amp; Compras</span>
                </div>
                <div style="background:rgba(255,255,255,0.14);backdrop-filter:blur(8px);border:1px solid rgba(255,255,255,0.22);border-radius:12px;padding:8px 16px;display:flex;align-items:center;gap:8px;">
                    <span style="width:8px;height:8px;border-radius:50%;background:#ffae1f;display:inline-block;"></span>
                    <span style="font-size:12px;font-weight:600;color:#fff;">Reportes PDF/Excel</span>
                </div>
            </div>
        </div>
    </div>

    <!-- Right: Form panel -->
    <div class="auth-split-right">
        <div class="auth-split-right-inner">

            <h2 class="auth-split-title">Bienvenido a <?= htmlspecialchars($instance_name, ENT_QUOTES, 'UTF-8') ?></h2>
            <p class="auth-split-subtitle">Tu panel de administración</p>

            <?php if (!empty($message)): ?>
            <div class="alert alert-danger">
                <i class="fas fa-circle-exclamation"></i>
                <span><?= $message ?></span>
            </div>
            <?php endif; ?>

            <?php if (isset($_GET['registered'])): ?>
            <div class="alert alert-success">
                <i class="fas fa-circle-check"></i>
                <span>Cuenta creada exitosamente. Ya puedes iniciar sesión.</span>
            </div>
            <?php endif; ?>

            <form class="auth-form" action="login.php" method="post" id="login-form">

                <div class="form-group">
                    <label for="email">Correo electrónico</label>
                    <div class="input-icon-wrap">
                        <i class="fas fa-envelope input-icon"></i>
                        <input type="email" id="email" name="email"
                               placeholder="tu@correo.com" required
                               value="<?= htmlspecialchars($_POST['email'] ?? '', ENT_QUOTES, 'UTF-8') ?>">
                    </div>
                </div>

                <div class="form-group">
                    <label for="password">Contraseña</label>
                    <div class="input-icon-wrap">
                        <i class="fas fa-lock input-icon"></i>
                        <input type="password" id="password" name="password"
                               placeholder="••••••••" required>
                    </div>
                </div>

                <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:24px;">
                    <label class="auth-remember">
                        <input type="checkbox" name="remember" style="width:15px;height:15px;accent-color:var(--primary);">
                        Recordarme
                    </label>
                    <a href="recuperar_contraseña.php" class="auth-link">¿Olvidaste tu contraseña?</a>
                </div>

                <button type="submit" class="btn-auth">
                    Iniciar Sesión
                </button>

            </form>

            <div class="auth-footer">
                ¿No tienes cuenta?
                <a href="register.php">Crear cuenta</a>
            </div>

        </div>
    </div>

</div>

</body>
</html>
