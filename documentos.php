<?php
require_once 'config.php';
$page_title  = 'Documentos';
$active_page = 'documentos.php';

requireAnyRole(['Administrador', 'Empleado']);

$user_role         = $_SESSION['user_role'] ?? '';
$can_add_documents = ($user_role === 'Administrador');
$current_user      = (int)$_SESSION['user_id'];

$conn->query("SET @current_user = " . $current_user);
$conn->query("SET @current_ip = '" . $conn->real_escape_string($_SERVER['REMOTE_ADDR']) . "'");

require_once __DIR__ . '/includes/documentos_actions.php';

$documentos = dbFetchAll($conn,
    "SELECT d.*, u.nombre AS usuario_nombre FROM Documentos d JOIN Usuarios u ON d.usuario_subio = u.id_usuario ORDER BY fecha_subida DESC"
);

$mensaje = '';
if (isset($_SESSION['mensaje'])) {
    $mensaje = $_SESSION['mensaje'];
    unset($_SESSION['mensaje']);
}

include('layout/sidebar.php');
$print_generated_at = appFormatDateTime(time());
?>

<!-- Page Banner -->
<div class="page-banner">
    <div class="page-banner-content">
        <h1>Documentos</h1>
        <div class="page-banner-breadcrumb">
            <a href="dashboard.php">Inicio</a>
            <span class="sep">•</span>
            <span>Documentos</span>
        </div>
    </div>
    <img src="assets/images/breadcrumb/inventario_productos_banner.svg" alt="Banner de inventario de productos" class="page-banner-img">
</div>
<div class="module-actions-row">
    <?php if ($can_add_documents): ?>
    <button class="btn-primary-master" onclick="openModal('createDocumentModal')">
        <i class="fas fa-upload"></i> Subir Documento
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
        <p>Reporte de documentos</p>
        <span>Generado: <?= htmlspecialchars($print_generated_at, ENT_QUOTES, 'UTF-8') ?></span>
    </div>
</div>

<?php if ($mensaje): ?>
<div class="alert-master info"><i class="fas fa-info-circle"></i> <?= $mensaje ?></div>
<?php endif; ?>

<!-- Tabla de documentos -->
<div class="card-master">
    <div class="card-header-master">
        <h3><i class="fas fa-file-alt icon-cyan"></i>Gestión Documental</h3>
        <div class="table-search-wrap no-icon">
            <input type="text" id="searchInput" class="table-search-input" placeholder="Buscar documentos..." onkeyup="filterDocuments()">
        </div>
    </div>

    <?php if (!empty($documentos)): ?>
    <div class="table-wrap">
        <table class="data-table" id="documentsTable">
            <thead>
                <tr>
                    <th>#</th>
                    <th>Tipo</th>
                    <th>Descripción</th>
                    <th>Versión</th>
                    <th>Subido por</th>
                    <th>Archivo</th>
                    <th>Fecha</th>
                    <th>Acciones</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach($documentos as $doc): ?>
                <tr>
                    <td class="td-muted">#<?= htmlspecialchars($doc['id_documento']) ?></td>
                    <td><span class="badge-pill badge-info"><?= htmlspecialchars($doc['tipo_documento']) ?></span></td>
                    <td class="td-primary"><?= htmlspecialchars($doc['descripcion']) ?></td>
                    <td><?= htmlspecialchars($doc['version']) ?></td>
                    <td><?= htmlspecialchars($doc['usuario_nombre']) ?></td>
                    <td><a href="<?= htmlspecialchars($doc['ruta_archivo']) ?>" target="_blank" download class="link-cyan"><i class="fas fa-download" style="margin-right:4px;"></i><?= htmlspecialchars($doc['nombre_archivo']) ?></a></td>
                    <td><?= htmlspecialchars(date('d M Y', strtotime($doc['fecha_subida']))) ?></td>
                    <td>
                        <div class="td-actions">
                            <button class="btn-icon" title="Historial" onclick="openModal('viewHistoryModal', <?= (int)$doc['id_documento'] ?>)">
                                <i class="fas fa-history"></i>
                            </button>
                            <button class="btn-icon warn" title="Adjuntar Registro" onclick="openModal('attachRecordModal', <?= (int)$doc['id_documento'] ?>)">
                                <i class="fas fa-paperclip"></i>
                            </button>
                            <button class="btn-icon" title="Editar" onclick="openEditModal(<?= (int)$doc['id_documento'] ?>, '<?= htmlspecialchars($doc['tipo_documento'], ENT_QUOTES) ?>', '<?= htmlspecialchars($doc['descripcion'], ENT_QUOTES) ?>', '<?= htmlspecialchars($doc['version'], ENT_QUOTES) ?>')">
                                <i class="fas fa-pencil-alt"></i>
                            </button>
                            <?php if ($can_add_documents): ?>
                            <a href="documentos.php?delete=<?= (int)$doc['id_documento'] ?>" class="btn-icon danger" title="Eliminar" onclick="return confirm('¿Eliminar este documento?');">
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
        <i class="fas fa-file-alt"></i>
        <p>No hay documentos subidos aún.</p>
    </div>
    <?php endif; ?>
