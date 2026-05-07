<?php
require_once 'config.php';
// Auth enforced automatically via auth_check.php (included by config.php)

$page_title  = 'Inicio';
$active_page = 'index.php';
$user_name = $_SESSION['nombre'] ?? 'Usuario';
$stock_threshold = max(0, (int)systemSetting('umbral_stock_bajo', 5));

$productos_stats = dbFetchOne($conn, "SELECT COUNT(*) AS total FROM Inventario");
$ventas_hoy_stats = dbFetchOne(
    $conn,
    "SELECT COUNT(*) AS total_ventas, COALESCE(SUM(monto_total), 0) AS monto_total FROM Ventas WHERE DATE(fecha_venta) = CURDATE()"
);
$alertas_stats = dbFetchOne(
    $conn,
    "SELECT COUNT(*) AS total FROM Inventario WHERE cantidad_disponible <= ?",
    "i",
    $stock_threshold
);

$total_productos = (int)($productos_stats['total'] ?? 0);
$ventas_hoy_total = (float)($ventas_hoy_stats['monto_total'] ?? 0);
$ventas_hoy_count = (int)($ventas_hoy_stats['total_ventas'] ?? 0);
$alertas_stock = (int)($alertas_stats['total'] ?? 0);

$quick_actions = [
    [
        'url' => 'gestion_inventario.php',
        'icon' => 'fas fa-boxes-stacked',
        'title' => 'Inventario',
        'subtitle' => 'Stock, entradas y salidas',
        'modifier' => 'inventory',
    ],
    [
        'url' => 'gestion_ventas.php',
        'icon' => 'fas fa-cart-shopping',
        'title' => 'Ventas',
        'subtitle' => 'Registra y consulta ventas',
        'modifier' => 'sales',
    ],
    [
        'url' => 'gestion_compras.php',
        'icon' => 'fas fa-truck-ramp-box',
        'title' => 'Compras',
        'subtitle' => 'Control de abastecimiento',
        'modifier' => 'purchases',
    ],
    [
        'url' => 'dashboard.php',
        'icon' => 'fas fa-chart-line',
        'title' => 'Dashboard',
        'subtitle' => 'Indicadores y tendencias',
        'modifier' => 'dashboard',
    ],
];

// Banner global configuration
$_bannerImagenRaw    = (string)systemSetting('banner_imagen', '');
$hasBannerCustom     = ($_bannerImagenRaw !== '' && file_exists(__DIR__ . '/' . $_bannerImagenRaw));
$currentBanner       = appResolveBannerPath();
$_bannerVer          = file_exists(__DIR__ . '/' . $currentBanner) ? (string)filemtime(__DIR__ . '/' . $currentBanner) : (string)time();
$currentBannerUrl    = $currentBanner . '?v=' . $_bannerVer;
$bannerOverlayColor  = normalizeHexColor((string)systemSetting('banner_overlay_color', '#0f172a'), '#0f172a');
$bannerOverlayOpacity = max(0.15, min(0.90, (float)systemSetting('banner_overlay_opacidad', 0.56)));
$bannerTextPrimary   = normalizeHexColor((string)systemSetting('banner_texto_primario', '#ffffff'), '#ffffff');
$bannerTextSecondary = normalizeHexColor((string)systemSetting('banner_texto_secundario', '#e2e8f0'), '#e2e8f0');
$_ovStrong = rgbaFromHex($bannerOverlayColor, $bannerOverlayOpacity);
$_ovMedium = rgbaFromHex($bannerOverlayColor, max(0.08, $bannerOverlayOpacity - 0.22));
$_ovSoft   = rgbaFromHex($bannerOverlayColor, max(0.04, $bannerOverlayOpacity - 0.40));
$welcomeOverlayGradient = "linear-gradient(108deg, {$_ovStrong} 0%, {$_ovMedium} 52%, {$_ovSoft} 100%)";

include('layout/sidebar.php');
?>

<!-- Topbar -->
<div class="topbar">
    <div class="topbar-title">
        <h1>Inicio</h1>
        <span class="date-badge"><i class="far fa-calendar-alt" style="margin-right:5px;"></i><?= htmlspecialchars(appFormatDate(time()), ENT_QUOTES, 'UTF-8') ?></span>
    </div>
    <div class="topbar-actions">
        <button class="btn-outline" id="sidebarToggle" style="display:none;"><i class="fas fa-bars"></i></button>
    </div>
