<?php
require_once 'config.php';
$page_title  = 'Usuarios';
$active_page = 'administrar_usuarios.php';

requireRole('Administrador');

if (isset($_GET['delete'])) {
    $user_id = intval($_GET['delete']);
    dbExecute($conn, "DELETE FROM Usuarios WHERE id_usuario = ?", "i", $user_id);
}

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $email          = trim($_POST['email']     ?? '');
    $nombre         = trim($_POST['nombre']    ?? '');
    $telefono       = trim($_POST['telefono']  ?? '');
    $direccion      = trim($_POST['direccion'] ?? '');
    $fecha_creacion = date('Y-m-d');

    $allowed_roles   = ['Administrador', 'Usuario', 'Empleado'];
    $allowed_estados = ['Activo', 'Inactivo'];
    $rol    = in_array($_POST['rol']    ?? '', $allowed_roles,   true) ? $_POST['rol']    : 'Usuario';
    $estado = in_array($_POST['estado'] ?? '', $allowed_estados, true) ? $_POST['estado'] : 'Activo';

    if (isset($_POST['id_usuario']) && !empty($_POST['id_usuario'])) {
        $id_usuario = intval($_POST['id_usuario']);
        if (!empty($_POST['contrasena'])) {
            $contrasena = password_hash($_POST['contrasena'], PASSWORD_DEFAULT);
            dbExecute($conn,
                "UPDATE Usuarios SET correo_electronico=?, nombre=?, rol=?, estado=?, telefono=?, direccion=?, contrasena=? WHERE id_usuario=?",
                "sssssssi", $email, $nombre, $rol, $estado, $telefono, $direccion, $contrasena, $id_usuario
            );
        } else {
            dbExecute($conn,
                "UPDATE Usuarios SET correo_electronico=?, nombre=?, rol=?, estado=?, telefono=?, direccion=? WHERE id_usuario=?",
                "ssssssi", $email, $nombre, $rol, $estado, $telefono, $direccion, $id_usuario
            );
        }
    } else {
        $contrasena = password_hash($_POST['contrasena'], PASSWORD_DEFAULT);
        dbExecute($conn,
            "INSERT INTO Usuarios (correo_electronico, nombre, rol, estado, telefono, direccion, fecha_creacion, contrasena) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            "ssssssss", $email, $nombre, $rol, $estado, $telefono, $direccion, $fecha_creacion, $contrasena
        );
    }
}

['page' => $page, 'limit' => $limit, 'offset' => $offset] = getPaginationParams(25);
$total_usuarios = countTotal($conn, "SELECT COUNT(*) FROM Usuarios");
$usuarios = dbFetchAll($conn,
    "SELECT id_usuario, correo_electronico, nombre, rol, estado, telefono, fecha_creacion, direccion FROM Usuarios ORDER BY nombre ASC LIMIT ? OFFSET ?",
    "ii", $limit, $offset
);

include('layout/sidebar.php');
?>

<!-- Page Banner -->
<div class="page-banner">
    <div class="page-banner-content">
        <h1>Usuarios</h1>
        <div class="page-banner-breadcrumb">
            <a href="dashboard.php">Inicio</a>
            <span class="sep">•</span>
            <span>Administrar Usuarios</span>
        </div>
    </div>
    <img src="assets/images/breadcrumb/inventario_productos_banner.svg" alt="Banner de inventario de productos" class="page-banner-img">
</div>
<div class="module-actions-row">
    <button type="button" class="btn-primary-master" onclick="openModal('createUserModal')">
        <i class="fas fa-user-plus"></i> Crear Usuario
    </button>
</div>

