<?php
require_once 'config.php';
$page_title  = 'Proveedores';
$active_page = 'gestion_proveedores.php';

$is_admin = isset($_SESSION['user_role']) && $_SESSION['user_role'] === 'Administrador';

// Eliminar proveedor
if (isset($_GET['delete'])) {
    $proveedor_id = intval($_GET['delete']);
    $sql = "DELETE FROM Proveedores WHERE id_proveedor = $proveedor_id";
    $conn->query($sql);
}

// Registrar nuevo proveedor
if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['submit_provider'])) {
    $nombre_proveedor = $_POST['nombre_proveedor'];
    $telefono         = $_POST['telefono'];
    $email            = $_POST['email'];
    $direccion        = $_POST['direccion'];

    $stmt = $conn->prepare("INSERT INTO Proveedores (nombre_proveedor, telefono, email, direccion) VALUES (?, ?, ?, ?)");
    $stmt->bind_param("ssss", $nombre_proveedor, $telefono, $email, $direccion);
    $stmt->execute();
    $stmt->close();
}

// Listar proveedores (paginado)
['page' => $page, 'limit' => $limit, 'offset' => $offset] = getPaginationParams(25);
$total_proveedores = countTotal($conn, "SELECT COUNT(*) FROM Proveedores");
$proveedores_lista = dbFetchAll($conn,
    "SELECT * FROM Proveedores ORDER BY nombre_proveedor ASC LIMIT ? OFFSET ?",
    "ii", $limit, $offset
);

include('layout/sidebar.php');
$print_generated_at = appFormatDateTime(time());
?>

<!-- Page Banner -->
<div class="page-banner">
    <div class="page-banner-content">
        <h1>Proveedores</h1>
        <div class="page-banner-breadcrumb">
            <a href="dashboard.php">Inicio</a>
            <span class="sep">•</span>
            <span>Proveedores</span>
        </div>
    </div>
    <img src="assets/images/breadcrumb/inventario_productos_banner.svg" alt="Banner de inventario de productos" class="page-banner-img">
</div>
<div class="module-actions-row">
    <?php if ($is_admin): ?>
    <button type="button" class="btn-primary-master" onclick="openModal('createProviderModal')">
        <i class="fas fa-plus"></i> Registrar Proveedor
    </button>
    <?php endif; ?>
    <button type="button" class="btn-secondary-master btn-print-module" onclick="window.print()">
        <i class="fas fa-print"></i> Imprimir / PDF
    </button>
</div>
<div class="module-print-header">
    <img src="<?= htmlspecialchars($instance_logo, ENT_QUOTES, 'UTF-8') ?>" alt="<?= htmlspecialchars($instance_name, ENT_QUOTES, 'UTF-8') ?>" class="module-print-header-logo">
    <div class="module-print-header-copy">
        <h2><?= htmlspecialchars($instance_name, ENT_QUOTES, 'UTF-8') ?></h2>
        <p>Reporte de proveedores</p>
        <span>Generado: <?= htmlspecialchars($print_generated_at, ENT_QUOTES, 'UTF-8') ?></span>
    </div>
</div>

<!-- Tabla de proveedores -->
<div class="card-master">
    <div class="card-header-master">
        <h3><i class="fas fa-building icon-pink"></i>Directorio de Proveedores</h3>
        <div class="table-search-wrap no-icon">
            <input type="text" id="tableSearchProviders" class="table-search-input" placeholder="Buscar proveedor...">
        </div>
    </div>

    <?php if (!empty($proveedores_lista)): ?>
    <div class="table-wrap">
        <table class="data-table" id="providersTable">
            <thead>
                <tr>
                    <th>#</th>
                    <th>Nombre</th>
                    <th>Teléfono</th>
                    <th>Email</th>
                    <th>Dirección</th>
                    <th>Acciones</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($proveedores_lista as $row): ?>
                <tr>
                    <td class="td-muted">#<?= htmlspecialchars($row['id_proveedor']) ?></td>
                    <td class="td-primary"><?= htmlspecialchars($row['nombre_proveedor']) ?></td>
                    <td><?= htmlspecialchars($row['telefono']) ?></td>
                    <td><?= htmlspecialchars($row['email']) ?></td>
                    <td><?= htmlspecialchars($row['direccion']) ?></td>
                    <td>
                        <div class="td-actions">
                            <button class="btn-icon" title="Editar" onclick="openEditModal(<?= intval($row['id_proveedor']) ?>)">
                                <i class="fas fa-pencil-alt"></i>
                            </button>
                            <?php if ($is_admin): ?>
                            <a href="gestion_proveedores.php?delete=<?= intval($row['id_proveedor']) ?>" class="btn-icon danger" title="Eliminar" onclick="return confirm('¿Eliminar este proveedor?');">
                                <i class="fas fa-trash-alt"></i>
                            </a>
                            <?php endif; ?>
                        </div>
                    </td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php else: ?>
    <div class="empty-state">
        <i class="fas fa-building"></i>
        <p>No se encontraron proveedores registrados.</p>
    </div>
    <?php endif; ?>
    <div id="noProviderResults" style="display:none;">
        <div class="empty-state">
            <i class="fas fa-search"></i>
            <p>Sin resultados para "<span id="providerSearchTerm"></span>"</p>
        </div>
    </div>

    <?= renderPagination($total_proveedores, $page, $limit) ?>
