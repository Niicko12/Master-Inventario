<?php
require_once 'config.php';
requireAuth();

$page_title  = 'Calendario y Pendientes';
$active_page = 'agenda_calendario.php';

$conn->query("CREATE TABLE IF NOT EXISTS agenda_dashboard_pendientes (
    id_pendiente INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    fecha DATE NOT NULL,
    titulo VARCHAR(160) NOT NULL,
    detalle VARCHAR(255) DEFAULT NULL,
    completado TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_agenda_user_fecha (id_usuario, fecha),
    INDEX idx_agenda_estado (completado)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");

$agenda_flash_message = $_SESSION['agenda_flash_message'] ?? '';
$agenda_flash_type    = $_SESSION['agenda_flash_type'] ?? 'info';
unset($_SESSION['agenda_flash_message'], $_SESSION['agenda_flash_type']);

$id_usuario_actual = (int)($_SESSION['user_id'] ?? 0);
$hoy_iso = date('Y-m-d');
$fecha_agenda = $_GET['fecha_agenda'] ?? $hoy_iso;
if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $fecha_agenda)) {
    $fecha_agenda = $hoy_iso;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['agenda_action']) && $id_usuario_actual > 0) {
    $agenda_action = (string)($_POST['agenda_action'] ?? '');
    $fecha_post    = (string)($_POST['fecha_agenda'] ?? $fecha_agenda);
    if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $fecha_post)) {
        $fecha_post = $hoy_iso;
    }

    if ($agenda_action === 'add') {
        $titulo = trim((string)($_POST['titulo_pendiente'] ?? ''));
        $detalle = trim((string)($_POST['detalle_pendiente'] ?? ''));

        if ($titulo === '') {
            $_SESSION['agenda_flash_message'] = 'Escribe un título para el pendiente.';
            $_SESSION['agenda_flash_type']    = 'warning';
        } elseif (mb_strlen($titulo) > 160) {
            $_SESSION['agenda_flash_message'] = 'El título no puede superar 160 caracteres.';
            $_SESSION['agenda_flash_type']    = 'warning';
        } else {
            $detalle_sql = $detalle !== '' ? mb_substr($detalle, 0, 255) : null;
            $stmt = $conn->prepare("INSERT INTO agenda_dashboard_pendientes (id_usuario, fecha, titulo, detalle) VALUES (?, ?, ?, ?)");
            if ($stmt) {
                $stmt->bind_param("isss", $id_usuario_actual, $fecha_post, $titulo, $detalle_sql);
                if ($stmt->execute()) {
                    $_SESSION['agenda_flash_message'] = 'Pendiente agregado correctamente.';
                    $_SESSION['agenda_flash_type']    = 'success';
                } else {
                    $_SESSION['agenda_flash_message'] = 'No se pudo guardar el pendiente.';
                    $_SESSION['agenda_flash_type']    = 'error';
                }
                $stmt->close();
            }
        }
    } elseif ($agenda_action === 'toggle') {
        $id_pendiente = (int)($_POST['id_pendiente'] ?? 0);
        $nuevo_estado = ((int)($_POST['nuevo_estado'] ?? 0) === 1) ? 1 : 0;
        $stmt = $conn->prepare("UPDATE agenda_dashboard_pendientes SET completado = ?, updated_at = CURRENT_TIMESTAMP WHERE id_pendiente = ? AND id_usuario = ?");
        if ($stmt) {
            $stmt->bind_param("iii", $nuevo_estado, $id_pendiente, $id_usuario_actual);
            if ($stmt->execute()) {
                $_SESSION['agenda_flash_message'] = $nuevo_estado ? 'Pendiente marcado como completado.' : 'Pendiente reabierto.';
                $_SESSION['agenda_flash_type']    = 'success';
            }
            $stmt->close();
        }
    } elseif ($agenda_action === 'delete') {
        $id_pendiente = (int)($_POST['id_pendiente'] ?? 0);
        $stmt = $conn->prepare("DELETE FROM agenda_dashboard_pendientes WHERE id_pendiente = ? AND id_usuario = ?");
        if ($stmt) {
            $stmt->bind_param("ii", $id_pendiente, $id_usuario_actual);
            if ($stmt->execute()) {
                $_SESSION['agenda_flash_message'] = 'Pendiente eliminado.';
                $_SESSION['agenda_flash_type']    = 'info';
            }
            $stmt->close();
        }
    }

    header('Location: agenda_calendario.php?fecha_agenda=' . urlencode($fecha_post));
    exit;
}