<!-- Tabla de usuarios -->
<div class="card-master">
    <div class="card-header-master">
        <h3><i class="fas fa-users icon-pink"></i>Directorio de Usuarios</h3>
        <div class="table-search-wrap no-icon">
            <input type="text" id="tableSearchUsers" class="table-search-input" placeholder="Buscar usuario...">
        </div>
    </div>

    <?php if (!empty($usuarios)): ?>
    <div class="table-wrap">
        <table class="data-table" id="usersTable">
            <thead>
                <tr>
                    <th>#</th>
                    <th>Nombre</th>
                    <th>Correo</th>
                    <th>Rol</th>
                    <th>Estado</th>
                    <th>Teléfono</th>
                    <th>Creación</th>
                    <th>Acciones</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($usuarios as $row): ?>
                <tr>
                    <td class="td-muted">#<?= htmlspecialchars($row['id_usuario']) ?></td>
                    <td class="td-primary"><?= htmlspecialchars($row['nombre']) ?></td>
                    <td><?= htmlspecialchars($row['correo_electronico']) ?></td>
                    <td>
                        <span class="badge-pill <?= $row['rol'] === 'Administrador' ? 'badge-danger' : ($row['rol'] === 'Empleado' ? 'badge-info' : 'badge-neutral') ?>">
                            <?= htmlspecialchars($row['rol']) ?>
                        </span>
                    </td>
                    <td>
                        <span class="badge-pill <?= $row['estado'] === 'Activo' ? 'badge-success' : 'badge-neutral' ?>">
                            <?= htmlspecialchars($row['estado']) ?>
                        </span>
                    </td>
                    <td><?= htmlspecialchars($row['telefono']) ?></td>
                    <td><?= htmlspecialchars($row['fecha_creacion']) ?></td>
                    <td>
                        <div class="td-actions">
                            <button class="btn-icon" title="Editar" onclick="openEditModal(
                                '<?= intval($row['id_usuario']) ?>',
                                '<?= htmlspecialchars($row['correo_electronico'], ENT_QUOTES) ?>',
                                '<?= htmlspecialchars($row['nombre'], ENT_QUOTES) ?>',
                                '<?= htmlspecialchars($row['rol'], ENT_QUOTES) ?>',
                                '<?= htmlspecialchars($row['estado'], ENT_QUOTES) ?>',
                                '<?= htmlspecialchars($row['telefono'], ENT_QUOTES) ?>',
                                '<?= htmlspecialchars($row['direccion'], ENT_QUOTES) ?>'
                            )"><i class="fas fa-pencil-alt"></i></button>
                            <a href="administrar_usuarios.php?delete=<?= intval($row['id_usuario']) ?>" class="btn-icon danger" title="Eliminar" onclick="return confirm('¿Eliminar este usuario?');">
                                <i class="fas fa-trash-alt"></i>
                            </a>
                        </div>
                    </td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php else: ?>
    <div class="empty-state">
        <i class="fas fa-users"></i>
        <p>No se encontraron usuarios.</p>
    </div>
    <?php endif; ?>
    <div id="noUsersResults" style="display:none;">
        <div class="empty-state">
            <i class="fas fa-search"></i>
            <p>Sin resultados para "<span id="usersSearchTerm"></span>"</p>
        </div>
    </div>

    <?= renderPagination($total_usuarios, $page, $limit) ?>
</div>

<!-- Modal: crear usuario -->
<div class="modal" id="createUserModal">
    <div class="modal-content">
        <div class="modal-header">
            <h5>Crear Usuario</h5>
            <button class="modal-close close" onclick="closeModal('createUserModal')">&times;</button>
        </div>
        <form action="administrar_usuarios.php" method="post">
            <div class="modal-body">
                <div class="form-group">
                    <label class="form-label" for="email">Correo Electrónico</label>
                    <input type="email" class="form-control" id="email" name="email" required>
                </div>
                <div class="form-group">
                    <label class="form-label" for="nombre">Nombre</label>
                    <input type="text" class="form-control" id="nombre" name="nombre" required>
                </div>
                <div class="form-group">
                    <label class="form-label" for="contrasena">Contraseña</label>
                    <input type="password" class="form-control" id="contrasena" name="contrasena" required>
                </div>
                <div class="form-group">
                    <label class="form-label" for="rol">Rol</label>
                    <select class="form-control" id="rol" name="rol">
                        <option value="Administrador">Administrador</option>
                        <option value="Empleado">Empleado</option>
                        <option value="Usuario">Usuario</option>
                    </select>
                </div>
                <div class="form-group">
                    <label class="form-label" for="estado">Estado</label>
                    <select class="form-control" id="estado" name="estado">
                        <option value="Activo">Activo</option>
                        <option value="Inactivo">Inactivo</option>
                    </select>
                </div>
                <div class="form-group">
                    <label class="form-label" for="telefono">Teléfono</label>
                    <input type="text" class="form-control" id="telefono" name="telefono" required>
                </div>
                <div class="form-group">
                    <label class="form-label" for="direccion">Dirección</label>
                    <input type="text" class="form-control" id="direccion" name="direccion" required>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn-secondary-master" onclick="closeModal('createUserModal')">Cerrar</button>
                <button type="submit" class="btn-primary-master">Crear</button>
            </div>
        </form>
    </div>
