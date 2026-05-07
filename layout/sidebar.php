<?php
/**
 * layout/sidebar.php — Componente maestro de layout
 *
 * Variables esperadas antes de incluir este archivo:
 *   $page_title  (string) — título de la página para <title> y topbar
 *   $active_page (string) — nombre del archivo activo, ej. 'gestion_inventario.php'
 *
 * Emite: DOCTYPE, <html>, <head>, .layout, .sidebar, .body-wrapper, .topbar, .page-content
 * Cierra: layout/footer_main.php
 */

// Security headers — must fire before any output
if (!headers_sent()) {
    header("Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.jsdelivr.net https://cdnjs.cloudflare.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com https://cdn.jsdelivr.net https://cdnjs.cloudflare.com; font-src 'self' https://fonts.gstatic.com https://cdnjs.cloudflare.com; img-src 'self' data: https:; object-src 'none'; base-uri 'self';");
    header("X-Content-Type-Options: nosniff");
    header("Referrer-Policy: strict-origin-when-cross-origin");
}

$user_role   = $_SESSION['user_role'] ?? '';
$user_nombre = $_SESSION['nombre'] ?? 'Usuario';

// Cache foto_perfil + avatar_fit in session (refreshed once per session or after upload)
if ((!isset($_SESSION['foto_perfil']) || !isset($_SESSION['avatar_fit'])) && !empty($_SESSION['user_id'])) {
    $col_chk = $conn->query("SHOW COLUMNS FROM Usuarios LIKE 'foto_perfil'");
    $fit_chk = $conn->query("SHOW COLUMNS FROM Usuarios LIKE 'avatar_fit'");

    if ($col_chk && $col_chk->num_rows > 0) {
        if ($fit_chk && $fit_chk->num_rows > 0) {
            $fp_stmt = $conn->prepare("SELECT foto_perfil, avatar_fit FROM Usuarios WHERE id_usuario = ?");
            $fp_stmt->bind_param("i", $_SESSION['user_id']);
            $fp_stmt->execute();
            $fp_stmt->bind_result($_fp_val, $_fit_val);
            $fp_stmt->fetch();
            $fp_stmt->close();
            $_SESSION['foto_perfil'] = $_fp_val ?? '';
            $_SESSION['avatar_fit'] = in_array((string)$_fit_val, ['cover', 'contain'], true) ? (string)$_fit_val : 'cover';
        } else {
            $fp_stmt = $conn->prepare("SELECT foto_perfil FROM Usuarios WHERE id_usuario = ?");
            $fp_stmt->bind_param("i", $_SESSION['user_id']);
            $fp_stmt->execute();
            $fp_stmt->bind_result($_fp_val);
            $fp_stmt->fetch();
            $fp_stmt->close();
            $_SESSION['foto_perfil'] = $_fp_val ?? '';
            $_SESSION['avatar_fit'] = 'cover';
        }
    } else {
        $_SESSION['foto_perfil'] = '';
        $_SESSION['avatar_fit'] = 'cover';
    }
}
$user_foto = $_SESSION['foto_perfil'] ?? '';
$user_avatar_fit = (string)($_SESSION['avatar_fit'] ?? 'cover');
if (!in_array($user_avatar_fit, ['cover', 'contain'], true)) {
    $user_avatar_fit = 'cover';
}

$page_title  = $page_title  ?? 'Sistema de Gestión';
$active_page = $active_page ?? '';
$instance_name = (string)systemSetting('nombre_instancia', 'Master Inventario');
$instance_logo = appResolveLogoPath();
$force_dark_mode = isSystemSettingEnabled('modo_oscuro_permanente');
$density_tables = (string)systemSetting('densidad_tablas', 'comoda');
$stock_threshold = max(0, (int)systemSetting('umbral_stock_bajo', 5));
$theme_css_dynamic = appBuildDynamicThemeCss();
$global_banner_image = appResolveBannerPath();
$global_banner_fullpath = __DIR__ . '/../' . ltrim($global_banner_image, '/');
$global_banner_version = file_exists($global_banner_fullpath) ? (string)filemtime($global_banner_fullpath) : (string)time();
$html_classes = [];
if ($force_dark_mode) $html_classes[] = 'dark';
if ($density_tables === 'compacta') $html_classes[] = 'density-compact';
$html_class_attr = implode(' ', $html_classes);

