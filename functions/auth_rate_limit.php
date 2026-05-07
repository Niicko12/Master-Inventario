<?php
/**
 * Login rate limiting helpers — Sistema de Gestión de Inventario
 *
 * Protección contra ataques de fuerza bruta via MySQL-backed rate limiting.
 * Compatible con Hostinger shared hosting (no Redis, no APCu, no cron jobs).
 * Diseñado para CGNAT de México (Telmex/Telcel): umbral IP alto (20), cuenta bajo (5).
 */

// Auto-create table on first use — no manual migration needed
function _ensureLoginAttemptsTable(mysqli $conn): void {
    static $checked = false;
    if ($checked) return;
    $conn->query("CREATE TABLE IF NOT EXISTS `LoginAttempts` (
        `id`           INT(11)      NOT NULL AUTO_INCREMENT,
        `email`        VARCHAR(100) NOT NULL,
        `ip`           VARCHAR(45)  NOT NULL,
        `success`      TINYINT(1)   NOT NULL DEFAULT 0,
        `attempted_at` TIMESTAMP    NULL     DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        INDEX `idx_email_time` (`email`, `attempted_at`),
        INDEX `idx_ip_time`    (`ip`,    `attempted_at`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");
    $checked = true;
}

/**
 * Registra un intento de login (exitoso o fallido) en LoginAttempts.
 * IMPORTANTE: NO llamar cuando el request ya está bloqueado por rate limit
 * (evita inflar el contador durante un bloqueo activo).
 */
function recordLoginAttempt(mysqli $conn, string $email, string $ip, bool $success): void {
    _ensureLoginAttemptsTable($conn);
    $stmt = $conn->prepare(
        "INSERT INTO LoginAttempts (email, ip, success) VALUES (?, ?, ?)"
    );
    $s = $success ? 1 : 0;
    $stmt->bind_param("ssi", $email, $ip, $s);
    $stmt->execute();
    $stmt->close();
}

/**
 * Verifica soft rate limit por IP (protección contra scanners automatizados).
 *
 * Si ≥ 20 intentos fallidos del mismo IP en 15 min → sleep(3) + retorna false.
 * NO bloquea completamente — soft limit por CGNAT de México (Telmex/Telcel/Totalplay):
 * un solo IP público puede representar cientos de hogares.
 *
 * @return bool true = continuar normal | false = soft-limited (ya ejecutó sleep de 3s)
 */
function checkIPRateLimit(mysqli $conn, string $ip): bool {
    _ensureLoginAttemptsTable($conn);
    $window = date('Y-m-d H:i:s', time() - 900); // 15 minutos
    $stmt = $conn->prepare(
        "SELECT COUNT(*) AS cnt FROM LoginAttempts
         WHERE ip = ? AND success = 0 AND attempted_at > ?"
    );
    $stmt->bind_param("ss", $ip, $window);
    $stmt->execute();
    $cnt = (int)$stmt->get_result()->fetch_assoc()['cnt'];
    $stmt->close();

    if ($cnt >= 20) {
        sleep(3); // Progressive delay — no hard block
        return false;
    }
    return true;
}

/**
 * Verifica rate limit por cuenta con lockout escalado.
 *
 * Política:
 *   - 5 fallos en ventana de 15 min → lockout
 *   - Escalada basada en historial de 24h:
 *     · 5–9 fallos totales  → 15 min (primer lockout)
 *     · 10–14 fallos totales → 30 min (segundo lockout)
 *     · 15+ fallos totales  → 60 min (tercer lockout+)
 *
 * Incluye lazy cleanup (DELETE LIMIT 500) sin cron job — compatible con Hostinger.
 *
 * @return array{allowed: bool, lockout_minutes: int, attempts: int}
 */
function checkAccountRateLimit(mysqli $conn, string $email): array {
    _ensureLoginAttemptsTable($conn);
    // Lazy cleanup: eliminar registros de más de 24h (sin cron job)
    $conn->query("DELETE FROM LoginAttempts WHERE attempted_at < NOW() - INTERVAL 24 HOUR LIMIT 500");

    $window = date('Y-m-d H:i:s', time() - 900); // ventana de 15 minutos

    $stmt = $conn->prepare(
        "SELECT COUNT(*) AS cnt FROM LoginAttempts
         WHERE email = ? AND success = 0 AND attempted_at > ?"
    );
    $stmt->bind_param("ss", $email, $window);
    $stmt->execute();
    $cnt = (int)$stmt->get_result()->fetch_assoc()['cnt'];
    $stmt->close();

    if ($cnt < 5) {
        return ['allowed' => true, 'attempts' => $cnt, 'lockout_minutes' => 0];
    }

    // Cuenta en lockout — calcular nivel de escalada según fallos en 24h
    $day = date('Y-m-d H:i:s', time() - 86400);
    $stmt = $conn->prepare(
        "SELECT COUNT(*) AS total FROM LoginAttempts
         WHERE email = ? AND success = 0 AND attempted_at > ?"
    );
    $stmt->bind_param("ss", $email, $day);
    $stmt->execute();
    $total = (int)$stmt->get_result()->fetch_assoc()['total'];
    $stmt->close();

    // Nivel 0 = primer bloqueo (5-9 fallos), 1 = segundo (10-14), 2+ = tercero (15+)
    $level = max(0, (int)floor($total / 5) - 1);
    $minutes = match(true) {
        $level >= 2 => 60,
        $level === 1 => 30,
        default     => 15,
    };

    return ['allowed' => false, 'lockout_minutes' => $minutes, 'attempts' => $cnt];
}

/**
 * Valida token de Google reCAPTCHA contra la API server-side.
 *
 * Fail-open: si la API de Google no responde, retorna true para no bloquear
 * usuarios legítimos por fallos de servicios externos.
 *
 * @param string $token  El valor de $_POST['g-recaptcha-response']
 * @param string $secret La clave secreta de reCAPTCHA (de .env)
 * @param string $ip     IP del cliente para validación
 * @return bool true = válido o API no disponible | false = token inválido/ausente
 */
function validateRecaptcha(string $token, string $secret, string $ip): bool {
    if (empty($token)) return false;
    if (empty($secret)) return true; // Sin clave configurada: skip (modo desarrollo)

    $url = 'https://www.google.com/recaptcha/api/siteverify?' .
        http_build_query([
            'secret'   => $secret,
            'response' => $token,
            'remoteip' => $ip,
        ]);

    $result = @file_get_contents($url); // @ suprime warning si allow_url_fopen=Off
    if ($result === false) {
        // API no disponible — fail open (no bloquear usuarios legítimos)
        error_log("[rate_limit] reCAPTCHA API no disponible — fail open para IP $ip");
        return true;
    }

    $data = json_decode($result, true);
    return ($data['success'] ?? false) === true;
}

/**
 * Notifica a todos los administradores activos cuando una cuenta es bloqueada.
 *
 * Se dispara EXACTAMENTE en el 5to intento fallido (transición a bloqueado).
 * NO se llama en intentos 6, 7, 8... del mismo período de bloqueo.
 * Captura todas las excepciones — un fallo de email NO debe abortar el lockout.
 */
function notifyAdminAccountLocked(
    mysqli $conn,
    string $locked_email,
    string $locked_name,
    string $attacker_ip,
    int    $lockout_minutes
): void {
    // Obtener todos los administradores activos
    $stmt = $conn->prepare(
        "SELECT nombre, correo_electronico FROM Usuarios
         WHERE rol = 'Administrador' AND estado = 'Activo'"
    );
    $stmt->execute();
    $admins = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
    $stmt->close();

    if (empty($admins)) return;

    // PHPMailer con require manual (patrón del proyecto — no Composer autoload)
    require_once __DIR__ . '/../PHPMailer/src/Exception.php';
    require_once __DIR__ . '/../PHPMailer/src/PHPMailer.php';
    require_once __DIR__ . '/../PHPMailer/src/SMTP.php';

    $now         = date('d/m/Y H:i:s');
    $safe_name   = htmlspecialchars($locked_name, ENT_HTML5, 'UTF-8');
    $safe_email  = htmlspecialchars($locked_email, ENT_HTML5, 'UTF-8');
    $safe_ip     = htmlspecialchars($attacker_ip, ENT_HTML5, 'UTF-8');

    foreach ($admins as $admin) {
        try {
            $mail = new \PHPMailer\PHPMailer\PHPMailer(true);
            $mail->isSMTP();
            $mail->Host       = 'smtp.gmail.com';
            $mail->SMTPAuth   = true;
            $mail->Username   = 'limbermagana85@gmail.com';
            $mail->Password   = 'rsqu cxly dkup lsnl';
            $mail->SMTPSecure = \PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_STARTTLS;
            $mail->Port       = 587;
            $mail->CharSet    = 'UTF-8';

            $admin_name = htmlspecialchars($admin['nombre'], ENT_HTML5, 'UTF-8');

            $mail->setFrom('limbermagana85@gmail.com', 'Master Inventario — Seguridad');
            $mail->addAddress($admin['correo_electronico'], $admin['nombre']);
            $mail->isHTML(true);
            $mail->Subject = "⚠️ Cuenta bloqueada — {$locked_name}";
            $mail->Body    = "
<div style='font-family:Arial,sans-serif;max-width:600px;margin:0 auto;padding:24px'>
  <h2 style='color:#c0392b;margin-top:0;border-bottom:2px solid #c0392b;padding-bottom:12px'>
    ⚠️ Cuenta bloqueada por intentos fallidos
  </h2>
  <p>Hola <strong>{$admin_name}</strong>,</p>
  <p>La cuenta de <strong>{$safe_name}</strong>
     (<code style='background:#f8f9fa;padding:2px 6px;border-radius:3px'>{$safe_email}</code>)
     fue bloqueada automáticamente por 5 intentos de login fallidos consecutivos.</p>

  <table style='border-collapse:collapse;width:100%;margin:20px 0;font-size:14px'>
    <tr style='background:#fff3cd'>
      <td style='padding:10px 16px;border:1px solid #ffc107;font-weight:bold'>IP de origen</td>
      <td style='padding:10px 16px;border:1px solid #ffc107'>
        <code style='background:#fff;padding:2px 6px;border-radius:3px'>{$safe_ip}</code>
      </td>
    </tr>
    <tr>
      <td style='padding:10px 16px;border:1px solid #dee2e6;font-weight:bold'>Fecha y hora</td>
      <td style='padding:10px 16px;border:1px solid #dee2e6'>{$now}</td>
    </tr>
    <tr style='background:#f8f9fa'>
      <td style='padding:10px 16px;border:1px solid #dee2e6;font-weight:bold'>Bloqueo automático</td>
      <td style='padding:10px 16px;border:1px solid #dee2e6'>{$lockout_minutes} minutos (auto-desbloqueo)</td>
    </tr>
  </table>

  <p style='background:#fff3cd;border-left:4px solid #ffc107;padding:12px 16px;margin:20px 0'>
    Si el usuario <strong>{$safe_name}</strong> no reconoce esta actividad,
    puede ser un intento de acceso no autorizado. Revisa el log de acceso del sistema.
  </p>

  <p style='color:#6c757d;font-size:12px;margin-top:24px;border-top:1px solid #dee2e6;padding-top:12px'>
    Este mensaje fue generado automáticamente por el Sistema Master Inventario.<br>
    No respondas a este correo.
  </p>
</div>";

            $mail->send();
        } catch (\Exception $e) {
            // Loguear pero NO propagar — el fallo de email no cancela el lockout
            error_log("[rate_limit] notifyAdminAccountLocked falló para {$admin['correo_electronico']}: " . $e->getMessage());
        }
    }
}
