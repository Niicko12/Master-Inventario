<?php
require_once 'config.php';
requireAuth();

$page_title  = 'Dashboard';
$active_page = 'dashboard.php';

$user_role   = $_SESSION['user_role'] ?? '';
$user_nombre = $_SESSION['nombre'] ?? 'Usuario';

require_once __DIR__ . '/functions/dashboard_data.php';
extract(getDashboardData($conn));
$today_ts = time();
$weekday_names_es = [
    1 => 'lunes',
    2 => 'martes',
    3 => 'miércoles',
    4 => 'jueves',
    5 => 'viernes',
    6 => 'sábado',
    7 => 'domingo',
];
$month_names_es = [
    1  => 'enero',
    2  => 'febrero',
    3  => 'marzo',
    4  => 'abril',
    5  => 'mayo',
    6  => 'junio',
    7  => 'julio',
    8  => 'agosto',
    9  => 'septiembre',
    10 => 'octubre',
    11 => 'noviembre',
    12 => 'diciembre',
];
$dashboard_date_label = ucfirst(
    $weekday_names_es[(int)date('N', $today_ts)] . ', ' .
    date('d', $today_ts) . ' de ' .
    $month_names_es[(int)date('n', $today_ts)] . ' de ' .
    date('Y', $today_ts)
);


include 'layout/sidebar.php';
?>

<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

<div class="profile-welcome card-master dashboard-hero">
    <div class="dashboard-hero-content">
        <div class="dashboard-hero-user">
        <?php $dash_foto = $_SESSION['foto_perfil'] ?? ''; ?>
        <div class="user-avatar" style="width:50px; height:50px; font-size:18px; font-weight:700; background:var(--lightprimary); color:var(--primary); overflow:hidden; padding:0;">
            <?php if (!empty($dash_foto) && file_exists(__DIR__ . '/' . $dash_foto)): ?>
                <img src="<?= htmlspecialchars($dash_foto) ?>?v=<?= $_SESSION['foto_v'] ?? 1 ?>" alt="Foto" style="width:100%;height:100%;object-fit:cover;border-radius:inherit;">
            <?php else: ?>
                <?= strtoupper(mb_substr($user_nombre, 0, 1)) ?>
            <?php endif; ?>
        </div>
        <div>
            <h2 style="font-size:18px; font-weight:700; color:var(--dark); margin-bottom:2px;">Bienvenido, Administrador</h2>
            <p style="font-size:13px; color:var(--text-muted); text-transform:capitalize;">
                <?= htmlspecialchars($dashboard_date_label, ENT_QUOTES, 'UTF-8') ?>
            </p>
        </div>
        </div>
    </div>
    <div class="page-header-right" style="z-index:1;">

    </div>
    <img src="assets/images/breadcrumb/inventario_productos_banner.svg" alt="Banner de inventario de productos" class="page-banner-img dashboard-hero-img">
</div>

<div class="module-actions-row">
    <a href="gestion_ventas.php" class="btn-primary-master">
        <i class="fas fa-plus"></i> Nueva Venta
    </a>
</div>


<!-- Resumen por Módulo -->
<div class="table-card">
    <div class="chart-header">
        <h3>Resumen por Módulo</h3>
        <span class="chart-badge">Datos en tiempo real</span>
    </div>
    <div class="kpi-grid" style="margin-bottom:0;">
        <?php foreach ($module_cards as $module): ?>
            <?php if (!empty($module['admin']) && $user_role !== 'Administrador') continue; ?>
            <?php
                $valor_modulo = is_numeric($module['valor'])
                    ? number_format((float)$module['valor'], 0, '.', ',')
                    : (string)$module['valor'];
            ?>
            <a href="<?= htmlspecialchars($module['url'], ENT_QUOTES, 'UTF-8') ?>" class="kpi-card" style="text-decoration:none;color:inherit;padding:18px;">
                <div class="kpi-icon cyan" style="width:44px;height:44px;font-size:16px;margin-bottom:12px;">
                    <i class="<?= htmlspecialchars($module['icono'], ENT_QUOTES, 'UTF-8') ?>"></i>
                </div>
                <div class="kpi-value" style="font-size:24px;"><?= htmlspecialchars($valor_modulo, ENT_QUOTES, 'UTF-8') ?></div>
                <div class="kpi-label"><?= htmlspecialchars($module['nombre'], ENT_QUOTES, 'UTF-8') ?></div>
                <div class="kpi-sub"><?= htmlspecialchars($module['detalle'], ENT_QUOTES, 'UTF-8') ?></div>
            </a>
        <?php endforeach; ?>
    </div>
