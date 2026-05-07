<?php
require_once 'config.php';
$page_title  = 'Soporte y Mantenimiento';
$active_page = 'soporte_mantenimiento.php';

$user_role = $_SESSION['user_role'] ?? null;
$user_id   = $_SESSION['user_id']   ?? null;

$can_report_incidents = ($user_role == 'Usuario' || $user_role == 'Empleado' || $user_role == 'Administrador');
$can_manage_tasks     = ($user_role == 'Empleado' || $user_role == 'Administrador');
$can_assign_tasks     = ($user_role == 'Administrador');
$currentBanner = appResolveBannerPath();
$currentBannerVersion = file_exists(__DIR__ . '/' . ltrim($currentBanner, '/'))
    ? (string)filemtime(__DIR__ . '/' . ltrim($currentBanner, '/'))
    : (string)time();

// Eliminar incidente
if (isset($_GET['delete_incident'])) {
    $incident_id = intval($_GET['delete_incident']);
    $sql = "DELETE FROM incidentes_soporte WHERE id_incidente = $incident_id";
    $conn->query($sql);
}

// Eliminar tarea
if (isset($_GET['delete_task'])) {
    $task_id = intval($_GET['delete_task']);
    $sql = "DELETE FROM tareas_mantenimiento WHERE id_tarea = $task_id";
    $conn->query($sql);
}

// Reportar incidente
if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['descripcion_incidente'])) {
    $descripcion_incidente = $conn->real_escape_string($_POST['descripcion_incidente']);
    $prioridad             = $conn->real_escape_string($_POST['prioridad']);
    $estado_incidente      = 'En Proceso';
    $usuario_reporta       = $user_id;
    $sql = "INSERT INTO incidentes_soporte (descripcion_incidente, prioridad, estado_incidente, usuario_reporta, fecha_reporte) VALUES ('$descripcion_incidente', '$prioridad', '$estado_incidente', '$usuario_reporta', NOW())";
    $conn->query($sql);
}

// Crear tarea
if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['descripcion_tarea']) && empty($_POST['task_id'])) {
    $descripcion_tarea  = $conn->real_escape_string($_POST['descripcion_tarea']);
    $fecha_programada   = $conn->real_escape_string($_POST['fecha_programada']);
    $estado_tarea       = 'Programada';
    $usuario_responsable = $conn->real_escape_string($_POST['usuario_responsable']);
    $sql = "INSERT INTO tareas_mantenimiento (descripcion_tarea, fecha_programada, estado_tarea, usuario_responsable) VALUES ('$descripcion_tarea', '$fecha_programada', '$estado_tarea', '$usuario_responsable')";
    $conn->query($sql);
}

// Editar tarea
if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['descripcion_tarea']) && !empty($_POST['task_id'])) {
    $descripcion_tarea   = $conn->real_escape_string($_POST['descripcion_tarea']);
    $fecha_programada    = $conn->real_escape_string($_POST['fecha_programada']);
    $usuario_responsable = $conn->real_escape_string($_POST['usuario_responsable']);
    $task_id             = intval($_POST['task_id']);
    $sql = "UPDATE tareas_mantenimiento SET descripcion_tarea='$descripcion_tarea', fecha_programada='$fecha_programada', usuario_responsable='$usuario_responsable' WHERE id_tarea=$task_id";
    $conn->query($sql);
}

// Consultar incidentes
$incident_query = "SELECT I.id_incidente, I.descripcion_incidente, I.fecha_reporte, I.prioridad, I.estado_incidente, U.nombre AS usuario_reporta FROM incidentes_soporte I JOIN Usuarios U ON I.usuario_reporta = U.id_usuario";
$incident_query .= $user_role == 'Usuario' ? " WHERE I.usuario_reporta = $user_id" : "";
$incident_result = $conn->query($incident_query);

// Consultar tareas
$task_query  = "SELECT T.id_tarea, T.descripcion_tarea, T.fecha_programada, T.estado_tarea, U.nombre AS usuario_responsable FROM tareas_mantenimiento T JOIN Usuarios U ON T.usuario_responsable = U.id_usuario";
$task_result = $conn->query($task_query);

include('layout/sidebar.php');
?>