$agenda_pendientes = [];
$agenda_total = 0;
$agenda_completados = 0;

if ($id_usuario_actual > 0) {
    $stmt = $conn->prepare("SELECT id_pendiente, titulo, detalle, completado, DATE_FORMAT(created_at, '%H:%i') AS hora_creacion
                            FROM agenda_dashboard_pendientes
                            WHERE id_usuario = ? AND fecha = ?
                            ORDER BY completado ASC, created_at ASC");
    if ($stmt) {
        $stmt->bind_param("is", $id_usuario_actual, $fecha_agenda);
        $stmt->execute();
        $agenda_pendientes = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
        $stmt->close();
    }
    $agenda_total = count($agenda_pendientes);
    $agenda_completados = count(array_filter($agenda_pendientes, function ($item) {
        return (int)$item['completado'] === 1;
    }));
}

$fecha_agenda_ts = strtotime($fecha_agenda);
$fecha_agenda_badge = $fecha_agenda_ts ? date('d M Y', $fecha_agenda_ts) : date('d M Y');
$dias_semana_es = [1 => 'Lunes', 2 => 'Martes', 3 => 'Miércoles', 4 => 'Jueves', 5 => 'Viernes', 6 => 'Sábado', 7 => 'Domingo'];
$meses_es = [1 => 'enero', 2 => 'febrero', 3 => 'marzo', 4 => 'abril', 5 => 'mayo', 6 => 'junio', 7 => 'julio', 8 => 'agosto', 9 => 'septiembre', 10 => 'octubre', 11 => 'noviembre', 12 => 'diciembre'];
$fecha_ref = $fecha_agenda_ts ?: time();
$fecha_agenda_larga = $dias_semana_es[(int)date('N', $fecha_ref)] . ', ' . date('d', $fecha_ref) . ' de ' . $meses_es[(int)date('n', $fecha_ref)] . ' de ' . date('Y', $fecha_ref);

include 'layout/sidebar.php';
?>

<?php if (!empty($agenda_flash_message)): ?>
<script>
document.addEventListener('DOMContentLoaded', function() {
    showToast(<?= json_encode($agenda_flash_message) ?>, <?= json_encode($agenda_flash_type) ?>);
});
</script>
<?php endif; ?>

<div class="page-banner">
    <div class="page-banner-content">
        <h1>Calendario y Pendientes</h1>
        <div class="page-banner-breadcrumb">
            <a href="dashboard.php">Dashboard</a>
            <span class="sep">/</span>
            <span>Agenda</span>
        </div>
    </div>
    <img src="assets/images/breadcrumb/inventario_productos_banner.svg" alt="Banner de calendario y pendientes" class="page-banner-img">
</div>

<div class="table-card agenda-card">
    <div class="chart-header">
        <h3>Agenda por Fecha</h3>
        <span class="chart-badge" style="background:rgba(19,222,185,0.16);color:#0f9f86;">
            <?= (int)$agenda_completados ?>/<?= (int)$agenda_total ?> completados
        </span>
    </div>

    <div class="agenda-grid">
        <div class="agenda-tools">
            <div class="date-badge" style="display:inline-flex;width:fit-content;">
                <i class="far fa-calendar-alt" style="margin-right:6px;"></i>
                <?= htmlspecialchars($fecha_agenda_badge, ENT_QUOTES, 'UTF-8') ?>
            </div>
            <form action="agenda_calendario.php" method="get" class="agenda-date-form">
                <label for="fecha_agenda" class="agenda-label">Fecha de trabajo</label>
                <input type="date" id="fecha_agenda" name="fecha_agenda" class="form-control agenda-date-input" value="<?= htmlspecialchars($fecha_agenda, ENT_QUOTES, 'UTF-8') ?>" required>
                <button type="submit" class="btn-secondary-master">
                    <i class="fas fa-filter"></i> Ver pendientes
                </button>
            </form>
            <div class="agenda-date-title">
                <i class="far fa-calendar-check"></i>
                <span><?= htmlspecialchars($fecha_agenda_larga, ENT_QUOTES, 'UTF-8') ?></span>
            </div>
            <p class="agenda-hint">
                Selecciona una fecha del calendario y agrega las tareas pendientes para ese día.
            </p>
        </div>

        <div>
            <form action="agenda_calendario.php?fecha_agenda=<?= urlencode($fecha_agenda) ?>" method="post" class="agenda-add-form">
                <input type="hidden" name="agenda_action" value="add">
                <input type="hidden" name="fecha_agenda" value="<?= htmlspecialchars($fecha_agenda, ENT_QUOTES, 'UTF-8') ?>">
                <input type="text" name="titulo_pendiente" class="form-control" maxlength="160" placeholder="Ej.: Revisar stock crítico de bodega A" required>
                <textarea name="detalle_pendiente" class="form-control agenda-textarea" maxlength="255" placeholder="Detalle opcional del pendiente..."></textarea>
                <button type="submit" class="btn-primary-master">
                    <i class="fas fa-plus"></i> Agregar pendiente
                </button>
            </form>

            <div class="agenda-list">
                <?php if (empty($agenda_pendientes)): ?>
                    <div class="empty-state agenda-empty">
                        <i class="fas fa-calendar-day"></i>
                        No hay pendientes para esta fecha.
                    </div>
                <?php else: ?>
                    <?php foreach ($agenda_pendientes as $pendiente): ?>
                        <?php $esta_completado = (int)$pendiente['completado'] === 1; ?>
                        <div class="agenda-item<?= $esta_completado ? ' is-done' : '' ?>">
                            <div class="agenda-item-main">
                                <div class="agenda-item-title"><?= htmlspecialchars($pendiente['titulo'], ENT_QUOTES, 'UTF-8') ?></div>
                                <?php if (!empty($pendiente['detalle'])): ?>
                                    <div class="agenda-item-detail"><?= htmlspecialchars($pendiente['detalle'], ENT_QUOTES, 'UTF-8') ?></div>
                                <?php endif; ?>
                                <div class="agenda-item-meta">
                                    <i class="far fa-clock"></i>
                                    Creado a las <?= htmlspecialchars((string)$pendiente['hora_creacion'], ENT_QUOTES, 'UTF-8') ?>
                                </div>
                            </div>
                            <div class="agenda-item-actions">
                                <form action="agenda_calendario.php?fecha_agenda=<?= urlencode($fecha_agenda) ?>" method="post">
                                    <input type="hidden" name="agenda_action" value="toggle">
                                    <input type="hidden" name="fecha_agenda" value="<?= htmlspecialchars($fecha_agenda, ENT_QUOTES, 'UTF-8') ?>">
                                    <input type="hidden" name="id_pendiente" value="<?= (int)$pendiente['id_pendiente'] ?>">
                                    <input type="hidden" name="nuevo_estado" value="<?= $esta_completado ? 0 : 1 ?>">
                                    <button type="submit" class="btn-secondary-master agenda-action-btn">
                                        <i class="fas <?= $esta_completado ? 'fa-rotate-left' : 'fa-check' ?>"></i>
                                        <?= $esta_completado ? 'Reabrir' : 'Completar' ?>
                                    </button>
                                </form>
                                <form action="agenda_calendario.php?fecha_agenda=<?= urlencode($fecha_agenda) ?>" method="post">
                                    <input type="hidden" name="agenda_action" value="delete">
                                    <input type="hidden" name="fecha_agenda" value="<?= htmlspecialchars($fecha_agenda, ENT_QUOTES, 'UTF-8') ?>">
                                    <input type="hidden" name="id_pendiente" value="<?= (int)$pendiente['id_pendiente'] ?>">
                                    <button type="submit" class="btn-icon danger" title="Eliminar pendiente" aria-label="Eliminar pendiente">
                                        <i class="fas fa-trash"></i>
                                    </button>
                                </form>
                            </div>
                        </div>
                    <?php endforeach; ?>
                <?php endif; ?>
            </div>
        </div>
    </div>
</div>

<?php include 'layout/footer_main.php'; ?>