</div>

<!-- Modal: editar usuario -->
<div class="modal" id="editUserModal">
    <div class="modal-content">
        <div class="modal-header">
            <h5>Editar Usuario</h5>
            <button class="modal-close close" onclick="closeModal('editUserModal')">&times;</button>
        </div>
        <form action="administrar_usuarios.php" method="post">
            <div class="modal-body">
                <input type="hidden" id="id_usuario" name="id_usuario">
                <div class="form-group">
                    <label class="form-label" for="email_edit">Correo Electrónico</label>
                    <input type="email" class="form-control" id="email_edit" name="email" required>
                </div>
                <div class="form-group">
                    <label class="form-label" for="nombre_edit">Nombre</label>
                    <input type="text" class="form-control" id="nombre_edit" name="nombre" required>
                </div>
                <div class="form-group">
                    <label class="form-label" for="contrasena_edit">Contraseña (dejar en blanco para no cambiar)</label>
                    <input type="password" class="form-control" id="contrasena_edit" name="contrasena">
                </div>
                <div class="form-group">
                    <label class="form-label" for="rol_edit">Rol</label>
                    <select class="form-control" id="rol_edit" name="rol">
                        <option value="Administrador">Administrador</option>
                        <option value="Empleado">Empleado</option>
                        <option value="Usuario">Usuario</option>
                    </select>
                </div>
                <div class="form-group">
                    <label class="form-label" for="estado_edit">Estado</label>
                    <select class="form-control" id="estado_edit" name="estado">
                        <option value="Activo">Activo</option>
                        <option value="Inactivo">Inactivo</option>
                    </select>
                </div>
                <div class="form-group">
                    <label class="form-label" for="telefono_edit">Teléfono</label>
                    <input type="text" class="form-control" id="telefono_edit" name="telefono" required>
                </div>
                <div class="form-group">
                    <label class="form-label" for="direccion_edit">Dirección</label>
                    <input type="text" class="form-control" id="direccion_edit" name="direccion" required>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn-secondary-master" onclick="closeModal('editUserModal')">Cerrar</button>
                <button type="submit" class="btn-primary-master">Guardar Cambios</button>
            </div>
        </form>
    </div>
</div>

<script>
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

function openEditModal(id, email, nombre, rol, estado, telefono, direccion) {
    document.getElementById('id_usuario').value    = id;
    document.getElementById('email_edit').value    = email;
    document.getElementById('nombre_edit').value   = nombre;
    document.getElementById('rol_edit').value      = rol;
    document.getElementById('estado_edit').value   = estado;
    document.getElementById('telefono_edit').value = telefono;
    document.getElementById('direccion_edit').value = direccion;
    openModal('editUserModal');
}

var usersSearchInput = document.getElementById('tableSearchUsers');
if (usersSearchInput) {
    usersSearchInput.addEventListener('input', function() {
        var term = this.value.toLowerCase().trim();
        var rows = document.querySelectorAll('#usersTable tbody tr');
        var visible = 0;

        rows.forEach(function(row) {
            var show = term === '' || row.textContent.toLowerCase().includes(term);
            row.style.display = show ? '' : 'none';
            if (show) visible++;
        });

        var noResults = document.getElementById('noUsersResults');
        if (noResults) {
            noResults.style.display = (term !== '' && rows.length > 0 && visible === 0) ? 'block' : 'none';
        }
        var searchTerm = document.getElementById('usersSearchTerm');
        if (searchTerm) {
            searchTerm.textContent = term;
        }
    });
}
</script>

<?php include('layout/footer_main.php'); ?>