<div class="page-banner">
    <div class="page-banner-content">
        <h1>Soporte y Mantenimiento</h1>
        <div class="page-banner-breadcrumb">
            <a href="dashboard.php">Inicio</a>
            <span class="sep">•</span>
            <span>Soporte</span>
        </div>
    </div>
    <img src="<?= htmlspecialchars($currentBanner, ENT_QUOTES, 'UTF-8') ?>?v=<?= htmlspecialchars($currentBannerVersion, ENT_QUOTES, 'UTF-8') ?>" alt="Banner de soporte y mantenimiento" class="page-banner-img">
</div>
<div class="module-actions-row">
    <?php if ($can_manage_tasks): ?>
    <button class="btn-secondary-master" onclick="openModal('reportIncidentModal')">
        <i class="fas fa-exclamation-circle"></i> Reportar Incidente
    </button>
    <?php endif; ?>
    <?php if ($user_role == 'Administrador'): ?>
    <button class="btn-primary-master" onclick="openModal('addTaskModal')">
        <i class="fas fa-plus"></i> Agregar Tarea
    </button>
    <?php endif; ?>
</div>

<!-- Incidentes -->
<div class="card-master">
    <div class="card-header-master">
        <h3><i class="fas fa-exclamation-triangle icon-warn"></i>Incidentes de Soporte</h3>
    </div>

    <?php if ($incident_result && $incident_result->num_rows > 0): ?>
    <div class="table-wrap">
        <table class="data-table">
            <thead>
                <tr>
                    <th>#</th>
                    <th>Descripción</th>
                    <th>Fecha</th>
                    <th>Prioridad</th>
                    <th>Estado</th>
                    <th>Reportado por</th>
                    <?php if ($can_manage_tasks): ?><th>Acciones</th><?php endif; ?>
                </tr>
            </thead>
            <tbody>
                <?php while ($row = $incident_result->fetch_assoc()): ?>
                <tr>
                    <td class="td-muted">#<?= $row['id_incidente'] ?></td>
                    <td class="td-primary"><?= htmlspecialchars($row['descripcion_incidente']) ?></td>
                    <td><?= htmlspecialchars(date('d M Y', strtotime($row['fecha_reporte']))) ?></td>
                    <td>
                        <span class="badge-pill <?= $row['prioridad'] === 'Alta' ? 'badge-danger' : ($row['prioridad'] === 'Media' ? 'badge-warning' : 'badge-neutral') ?>">
                            <?= htmlspecialchars($row['prioridad']) ?>
                        </span>
                    </td>
                    <td>
                        <span class="badge-pill <?= $row['estado_incidente'] === 'Resuelto' ? 'badge-success' : 'badge-info' ?>">
                            <?= htmlspecialchars($row['estado_incidente']) ?>
                        </span>
                    </td>
                    <td><?= htmlspecialchars($row['usuario_reporta']) ?></td>
                    <?php if ($can_manage_tasks): ?>
                    <td>
                        <div class="td-actions">
                            <?php if ($can_assign_tasks): ?>
                            <button class="btn-icon" title="Asignar" onclick="openAssignModal(<?= $row['id_incidente'] ?>)">
                                <i class="fas fa-user-tag"></i>
                            </button>
                            <a href="soporte_mantenimiento.php?delete_incident=<?= $row['id_incidente'] ?>" class="btn-icon danger" title="Eliminar" onclick="return confirm('¿Eliminar este incidente?');">
                                <i class="fas fa-trash-alt"></i>
                            </a>
                            <?php endif; ?>
                        </div>
                    </td>
                    <?php endif; ?>
                </tr>
                <?php endwhile; ?>
            </tbody>
        </table>
    </div>
    <?php else: ?>
    <div class="empty-state">
        <i class="fas fa-check-circle"></i>
        <p>No se encontraron incidentes de soporte.</p>
    </div>
    <?php endif; ?>
</div>

