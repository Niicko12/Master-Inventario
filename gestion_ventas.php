<?php
require_once 'config.php';
$page_title  = 'Ventas';
$active_page = 'gestion_ventas.php';
$user_role   = $_SESSION['user_role'] ?? null;
$allow_negative_inventory = isSystemSettingEnabled('permitir_inventario_negativo');
$flash_message = '';
$flash_type = 'info';

// Definir permisos según el rol
$can_add_sales    = ($user_role == 'Empleado' || $user_role == 'Administrador');
$can_manage_sales = ($user_role == 'Administrador');

// Eliminar venta y actualizar inventario
if (isset($_GET['delete']) && $can_manage_sales) {
    $sale_id = intval($_GET['delete']);

    $sale_items = dbFetchAll($conn,
        "SELECT id_producto, cantidad_vendida FROM Detalle_Ventas WHERE id_venta = ?",
        "i", $sale_id
    );

    foreach ($sale_items as $sale) {
        $id_producto      = (int)$sale['id_producto'];
        $cantidad_vendida = (int)$sale['cantidad_vendida'];
        dbExecute($conn,
            "UPDATE Inventario SET cantidad_disponible = cantidad_disponible + ? WHERE id_producto = ?",
            "ii", $cantidad_vendida, $id_producto
        );
    }

    dbExecute($conn, "DELETE FROM Detalle_Ventas WHERE id_venta = ?", "i", $sale_id);
    dbExecute($conn, "DELETE FROM Ventas WHERE id_venta = ?", "i", $sale_id);
}

// Crear nueva venta
if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['submit_sale'])) {
    $id_cliente       = intval($_POST['id_cliente']);
    $id_producto      = intval($_POST['id_producto']);
    $cantidad_vendida = intval($_POST['cantidad_vendida']);
    $monto_total      = floatval($_POST['monto_total']);
    $fecha_venta      = date('Y-m-d H:i:s');
    $estado           = 'Petición Realizada';

    $stmt = $conn->prepare("SELECT cantidad_disponible FROM Inventario WHERE id_producto = ?");
    $stmt->bind_param("i", $id_producto);
    $stmt->execute();
    $inventory_result = $stmt->get_result();
    $inventory = $inventory_result->fetch_assoc();
    $stmt->close();

    if ($inventory && ($allow_negative_inventory || $inventory['cantidad_disponible'] >= $cantidad_vendida)) {
        $stmt = $conn->prepare("INSERT INTO Ventas (id_cliente, fecha_venta, monto_total, estado) VALUES (?, ?, ?, ?)");
        $stmt->bind_param("isds", $id_cliente, $fecha_venta, $monto_total, $estado);
        $stmt->execute();
        $id_venta = $conn->insert_id;
        $stmt->close();

        $precio_unitario = $cantidad_vendida > 0 ? $monto_total / $cantidad_vendida : 0;
        $stmt = $conn->prepare("INSERT INTO Detalle_Ventas (id_venta, id_producto, cantidad_vendida, precio_unitario) VALUES (?, ?, ?, ?)");
        $stmt->bind_param("iiid", $id_venta, $id_producto, $cantidad_vendida, $precio_unitario);
        $stmt->execute();
        $stmt->close();

        $stmt = $conn->prepare("UPDATE Inventario SET cantidad_disponible = cantidad_disponible - ? WHERE id_producto = ?");
        $stmt->bind_param("ii", $cantidad_vendida, $id_producto);
        $stmt->execute();
        $stmt->close();
        $flash_message = 'Venta registrada correctamente.';
        $flash_type    = 'success';
    } else {
        $disponible = isset($inventory['cantidad_disponible']) ? (int)$inventory['cantidad_disponible'] : 0;
        $flash_message = 'Stock insuficiente para registrar la venta. Disponible actual: ' . $disponible . '.';
        $flash_type    = 'error';
    }
}

// Obtener datos de clientes y productos
$clientes = $conn->query("SELECT id_usuario, nombre FROM Usuarios WHERE rol = 'Usuario'")->fetch_all(MYSQLI_ASSOC);
$productosQuery = $allow_negative_inventory
    ? "SELECT id_producto, nombre_producto, cantidad_disponible FROM Inventario"
    : "SELECT id_producto, nombre_producto, cantidad_disponible FROM Inventario WHERE cantidad_disponible > 0";
$productos = $conn->query($productosQuery)->fetch_all(MYSQLI_ASSOC);