</div>

<?php if ($can_add_documents): ?>
<!-- Modal: crear documento -->
<div class="modal" id="createDocumentModal">
    <div class="modal-content">
        <div class="modal-header">
            <h5>Subir Nuevo Documento</h5>
            <button class="modal-close close" onclick="closeModal('createDocumentModal')">&times;</button>
        </div>
        <form action="documentos.php" method="post" enctype="multipart/form-data">
            <div class="modal-body">
                <div class="form-group">
                    <label class="form-label" for="tipo_documento">Tipo de Documento</label>
                    <input type="text" class="form-control" id="tipo_documento" name="tipo_documento" required>
                </div>
                <div class="form-group">
                    <label class="form-label" for="descripcion">Descripción</label>
                    <textarea class="form-control" id="descripcion" name="descripcion" required></textarea>
                </div>
                <div class="form-group">
                    <label class="form-label" for="version">Versión</label>
                    <input type="text" class="form-control" id="version" name="version" required>
                </div>
                <div class="form-group">
                    <label class="form-label" for="documento">Archivo (PDF, DOCX, XLSX, TXT)</label>
                    <input type="file" class="form-control" id="documento" name="documento" accept=".pdf,.docx,.xlsx,.txt" required>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn-secondary-master" onclick="closeModal('createDocumentModal')">Cerrar</button>
                <button type="submit" class="btn-primary-master" name="subir_documento">Subir Documento</button>
            </div>
        </form>
    </div>
</div>
<?php endif; ?>

<!-- Modal: historial de cambios -->
<div class="modal" id="viewHistoryModal">
    <div class="modal-content">
        <div class="modal-header">
            <h5>Historial de Cambios</h5>
            <button class="modal-close close" onclick="closeModal('viewHistoryModal')">&times;</button>
        </div>
        <div class="modal-body" id="historyContent">
            <div class="empty-state"><i class="fas fa-spinner fa-spin"></i><p>Cargando...</p></div>
        </div>
        <div class="modal-footer">
            <button type="button" class="btn-secondary-master" onclick="closeModal('viewHistoryModal')">Cerrar</button>
        </div>
    </div>
</div>

<!-- Modal: editar documento -->
<div class="modal" id="editDocumentModal">
    <div class="modal-content">
        <div class="modal-header">
            <h5>Editar Documento</h5>
            <button class="modal-close close" onclick="closeModal('editDocumentModal')">&times;</button>
        </div>
        <form action="documentos.php" method="post">
            <input type="hidden" name="doc_id" id="edit_doc_id">
            <div class="modal-body">
                <div class="form-group">
                    <label class="form-label" for="edit_tipo_documento">Tipo de Documento</label>
                    <input type="text" class="form-control" id="edit_tipo_documento" name="tipo_documento" required>
                </div>
                <div class="form-group">
                    <label class="form-label" for="edit_descripcion">Descripción</label>
                    <textarea class="form-control" id="edit_descripcion" name="descripcion" required></textarea>
                </div>
                <div class="form-group">
                    <label class="form-label" for="edit_version">Versión</label>
                    <input type="text" class="form-control" id="edit_version" name="version" required>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn-secondary-master" onclick="closeModal('editDocumentModal')">Cerrar</button>
                <button type="submit" class="btn-primary-master" name="editar_documento">Guardar Cambios</button>
            </div>
        </form>
    </div>
