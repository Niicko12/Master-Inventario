<?php
require_once 'config.php';
$page_title  = 'Inventario';
$active_page = 'gestion_inventario.php';
$user_role   = $_SESSION['user_role'] ?? '';
$stock_threshold = max(0, (int)systemSetting('umbral_stock_bajo', 5));
$auto_categorization = isSystemSettingEnabled('categorizacion_automatica');

function inventoryInferCategory(string $nombreProducto): string
{
    $value = mb_strtolower(trim($nombreProducto));
    if ($value === '') return 'General';
    if (preg_match('/tornillo|tuerca|clavo|perno|broca|herramienta|taladro|martillo/', $value)) return 'Ferretería';
    if (preg_match('/aceite|lubricante|grasa|filtro|mantenimiento/', $value)) return 'Mantenimiento';
    if (preg_match('/cable|switch|router|laptop|monitor|teclado|mouse|impresora/', $value)) return 'Tecnología';
    if (preg_match('/motor|bomba|valvula|válvula|compresor|rodamiento/', $value)) return 'Mecánica';
    if (preg_match('/uniforme|guante|casco|botas|mascarilla|lente/', $value)) return 'Seguridad';
    return 'General';
}

$flash_message = '';
$flash_type    = 'info';

// ── Añadir producto ──
if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['action']) && $_POST['action'] == 'add') {
    $nombre_producto      = trim($_POST['nombre_producto'] ?? '');
    $cantidad_disponible  = intval($_POST['cantidad_disponible'] ?? 0);
    $stock_minimo         = intval($_POST['stock_minimo'] ?? 0);

    if ($nombre_producto !== '') {
        $stmt = $conn->prepare("INSERT INTO Inventario (nombre_producto, cantidad_disponible, stock_minimo, fecha_ultima_actualizacion) VALUES (?, ?, ?, NOW())");
        $stmt->bind_param("sii", $nombre_producto, $cantidad_disponible, $stock_minimo);
        if ($stmt->execute()) {
            $flash_message = 'Producto añadido correctamente.';
            $flash_type    = 'success';
            $newProductId = (int)$stmt->insert_id;
            logInventoryActivity($conn, 'CREAR', 'Producto creado: ' . $nombre_producto . ' | Cantidad: ' . $cantidad_disponible . ' | Stock mínimo: ' . $stock_minimo, $newProductId);
        } else {
            $flash_message = 'Error al añadir el producto.';
            $flash_type    = 'error';
        }
        $stmt->close();
    }
}

// ── Actualizar producto ──
if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['action']) && $_POST['action'] == 'update') {
    $id_producto         = intval($_POST['id_producto'] ?? 0);
    $nombre_producto     = trim($_POST['nombre_producto'] ?? '');
    $cantidad_disponible = intval($_POST['cantidad_disponible'] ?? 0);
    $stock_minimo        = intval($_POST['stock_minimo'] ?? 0);

    if ($id_producto > 0 && $nombre_producto !== '') {
        $stmt = $conn->prepare("UPDATE Inventario SET nombre_producto = ?, cantidad_disponible = ?, stock_minimo = ?, fecha_ultima_actualizacion = NOW() WHERE id_producto = ?");
        $stmt->bind_param("siii", $nombre_producto, $cantidad_disponible, $stock_minimo, $id_producto);
        if ($stmt->execute()) {
            $flash_message = 'Producto actualizado correctamente.';
            $flash_type    = 'success';
            logInventoryActivity($conn, 'ACTUALIZAR', 'Producto actualizado: ' . $nombre_producto . ' | Cantidad: ' . $cantidad_disponible . ' | Stock mínimo: ' . $stock_minimo, $id_producto);
        } else {
            $flash_message = 'Error al actualizar el producto.';
            $flash_type    = 'error';
        }
        $stmt->close();
    }
}

// ── Eliminar producto ──
if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['action']) && $_POST['action'] == 'delete') {
    $id_producto = intval($_POST['id_producto'] ?? 0);
    if ($id_producto > 0 && $user_role === 'Administrador') {
        $row = dbFetchOne($conn, "SELECT nombre_producto FROM Inventario WHERE id_producto = ?", "i", $id_producto);
        $nombre_eliminado = $row['nombre_producto'] ?? ('Producto #' . $id_producto);
        $stmt = $conn->prepare("DELETE FROM Inventario WHERE id_producto = ?");
        $stmt->bind_param("i", $id_producto);
        if ($stmt->execute()) {
            $flash_message = 'Producto eliminado correctamente.';
            $flash_type    = 'success';
            logInventoryActivity($conn, 'ELIMINAR', 'Producto eliminado: ' . $nombre_eliminado, $id_producto);
        } else {
            $flash_message = 'Error al eliminar el producto.';
            $flash_type    = 'error';
        }
        $stmt->close();
    }
}