</div>
<!-- Welcome Banner -->
<div class="card-master index-welcome-banner<?= $hasBannerCustom ? ' index-welcome-banner--photo' : '' ?>"<?= $hasBannerCustom ? ' style="--welcome-text:' . htmlspecialchars($bannerTextPrimary, ENT_QUOTES, 'UTF-8') . ';--welcome-muted:' . htmlspecialchars($bannerTextSecondary, ENT_QUOTES, 'UTF-8') . ';"' : '' ?>>
    <?php if ($hasBannerCustom): ?>
    <img class="page-banner-img" src="<?= htmlspecialchars($currentBannerUrl, ENT_QUOTES, 'UTF-8') ?>" alt="">
    <div class="index-welcome-overlay" style="background:<?= htmlspecialchars($welcomeOverlayGradient, ENT_QUOTES, 'UTF-8') ?>;"></div>
    <?php endif; ?>
    <div class="index-welcome-content">
        <span class="index-welcome-pill"><i class="fas fa-sparkles"></i> Panel operativo</span>
        <h2>Bienvenido, <?= htmlspecialchars($user_name, ENT_HTML5, 'UTF-8') ?></h2>
        <p class="index-welcome-copy">
            Gestiona tus módulos de inventario, ventas y compras desde un mismo lugar con acceso rápido a las tareas clave del día.
        </p>
        <div class="index-welcome-alert">
            <i class="fas fa-triangle-exclamation"></i>
            <span>Hoy tienes <strong><?= $alertas_stock ?></strong> alertas de stock pendientes.</span>
        </div>
    </div>
    <div class="index-welcome-visual">
        <i class="fas fa-boxes"></i>
    </div>
</div>

<!-- Mini KPIs -->
<div class="index-kpi-grid">
    <div class="index-kpi-card">
        <div class="index-kpi-icon products"><i class="fas fa-boxes-stacked"></i></div>
        <div class="index-kpi-value"><?= $total_productos ?></div>
        <div class="index-kpi-label">Total Productos</div>
    </div>
    <div class="index-kpi-card">
        <div class="index-kpi-icon sales"><i class="fas fa-sack-dollar"></i></div>
        <div class="index-kpi-value"><?= htmlspecialchars(appFormatCurrency($ventas_hoy_total), ENT_QUOTES, 'UTF-8') ?></div>
        <div class="index-kpi-label">Ventas del Día · <?= $ventas_hoy_count ?> transacciones</div>
    </div>
    <div class="index-kpi-card">
        <div class="index-kpi-icon alerts"><i class="fas fa-triangle-exclamation"></i></div>
        <div class="index-kpi-value"><?= $alertas_stock ?></div>
        <div class="index-kpi-label">Alertas de Stock (umbral <?= $stock_threshold ?>)</div>
    </div>
</div>

<!-- Quick Actions -->
<div class="card-master index-quick-actions-card">
    <div class="card-header-master">
        <h3><i class="fas fa-bolt" style="color:var(--accent-violet);"></i>Accesos rápidos</h3>
        <span class="text-muted-inline">Atajos de operación diaria</span>
    </div>
    <div class="index-quick-actions-grid">
        <?php foreach ($quick_actions as $action): ?>
        <a href="<?= htmlspecialchars($action['url'], ENT_QUOTES, 'UTF-8') ?>" class="index-quick-action index-quick-action--<?= htmlspecialchars($action['modifier'], ENT_QUOTES, 'UTF-8') ?>">
            <span class="index-quick-icon"><i class="<?= htmlspecialchars($action['icon'], ENT_QUOTES, 'UTF-8') ?>"></i></span>
            <span class="index-quick-title"><?= htmlspecialchars($action['title'], ENT_QUOTES, 'UTF-8') ?></span>
            <span class="index-quick-subtitle"><?= htmlspecialchars($action['subtitle'], ENT_QUOTES, 'UTF-8') ?></span>
        </a>
        <?php endforeach; ?>
    </div>
</div>

<?php include('layout/footer_main.php'); ?>
