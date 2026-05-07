<?php
header("X-Content-Type-Options: nosniff");
header("Referrer-Policy: strict-origin-when-cross-origin");
header("Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net https://cdnjs.cloudflare.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com https://cdnjs.cloudflare.com; font-src 'self' https://fonts.gstatic.com https://cdnjs.cloudflare.com; img-src 'self' data: https:; object-src 'none'; base-uri 'self';");

require_once 'config.php';

// Redirect if already logged in
if (!empty($_SESSION['user_id'])) {
    header('Location: index.php');
    exit;
}

$message      = '';
$message_type = '';
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
    $nombre          = trim($_POST['nombre']          ?? '');
    $email           = trim($_POST['email']           ?? '');
    $password        = $_POST['password']             ?? '';
    $passwordConfirm = $_POST['passwordConfirm']      ?? '';
    $esAdmin         = isset($_POST['esAdmin']);

    $telefono = '';
    $rol      = 'Usuario';

    if ($esAdmin) {
        $codigoPais     = $conn->real_escape_string($_POST['codigo_pais']      ?? '+52');
        $numeroTelefono = $conn->real_escape_string($_POST['numero_telefono']  ?? '');
        $telefono       = $codigoPais . preg_replace('/\s+/', '', $numeroTelefono);
        $rol            = $conn->real_escape_string($_POST['rol'] ?? 'Empleado');
    }

    $pattern = "/(union|select|insert|delete|update|drop|;|--|')/i";
    if (preg_match($pattern, $email) || preg_match($pattern, $nombre) ||
        ($esAdmin && (preg_match($pattern, $telefono) || preg_match($pattern, $rol)))) {
        $intento = $email;
        $ip = $_SERVER['REMOTE_ADDR'];
        $stmt = $conn->prepare("INSERT INTO IntentosInyeccionSQL (intento, ip) VALUES (?, ?)");
        $stmt->bind_param("ss", $intento, $ip);
        $stmt->execute();
        $stmt->close();
        $message = 'Se detectó un intento de inyección SQL y se ha registrado.';
        $message_type = 'error';
    } elseif ($password !== $passwordConfirm) {
        $message = 'Las contraseñas no coinciden.';
        $message_type = 'error';
    } elseif (strlen($password) < 8) {
        $message = 'La contraseña debe tener al menos 8 caracteres.';
        $message_type = 'error';
    } else {
        $stmt = $conn->prepare("SELECT id_usuario FROM Usuarios WHERE correo_electronico = ?");
        $stmt->bind_param("s", $email);
        $stmt->execute();
        $result = $stmt->get_result();
        $stmt->close();

        if ($result->num_rows > 0) {
            $message = 'El correo electrónico ya está registrado. Intenta con otro o recupera tu contraseña.';
            $message_type = 'error';
        } else {
            $passwordHash = password_hash($password, PASSWORD_DEFAULT);
            $stmt = $conn->prepare("INSERT INTO Usuarios (nombre, correo_electronico, contrasena, rol, estado, telefono, fecha_creacion) VALUES (?, ?, ?, ?, 'Activo', ?, NOW())");
            $stmt->bind_param("sssss", $nombre, $email, $passwordHash, $rol, $telefono);

            if ($stmt->execute()) {
                $stmt->close();
                header('Location: login.php?registered=true');
                exit;
            } else {
                $stmt->close();
                $message = 'Error al registrar el usuario. Inténtalo de nuevo.';
                $message_type = 'error';
            }
        }
    }
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Crear Cuenta — <?= htmlspecialchars($instance_name, ENT_QUOTES, 'UTF-8') ?></title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600;9..40,700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css">
    <link rel="stylesheet" href="styles/template-theme.css">
</head>
<body>

