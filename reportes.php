<?php
require_once 'config.php';
$page_title  = 'Reportes';
$active_page = 'reportes.php';

require('fpdf/fpdf.php');

if (!is_dir('reportes')) {
    mkdir('reportes', 0775, true);
}

$flash_message = '';
$flash_type    = 'info';
$instance_name = (string)systemSetting('nombre_instancia', 'Master Inventario');

if (isset($_GET['delete'])) {
    $report_id = intval($_GET['delete']);
    $row = dbFetchOne($conn, "SELECT ruta_archivo FROM Reportes WHERE id_reporte = ?", "i", $report_id);
    if ($row) {
        if (file_exists($row['ruta_archivo'])) unlink($row['ruta_archivo']);
        dbExecute($conn, "DELETE FROM Reportes WHERE id_reporte = ?", "i", $report_id);
        $flash_message = 'Reporte eliminado correctamente.';
        $flash_type    = 'success';
    } else {
        $flash_message = 'Error al eliminar el reporte.';
        $flash_type    = 'error';
    }
}

if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['table']) && isset($_POST['file_format']) && isset($_POST['report_name'])) {
    $allowed_tables = [
        'Compras', 'Detalle_Compras', 'Detalle_Ventas', 'Entradas_Inventario',
        'Inventario', 'Proveedores', 'Reportes', 'Salidas_Inventario',
        'Ubicaciones', 'Usuarios', 'Ventas',
    ];
    $table = $_POST['table'];
    if (!in_array($table, $allowed_tables, true)) {
        $flash_message = 'Tabla no permitida.';
        $flash_type    = 'error';
        $table = null;
    }

    $allowed_formats = ['csv', 'pdf'];
    $format = $_POST['file_format'];
    if (!in_array($format, $allowed_formats, true)) $format = null;

    $report_name = preg_replace('/[^a-zA-Z0-9_\-]/', '_', $_POST['report_name'] ?? 'reporte');

    if ($table && $format) {
        $file_path = "reportes/{$report_name}_" . date('Y-m-d_H-i-s') . ".{$format}";
        $result = $conn->query("SELECT * FROM `{$table}`");

        if ($result && $result->num_rows > 0) {
            if ($format === 'csv') {
                $file = fopen($file_path, 'w');
                if ($file) {
                    $headers = array_keys($result->fetch_assoc());
                    fputcsv($file, $headers);
                    $result->data_seek(0);
                    while ($row = $result->fetch_assoc()) fputcsv($file, $row);
                    fclose($file);
                    $stmt = $conn->prepare("INSERT INTO Reportes (nombre, tipo, fecha_generacion, ruta_archivo) VALUES (?, ?, NOW(), ?)");
                    $stmt->bind_param("sss", $report_name, $format, $file_path);
                    $stmt->execute();
                    $flash_message = 'Reporte CSV generado correctamente.';
                    $flash_type    = 'success';
                }
            } elseif ($format === 'pdf') {
                $pdf = new FPDF();
                $pdf->AddPage();
                $pdf->SetFont('Arial', 'B', 11);
                $pdf->Cell(0, 8, utf8_decode($instance_name), 0, 1, 'C');
                $pdf->SetFont('Arial', 'B', 14);
                $headers = array_keys($result->fetch_assoc());
                $cellWidth = 180 / count($headers);
                $pdf->Cell(0, 10, strtoupper($report_name), 0, 1, 'C');
                $pdf->SetFont('Arial', '', 9);
                $pdf->Cell(0, 6, utf8_decode('Generado: ' . appFormatDateTime(time())), 0, 1, 'C');
                $pdf->Ln(5);
                $pdf->SetFont('Arial', 'B', 10);
                $pdf->SetFillColor(200, 220, 255);
                foreach ($headers as $header) $pdf->Cell($cellWidth, 10, ucfirst($header), 1, 0, 'C', true);
                $pdf->Ln();
                $pdf->SetFont('Arial', '', 9);
                $pdf->SetFillColor(245, 245, 245);
                $fill = false;
                $result->data_seek(0);
                while ($row = $result->fetch_assoc()) {
                    foreach ($headers as $header) $pdf->Cell($cellWidth, 8, $row[$header], 1, 0, 'C', $fill);
                    $fill = !$fill;
                    $pdf->Ln();
                }
                $pdf->Output('F', $file_path);
                $stmt = $conn->prepare("INSERT INTO Reportes (nombre, tipo, fecha_generacion, ruta_archivo) VALUES (?, ?, NOW(), ?)");
                $stmt->bind_param("sss", $report_name, $format, $file_path);
                $stmt->execute();
                $flash_message = 'Reporte PDF generado correctamente.';
                $flash_type    = 'success';
            }
        } else {
            $flash_message = 'No hay datos disponibles en la tabla seleccionada.';
            $flash_type    = 'error';
        }
    }
}

$reports_result = $conn->query("SELECT * FROM Reportes ORDER BY fecha_generacion DESC");

include('layout/sidebar.php');
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
        <h1>Reportes</h1>
        <div class="page-banner-breadcrumb">
            <a href="dashboard.php">Inicio</a>
            <span class="sep">•</span>
            <span>Reportes</span>
        </div>
    </div>
    <img src="assets/images/breadcrumb/inventario_productos_banner.svg" alt="Banner de inventario de productos" class="page-banner-img">
</div>
<div class="module-actions-row">
    <button type="button" class="btn-primary-master" onclick="openModal('createReportModal')">
        <i class="fas fa-plus"></i> Generar Reporte
    </button>
</div>