// ── Resumen de alertas ──
$stmt = $conn->prepare("SELECT SUM(CASE WHEN cantidad_disponible = 0 THEN 1 ELSE 0 END) as sin_stock, SUM(CASE WHEN cantidad_disponible > 0 AND cantidad_disponible <= ? THEN 1 ELSE 0 END) as stock_bajo FROM Inventario");
$stmt->bind_param("i", $stock_threshold);
$stmt->execute();
$alertas = $stmt->get_result()->fetch_assoc();
$stmt->close();
$sin_stock  = (int)($alertas['sin_stock'] ?? 0);
$stock_bajo = (int)($alertas['stock_bajo'] ?? 0);

// ── Listar productos (paginado) ──
['page' => $page, 'limit' => $limit, 'offset' => $offset] = getPaginationParams(25);
$total_productos = countTotal($conn, "SELECT COUNT(*) FROM Inventario");
$productos = dbFetchAll($conn,
    "SELECT * FROM Inventario ORDER BY nombre_producto ASC LIMIT ? OFFSET ?",
    "ii", $limit, $offset
);
$inventory_rows_display = [];
$inventory_categories = [];
$inventory_summary = [
    'normal' => 0,
    'bajo' => 0,
    'sin_stock' => 0,
];
foreach ($productos as $row) {
    $cant = (int)($row['cantidad_disponible'] ?? 0);
    $min  = (int)($row['stock_minimo'] ?? 0);

    if ($cant === 0) {
        $badgeClass = 'badge-stock-sin';
        $badgeText  = 'Sin Stock';
        $estadoKey  = 'sin_stock';
        $inventory_summary['sin_stock']++;
    } elseif ($cant <= $stock_threshold) {
        $badgeClass = 'badge-stock-bajo';
        $badgeText  = 'Stock Bajo';
        $estadoKey  = 'bajo';
        $inventory_summary['bajo']++;
    } else {
        $badgeClass = 'badge-stock-normal';
        $badgeText  = 'Normal';
        $estadoKey  = 'normal';
        $inventory_summary['normal']++;
    }

    $categoriaLabel = inventoryInferCategory((string)($row['nombre_producto'] ?? ''));
    $categoriaKey = mb_strtolower($categoriaLabel);
    $inventory_categories[$categoriaKey] = $categoriaLabel;

    $row['_badge_class'] = $badgeClass;
    $row['_badge_text'] = $badgeText;
    $row['_estado_key'] = $estadoKey;
    $row['_categoria_label'] = $categoriaLabel;
    $row['_categoria_key'] = $categoriaKey;
    $row['_nombre_key'] = mb_strtolower((string)($row['nombre_producto'] ?? ''));
    $inventory_rows_display[] = $row;
}
asort($inventory_categories, SORT_NATURAL | SORT_FLAG_CASE);

include('layout/sidebar.php');
$print_generated_at = appFormatDateTime(time());
?>

<?php if ($flash_message): ?>
<script>
    document.addEventListener('DOMContentLoaded', function() {
        showToast(<?= json_encode($flash_message) ?>, <?= json_encode($flash_type) ?>);
    });
</script>
<?php endif; ?>

<!-- Page Banner -->
<div class="page-banner">
    <div class="page-banner-content">
        <h1>Inventario</h1>
        <div class="page-banner-breadcrumb">
            <a href="dashboard.php">Inicio</a>
            <span class="sep">•</span>
            <span>Inventario</span>
        </div>
    </div>
    <img src="assets/images/breadcrumb/inventario_productos_banner.svg" alt="Banner de inventario de productos" class="page-banner-img">
</div>
<div class="module-actions-row">
    <?php if ($user_role == 'Administrador' || $user_role == 'Empleado'): ?>
    <button type="button" class="btn-primary-master" onclick="openModal('createProductModal')">
        <i class="fas fa-plus"></i> Añadir Producto
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
        <p>Reporte de inventario</p>
        <span>Generado: <?= htmlspecialchars($print_generated_at, ENT_QUOTES, 'UTF-8') ?></span>
    </div>
</div>