<div class="auth-wrapper">
    <div class="auth-card" style="max-width:500px;">

        <!-- Logo -->
        <div class="auth-logo" style="display:flex;flex-direction:column;align-items:center;justify-content:center;gap:8px;margin-bottom:12px;text-align:center;">
            <img src="<?= htmlspecialchars($instance_logo, ENT_QUOTES, 'UTF-8') ?>?v=<?= htmlspecialchars($instance_logo_version, ENT_QUOTES, 'UTF-8') ?>" alt="<?= htmlspecialchars($instance_name, ENT_QUOTES, 'UTF-8') ?>" style="height:56px;width:56px;object-fit:contain;border-radius:50%;">
            <div style="text-align:center;">
                <div style="font-size:17px;font-weight:800;color:var(--dark);line-height:1.1;"><?= htmlspecialchars($instance_name, ENT_QUOTES, 'UTF-8') ?></div>
                <div style="font-size:10px;color:var(--text-muted);letter-spacing:0.5px;"><?= htmlspecialchars(mb_strtoupper($instance_name), ENT_QUOTES, 'UTF-8') ?></div>
            </div>
        </div>
        <h2 class="auth-title" style="text-align:center;">Crear cuenta</h2>
        <p class="auth-subtitle" style="text-align:center;">Completa los datos para registrarte en el sistema</p>

        <?php if (!empty($message)): ?>
        <div class="alert alert-<?= $message_type === 'error' ? 'danger' : $message_type ?>">
            <i class="fas fa-<?= $message_type === 'error' ? 'circle-exclamation' : 'circle-check' ?>"></i>
            <span><?= htmlspecialchars($message, ENT_QUOTES, 'UTF-8') ?></span>
        </div>
        <?php endif; ?>

        <form class="auth-form" action="register.php" method="post" id="register-form">

            <div class="form-group">
                <label for="nombre">Nombre completo</label>
                <div class="input-icon-wrap">
                    <i class="fas fa-user input-icon"></i>
                    <input type="text" id="nombre" name="nombre" placeholder="Tu nombre completo" required
                           value="<?= htmlspecialchars($_POST['nombre'] ?? '', ENT_QUOTES, 'UTF-8') ?>">
                </div>
            </div>

            <div class="form-group">
                <label for="email">Correo electrónico</label>
                <div class="input-icon-wrap">
                    <i class="fas fa-envelope input-icon"></i>
                    <input type="email" id="email" name="email" placeholder="tu@correo.com" required
                           value="<?= htmlspecialchars($_POST['email'] ?? '', ENT_QUOTES, 'UTF-8') ?>">
                </div>
            </div>

            <div style="display:grid;grid-template-columns:1fr 1fr;gap:16px;">
                <div class="form-group">
                    <label for="password">Contraseña</label>
                    <input type="password" id="password" name="password"
                           placeholder="Mínimo 8 caracteres" minlength="8" required>
                </div>
                <div class="form-group">
                    <label for="passwordConfirm">Confirmar contraseña</label>
                    <input type="password" id="passwordConfirm" name="passwordConfirm"
                           placeholder="Repite tu contraseña" minlength="8" required>
                </div>
            </div>

            <!-- Admin toggle -->
            <div class="form-group" style="background:#f8fafc;border:1px solid var(--border-color);border-radius:var(--radius-md);padding:14px 16px;">
                <label class="auth-remember" style="cursor:pointer;user-select:none;margin:0;">
                    <input type="checkbox" id="esAdmin" name="esAdmin" onchange="toggleAdminFields()"
                           style="width:16px;height:16px;accent-color:var(--primary);">
                    <span style="font-weight:600;color:var(--dark);">Registrar como Administrador / Empleado</span>
                </label>
                <p style="font-size:11px;color:var(--text-muted);margin-top:4px;margin-left:24px;">
                    Solo para configuración inicial o cuentas con acceso extendido
                </p>
            </div>

            <!-- Admin extra fields -->
            <div id="adminFields" style="display:none;">
                <div style="display:grid;grid-template-columns:auto 1fr;gap:12px;" class="form-group">
                    <div>
                        <label>País</label>
                        <select id="codigo_pais" name="codigo_pais" style="width:130px;">
                            <option value="+52">México (+52)</option>
                            <option value="+57">Colombia (+57)</option>
                            <option value="+1">EE.UU. (+1)</option>
                            <option value="+34">España (+34)</option>
                            <option value="+54">Argentina (+54)</option>
                            <option value="+55">Brasil (+55)</option>
                            <option value="+56">Chile (+56)</option>
                            <option value="+51">Perú (+51)</option>
                            <option value="+58">Venezuela (+58)</option>
                            <option value="+503">El Salvador (+503)</option>
                            <option value="+504">Honduras (+504)</option>
                            <option value="+505">Nicaragua (+505)</option>
                            <option value="+502">Guatemala (+502)</option>
                        </select>
                    </div>
                    <div>
                        <label for="numero_telefono">Teléfono</label>
                        <input type="tel" id="numero_telefono" name="numero_telefono" placeholder="Número de teléfono">
                    </div>
                </div>

                <div class="form-group">
                    <label for="rol">Rol</label>
                    <select id="rol" name="rol" class="form-select">
                        <option value="Administrador">Administrador</option>
                        <option value="Empleado">Empleado</option>
                    </select>
                </div>
            </div>

            <button type="submit" class="btn-auth" style="margin-top:4px;">
                <i class="fas fa-user-plus" style="margin-right:6px;"></i>
                Crear cuenta
            </button>

        </form>

        <div class="auth-footer" style="text-align:center;">
            ¿Ya tienes cuenta?
            <a href="login.php">Iniciar sesión</a>
        </div>

    </div>
</div>

<script>
function toggleAdminFields() {
    const adminFields      = document.getElementById('adminFields');
    const checkbox         = document.getElementById('esAdmin');
    const telefonoInput    = document.getElementById('numero_telefono');
    const codigoPaisSelect = document.getElementById('codigo_pais');
    const rolSelect        = document.getElementById('rol');

    if (checkbox.checked) {
        adminFields.style.display = 'block';
        telefonoInput.required    = true;
        rolSelect.required        = true;
    } else {
        adminFields.style.display = 'none';
        telefonoInput.required    = false;
        rolSelect.required        = false;
        telefonoInput.value       = '';
    }
}

document.getElementById('register-form').addEventListener('submit', function () {
    if (document.getElementById('esAdmin').checked) {
        const codigo  = document.getElementById('codigo_pais').value;
        const numero  = document.getElementById('numero_telefono').value.replace(/\s/g, '');
        const hidden  = document.createElement('input');
        hidden.type   = 'hidden';
        hidden.name   = 'telefono';
        hidden.value  = codigo + numero;
        this.appendChild(hidden);
    }
});
</script>

</body>
</html>