</div>

<!-- Modal: adjuntar registro -->
<div class="modal" id="attachRecordModal">
    <div class="modal-content">
        <div class="modal-header">
            <h5>Adjuntar Registro a Documento</h5>
            <button class="modal-close close" onclick="closeModal('attachRecordModal')">&times;</button>
        </div>
        <form action="documentos.php" method="post">
            <input type="hidden" name="doc_id" id="doc_id">
            <div class="modal-body">
                <div class="form-group">
                    <label class="form-label" for="tabla">Seleccionar Tabla</label>
                    <select class="form-control" id="tabla" name="tabla">
                        <option value="Inventario">Inventario</option>
                        <option value="Ventas">Ventas</option>
                        <option value="Compras">Compras</option>
                    </select>
                </div>
                <div class="form-group">
                    <label class="form-label" for="registro_id">ID del Registro</label>
                    <input type="number" class="form-control" id="registro_id" name="registro_id" required>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn-secondary-master" onclick="closeModal('attachRecordModal')">Cerrar</button>
                <button type="submit" class="btn-primary-master" name="adjuntar_registro">Adjuntar Registro</button>
            </div>
        </form>
    </div>
</div>

<script>
function openModal(modalId, docId) {
    var modal = document.getElementById(modalId);
    if (modal) {
        modal.style.display = 'flex';
        if (docId) {
            var docIdField = document.getElementById('doc_id');
            if (docIdField) docIdField.value = docId;
            if (modalId === 'viewHistoryModal') loadHistory(docId);
        }
    }
}
function closeModal(modalId) {
    var modal = document.getElementById(modalId);
    if (modal) modal.style.display = 'none';
}
document.querySelectorAll('.modal').forEach(function(m) {
    m.addEventListener('click', function(e) { if (e.target === m) closeModal(m.id); });
});
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') document.querySelectorAll('.modal').forEach(function(m) {
        if (m.style.display !== 'none') closeModal(m.id);
    });
});

function filterDocuments() {
    var filter = document.getElementById('searchInput').value.toUpperCase();
    var rows   = document.querySelectorAll('#documentsTable tbody tr');
    rows.forEach(function(row) {
        var match = Array.from(row.cells).some(function(td) { return td.textContent.toUpperCase().includes(filter); });
        row.style.display = match ? '' : 'none';
    });
}

function openEditModal(docId, tipoDocumento, descripcion, version) {
    document.getElementById('edit_doc_id').value = docId;
    document.getElementById('edit_tipo_documento').value = tipoDocumento;
    document.getElementById('edit_descripcion').value = descripcion;
    document.getElementById('edit_version').value = version;
    openModal('editDocumentModal');
}

function loadHistory(docId) {
    document.getElementById('historyContent').innerHTML = '<div class="empty-state"><i class="fas fa-spinner fa-spin"></i><p>Cargando...</p></div>';
    fetch(`historial_cambios.php?doc_id=${docId}`)
        .then(function(r) { return r.json(); })
        .then(function(data) {
            var el = document.getElementById('historyContent');
            if (data.length > 0) {
                var html = '<ul style="list-style:none;display:flex;flex-direction:column;gap:8px;">';
                data.forEach(function(e) {
                    html += `<li style="padding:10px 12px;background:var(--bg-card-alt);border-radius:8px;font-size:13px;color:var(--text-secondary);">
                        <strong style="color:var(--accent-cyan);">${e.tipo_accion}</strong> por ${e.usuario_modifico} — ${e.fecha_modificacion}
                        <div style="margin-top:4px;color:var(--text-muted);">${e.descripcion_cambio}</div>
                    </li>`;
                });
                html += '</ul>';
                el.innerHTML = html;
            } else {
                el.innerHTML = '<div class="empty-state"><i class="fas fa-history"></i><p>No hay cambios registrados para este documento.</p></div>';
            }
        })
        .catch(function() {
            document.getElementById('historyContent').innerHTML = '<div class="empty-state"><i class="fas fa-exclamation-circle"></i><p>Error al cargar el historial.</p></div>';
        });
}
</script>

<?php include('layout/footer_main.php'); ?>