</div>

<!-- Stock alert banner -->
<?php if ($alertas_stock > 0): ?>
<div class="alert-banner">
    <i class="fas fa-triangle-exclamation"></i>
    <span><strong><?= $alertas_stock ?> producto(s)</strong> con stock bajo por umbral o agotado.
    <a href="gestion_inventario.php">Revisar inventario →</a></span>
</div>
<?php endif; ?>

<!-- KPI Grid -->
<div class="kpi-grid">
    <div class="kpi-card">
        <div class="kpi-icon pink"><i class="fas fa-dollar-sign"></i></div>
        <div class="kpi-value"><?= htmlspecialchars(appFormatCurrency((float)$ventas_mes['monto']), ENT_QUOTES, 'UTF-8') ?></div>
        <div class="kpi-label">Ventas este mes</div>
        <div class="kpi-sub"><?= (int)$ventas_mes['cnt'] ?> transacciones</div>
    </div>
    <div class="kpi-card">
        <div class="kpi-icon cyan"><i class="fas fa-truck"></i></div>
        <div class="kpi-value"><?= htmlspecialchars(appFormatCurrency((float)$compras_mes['monto']), ENT_QUOTES, 'UTF-8') ?></div>
        <div class="kpi-label">Compras este mes</div>
        <div class="kpi-sub"><?= (int)$compras_mes['cnt'] ?> registro(s)</div>
    </div>
    <div class="kpi-card">
        <div class="kpi-icon cyan"><i class="fas fa-boxes-stacked"></i></div>
        <div class="kpi-value"><?= $total_productos ?></div>
        <div class="kpi-label">Productos en inventario</div>
        <div class="kpi-sub"><?= $stock_normal ?> con stock normal</div>
    </div>
    <div class="kpi-card">
        <div class="kpi-icon warn"><i class="fas fa-triangle-exclamation"></i></div>
        <div class="kpi-value"><?= $alertas_stock ?></div>
        <div class="kpi-label">Alertas de stock</div>
        <div class="kpi-sub"><?= $sin_stock ?> sin stock · <?= $stock_bajo ?> bajo umbral</div>
    </div>
    <div class="kpi-card">
        <div class="kpi-icon green"><i class="fas fa-building"></i></div>
        <div class="kpi-value"><?= $total_proveedores ?></div>
        <div class="kpi-label">Proveedores activos</div>
        <div class="kpi-sub">Registrados en el sistema</div>
    </div>
    <div class="kpi-card">
        <div class="kpi-icon pink"><i class="fas fa-file-lines"></i></div>
        <div class="kpi-value"><?= (int)$total_documentos ?></div>
        <div class="kpi-label">Documentos cargados</div>
        <div class="kpi-sub"><?= (int)$documentos_mes ?> este mes</div>
    </div>
</div>

<!-- Charts Row 1: line + donut -->
<div class="charts-row charts-row-2col">
    <div class="chart-card">
        <div class="chart-header">
            <h3>Ventas — Últimos 30 Días</h3>
            <div class="chart-header-tools">
                <span class="chart-badge">Monto <?= htmlspecialchars(appCurrencySymbol(), ENT_QUOTES, 'UTF-8') ?></span>
                <select id="lineTypeSelector" class="chart-type-select" aria-label="Tipo de gráfica de ventas últimos 30 días">
                    <option value="line">Línea</option>
                    <option value="bar">Barras</option>
                    <option value="radar">Radar</option>
                </select>
            </div>
        </div>
        <div class="chart-canvas-wrap tall">
            <canvas id="lineChart"></canvas>
        </div>
    </div>
    <div class="chart-card">
        <div class="chart-header">
            <h3>Estado de Stock</h3>
            <div class="chart-header-tools">
                <select id="donutTypeSelector" class="chart-type-select" aria-label="Tipo de gráfica de estado de stock">
                    <option value="doughnut">Dona</option>
                    <option value="pie">Pastel</option>
                    <option value="polarArea">Polar</option>
                    <option value="bar">Barras</option>
                </select>
            </div>
        </div>
        <div class="chart-canvas-wrap donut">
            <canvas id="donutChart"></canvas>
        </div>
        <div class="donut-legend">
            <div class="donut-legend-item">
                <div class="legend-dot" style="background:#13deb9;"></div>
                <span>Stock normal</span>
                <span class="legend-value"><?= $stock_normal ?></span>
            </div>
            <div class="donut-legend-item">
                <div class="legend-dot" style="background:#f6b51e;"></div>
                <span>Stock bajo</span>
                <span class="legend-value"><?= $stock_bajo ?></span>
            </div>
            <div class="donut-legend-item">
                <div class="legend-dot" style="background:#ef4444;"></div>
                <span>Sin stock</span>
                <span class="legend-value"><?= $sin_stock ?></span>
            </div>
        </div>
    </div>