<?php if ($sin_stock > 0 || $stock_bajo > 0): ?>
<div class="alert-banner">
    <i class="fas fa-exclamation-triangle"></i>
    <span>
        <?php if ($sin_stock > 0): ?><strong><?= $sin_stock ?> sin stock.</strong> <?php endif; ?>
        <?php if ($stock_bajo > 0): ?><strong><?= $stock_bajo ?> bajo el umbral (<?= $stock_threshold ?>).</strong><?php endif; ?>
        Reabastecer según sea necesario.
    </span>
</div>
<?php endif; ?>

<!-- Tabla de inventario -->
<div class="card-master">
    <div class="card-header-master">
        <h3><i class="fas fa-boxes icon-cyan"></i>Productos</h3>
    </div>
    <div class="inventory-pro-toolbar">
        <div class="inventory-pro-filters">
            <div class="table-search-wrap no-icon">
                <input type="text" id="tableSearch" class="table-search-input" placeholder="Buscar por nombre...">
            </div>
            <select id="statusFilter" class="form-control inventory-filter-control">
                <option value="all">Todos los estados</option>
                <option value="normal">Solo stock normal</option>
                <option value="bajo">Solo stock bajo</option>
                <option value="sin_stock">Solo sin stock</option>
            </select>
            <select id="categoryFilter" class="form-control inventory-filter-control">
                <option value="all">Todas las categorías</option>
                <?php foreach ($inventory_categories as $category_key => $category_label): ?>
                <option value="<?= htmlspecialchars($category_key, ENT_QUOTES, 'UTF-8') ?>">
                    <?= htmlspecialchars($category_label, ENT_QUOTES, 'UTF-8') ?>
                </option>
                <?php endforeach; ?>
            </select>
        </div>
        <div class="inventory-pro-stats">
            <span class="badge-stock-normal">Normal: <?= (int)$inventory_summary['normal'] ?></span>
            <span class="badge-stock-bajo">Bajo: <?= (int)$inventory_summary['bajo'] ?></span>
            <span class="badge-stock-sin">Sin stock: <?= (int)$inventory_summary['sin_stock'] ?></span>
        </div>
    </div>

    <?php if (!empty($inventory_rows_display)): ?>
    <div class="table-wrap">
        <table class="data-table" id="inventoryTable">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Nombre del Producto</th>
                    <th>Categoría</th>
                    <th style="text-align:right;">Disponible</th>
                    <th style="text-align:right;">Stock Mínimo</th>
                    <th>Estado</th>
                    <?php if ($user_role == 'Administrador' || $user_role == 'Empleado'): ?>
                    <th>Acciones</th>
                    <?php endif; ?>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($inventory_rows_display as $row):
                    $cant = (int)$row['cantidad_disponible'];
                    $min  = (int)$row['stock_minimo'];
                ?>
                <tr
                    data-nombre="<?= htmlspecialchars($row['_nombre_key'], ENT_QUOTES, 'UTF-8') ?>"
                    data-status="<?= htmlspecialchars($row['_estado_key'], ENT_QUOTES, 'UTF-8') ?>"
                    data-category="<?= htmlspecialchars($row['_categoria_key'], ENT_QUOTES, 'UTF-8') ?>"
                >
                    <td class="td-muted">#<?= (int)$row['id_producto'] ?></td>
                    <td class="td-primary"><?= htmlspecialchars($row['nombre_producto'], ENT_QUOTES, 'UTF-8') ?></td>
                    <td><span class="badge-pill badge-neutral"><?= htmlspecialchars($row['_categoria_label'], ENT_QUOTES, 'UTF-8') ?></span></td>
                    <td class="num"><?= $cant ?></td>
                    <td class="num"><?= $min ?></td>
                    <td><span class="<?= $row['_badge_class'] ?>"><?= $row['_badge_text'] ?></span></td>
                    <?php if ($user_role == 'Administrador' || $user_role == 'Empleado'): ?>
                    <td>
                        <div class="td-actions">
                            <button
                                type="button"
                                class="btn-icon js-edit-product"
                                title="Editar"
                                data-id="<?= (int)$row['id_producto'] ?>"
                                data-nombre="<?= htmlspecialchars($row['nombre_producto'], ENT_QUOTES, 'UTF-8') ?>"
                                data-cantidad="<?= $cant ?>"
                                data-stock="<?= $min ?>"
                            ><i class="fas fa-pencil-alt"></i></button>
                            <?php if ($user_role == 'Administrador'): ?>
                            <button
                                type="button"
                                class="btn-icon danger js-delete-product"
                                title="Eliminar"
                                data-id="<?= (int)$row['id_producto'] ?>"
                                data-nombre="<?= htmlspecialchars($row['nombre_producto'], ENT_QUOTES, 'UTF-8') ?>"
                            ><i class="fas fa-trash-alt"></i></button>
                            <?php endif; ?>
                        </div>
                    </td>
                    <?php endif; ?>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php else: ?>
    <div class="empty-state">
        <i class="fas fa-boxes"></i>
        <p>No se encontraron productos en el inventario.</p>
    </div>
    <?php endif; ?>

    <div id="noSearchResults" style="display:none;">
        <div class="empty-state">
            <i class="fas fa-search"></i>
            <p>Sin resultados para "<span id="searchTerm"></span>"</p>
        </div>
    </div>

    <?= renderPagination($total_productos, $page, $limit) ?>