<!-- Tareas de mantenimiento -->
<div class="card-master">
    <div class="card-header-master">
        <h3><i class="fas fa-tools icon-cyan"></i>Tareas de Mantenimiento</h3>
    </div>

    <?php if ($task_result && $task_result->num_rows > 0): ?>
    <div class="table-wrap">
        <table class="data-table">
            <thead>
                <tr>
                    <th>#</th>
                    <th>Descripción</th>
                    <th>Fecha Programada</th>
                    <th>Estado</th>
                    <th>Responsable</th>
                    <?php if ($can_manage_tasks): ?><th>Acciones</th><?php endif; ?>
                </tr>
            </thead>
            <tbody>
                <?php while ($row = $task_result->fetch_assoc()): ?>
                <tr>
                    <td class="td-muted">#<?= $row['id_tarea'] ?></td>
                    <td class="td-primary"><?= htmlspecialchars($row['descripcion_tarea']) ?></td>
                    <td><?= htmlspecialchars(date('d M Y, H:i', strtotime($row['fecha_programada']))) ?></td>
                    <td>
                        <span class="badge-pill <?= $row['estado_tarea'] === 'Completada' ? 'badge-success' : ($row['estado_tarea'] === 'En Proceso' ? 'badge-info' : 'badge-neutral') ?>">
                            <?= htmlspecialchars($row['estado_tarea']) ?>
                        </span>
                    </td>
                    <td><?= htmlspecialchars($row['usuario_responsable']) ?></td>
                    <?php if ($can_manage_tasks): ?>
                    <td>
                        <div class="td-actions">
                            <?php if ($can_assign_tasks): ?>
                            <button class="btn-icon" title="Editar" onclick="openEditTaskModal(<?= $row['id_tarea'] ?>, '<?= htmlspecialchars($row['descripcion_tarea'], ENT_QUOTES) ?>', '<?= $row['fecha_programada'] ?>', '<?= $row['usuario_responsable'] ?>')">
                                <i class="fas fa-pencil-alt"></i>
                            </button>
                            <a href="soporte_mantenimiento.php?delete_task=<?= $row['id_tarea'] ?>" class="btn-icon danger" title="Eliminar" onclick="return confirm('¿Eliminar esta tarea?');">
                                <i class="fas fa-trash-alt"></i>
                            </a>
                            <?php endif; ?>
                        </div>
                    </td>
                    <?php endif; ?>
                </tr>
                <?php endwhile; ?>
            </tbody>
        </table>
    </div>
    <?php else: ?>
    <div class="empty-state">
        <i class="fas fa-tools"></i>
        <p>No se encontraron tareas de mantenimiento.</p>
    </div>
    <?php endif; ?>
</div>

<!-- Modal: reportar incidente -->
<div class="modal" id="reportIncidentModal">
    <div class="modal-content">
        <div class="modal-header">
            <h5>Reportar Incidente</h5>
            <button class="modal-close close" onclick="closeModal('reportIncidentModal')">&times;</button>
        </div>
        <form action="soporte_mantenimiento.php" method="post">
            <div class="modal-body">
                <div class="form-group">
                    <label class="form-label" for="descripcion_incidente">Descripción</label>
                    <textarea class="form-control" id="descripcion_incidente" name="descripcion_incidente" required></textarea>
                </div>
                <div class="form-group">
                    <label class="form-label" for="prioridad">Prioridad</label>
                    <select class="form-control" id="prioridad" name="prioridad" required>
                        <option value="Alta">Alta</option>
                        <option value="Media">Media</option>
                        <option value="Baja">Baja</option>
                    </select>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn-secondary-master" onclick="closeModal('reportIncidentModal')">Cerrar</button>
                <button type="submit" class="btn-primary-master">Reportar Incidente</button>
            </div>
        </form>
    </div>
</div>

<!-- Modal: agregar tarea -->
<div class="modal" id="addTaskModal">
    <div class="modal-content">
        <div class="modal-header">
            <h5>Agregar Tarea de Mantenimiento</h5>
            <button class="modal-close close" onclick="closeModal('addTaskModal')">&times;</button>
        </div>
        <form action="soporte_mantenimiento.php" method="post">
            <div class="modal-body">
                <div class="form-group">
                    <label class="form-label" for="descripcion_tarea">Descripción</label>
                    <textarea class="form-control" id="descripcion_tarea" name="descripcion_tarea" required></textarea>
                </div>
                <div class="form-group">
                    <label class="form-label" for="fecha_programada">Fecha Programada</label>
                    <input type="datetime-local" class="form-control" id="fecha_programada" name="fecha_programada" required>
                </div>
                <div class="form-group">
                    <label class="form-label" for="usuario_responsable">Responsable</label>
                    <select class="form-control" id="usuario_responsable" name="usuario_responsable" required>
                        <?php
                        $usuarios_sql    = "SELECT id_usuario, nombre FROM Usuarios WHERE rol IN ('Empleado', 'Administrador')";
                        $usuarios_result = $conn->query($usuarios_sql);
                        while ($usuario = $usuarios_result->fetch_assoc()) {
                            echo "<option value='{$usuario['id_usuario']}'>{$usuario['nombre']}</option>";
                        }
                        ?>
                    </select>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn-secondary-master" onclick="closeModal('addTaskModal')">Cerrar</button>
                <button type="submit" class="btn-primary-master">Agregar Tarea</button>
            </div>
        </form>
    </div>