<!-- Tabla de reportes generados -->
<div class="card-master">
    <div class="card-header-master">
        <h3><i class="fas fa-chart-bar icon-pink"></i>Reportes Generados</h3>
        <div class="table-search-wrap no-icon">
            <input type="text" id="tableSearchReports" class="table-search-input" placeholder="Buscar reporte...">
        </div>
    </div>

    <?php if ($reports_result && $reports_result->num_rows > 0): ?>
    <div class="table-wrap">
        <table class="data-table" id="reportsTable">
            <thead>
                <tr>
                    <th>Nombre</th>
                    <th>Tipo</th>
                    <th>Fecha de Generación</th>
                    <th>Acciones</th>
                </tr>
            </thead>
            <tbody>
                <?php while ($row = $reports_result->fetch_assoc()): ?>
                <tr>
                    <td class="td-primary"><?= htmlspecialchars($row['nombre']) ?></td>
                    <td>
                        <span class="badge-pill <?= strtolower($row['tipo']) === 'pdf' ? 'badge-danger' : 'badge-success' ?>">
                            <?= strtoupper($row['tipo']) ?>
                        </span>
                    </td>
                    <td><?= htmlspecialchars(appFormatDateTime($row['fecha_generacion']), ENT_QUOTES, 'UTF-8') ?></td>
                    <td>
                        <div class="td-actions">
                            <?php if (file_exists($row['ruta_archivo'])): ?>
                            <a href="<?= htmlspecialchars($row['ruta_archivo']) ?>" class="btn-icon" title="Descargar" download>
                                <i class="fas fa-download"></i>
                            </a>
                            <?php else: ?>
                            <span style="font-size:12px;color:var(--text-muted);">No disponible</span>
                            <?php endif; ?>
                            <a href="reportes.php?delete=<?= $row['id_reporte'] ?>" class="btn-icon danger" title="Eliminar" onclick="return confirm('¿Eliminar este reporte?');">
                                <i class="fas fa-trash-alt"></i>
                            </a>
                        </div>
                    </td>
                </tr>
                <?php endwhile; ?>
            </tbody>
        </table>
    </div>
    <?php else: ?>
    <div class="empty-state">
        <i class="fas fa-chart-bar"></i>
        <p>No se han generado reportes aún.</p>
    </div>
    <?php endif; ?>
    <div id="noReportsResults" style="display:none;">
        <div class="empty-state">
            <i class="fas fa-search"></i>
            <p>Sin resultados para "<span id="reportsSearchTerm"></span>"</p>
        </div>
    </div>
</div>

<!-- Modal: generar reporte -->
<div class="modal" id="createReportModal">
    <div class="modal-content">
        <div class="modal-header">
            <h5>Generar Nuevo Reporte</h5>
            <button class="modal-close close" onclick="closeModal('createReportModal')">&times;</button>
        </div>
        <form method="POST" action="reportes.php">
            <div class="modal-body">
                <div class="form-group">
                    <label class="form-label" for="table">Tabla de origen</label>
                    <select name="table" id="table" class="form-control" required>
                        <option value="">Seleccione una tabla</option>
                        <option value="Compras">Compras</option>
                        <option value="Detalle_Compras">Detalle_Compras</option>
                        <option value="Detalle_Ventas">Detalle_Ventas</option>
                        <option value="Entradas_Inventario">Entradas_Inventario</option>
                        <option value="Inventario">Inventario</option>
                        <option value="Proveedores">Proveedores</option>
                        <option value="Reportes">Reportes</option>
                        <option value="Salidas_Inventario">Salidas_Inventario</option>
                        <option value="Ubicaciones">Ubicaciones</option>
                        <option value="Usuarios">Usuarios</option>
                        <option value="Ventas">Ventas</option>
                    </select>
                </div>
                <div class="form-group">
                    <label class="form-label" for="file_format">Formato</label>
                    <select name="file_format" id="file_format" class="form-control" required>
                        <option value="csv">CSV</option>
                        <option value="pdf">PDF</option>
                    </select>
                </div>
                <div class="form-group">
                    <label class="form-label" for="report_name">Nombre del Reporte</label>
                    <input type="text" name="report_name" id="report_name" class="form-control" placeholder="Ej. inventario_enero_2025" required>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn-secondary-master" onclick="closeModal('createReportModal')">Cancelar</button>
                <button type="submit" class="btn-primary-master"><i class="fas fa-file-export" style="margin-right:6px;"></i>Generar</button>
            </div>
        </form>
    </div>
</div>

<script>
function openModal(id) {
    document.getElementById(id).style.display = 'flex';
}
function closeModal(id) {
    document.getElementById(id).style.display = 'none';
}
document.querySelectorAll('.modal').forEach(function(m) {
    m.addEventListener('click', function(e) { if (e.target === m) closeModal(m.id); });
});
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') document.querySelectorAll('.modal').forEach(function(m) {
        if (m.style.display !== 'none') closeModal(m.id);
    });
});

var reportsSearchInput = document.getElementById('tableSearchReports');
if (reportsSearchInput) {
    reportsSearchInput.addEventListener('input', function() {
        var term = this.value.toLowerCase().trim();
        var rows = document.querySelectorAll('#reportsTable tbody tr');
        var visible = 0;

        rows.forEach(function(row) {
            var show = term === '' || row.textContent.toLowerCase().includes(term);
            row.style.display = show ? '' : 'none';
            if (show) visible++;
        });

        var noResults = document.getElementById('noReportsResults');
        if (noResults) {
            noResults.style.display = (term !== '' && rows.length > 0 && visible === 0) ? 'block' : 'none';
        }
        var searchTerm = document.getElementById('reportsSearchTerm');
        if (searchTerm) {
            searchTerm.textContent = term;
        }
    });
}
</script>

<?php include('layout/footer_main.php'); ?>