// Listar ventas (paginado)
['page' => $page, 'limit' => $limit, 'offset' => $offset] = getPaginationParams(25);
$total_ventas = countTotal($conn,
    "SELECT COUNT(*) FROM Ventas V
     JOIN Usuarios U ON V.id_cliente = U.id_usuario
     JOIN Detalle_Ventas DV ON V.id_venta = DV.id_venta
     JOIN Inventario I ON DV.id_producto = I.id_producto"
);
$ventas = dbFetchAll($conn,
    "SELECT V.id_venta, U.nombre AS cliente, V.fecha_venta, V.monto_total, DV.cantidad_vendida, I.nombre_producto, V.estado
     FROM Ventas V
     JOIN Usuarios U ON V.id_cliente = U.id_usuario
     JOIN Detalle_Ventas DV ON V.id_venta = DV.id_venta
     JOIN Inventario I ON DV.id_producto = I.id_producto
     ORDER BY V.fecha_venta DESC LIMIT ? OFFSET ?",
    "ii", $limit, $offset
);

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
        <h1>Ventas</h1>
        <div class="page-banner-breadcrumb">
            <a href="dashboard.php">Inicio</a>
            <span class="sep">•</span>
            <span>Ventas</span>
        </div>
    </div>
    <img src="assets/images/breadcrumb/inventario_productos_banner.svg" alt="Banner de inventario de productos" class="page-banner-img">
</div>
<div class="module-actions-row">
    <?php if ($can_add_sales): ?>
    <button type="button" class="btn-primary-master" onclick="openModal('createSaleModal')">
        <i class="fas fa-plus"></i> Registrar Venta
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
        <p>Reporte de ventas</p>
        <span>Generado: <?= htmlspecialchars($print_generated_at, ENT_QUOTES, 'UTF-8') ?></span>
    </div>
</div>
<?php if ($allow_negative_inventory): ?>
<div class="alert-banner">
    <i class="fas fa-info-circle"></i>
    <span>Inventario negativo <strong>habilitado</strong>: se permiten ventas con stock en cero o menor.</span>
</div>
<?php endif; ?>

<!-- Tabla de ventas -->
<div class="card-master">
    <div class="card-header-master">
        <h3><i class="fas fa-shopping-cart icon-pink"></i>Registro de Ventas</h3>
        <div class="table-search-wrap no-icon">
            <input type="text" id="tableSearchSales" class="table-search-input" placeholder="Buscar venta...">
        </div>
    </div>

    <?php if (!empty($ventas)): ?>
    <div class="table-wrap">
        <table class="data-table" id="salesTable">
            <thead>
                <tr>
                    <th>#</th>
                    <th>Cliente</th>
                    <th>Producto</th>
                    <th style="text-align:right;">Cantidad</th>
                    <th>Fecha</th>
                    <th style="text-align:right;">Monto</th>
                    <th>Estado</th>
                    <?php if ($can_add_sales): ?>
                    <th>Acciones</th>
                    <?php endif; ?>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($ventas as $row): ?>
                <tr>
                    <td class="td-muted">#<?= htmlspecialchars($row['id_venta']) ?></td>
                    <td class="td-primary"><?= htmlspecialchars($row['cliente']) ?></td>
                    <td><?= htmlspecialchars($row['nombre_producto']) ?></td>
                    <td class="num"><?= htmlspecialchars($row['cantidad_vendida']) ?></td>
                    <td><?= htmlspecialchars(appFormatDateTime($row['fecha_venta']), ENT_QUOTES, 'UTF-8') ?></td>
                    <td class="td-amount"><?= htmlspecialchars(appFormatCurrency((float)$row['monto_total']), ENT_QUOTES, 'UTF-8') ?></td>
                    <td><span class="badge-pill <?= $row['estado'] === 'Entregado' ? 'badge-success' : ($row['estado'] === 'Devuelto' ? 'badge-danger' : 'badge-info') ?>"><?= htmlspecialchars($row['estado']) ?></span></td>
                    <?php if ($can_add_sales): ?>
                    <td>
                        <div class="td-actions">
                            <button class="btn-icon" title="Ver Detalles" onclick="openEditModal(<?= intval($row['id_venta']) ?>)">
                                <i class="fas fa-eye"></i>
                            </button>
                            <?php if ($can_manage_sales): ?>
                            <a href="gestion_ventas.php?delete=<?= intval($row['id_venta']) ?>" class="btn-icon danger" title="Eliminar" onclick="return confirm('¿Eliminar esta venta? El inventario será restaurado.');">
                                <i class="fas fa-trash-alt"></i>
                            </a>
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
        <i class="fas fa-shopping-cart"></i>
        <p>No hay ventas registradas aún.</p>
    </div>
    <?php endif; ?>
    <div id="noSalesResults" style="display:none;">
        <div class="empty-state">
            <i class="fas fa-search"></i>
            <p>Sin resultados para "<span id="salesSearchTerm"></span>"</p>
        </div>
    </div>

    <?= renderPagination($total_ventas, $page, $limit) ?>
</div>