</div>

<!-- Modal: asignar incidente -->
<div class="modal" id="editIncidentModal">
    <div class="modal-content">
        <div class="modal-header">
            <h5>Asignar Incidente</h5>
            <button class="modal-close close" onclick="closeModal('editIncidentModal')">&times;</button>
        </div>
        <form action="soporte_mantenimiento.php" method="post">
            <input type="hidden" id="incident_id" name="incident_id">
            <div class="modal-body">
                <div class="form-group">
                    <label class="form-label" for="usuario_asignado">Asignar a</label>
                    <select class="form-control" id="usuario_asignado" name="usuario_asignado" required>
                        <?php
                        $usuarios_sql    = "SELECT id_usuario, nombre FROM Usuarios WHERE rol IN ('Empleado', 'Administrador')";
                        $usuarios_result = $conn->query($usuarios_sql);
                        while ($usuario = $usuarios_result->fetch_assoc()) {
                            echo "<option value='{$usuario['id_usuario']}'>{$usuario['nombre']}</option>";
                        }
                        ?>
                    </select>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn-secondary-master" onclick="closeModal('editIncidentModal')">Cerrar</button>
                <button type="submit" class="btn-primary-master">Asignar Incidente</button>
            </div>
        </form>
    </div>
</div>

<!-- Modal: editar tarea -->
<div class="modal" id="editTaskModal">
    <div class="modal-content">
        <div class="modal-header">
            <h5>Editar Tarea de Mantenimiento</h5>
            <button class="modal-close close" onclick="closeModal('editTaskModal')">&times;</button>
        </div>
        <form action="soporte_mantenimiento.php" method="post">
            <input type="hidden" id="task_id" name="task_id">
            <div class="modal-body">
                <div class="form-group">
                    <label class="form-label" for="descripcion_tarea_edit">Descripción</label>
                    <textarea class="form-control" id="descripcion_tarea_edit" name="descripcion_tarea" required></textarea>
                </div>
                <div class="form-group">
                    <label class="form-label" for="fecha_programada_edit">Fecha Programada</label>
                    <input type="datetime-local" class="form-control" id="fecha_programada_edit" name="fecha_programada" required>
                </div>
                <div class="form-group">
                    <label class="form-label" for="usuario_responsable_edit">Responsable</label>
                    <select class="form-control" id="usuario_responsable_edit" name="usuario_responsable" required>
                        <?php
                        $usuarios_sql    = "SELECT id_usuario, nombre FROM Usuarios WHERE rol IN ('Empleado', 'Administrador')";
                        $usuarios_result = $conn->query($usuarios_sql);
                        while ($usuario = $usuarios_result->fetch_assoc()) {
                            echo "<option value='{$usuario['id_usuario']}'>{$usuario['nombre']}</option>";
                        }
                        ?>
                    </select>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn-secondary-master" onclick="closeModal('editTaskModal')">Cerrar</button>
                <button type="submit" class="btn-primary-master">Guardar Cambios</button>
            </div>
        </form>
    </div>
</div>

<script>
function openAssignModal(incidentId) {
    document.getElementById('incident_id').value = incidentId;
    openModal('editIncidentModal');
}
function openEditTaskModal(taskId, descripcion, fechaProgramada, responsableId) {
    document.getElementById('task_id').value = taskId;
    document.getElementById('descripcion_tarea_edit').value = descripcion;
    document.getElementById('fecha_programada_edit').value  = fechaProgramada;
    document.getElementById('usuario_responsable_edit').value = responsableId;
    openModal('editTaskModal');
}
function openModal(modalId) {
    document.getElementById(modalId).style.display = 'flex';
}
function closeModal(modalId) {
    document.getElementById(modalId).style.display = 'none';
}
document.querySelectorAll('.modal').forEach(function(m) {
    m.addEventListener('click', function(e) { if (e.target === m) closeModal(m.id); });
});
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') document.querySelectorAll('.modal').forEach(function(m) {
        if (m.style.display !== 'none') closeModal(m.id);
    });
});
</script>

<?php include('layout/footer_main.php'); ?>