</div>

<!-- Charts Row 2: bar + comparison -->
<div class="charts-row charts-row-equal">
    <div class="chart-card">
        <div class="chart-header">
            <h3>Top 5 Productos Vendidos</h3>
            <div class="chart-header-tools">
                <span class="chart-badge" style="background:rgba(73,190,255,0.12);color:#49beff;">Unidades</span>
                <select id="barTypeSelector" class="chart-type-select" aria-label="Tipo de gráfica de top productos">
                    <option value="bar">Barras</option>
                    <option value="line">Línea</option>
                    <option value="pie">Pastel</option>
                    <option value="doughnut">Dona</option>
                    <option value="polarArea">Polar</option>
                    <option value="radar">Radar</option>
                </select>
            </div>
        </div>
        <div class="chart-canvas-wrap" style="min-height:220px;">
            <?php if (empty($bar_labels)): ?>
            <div class="empty-state">
                <i class="fas fa-chart-bar"></i>Sin datos de ventas aún
            </div>
            <?php else: ?>
            <canvas id="barChart"></canvas>
            <?php endif; ?>
        </div>
    </div>
    <div class="chart-card">
        <div class="chart-header">
            <h3>Ventas vs Compras (6 meses)</h3>
            <div class="chart-header-tools">
                <select id="compTypeSelector" class="chart-type-select" aria-label="Tipo de gráfica comparativa ventas vs compras">
                    <option value="line">Línea</option>
                    <option value="bar">Barras</option>
                    <option value="radar">Radar</option>
                </select>
            </div>
        </div>
        <div class="chart-canvas-wrap" style="min-height:220px;">
            <?php if (empty($vc_labels)): ?>
            <div class="empty-state">
                <i class="fas fa-chart-line"></i>Sin datos históricos aún
            </div>
            <?php else: ?>
            <canvas id="comparisonChart"></canvas>
            <?php endif; ?>
        </div>
    </div>
</div>

<!-- Recent Sales Table -->
<div class="table-card">
    <div class="chart-header">
        <h3>Ventas Recientes</h3>
        <a href="gestion_ventas.php" class="link-all">Ver todas <i class="fas fa-arrow-right"></i></a>
    </div>
    <?php if (empty($recientes)): ?>
    <div class="empty-state">
        <i class="fas fa-receipt"></i>No hay ventas registradas.
    </div>
    <?php else: ?>
    <div class="table-responsive">
    <table class="data-table">
        <thead>
            <tr>
                <th>#</th>
                <th>Cliente</th>
                <th>Fecha</th>
                <th>Monto</th>
                <th>Estado</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($recientes as $v): ?>
            <tr>
                <td style="color:var(--text-muted);font-size:12px;">#<?= (int)$v['id_venta'] ?></td>
                <td style="font-weight:600;color:var(--dark);"><?= htmlspecialchars($v['cliente'], ENT_QUOTES, 'UTF-8') ?></td>
                <td><?= htmlspecialchars(appFormatDateTime($v['fecha_venta']), ENT_QUOTES, 'UTF-8') ?></td>
                <td class="amount-cell"><?= htmlspecialchars(appFormatCurrency((float)$v['monto_total']), ENT_QUOTES, 'UTF-8') ?></td>
                <td><span class="badge-pill">Completada</span></td>
            </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
    </div>
    <?php endif; ?>
</div>