// Stock alert badge
$alertas_nav = 0;
if (!empty($_SESSION['user_id']) && isset($conn)) {
    $stmt_alert = $conn->prepare("SELECT COUNT(*) AS total FROM Inventario WHERE cantidad_disponible <= ?");
    if ($stmt_alert) {
        $stmt_alert->bind_param("i", $stock_threshold);
        $stmt_alert->execute();
        $alertas_nav = (int)$stmt_alert->get_result()->fetch_assoc()['total'];
        $stmt_alert->close();
    }
}

function navActive(string $file, string $activePage): string {
    return ($activePage === $file) ? ' active' : '';
}
?>
<!DOCTYPE html>
<html lang="es" id="html-root" class="<?= htmlspecialchars($html_class_attr, ENT_QUOTES, 'UTF-8') ?>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= htmlspecialchars($page_title, ENT_QUOTES, 'UTF-8') ?> — <?= htmlspecialchars($instance_name, ENT_QUOTES, 'UTF-8') ?></title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:ital,opsz,wght@0,9..40,300;0,9..40,400;0,9..40,500;0,9..40,600;0,9..40,700;1,9..40,400&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css">
    <link rel="stylesheet" href="styles/template-theme.css">
    <link rel="stylesheet" href="styles/components.css">
    <?php if (isset($extra_css)): ?>
        <?php foreach ((array)$extra_css as $css): ?>
        <link rel="stylesheet" href="<?= htmlspecialchars($css, ENT_QUOTES, 'UTF-8') ?>">
        <?php endforeach; ?>
    <?php endif; ?>
    <style><?= $theme_css_dynamic ?></style>
    <script>
    window.APP_UI_SETTINGS = {
        forceDarkMode: <?= $force_dark_mode ? 'true' : 'false' ?>,
        bannerImage: <?= json_encode($global_banner_image, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) ?>,
        bannerVersion: <?= json_encode($global_banner_version, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) ?>
    };
    // Apply saved theme immediately (before paint) to prevent flash
    (function() {
        if (window.APP_UI_SETTINGS.forceDarkMode) {
            document.documentElement.classList.add('dark');
            try { localStorage.setItem('theme', 'dark'); } catch (e) {}
            return;
        }
        var saved = localStorage.getItem('theme');
        if (saved === 'dark') {
            document.documentElement.classList.add('dark');
        }
    })();
    </script>
</head>
<body>