</div>

<!-- Modal: registrar nuevo proveedor -->
<div class="modal" id="createProviderModal">
    <div class="modal-content">
        <div class="modal-header">
            <h5>Registrar Nuevo Proveedor</h5>
            <button class="modal-close close" onclick="closeModal('createProviderModal')">&times;</button>
        </div>
        <form action="gestion_proveedores.php" method="post" data-validate>
            <div class="modal-body">
                <div class="form-group">
                    <label class="form-label" for="nombre_proveedor">Nombre</label>
                    <input type="text" class="form-control" id="nombre_proveedor" name="nombre_proveedor" required>
                </div>
                <div class="form-group">
                    <label class="form-label" for="telefono">Teléfono</label>
                    <input type="text" class="form-control" id="telefono" name="telefono" required>
                </div>
                <div class="form-group">
                    <label class="form-label" for="email">Email</label>
                    <input type="email" class="form-control" id="email" name="email" required>
                </div>
                <div class="form-group">
                    <label class="form-label" for="direccion">Dirección</label>
                    <input type="text" class="form-control" id="direccion" name="direccion" required>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn-secondary-master" onclick="closeModal('createProviderModal')">Cerrar</button>
                <button type="submit" name="submit_provider" class="btn-primary-master">Registrar Proveedor</button>
            </div>
        </form>
    </div>
</div>

<!-- Modal: editar proveedor -->
<div class="modal" id="editProviderModal">
    <div class="modal-content">
        <div class="modal-header">
            <h5>Editar Proveedor</h5>
            <button class="modal-close close" onclick="closeModal('editProviderModal')">&times;</button>
        </div>
        <form id="editProviderForm" action="update_provider.php" method="post">
            <div class="modal-body" id="providerDetailsContent"></div>
            <?php if ($is_admin): ?>
            <div class="modal-footer">
                <button type="button" class="btn-secondary-master" onclick="closeModal('editProviderModal')">Cerrar</button>
                <button type="submit" class="btn-primary-master">Guardar Cambios</button>
            </div>
            <?php endif; ?>
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

// ── Validación de formularios ──
document.querySelectorAll('form[data-validate]').forEach(function(form) {
    form.addEventListener('submit', function(e) {
        var required = form.querySelectorAll('[required]');
        var valid = true;
        required.forEach(function(field) {
            field.classList.remove('is-invalid');
            if (!field.value.trim()) {
                field.classList.add('is-invalid');
                valid = false;
            }
        });
        if (!valid) {
            e.preventDefault();
            var existing = form.querySelector('.validation-error');
            if (!existing) {
                var msg = document.createElement('div');
                msg.className = 'alert alert-danger validation-error';
                msg.innerHTML = '<i class="fas fa-exclamation-circle"></i> Completa todos los campos obligatorios.';
                form.prepend(msg);
            }
        }
    });
    form.querySelectorAll('[required]').forEach(function(field) {
        field.addEventListener('input', function() { field.classList.remove('is-invalid'); });
    });
});

function openEditModal(id) {
    openModal('editProviderModal');
    fetch(`get_provider_details.php?id_proveedor=${id}`)
        .then(function(r) { return r.json(); })
        .then(function(data) {
            if (data.error) {
                showToast(data.error, 'error');
            } else {
                document.getElementById('providerDetailsContent').innerHTML = `
                    <input type="hidden" name="id_proveedor" value="${data.id_proveedor}">
                    <div class="form-group">
                        <label class="form-label">Nombre</label>
                        <input type="text" class="form-control" name="nombre_proveedor" value="${data.nombre_proveedor}" required>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Teléfono</label>
                        <input type="text" class="form-control" name="telefono" value="${data.telefono}" required>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Email</label>
                        <input type="email" class="form-control" name="email" value="${data.email}" required>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Dirección</label>
                        <input type="text" class="form-control" name="direccion" value="${data.direccion}" required>
                    </div>`;
            }
        })
        .catch(function(error) { console.error('Error:', error); });
}

var providersSearchInput = document.getElementById('tableSearchProviders');
if (providersSearchInput) {
    providersSearchInput.addEventListener('input', function() {
        var term = this.value.toLowerCase().trim();
        var rows = document.querySelectorAll('#providersTable tbody tr');
        var visible = 0;

        rows.forEach(function(row) {
            var show = term === '' || row.textContent.toLowerCase().includes(term);
            row.style.display = show ? '' : 'none';
            if (show) visible++;
        });

        var noResults = document.getElementById('noProviderResults');
        if (noResults) {
            noResults.style.display = (term !== '' && rows.length > 0 && visible === 0) ? 'block' : 'none';
        }
        var searchTerm = document.getElementById('providerSearchTerm');
        if (searchTerm) {
            searchTerm.textContent = term;
        }
    });
}
</script>

<?php include('layout/footer_main.php'); ?>