<!-- Modal: registrar nueva venta -->
<div class="modal" id="createSaleModal">
    <div class="modal-content">
        <div class="modal-header">
            <h5>Registrar Nueva Venta</h5>
            <button class="modal-close close" onclick="closeModal('createSaleModal')">&times;</button>
        </div>
        <form action="gestion_ventas.php" method="post" data-validate>
            <div class="modal-body">
                <div class="form-group">
                    <label class="form-label" for="id_cliente">Cliente</label>
                    <select class="form-control" id="id_cliente" name="id_cliente" required>
                        <?php foreach ($clientes as $cliente): ?>
                            <option value="<?= $cliente['id_usuario'] ?>"><?= htmlspecialchars($cliente['nombre']) ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="form-group">
                    <label class="form-label" for="id_producto">Producto</label>
                    <select class="form-control" id="id_producto" name="id_producto" required>
                        <?php foreach ($productos as $producto): ?>
                            <option value="<?= $producto['id_producto'] ?>"><?= htmlspecialchars($producto['nombre_producto']) ?> (Disponibles: <?= (int)$producto['cantidad_disponible'] ?>)</option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="form-group">
                    <label class="form-label" for="cantidad_vendida">Cantidad Vendida</label>
                    <input type="number" class="form-control" id="cantidad_vendida" name="cantidad_vendida" min="1" required>
                </div>
                <div class="form-group">
                    <label class="form-label" for="monto_total">Monto Total</label>
                    <input type="number" step="0.01" class="form-control" id="monto_total" name="monto_total" required>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn-secondary-master" onclick="closeModal('createSaleModal')">Cerrar</button>
                <button type="submit" name="submit_sale" class="btn-primary-master">Registrar Venta</button>
            </div>
        </form>
    </div>
</div>

<!-- Modal: ver/editar detalles de venta -->
<div class="modal" id="viewDetailsModal">
    <div class="modal-content">
        <div class="modal-header">
            <h5>Detalles de la Venta</h5>
            <button class="modal-close close" onclick="closeModal('viewDetailsModal')">&times;</button>
        </div>
        <form id="editSaleForm" method="post">
            <div class="modal-body" id="saleDetailsContent"></div>
            <div class="modal-footer">
                <button type="button" class="btn-secondary-master" onclick="closeModal('viewDetailsModal')">Cerrar</button>
                <button type="submit" name="update_sale" class="btn-primary-master">Guardar Cambios</button>
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
    fetch('detalle_venta.php?id_venta=' + id, {
        headers: { 'X-Requested-With': 'XMLHttpRequest' }
    })
    .then(function(r) { return r.json(); })
    .then(function(data) {
        if (data.error) {
            showToast(data.error, 'error');
        } else {
            document.getElementById('saleDetailsContent').innerHTML = `
                <input type="hidden" name="id_venta" value="${data.id_venta}">
                <div class="form-group">
                    <label class="form-label">Cliente</label>
                    <input type="text" class="form-control" value="${data.cliente}" readonly>
                </div>
                <div class="form-group">
                    <label class="form-label">Producto</label>
                    <input type="text" class="form-control" value="${data.nombre_producto}" readonly>
                </div>
                <div class="form-group">
                    <label class="form-label">Cantidad Vendida</label>
                    <input type="number" class="form-control" name="cantidad_vendida" value="${data.cantidad_vendida}" min="1" required>
                </div>
                <div class="form-group">
                    <label class="form-label">Estado</label>
                    <select class="form-control" name="estado" required>
                        <option value="Petición Realizada" ${data.estado == 'Petición Realizada' ? 'selected' : ''}>Petición Realizada</option>
                        <option value="Producto Pagado" ${data.estado == 'Producto Pagado' ? 'selected' : ''}>Producto Pagado</option>
                        <option value="En Envío" ${data.estado == 'En Envío' ? 'selected' : ''}>En Envío</option>
                        <option value="Entregado" ${data.estado == 'Entregado' ? 'selected' : ''}>Entregado</option>
                        <option value="Devuelto" ${data.estado == 'Devuelto' ? 'selected' : ''}>Devuelto</option>
                    </select>
                </div>`;
            openModal('viewDetailsModal');
        }
    })
    .catch(function(error) {
        console.error('Error:', error);
        showToast('Error al realizar la solicitud.', 'error');
    });
}

var salesSearchInput = document.getElementById('tableSearchSales');
if (salesSearchInput) {
    salesSearchInput.addEventListener('input', function() {
        var term = this.value.toLowerCase().trim();
        var rows = document.querySelectorAll('#salesTable tbody tr');
        var visible = 0;

        rows.forEach(function(row) {
            var show = term === '' || row.textContent.toLowerCase().includes(term);
            row.style.display = show ? '' : 'none';
            if (show) visible++;
        });

        var noResults = document.getElementById('noSalesResults');
        if (noResults) {
            noResults.style.display = (term !== '' && rows.length > 0 && visible === 0) ? 'block' : 'none';
        }
        var searchTerm = document.getElementById('salesSearchTerm');
        if (searchTerm) {
            searchTerm.textContent = term;
        }
    });
}
</script>

<?php include('layout/footer_main.php'); ?>