<div class="layout">

    <!-- ═══ SIDEBAR ═══ -->
    <aside class="sidebar" id="sidebar">

        <!-- Logo -->
        <div class="sidebar-logo">
            <a href="index.php" class="sidebar-logo-link comersur-brand">
                <img src="<?= htmlspecialchars($instance_logo, ENT_QUOTES, 'UTF-8') ?>" alt="<?= htmlspecialchars($instance_name, ENT_QUOTES, 'UTF-8') ?>" class="comersur-logo-img">
                <span class="comersur-logo-text"><?= htmlspecialchars($instance_name, ENT_QUOTES, 'UTF-8') ?></span>
            </a>
        </div>

        <!-- Navigation -->
        <nav class="sidebar-nav">

            <span class="nav-section-label">Principal</span>

            <a href="dashboard.php" class="nav-link<?= navActive('dashboard.php', $active_page) ?>">
                <i class="fas fa-gauge"></i><span>Dashboard</span>
            </a>

            <span class="nav-section-label">Operaciones</span>

            <a href="gestion_inventario.php" class="nav-link<?= navActive('gestion_inventario.php', $active_page) ?>">
                <i class="fas fa-boxes-stacked"></i>
                <span>Inventario</span>
                <?php if ($alertas_nav > 0): ?>
                    <span class="nav-badge"><?= $alertas_nav ?></span>
                <?php endif; ?>
            </a>

            <a href="gestion_ventas.php" class="nav-link<?= navActive('gestion_ventas.php', $active_page) ?>">
                <i class="fas fa-cart-shopping"></i><span>Ventas</span>
            </a>

            <a href="gestion_compras.php" class="nav-link<?= navActive('gestion_compras.php', $active_page) ?>">
                <i class="fas fa-truck"></i><span>Compras</span>
            </a>

            <a href="gestion_proveedores.php" class="nav-link<?= navActive('gestion_proveedores.php', $active_page) ?>">
                <i class="fas fa-building"></i><span>Proveedores</span>
            </a>

            <a href="documentos.php" class="nav-link<?= navActive('documentos.php', $active_page) ?>">
                <i class="fas fa-file-lines"></i><span>Documentos</span>
            </a>

            <a href="agenda_calendario.php" class="nav-link<?= navActive('agenda_calendario.php', $active_page) ?>">
                <i class="fas fa-calendar-check"></i><span>Calendario</span>
            </a>

            <?php if ($user_role === 'Administrador'): ?>
            <span class="nav-section-label">Administración</span>

            <a href="administrar_usuarios.php" class="nav-link<?= navActive('administrar_usuarios.php', $active_page) ?>">
                <i class="fas fa-users"></i><span>Usuarios</span>
            </a>

            <a href="reportes.php" class="nav-link<?= navActive('reportes.php', $active_page) ?>">
                <i class="fas fa-chart-bar"></i><span>Reportes</span>
            </a>

            <a href="graficas.php" class="nav-link<?= navActive('graficas.php', $active_page) ?>">
                <i class="fas fa-chart-line"></i><span>Gráficas</span>
            </a>

            <a href="configuracion_sistema.php" class="nav-link<?= navActive('configuracion_sistema.php', $active_page) ?>">
                <i class="fas fa-sliders"></i><span>Configuración</span>
            </a>

            <?php endif; ?>

            <span class="nav-section-label">Cuenta</span>

            <a href="perfil.php" class="nav-link<?= navActive('perfil.php', $active_page) ?>">
                <i class="fas fa-circle-user"></i><span>Mi Perfil</span>
            </a>

            <a href="soporte_mantenimiento.php" class="nav-link<?= navActive('soporte_mantenimiento.php', $active_page) ?>">
                <i class="fas fa-life-ring"></i><span>Soporte</span>
            </a>

        </nav>


    </aside>
    <!-- /sidebar -->

    <!-- Mobile overlay -->
    <div class="sidebar-overlay" id="sidebarOverlay"></div>

    <!-- ═══ BODY WRAPPER ═══ -->
    <div class="body-wrapper">

        <!-- Universal Topbar -->
        <header class="topbar" id="topbar">
            <div class="topbar-left">
                <!-- Mobile hamburger -->
                <button class="mobile-toggle" id="sidebarToggle" aria-label="Abrir menú">
                    <i class="fas fa-bars"></i>
                </button>

                <!-- Mobile logo -->
                <div class="topbar-logo">
                    <a href="index.php">
                        <img src="<?= htmlspecialchars($instance_logo, ENT_QUOTES, 'UTF-8') ?>" alt="<?= htmlspecialchars($instance_name, ENT_QUOTES, 'UTF-8') ?>" style="height:28px; width:auto;">
                    </a>
                </div>

            </div>

            <div class="topbar-right">
                <!-- Dark Mode Toggle -->
                <button class="theme-toggle" id="themeToggle" title="Cambiar tema" aria-label="Cambiar tema claro/oscuro">
                    <!-- Sun icon (shown in dark mode) -->
                    <i class="fas fa-sun theme-icon-dark"></i>
                    <!-- Moon icon (shown in light mode) -->
                    <i class="fas fa-moon theme-icon-light"></i>
                </button>

                <!-- Alerts bell -->
                <button class="icon-btn" title="Alertas de stock" onclick="window.location='gestion_inventario.php'">
                    <i class="fas fa-bell"></i>
                    <?php if ($alertas_nav > 0): ?>
                        <span class="badge-count"><?= $alertas_nav > 9 ? '9+' : $alertas_nav ?></span>
                    <?php endif; ?>
                </button>

                <!-- Profile -->
                <a href="perfil.php" class="header-profile">
                    <div class="user-avatar">
                        <?php if (!empty($user_foto) && file_exists(__DIR__ . '/../' . $user_foto)): ?>
                            <img src="<?= htmlspecialchars($user_foto) ?>?v=<?= $_SESSION['foto_v'] ?? 1 ?>" alt="Foto" style="width:100%;height:100%;object-fit:<?= $user_avatar_fit === 'contain' ? 'contain' : 'cover' ?>;background:rgba(255,255,255,0.12);border-radius:inherit;">
                        <?php else: ?>
                            <?= strtoupper(mb_substr($user_nombre, 0, 1)) ?>
                        <?php endif; ?>
                    </div>
                    <div class="header-profile-info">
                        <span class="header-profile-name"><?= htmlspecialchars($user_nombre, ENT_QUOTES, 'UTF-8') ?></span>
                        <span class="header-profile-role"><?= htmlspecialchars($user_role, ENT_QUOTES, 'UTF-8') ?></span>
                    </div>
                </a>

                <!-- Logout -->
                <a href="logout.php" class="icon-btn" title="Cerrar sesión">
                    <i class="fas fa-arrow-right-from-bracket"></i>
                </a>
            </div>
        </header>

        <!-- Page content starts here -->
        <div class="page-content">