<!-- Activity Feed -->
<div class="table-card">
    <div class="chart-header">
        <h3>Actividad Reciente de Módulos</h3>
    </div>
    <?php if (empty($actividad_reciente)): ?>
    <div class="empty-state">
        <i class="fas fa-clock-rotate-left"></i>No hay actividad reciente para mostrar.
    </div>
    <?php else: ?>
    <div class="table-responsive">
    <table class="data-table">
        <thead>
            <tr>
                <th>Módulo</th>
                <th>Evento</th>
                <th>Fecha</th>
                <th></th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($actividad_reciente as $item): ?>
            <?php $fecha_item = strtotime((string)$item['fecha']); ?>
            <tr>
                <td>
                    <span class="badge-pill badge-info">
                        <i class="<?= htmlspecialchars($item['icono'], ENT_QUOTES, 'UTF-8') ?>" style="margin-right:6px;"></i>
                        <?= htmlspecialchars($item['modulo'], ENT_QUOTES, 'UTF-8') ?>
                    </span>
                </td>
                <td>
                    <div style="font-weight:600;color:var(--dark);"><?= htmlspecialchars($item['titulo'], ENT_QUOTES, 'UTF-8') ?></div>
                    <div style="font-size:12px;color:var(--text-muted);margin-top:2px;"><?= htmlspecialchars($item['detalle'], ENT_QUOTES, 'UTF-8') ?></div>
                </td>
                <td><?= $fecha_item ? htmlspecialchars(appFormatDateTime($fecha_item), ENT_QUOTES, 'UTF-8') : '-' ?></td>
                <td style="text-align:right;">
                    <a href="<?= htmlspecialchars($item['url'], ENT_QUOTES, 'UTF-8') ?>" class="link-all">Abrir <i class="fas fa-arrow-right"></i></a>
                </td>
            </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
    </div>
    <?php endif; ?>
</div>

<script>
const primary   = '#5d87ff';
const secondary = '#49beff';
const success   = '#13deb9';
const warning   = '#f6b51e';
const errColor  = '#ef4444';
const infoColor = '#8754ec';

const primaryT   = 'rgba(93,135,255,0.15)';
const secondaryT = 'rgba(73,190,255,0.14)';
const currencySymbol = <?= json_encode(appCurrencySymbol()) ?>;
const currencyPosition = <?= json_encode(systemSetting('posicion_moneda', 'antes')) ?>;

