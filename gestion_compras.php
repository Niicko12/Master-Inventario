<?php
require_once 'config.php';
$page_title  = 'Compras';
$active_page = 'gestion_compras.php';

$is_admin = isset($_SESSION['user_role']) && $_SESSION['user_role'] === 'Administrador';

// Regresar compra
if (isset($_GET['return']) && $is_admin) {
    $purchase_id = intval($_GET['return']);
    $purchase = dbFetchOne($conn,
        "SELECT id_compra, cantidad_comprada FROM Compras WHERE id_compra = ?",
        "i", $purchase_id
    );
    if ($purchase) {
        $id_compra         = (int)$purchase['id_compra'];
        $cantidad_comprada = (int)$purchase['cantidad_comprada'];
        dbExecute($conn,
            "UPDATE Inventario SET cantidad_disponible = cantidad_disponible + ?
             WHERE id_producto = (SELECT id_producto FROM Detalle_Ventas WHERE id_venta = ? LIMIT 1)",
            "ii", $cantidad_comprada, $id_compra
        );
        dbExecute($conn, "UPDATE Compras SET estado = 'Devuelto' WHERE id_compra = ?", "i", $purchase_id);
        dbExecute($conn, "DELETE FROM Compras WHERE id_compra = ?", "i", $purchase_id);
    }
}

// Eliminar compra
if (isset($_GET['delete']) && $is_admin) {
    $purchase_id = intval($_GET['delete']);
    dbExecute($conn, "DELETE FROM Compras WHERE id_compra = ?", "i", $purchase_id);
}

// Registrar nueva compra
if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['submit_purchase'])) {
    $id_proveedor      = intval($_POST['id_proveedor']);
    $nombre_producto   = $_POST['nombre_producto'];
    $cantidad_comprada = intval($_POST['cantidad_comprada']);
    $monto_total       = floatval($_POST['monto_total']);
    $fecha_compra      = date('Y-m-d H:i:s');

    $stmt = $conn->prepare("INSERT INTO Compras (id_proveedor, nombre_producto, cantidad_comprada, fecha_compra, monto_total) VALUES (?, ?, ?, ?, ?)");
    $stmt->bind_param("isisd", $id_proveedor, $nombre_producto, $cantidad_comprada, $fecha_compra, $monto_total);
    if ($stmt->execute()) {
        $stmt->close();
        $stmt = $conn->prepare("SELECT id_producto FROM Inventario WHERE nombre_producto = ?");
        $stmt->bind_param("s", $nombre_producto);
        $stmt->execute();
        $check_result = $stmt->get_result();
        $stmt->close();
        if ($check_result->num_rows > 0) {
            $stmt = $conn->prepare("UPDATE Inventario SET cantidad_disponible = cantidad_disponible + ?, fecha_ultima_actualizacion = NOW() WHERE nombre_producto = ?");
            $stmt->bind_param("is", $cantidad_comprada, $nombre_producto);
            $stmt->execute();
            $stmt->close();
        } else {
            $stmt = $conn->prepare("INSERT INTO Inventario (nombre_producto, cantidad_disponible, stock_minimo, fecha_ultima_actualizacion, ubicacion_id, id_proveedor) VALUES (?, ?, 10, NOW(), NULL, ?)");
            $stmt->bind_param("sii", $nombre_producto, $cantidad_comprada, $id_proveedor);
            $stmt->execute();
            $stmt->close();
        }
    } else {
        $stmt->close();
    }
}

// Listar compras (paginado)
['page' => $page, 'limit' => $limit, 'offset' => $offset] = getPaginationParams(25);
$total_compras = countTotal($conn,
    "SELECT COUNT(*) FROM Compras C JOIN Proveedores P ON C.id_proveedor = P.id_proveedor"
);
$compras = dbFetchAll($conn,
    "SELECT C.id_compra, P.nombre_proveedor AS proveedor, C.nombre_producto, C.cantidad_comprada, C.fecha_compra, C.monto_total
     FROM Compras C
     JOIN Proveedores P ON C.id_proveedor = P.id_proveedor
     ORDER BY C.fecha_compra DESC LIMIT ? OFFSET ?",
    "ii", $limit, $offset
);

// Proveedores para el formulario
$proveedores = dbFetchAll($conn, "SELECT id_proveedor, nombre_proveedor FROM Proveedores ORDER BY nombre_proveedor ASC");