</div>

<!-- Formulario oculto para DELETE -->
<form id="deleteForm" method="POST" action="gestion_inventario.php" style="display:none;">
    <input type="hidden" name="action" value="delete">
    <input type="hidden" name="id_producto" id="deleteProductId">
</form>

<!-- Modal: crear producto -->
<div class="modal" id="createProductModal" role="dialog" aria-modal="true" aria-labelledby="createModalTitle">
    <div class="modal-content">
        <div class="modal-header">
            <h5 id="createModalTitle">Añadir Producto</h5>
            <button type="button" class="modal-close close" onclick="closeModal('createProductModal')" aria-label="Cerrar">&times;</button>
        </div>
        <form method="post" action="gestion_inventario.php" data-validate>
            <input type="hidden" name="action" value="add">
            <div class="modal-body">
                <div class="form-group">
                    <label class="form-label" for="nombre_producto">Nombre del Producto</label>
                    <input type="text" class="form-control" id="nombre_producto" name="nombre_producto" placeholder="Ej. Laptop Dell XPS" required>
                    <?php if ($auto_categorization): ?>
                    <span class="form-helper" id="categorySuggestionText">Categoría sugerida: <strong id="categorySuggestionValue">Sin sugerencia</strong></span>
                    <?php endif; ?>
                </div>
                <div class="form-group">
                    <label class="form-label" for="cantidad_disponible">Cantidad Disponible</label>
                    <input type="number" class="form-control" id="cantidad_disponible" name="cantidad_disponible" min="0" placeholder="0" required>
                </div>
                <div class="form-group">
                    <label class="form-label" for="stock_minimo">Stock Mínimo</label>
                    <input type="number" class="form-control" id="stock_minimo" name="stock_minimo" min="0" placeholder="0" required>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn-secondary-master" onclick="closeModal('createProductModal')">Cancelar</button>
                <button type="submit" class="btn-primary-master">Guardar Producto</button>
            </div>
        </form>
    </div>
</div>

<!-- Modal: editar producto -->
<div class="modal" id="editProductModal" role="dialog" aria-modal="true" aria-labelledby="editModalTitle">
    <div class="modal-content">
        <div class="modal-header">
            <h5 id="editModalTitle">Editar Producto</h5>
            <button type="button" class="modal-close close" onclick="closeModal('editProductModal')" aria-label="Cerrar">&times;</button>
        </div>
        <form method="post" action="gestion_inventario.php" data-validate>
            <input type="hidden" name="action" value="update">
            <input type="hidden" id="id_producto" name="id_producto">
            <div class="modal-body">
                <div class="form-group">
                    <label class="form-label" for="nombre_producto_edit">Nombre del Producto</label>
                    <input type="text" class="form-control" id="nombre_producto_edit" name="nombre_producto" required>
                </div>
                <div class="form-group">
                    <label class="form-label" for="cantidad_disponible_edit">Cantidad Disponible</label>
                    <input type="number" class="form-control" id="cantidad_disponible_edit" name="cantidad_disponible" min="0" required>
                </div>
                <div class="form-group">
                    <label class="form-label" for="stock_minimo_edit">Stock Mínimo</label>
                    <input type="number" class="form-control" id="stock_minimo_edit" name="stock_minimo" min="0" required>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn-secondary-master" onclick="closeModal('editProductModal')">Cancelar</button>
                <button type="submit" class="btn-primary-master">Guardar Cambios</button>
            </div>
        </form>
    </div>
</div>

<script>
function openModal(id) {
    var m = document.getElementById(id);
    m.style.display = 'flex';
    var first = m.querySelector('input, select, textarea');
    if (first) first.focus();
}
function closeModal(id) {
    document.getElementById(id).style.display = 'none';
}
document.querySelectorAll('.modal').forEach(function(m) {
    m.addEventListener('click', function(e) { if (e.target === m) closeModal(m.id); });
});
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        document.querySelectorAll('.modal').forEach(function(m) {
            if (m.style.display !== 'none') closeModal(m.id);
        });
    }
});