function formatCurrencyJs(value) {
    var formatted = Number(value || 0).toLocaleString('es', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    return currencyPosition === 'despues'
        ? formatted + ' ' + currencySymbol
        : currencySymbol + ' ' + formatted;
}

const isDark = () => document.documentElement.classList.contains('dark');
const getGridColor = () => isDark() ? 'rgba(51,63,85,0.8)' : 'rgba(222,229,239,0.8)';
const getTextColor = () => isDark() ? '#7c8fac' : '#5a6a85';
const getTooltipBg = () => isDark() ? '#1c2536' : '#ffffff';
const getTooltipTitle = () => isDark() ? '#ffffff' : '#1c2536';
const getTooltipBorder = () => isDark() ? '#333f55' : 'rgba(93,135,255,0.2)';
const getDonutBorder = () => isDark() ? '#1c2536' : '#ffffff';
const chartTypeStoragePrefix = 'dashboard_chart_type_';

const lineLabels = <?= json_encode($line_labels) ?>;
const lineData   = <?= json_encode($line_data) ?>;
const barLabels  = <?= json_encode($bar_labels) ?>;
const barData    = <?= json_encode($bar_data) ?>;
const vcLabels   = <?= json_encode($vc_labels) ?>;
const vcVentas   = <?= json_encode($vc_ventas) ?>;
const vcCompras  = <?= json_encode($vc_compras) ?>;

const stockNorm  = <?= (int)$stock_normal ?>;
const stockBajo  = <?= (int)$stock_bajo ?>;
const sinStock   = <?= (int)$sin_stock ?>;

let lineChartInst = null;
let donutChartInst = null;
let barChartInst = null;
let compChartInst = null;

function syncChartDefaults() {
    Chart.defaults.color = getTextColor();
    Chart.defaults.font.family = "'DM Sans', 'Inter', sans-serif";
    Chart.defaults.font.size = 12;
}

function tooltipCfg(extra) {
    return Object.assign({
        backgroundColor: getTooltipBg(),
        borderColor: getTooltipBorder(),
        borderWidth: 1,
        titleColor: getTooltipTitle(),
        bodyColor: getTextColor()
    }, extra || {});
}

function getCircularColors(count) {
    const palette = [primary, secondary, success, warning, errColor, infoColor, '#22c55e', '#f97316'];
    return Array.from({ length: count }, (_, i) => palette[i % palette.length]);
}

function getSavedChartType(key, fallback) {
    try {
        return localStorage.getItem(chartTypeStoragePrefix + key) || fallback;
    } catch (e) {
        return fallback;
    }
}

function saveChartType(key, value) {
    try {
        localStorage.setItem(chartTypeStoragePrefix + key, value);
    } catch (e) {}
}

function buildCartesianScales(isMoney) {
    const xTicks = { color: getTextColor(), maxRotation: 0 };
    const yTicks = { color: getTextColor() };
    if (isMoney) {
        yTicks.callback = function(v) { return formatCurrencyJs(v); };
    } else {
        yTicks.precision = 0;
    }
    return {
        x: {
            grid: { color: getGridColor(), drawBorder: false },
            ticks: xTicks
        },
        y: {
            grid: { color: getGridColor(), drawBorder: false },
            ticks: yTicks,
            beginAtZero: true
        }
    };
}

function buildRadarScales(isMoney) {
    const radarTicks = { color: getTextColor(), backdropColor: 'transparent' };
    if (isMoney) {
        radarTicks.callback = function(v) { return formatCurrencyJs(v); };
    } else {
        radarTicks.precision = 0;
    }
    return {
        r: {
            grid: { color: getGridColor() },
            angleLines: { color: getGridColor() },
            pointLabels: { color: getTextColor() },
            ticks: radarTicks,
            beginAtZero: true
        }
    };
}

function renderLineChart(type) {
    const safeType = ['line', 'bar', 'radar'].includes(type) ? type : 'line';
    const canvas = document.getElementById('lineChart');
    if (lineChartInst) { lineChartInst.destroy(); lineChartInst = null; }
    if (!canvas) return;

    if (!lineLabels.length) {
        canvas.parentElement.innerHTML = '<div class="empty-state"><i class="fas fa-chart-line"></i>Sin ventas en los últimos 30 días</div>';
        return;
    }

    const ctx = canvas.getContext('2d');
    let dataset = {};
    if (safeType === 'bar') {
        dataset = {
            label: 'Ventas (' + currencySymbol + ')',
            data: lineData,
            backgroundColor: primaryT,
            borderColor: primary,
            borderWidth: 1.5,
            borderRadius: 6
        };
    } else if (safeType === 'radar') {
        dataset = {
            label: 'Ventas (' + currencySymbol + ')',
            data: lineData,
            borderColor: primary,
            backgroundColor: primaryT,
            borderWidth: 2,
            pointBackgroundColor: primary,
            pointBorderColor: '#fff',
            pointBorderWidth: 2,
            pointRadius: 3,
            fill: true
        };
    } else {
        const gradient = ctx.createLinearGradient(0, 0, 0, 280);
        gradient.addColorStop(0, 'rgba(93,135,255,0.25)');
        gradient.addColorStop(1, 'rgba(93,135,255,0)');
        dataset = {
            label: 'Ventas (' + currencySymbol + ')',
            data: lineData,
            borderColor: primary,
            backgroundColor: gradient,
            borderWidth: 2.5,
            pointBackgroundColor: primary,
            pointBorderColor: '#fff',
            pointBorderWidth: 2,
            pointRadius: 4,
            pointHoverRadius: 6,
            tension: 0.4,
            fill: true
        };
    }

    lineChartInst = new Chart(ctx, {
        type: safeType,
        data: { labels: lineLabels, datasets: [dataset] },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false },
                tooltip: {
                    ...tooltipCfg(),
                    callbacks: {
                        label: function(ctx) {
                            return ' ' + formatCurrencyJs(ctx.parsed.y ?? ctx.parsed.r ?? 0);
                        }
                    }
                }
            },
            scales: safeType === 'radar' ? buildRadarScales(true) : buildCartesianScales(true)
        }
    });
}

