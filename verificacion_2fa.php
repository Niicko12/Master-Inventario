<?php
session_start();
require_once 'config.php';

// Guard: must arrive from login.php 2FA flow
if (!isset($_SESSION['temp_user_id']) || !isset($_SESSION['verification_code'])) {
    header("Location: login.php");
    exit;
}

$email  = htmlspecialchars($_SESSION['temp_email']  ?? '', ENT_QUOTES, 'UTF-8');
$nombre = htmlspecialchars($_SESSION['temp_nombre'] ?? 'Usuario', ENT_QUOTES, 'UTF-8');

// Mask email for display: l*****@gmail.com
$email_parts  = explode('@', $_SESSION['temp_email'] ?? '');
$email_masked = mb_substr($email_parts[0], 0, 1) . str_repeat('*', max(1, mb_strlen($email_parts[0]) - 1))
              . '@' . ($email_parts[1] ?? '');
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Verificación 2FA</title>
    <link rel="stylesheet" href="styles/verificacion_2fa.css">
    <style>
        body { font-family: Arial, sans-serif; display:flex; justify-content:center; align-items:center; min-height:100vh; margin:0; background:#f5f5f5; }
        .verification-box { background:#fff; padding:40px; border-radius:12px; box-shadow:0 4px 20px rgba(0,0,0,.1); max-width:420px; width:100%; text-align:center; }
        .verification-box h2 { margin-bottom:8px; color:#333; }
        .subtitle { color:#666; margin-bottom:24px; font-size:14px; }
        .form-group { margin-bottom:20px; text-align:left; }
        .form-group label { display:block; font-weight:600; margin-bottom:6px; color:#444; }
        .form-group input { width:100%; padding:12px; border:1px solid #ddd; border-radius:8px; font-size:18px; text-align:center; letter-spacing:8px; box-sizing:border-box; }
        .btn-primary { background:#007bff; color:#fff; border:none; padding:12px 28px; border-radius:8px; cursor:pointer; font-size:16px; width:100%; margin-bottom:10px; }
        .btn-primary:hover { background:#0056b3; }
        .btn-secondary { background:transparent; color:#007bff; border:1px solid #007bff; padding:10px 20px; border-radius:8px; cursor:pointer; font-size:14px; width:100%; }
        .btn-secondary:hover { background:#e8f0fe; }
        .btn-secondary:disabled { opacity:.5; cursor:default; }
        .error-msg { color:#dc3545; margin-top:10px; font-size:14px; }
        .success-msg { color:#28a745; margin-top:10px; font-size:14px; }
        .divider { margin:16px 0; color:#aaa; font-size:13px; }
    </style>
</head>
<body>
<div class="verification-box">
    <h2>Verificación en dos pasos</h2>
    <p class="subtitle">Ingresa el código enviado a <strong><?= $email_masked ?></strong></p>

    <form id="verificationForm">
        <div class="form-group">
            <label for="verificationCode">Código de 6 dígitos</label>
            <input type="text" id="verificationCode" name="verificationCode"
                   maxlength="6" inputmode="numeric" pattern="[0-9]{6}"
                   placeholder="000000" required autocomplete="one-time-code">
        </div>
        <button type="submit" class="btn-primary">Verificar</button>
    </form>

    <div class="divider">— o —</div>
    <button type="button" class="btn-secondary" id="resendBtn" onclick="sendCode()">
        Enviar código por correo
    </button>

    <div id="error-message"  class="error-msg"></div>
    <div id="success-message" class="success-msg"></div>
</div>

<script>
let resendCooldown = 0;

function showError(msg)   { document.getElementById('error-message').textContent = msg; document.getElementById('success-message').textContent = ''; }
function showSuccess(msg) { document.getElementById('success-message').textContent = msg; document.getElementById('error-message').textContent = ''; }

function sendCode() {
    const btn = document.getElementById('resendBtn');
    if (resendCooldown > 0) return;

    btn.disabled = true;
    showSuccess('Enviando...');

    fetch('enviar_correo_confirmacion.php', { method: 'POST' })
        .then(r => r.text())
        .then(text => {
            if (text.trim() === 'success') {
                showSuccess('Código enviado. Revisa tu correo.');
                resendCooldown = 60;
                const timer = setInterval(() => {
                    resendCooldown--;
                    btn.textContent = `Reenviar en ${resendCooldown}s`;
                    if (resendCooldown <= 0) {
                        clearInterval(timer);
                        btn.disabled = false;
                        btn.textContent = 'Reenviar código';
                    }
                }, 1000);
            } else {
                showError('No se pudo enviar el correo. Intenta de nuevo.');
                btn.disabled = false;
            }
        })
        .catch(() => { showError('Error de red. Intenta de nuevo.'); btn.disabled = false; });
}

document.getElementById('verificationForm').addEventListener('submit', function(e) {
    e.preventDefault();
    const code = document.getElementById('verificationCode').value.trim();
    if (code.length !== 6) { showError('El código debe tener 6 dígitos.'); return; }

    const fd = new FormData();
    fd.append('verificationCode', code);

    fetch('verificar_codigo.php', { method: 'POST', body: fd })
        .then(r => r.text())
        .then(text => {
            const t = text.trim();
            if (t === 'success') {
                window.location.href = 'index.php';
            } else if (t === 'error_mismatch') {
                showError('Código incorrecto. Intenta de nuevo.');
            } else if (t === 'error_session') {
                showError('Sesión expirada. Vuelve a iniciar sesión.');
                setTimeout(() => window.location.href = 'login.php', 2000);
            } else {
                showError('Error al verificar. Intenta de nuevo.');
            }
        })
        .catch(() => showError('Error de red. Intenta de nuevo.'));
});
</script>
</body>
</html>