function openEditModal(id, nombre, cantidad, stock) {
    document.getElementById('id_producto').value = id;
    document.getElementById('nombre_producto_edit').value = nombre;
    document.getElementById('cantidad_disponible_edit').value = cantidad;
    document.getElementById('stock_minimo_edit').value = stock;
    openModal('editProductModal');
}

function triggerDelete(id, nombre) {
    var confirmado = window.confirm('¿Eliminar el producto "' + nombre + '"? Esta acción no se puede deshacer.');
    if (!confirmado) return;
    document.getElementById('deleteProductId').value = id;
    document.getElementById('deleteForm').submit();
}
document.addEventListener('click', function(e) {
    var editBtn = e.target.closest('.js-edit-product');
    if (editBtn) {
        openEditModal(
            parseInt(editBtn.dataset.id || '0', 10),
            editBtn.dataset.nombre || '',
            parseInt(editBtn.dataset.cantidad || '0', 10),
            parseInt(editBtn.dataset.stock || '0', 10)
        );
        return;
    }

    var deleteBtn = e.target.closest('.js-delete-product');
    if (deleteBtn) {
        triggerDelete(
            parseInt(deleteBtn.dataset.id || '0', 10),
            deleteBtn.dataset.nombre || ''
        );
    }
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
    // Limpiar is-invalid al escribir
    form.querySelectorAll('[required]').forEach(function(field) {
        field.addEventListener('input', function() { field.classList.remove('is-invalid'); });
    });
});

// ── Live search ──
var tableSearchInput = document.getElementById('tableSearch');
var statusFilter = document.getElementById('statusFilter');
var categoryFilter = document.getElementById('categoryFilter');

function applyInventoryFilters() {
    var rows = document.querySelectorAll('#inventoryTable tbody tr');
    if (!rows.length) return;

    var term = tableSearchInput ? tableSearchInput.value.toLowerCase().trim() : '';
    var statusValue = statusFilter ? statusFilter.value : 'all';
    var categoryValue = categoryFilter ? categoryFilter.value : 'all';
    var visible = 0;

    rows.forEach(function(row) {
        var nombre = row.getAttribute('data-nombre') || '';
        var status = row.getAttribute('data-status') || 'normal';
        var category = row.getAttribute('data-category') || 'general';

        var matchTerm = (term === '' || nombre.indexOf(term) !== -1);
        var matchStatus = (statusValue === 'all' || status === statusValue);
        var matchCategory = (categoryValue === 'all' || category === categoryValue);
        var show = matchTerm && matchStatus && matchCategory;

        row.style.display = show ? '' : 'none';
        if (show) visible++;
    });

    var noResults = document.getElementById('noSearchResults');
    if (noResults) {
        noResults.style.display = visible === 0 ? 'block' : 'none';
    }
    var searchTerm = document.getElementById('searchTerm');
    if (searchTerm) {
        searchTerm.textContent = term !== '' ? term : 'filtros seleccionados';
    }
}

if (tableSearchInput) {
    tableSearchInput.addEventListener('input', applyInventoryFilters);
}
if (statusFilter) {
    statusFilter.addEventListener('change', applyInventoryFilters);
}
if (categoryFilter) {
    categoryFilter.addEventListener('change', applyInventoryFilters);
}
applyInventoryFilters();

<?php if ($auto_categorization): ?>
(function() {
    var input = document.getElementById('nombre_producto');
    var text = document.getElementById('categorySuggestionValue');
    if (!input || !text) return;

    function inferCategory(nombre) {
        var value = (nombre || '').toLowerCase();
        if (/tornillo|tuerca|clavo|perno|herramienta|broca/.test(value)) return 'Ferretería';
        if (/aceite|lubricante|grasa|filtro/.test(value)) return 'Mantenimiento';
        if (/cable|switch|router|laptop|monitor|teclado|mouse/.test(value)) return 'Tecnología';
        if (/motor|bomba|válvula|valvula|compresor/.test(value)) return 'Mecánica';
        if (/uniforme|guante|casco|botas|mascarilla/.test(value)) return 'Seguridad';
        return 'General';
    }

    input.addEventListener('input', function() {
        text.textContent = inferCategory(input.value);
    });
})();
<?php endif; ?>
</script>

<?php include('layout/footer_main.php'); ?>