include('layout/sidebar.php');
$print_generated_at = appFormatDateTime(time());
?>

<!-- Page Banner -->
<div class="page-banner">
    <div class="page-banner-content">
        <h1>Compras</h1>
        <div class="page-banner-breadcrumb">
            <a href="dashboard.php">Inicio</a>
            <span class="sep">•</span>
            <span>Compras</span>
        </div>
    </div>
    <img src="assets/images/breadcrumb/inventario_productos_banner.svg" alt="Banner de inventario de productos" class="page-banner-img">
</div>
<div class="module-actions-row">
    <?php if ($is_admin): ?>
    <button type="button" class="btn-primary-master" onclick="openModal('createPurchaseModal')">
        <i class="fas fa-plus"></i> Registrar Compra
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
        <p>Reporte de compras</p>
        <span>Generado: <?= htmlspecialchars($print_generated_at, ENT_QUOTES, 'UTF-8') ?></span>
    </div>
</div>

<!-- Tabla de compras -->
<div class="card-master">
    <div class="card-header-master">
        <h3><i class="fas fa-truck icon-cyan"></i>Registro de Compras</h3>
        <div class="table-search-wrap no-icon">
            <input type="text" id="tableSearchPurchases" class="table-search-input" placeholder="Buscar compra...">
        </div>
    </div>

    <?php if (!empty($compras)): ?>
    <div class="table-wrap">
        <table class="data-table" id="purchasesTable">
            <thead>
                <tr>
                    <th>#</th>
                    <th>Proveedor</th>
                    <th>Producto</th>
                    <th style="text-align:right;">Cantidad</th>
                    <th>Fecha</th>
                    <th style="text-align:right;">Monto</th>
                    <th>Acciones</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($compras as $row): ?>
                <tr>
                    <td class="td-muted">#<?= htmlspecialchars($row['id_compra']) ?></td>
                    <td class="td-primary"><?= htmlspecialchars($row['proveedor']) ?></td>
                    <td><?= htmlspecialchars($row['nombre_producto']) ?></td>
                    <td class="num"><?= htmlspecialchars($row['cantidad_comprada']) ?></td>
                    <td><?= htmlspecialchars(appFormatDate($row['fecha_compra']), ENT_QUOTES, 'UTF-8') ?></td>
                    <td class="td-amount"><?= htmlspecialchars(appFormatCurrency((float)$row['monto_total']), ENT_QUOTES, 'UTF-8') ?></td>
                    <td>
                        <div class="td-actions">
                            <button class="btn-icon" title="Ver Detalles" onclick="openEditModal(<?= intval($row['id_compra']) ?>)">
                                <i class="fas fa-eye"></i>
                            </button>
                            <?php if ($is_admin): ?>
                            <a href="gestion_compras.php?return=<?= intval($row['id_compra']) ?>" class="btn-icon warn" title="Regresar Compra" onclick="return confirm('¿Regresar esta compra? El inventario será actualizado.');">
                                <i class="fas fa-undo"></i>
                            </a>
                            <a href="gestion_compras.php?delete=<?= intval($row['id_compra']) ?>" class="btn-icon danger" title="Eliminar" onclick="return confirm('¿Eliminar esta compra definitivamente?');">
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
        <i class="fas fa-truck"></i>
        <p>No se encontraron compras registradas.</p>
    </div>
    <?php endif; ?>
    <div id="noPurchaseResults" style="display:none;">
        <div class="empty-state">
            <i class="fas fa-search"></i>
            <p>Sin resultados para "<span id="purchaseSearchTerm"></span>"</p>
        </div>
    </div>

    <?= renderPagination($total_compras, $page, $limit) ?>
</div>