function renderStockChart(type) {
    const safeType = ['doughnut', 'pie', 'polarArea', 'bar'].includes(type) ? type : 'doughnut';
    const canvas = document.getElementById('donutChart');
    if (donutChartInst) { donutChartInst.destroy(); donutChartInst = null; }
    if (!canvas) return;

    const labels = ['Stock normal', 'Stock bajo', 'Sin stock'];
    const values = [stockNorm, stockBajo, sinStock];
    const total = stockNorm + stockBajo + sinStock;
    const ctx = canvas.getContext('2d');

    if (safeType === 'bar') {
        donutChartInst = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: labels,
                datasets: [{
                    label: 'Productos',
                    data: values,
                    backgroundColor: [success, warning, errColor],
                    borderRadius: 6
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false },
                    tooltip: tooltipCfg()
                },
                scales: buildCartesianScales(false)
            }
        });
        return;
    }

    donutChartInst = new Chart(ctx, {
        type: safeType,
        data: {
            labels: labels,
            datasets: [{
                data: total > 0 ? values : [1, 0, 0],
                backgroundColor: [success, warning, errColor],
                borderColor: getDonutBorder(),
                borderWidth: safeType === 'polarArea' ? 1 : 3,
                hoverBorderWidth: 0
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            cutout: safeType === 'doughnut' ? '72%' : undefined,
            plugins: {
                legend: { display: false },
                tooltip: tooltipCfg()
            }
        }
    });
}

function renderTopProductsChart(type) {
    const safeType = ['bar', 'line', 'pie', 'doughnut', 'polarArea', 'radar'].includes(type) ? type : 'bar';
    const canvas = document.getElementById('barChart');
    if (barChartInst) { barChartInst.destroy(); barChartInst = null; }
    if (!canvas || !barLabels.length) return;

    const ctx = canvas.getContext('2d');
    const colors = getCircularColors(barLabels.length);
    let dataset = {};
    let scales = undefined;
    let legendDisplay = false;
    let indexAxis = undefined;

    if (safeType === 'bar') {
        dataset = {
            label: 'Unidades vendidas',
            data: barData,
            backgroundColor: secondaryT,
            borderColor: secondary,
            borderWidth: 1.5,
            borderRadius: 6,
            borderSkipped: false
        };
        scales = buildCartesianScales(false);
        indexAxis = 'y';
    } else if (safeType === 'line') {
        dataset = {
            label: 'Unidades vendidas',
            data: barData,
            borderColor: secondary,
            backgroundColor: secondaryT,
            borderWidth: 2,
            pointBackgroundColor: secondary,
            pointBorderColor: '#fff',
            pointBorderWidth: 2,
            pointRadius: 4,
            tension: 0.3,
            fill: true
        };
        scales = buildCartesianScales(false);
    } else if (safeType === 'radar') {
        dataset = {
            label: 'Unidades vendidas',
            data: barData,
            borderColor: secondary,
            backgroundColor: secondaryT,
            borderWidth: 2,
            pointBackgroundColor: secondary,
            pointBorderColor: '#fff',
            pointBorderWidth: 2,
            pointRadius: 3,
            fill: true
        };
        scales = buildRadarScales(false);
    } else {
        dataset = {
            label: 'Unidades vendidas',
            data: barData,
            backgroundColor: colors,
            borderColor: getDonutBorder(),
            borderWidth: 2
        };
        legendDisplay = true;
    }

    barChartInst = new Chart(ctx, {
        type: safeType,
        data: { labels: barLabels, datasets: [dataset] },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            indexAxis: indexAxis,
            plugins: {
                legend: {
                    display: legendDisplay,
                    labels: {
                        color: getTextColor(),
                        usePointStyle: true,
                        pointStyle: 'circle',
                        boxWidth: 10
                    }
                },
                tooltip: tooltipCfg()
            },
            scales: scales
        }
    });
}

function renderComparisonChart(type) {
    const safeType = ['line', 'bar', 'radar'].includes(type) ? type : 'line';
    const canvas = document.getElementById('comparisonChart');
    if (compChartInst) { compChartInst.destroy(); compChartInst = null; }
    if (!canvas || !vcLabels.length) return;

    const ctx = canvas.getContext('2d');
    let datasets = [];
    let scales = undefined;

    if (safeType === 'bar') {
        datasets = [
            {
                label: 'Ventas',
                data: vcVentas,
                borderColor: primary,
                backgroundColor: primaryT,
                borderWidth: 1.5,
                borderRadius: 6
            },
            {
                label: 'Compras',
                data: vcCompras,
                borderColor: secondary,
                backgroundColor: secondaryT,
                borderWidth: 1.5,
                borderRadius: 6
            }
        ];
        scales = buildCartesianScales(true);
    } else if (safeType === 'radar') {
        datasets = [
            {
                label: 'Ventas',
                data: vcVentas,
                borderColor: primary,
                backgroundColor: primaryT,
                borderWidth: 2,
                pointBackgroundColor: primary,
                pointBorderColor: '#fff',
                pointBorderWidth: 2,
                pointRadius: 3,
                fill: true
            },
            {
                label: 'Compras',
                data: vcCompras,
                borderColor: secondary,
                backgroundColor: secondaryT,
                borderWidth: 2,
                pointBackgroundColor: secondary,
                pointBorderColor: '#fff',
                pointBorderWidth: 2,
                pointRadius: 3,
                fill: true
            }
        ];
        scales = buildRadarScales(true);
    } else {
        datasets = [
            {
                label: 'Ventas',
                data: vcVentas,
                borderColor: primary,
                backgroundColor: primaryT,
                borderWidth: 2,
                pointBackgroundColor: primary,
                pointBorderColor: '#fff',
                pointBorderWidth: 2,
                pointRadius: 4,
                tension: 0.3,
                fill: true
            },
            {
                label: 'Compras',
                data: vcCompras,
                borderColor: secondary,
                backgroundColor: secondaryT,
                borderWidth: 2,
                pointBackgroundColor: secondary,
                pointBorderColor: '#fff',
                pointBorderWidth: 2,
                pointRadius: 4,
                tension: 0.3,
                fill: true
            }
        ];
        scales = buildCartesianScales(true);
    }

    compChartInst = new Chart(ctx, {
        type: safeType,
        data: { labels: vcLabels, datasets: datasets },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'top',
                    align: 'end',
                    labels: {
                        boxWidth: 10,
                        boxHeight: 10,
                        usePointStyle: true,
                        pointStyle: 'circle',
                        padding: 16,
                        color: getTextColor(),
                        font: { size: 12 }
                    }
                },
                tooltip: {
                    ...tooltipCfg(),
                    callbacks: {
                        label: function(ctx) {
                            return ' ' + ctx.dataset.label + ': ' + formatCurrencyJs(ctx.parsed.y ?? ctx.parsed.r ?? 0);
                        }
                    }
                }
            },
            scales: scales
        }
    });
}

function initTypeSelector(selectorId, key, fallback, renderFn) {
    const selector = document.getElementById(selectorId);
    if (!selector) {
        renderFn(fallback);
        return;
    }

    const allowed = Array.prototype.map.call(selector.options, function(opt) { return opt.value; });
    const saved = getSavedChartType(key, fallback);
    const selected = allowed.includes(saved) ? saved : fallback;
    selector.value = selected;
    renderFn(selected);

    selector.addEventListener('change', function() {
        saveChartType(key, this.value);
        renderFn(this.value);
    });
}

syncChartDefaults();
initTypeSelector('lineTypeSelector', 'line', 'line', renderLineChart);
initTypeSelector('donutTypeSelector', 'stock', 'doughnut', renderStockChart);
initTypeSelector('barTypeSelector', 'top_products', 'bar', renderTopProductsChart);
initTypeSelector('compTypeSelector', 'comparison', 'line', renderComparisonChart);

(function() {
    const root = document.getElementById('html-root');
    if (!root) return;

    const observer = new MutationObserver(function(mutations) {
        mutations.forEach(function(m) {
            if (m.attributeName !== 'class') return;
            syncChartDefaults();

            const lineSelector = document.getElementById('lineTypeSelector');
            const stockSelector = document.getElementById('donutTypeSelector');
            const topSelector = document.getElementById('barTypeSelector');
            const compSelector = document.getElementById('compTypeSelector');

            renderLineChart(lineSelector ? lineSelector.value : 'line');
            renderStockChart(stockSelector ? stockSelector.value : 'doughnut');
            renderTopProductsChart(topSelector ? topSelector.value : 'bar');
            renderComparisonChart(compSelector ? compSelector.value : 'line');
        });
    });

    observer.observe(root, { attributes: true });
})();
</script>

<?php include 'layout/footer_main.php'; ?>