<!-- Modal: registrar nueva compra -->
<div class="modal" id="createPurchaseModal">
    <div class="modal-content">
        <div class="modal-header">
            <h5>Registrar Nueva Compra</h5>
            <button class="modal-close close" onclick="closeModal('createPurchaseModal')">&times;</button>
        </div>
        <form action="gestion_compras.php" method="post" data-validate>
            <div class="modal-body">
                <div class="form-group">
                    <label class="form-label" for="id_proveedor">Proveedor</label>
                    <select class="form-control" id="id_proveedor" name="id_proveedor" required>
                        <?php foreach ($proveedores as $proveedor): ?>
                            <option value="<?= $proveedor['id_proveedor'] ?>"><?= htmlspecialchars($proveedor['nombre_proveedor']) ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="form-group">
                    <label class="form-label" for="nombre_producto">Nombre del Producto</label>
                    <input type="text" class="form-control" id="nombre_producto" name="nombre_producto" required>
                </div>
                <div class="form-group">
                    <label class="form-label" for="cantidad_comprada">Cantidad Comprada</label>
                    <input type="number" class="form-control" id="cantidad_comprada" name="cantidad_comprada" min="1" required>
                </div>
                <div class="form-group">
                    <label class="form-label" for="monto_total">Monto Total</label>
                    <input type="number" step="0.01" class="form-control" id="monto_total" name="monto_total" required>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn-secondary-master" onclick="closeModal('createPurchaseModal')">Cerrar</button>
                <button type="submit" name="submit_purchase" class="btn-primary-master">Registrar Compra</button>
            </div>
        </form>
    </div>
</div>

<!-- Modal: ver detalles de compra -->
<div class="modal" id="viewDetailsModal">
    <div class="modal-content">
        <div class="modal-header">
            <h5>Detalles de la Compra</h5>
            <button class="modal-close close" onclick="closeModal('viewDetailsModal')">&times;</button>
        </div>
        <form id="editPurchaseForm" action="update_purchase.php" method="post">
            <div class="modal-body" id="purchaseDetailsContent"></div>
            <?php if ($is_admin): ?>
            <div class="modal-footer">
                <button type="button" class="btn-secondary-master" onclick="closeModal('viewDetailsModal')">Cerrar</button>
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
    openModal('viewDetailsModal');
    fetch(`get_purchase_details.php?id_compra=${id}`)
        .then(function(r) { return r.json(); })
        .then(function(data) {
            var proveedoresOptions = '';
            <?php foreach ($proveedores as $proveedor): ?>
                proveedoresOptions += `<option value="<?= $proveedor['id_proveedor'] ?>" ${data.id_proveedor == "<?= $proveedor['id_proveedor'] ?>" ? 'selected' : ''}><?= htmlspecialchars($proveedor['nombre_proveedor']) ?></option>`;
            <?php endforeach; ?>

            var isAdmin = <?= json_encode($is_admin) ?>;

            document.getElementById('purchaseDetailsContent').innerHTML = `
                <input type="hidden" name="id_compra" value="${data.id_compra}">
                <div class="form-group">
                    <label class="form-label">Fecha de Compra</label>
                    <input type="text" class="form-control" name="fecha_compra" value="${data.fecha_compra}" readonly>
                </div>
                <div class="form-group">
                    <label class="form-label">Nombre del Producto</label>
                    <input type="text" class="form-control" name="nombre_producto" value="${data.nombre_producto}" ${isAdmin ? '' : 'readonly'}>
                </div>
                <div class="form-group">
                    <label class="form-label">Cantidad Comprada</label>
                    <input type="number" class="form-control" name="cantidad_comprada" value="${data.cantidad_comprada}" ${isAdmin ? '' : 'readonly'}>
                </div>
                <div class="form-group">
                    <label class="form-label">Monto Total</label>
                    <input type="number" step="0.01" class="form-control" name="monto_total" value="${data.monto_total}" ${isAdmin ? '' : 'readonly'}>
                </div>
                <div class="form-group">
                    <label class="form-label">Proveedor</label>
                    <select class="form-control" name="id_proveedor" ${isAdmin ? '' : 'disabled'}>${proveedoresOptions}</select>
                </div>`;
        })
        .catch(function(error) { console.error('Error:', error); });
}

var purchasesSearchInput = document.getElementById('tableSearchPurchases');
if (purchasesSearchInput) {
    purchasesSearchInput.addEventListener('input', function() {
        var term = this.value.toLowerCase().trim();
        var rows = document.querySelectorAll('#purchasesTable tbody tr');
        var visible = 0;

        rows.forEach(function(row) {
            var show = term === '' || row.textContent.toLowerCase().includes(term);
            row.style.display = show ? '' : 'none';
            if (show) visible++;
        });

        var noResults = document.getElementById('noPurchaseResults');
        if (noResults) {
            noResults.style.display = (term !== '' && rows.length > 0 && visible === 0) ? 'block' : 'none';
        }
        var searchTerm = document.getElementById('purchaseSearchTerm');
        if (searchTerm) {
            searchTerm.textContent = term;
        }
    });
}
</script>

<?php include('layout/footer_main.php'); ?>
