<?php
/**
 * includes/header.php — Layout shell: <head>, blobs, sidebar, opening of <main>
 *
 * Variables the calling page MUST set BEFORE including this file:
 *   $page_title  (string)  — displayed in <title> and topbar h1
 *   $active_page (string)  — matches the keys below to mark the active nav-link
 *
 * Variables the calling page MAY set:
 *   $topbar_actions (string) — raw HTML injected into the right side of the topbar
 *
 * Config, session and auth MUST already be handled before this include.
 */

// Resolve session variables used inside the layout
$user_role   = $_SESSION['user_role']  ?? '';
$user_nombre = $_SESSION['nombre']     ?? 'Usuario';

// Stock alert count for the inventory nav icon
$alertas_nav = 0;
$stock_threshold = max(0, (int)systemSetting('umbral_stock_bajo', 5));
if (isset($conn) && isset($_SESSION['user_id'])) {
    $stmt_nav = $conn->prepare("SELECT COUNT(*) AS total FROM Inventario WHERE cantidad_disponible <= ?");
    if ($stmt_nav) {
        $stmt_nav->bind_param("i", $stock_threshold);
        $stmt_nav->execute();
        $alertas_nav = (int) $stmt_nav->get_result()->fetch_assoc()['total'];
        $stmt_nav->close();
    }
}

// Nav items definition: [label, href, icon, key]
$nav_items_principal = [
    ['Dashboard', 'dashboard.php', 'fas fa-th-large', 'dashboard'],
    ['Inicio',    'index.php',     'fas fa-home',     'inicio'],
];
$nav_items_operaciones = [
    ['Inventario',   'gestion_inventario.php',  'fas fa-boxes',        'inventario'],
    ['Ventas',       'gestion_ventas.php',       'fas fa-shopping-cart','ventas'],
    ['Compras',      'gestion_compras.php',      'fas fa-truck',        'compras'],
    ['Proveedores',  'gestion_proveedores.php',  'fas fa-building',     'proveedores'],
    ['Documentos',   'documentos.php',           'fas fa-file-alt',     'documentos'],
];
$nav_items_admin = [
    ['Usuarios',       'administrar_usuarios.php', 'fas fa-users',      'usuarios'],
    ['Reportes',       'reportes.php',             'fas fa-chart-bar',  'reportes'],
    ['Gráficas',       'graficas.php',             'fas fa-chart-line', 'graficas'],
    ['Configuración',  'configuracion_sistema.php','fas fa-cog',        'configuracion'],
    ['Integraciones',  'integraciones_externas.php','fas fa-plug',      'integraciones'],
    ['Soporte',        'soporte_mantenimiento.php','fas fa-tools',      'soporte'],
];
$nav_items_cuenta = [
    ['Mi Perfil', 'perfil.php', 'fas fa-user-circle', 'perfil'],
];

// Safe title and active page defaults
$page_title  = $page_title  ?? 'Sistema de Gestión';
$active_page = $active_page ?? '';
$topbar_actions = $topbar_actions ?? '';
$instance_name = (string)systemSetting('nombre_instancia', 'Sistema de Gestión');
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= htmlspecialchars($page_title, ENT_QUOTES, 'UTF-8') ?> — <?= htmlspecialchars($instance_name, ENT_QUOTES, 'UTF-8') ?></title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
    <link rel="stylesheet" href="assets/css/master.css">
    <?php if (isset($extra_css)): ?>
        <?= $extra_css ?>
    <?php endif; ?>
</head>
<body>

<!-- Ambient blobs -->
<div class="blob blob-1"></div>
<div class="blob blob-2"></div>

<div class="layout">

    <!-- ═══ SIDEBAR ═══ -->
    <aside class="sidebar" id="sidebar">
        <div class="sidebar-logo">
            <img src="logo.png" alt="Logo">
            <span class="logo-text">Master</span>
        </div>

        <nav class="sidebar-nav">
            <span class="nav-section-label">Principal</span>
            <?php foreach ($nav_items_principal as [$label, $href, $icon, $key]): ?>
            <a href="<?= $href ?>" class="nav-link <?= ($active_page === $key) ? 'active' : '' ?>">
                <i class="<?= $icon ?>"></i><span><?= $label ?></span>
            </a>
            <?php endforeach; ?>

            <span class="nav-section-label">Operaciones</span>
            <?php foreach ($nav_items_operaciones as [$label, $href, $icon, $key]): ?>
            <a href="<?= $href ?>" class="nav-link <?= ($active_page === $key) ? 'active' : '' ?>">
                <i class="<?= $icon ?>"></i>
                <span><?= $label ?></span>
                <?php if ($key === 'inventario' && $alertas_nav > 0): ?>
                    <span class="nav-badge"><?= $alertas_nav ?></span>
                <?php endif; ?>
            </a>
            <?php endforeach; ?>

            <?php if ($user_role === 'Administrador'): ?>
            <span class="nav-section-label">Administración</span>
            <?php foreach ($nav_items_admin as [$label, $href, $icon, $key]): ?>
            <a href="<?= $href ?>" class="nav-link <?= ($active_page === $key) ? 'active' : '' ?>">
                <i class="<?= $icon ?>"></i><span><?= $label ?></span>
            </a>
            <?php endforeach; ?>
            <?php endif; ?>

            <span class="nav-section-label">Cuenta</span>
            <?php foreach ($nav_items_cuenta as [$label, $href, $icon, $key]): ?>
            <a href="<?= $href ?>" class="nav-link <?= ($active_page === $key) ? 'active' : '' ?>">
                <i class="<?= $icon ?>"></i><span><?= $label ?></span>
            </a>
            <?php endforeach; ?>
        </nav>

        <div class="sidebar-footer">
            <a href="perfil.php" class="user-info">
                <div class="user-avatar">
                    <?php $hdr_foto = $_SESSION['foto_perfil'] ?? ''; ?>
                    <?php if (!empty($hdr_foto) && file_exists(__DIR__ . '/../' . $hdr_foto)): ?>
                        <img src="<?= htmlspecialchars($hdr_foto) ?>?v=<?= $_SESSION['foto_v'] ?? 1 ?>" alt="Foto" style="width:100%;height:100%;object-fit:cover;border-radius:inherit;">
                    <?php else: ?>
                        <?= strtoupper(mb_substr($user_nombre, 0, 1)) ?>
                    <?php endif; ?>
                </div>
                <div class="user-details">
                    <span class="user-role"><?= htmlspecialchars($user_role, ENT_QUOTES, 'UTF-8') ?></span>
                </div>
            </a>
            <a href="logout.php" class="logout-link" title="Cerrar sesión">
                <i class="fas fa-sign-out-alt"></i>
            </a>
        </div>
    </aside>

    <!-- ═══ MAIN ═══ -->
    <main class="main-content">

        <!-- Topbar -->
        <div class="topbar">
            <div class="topbar-title">
                <button class="btn-icon" id="sidebarToggle" aria-label="Menú">
                    <i class="fas fa-bars"></i>
                </button>
                <h1><?= htmlspecialchars($page_title, ENT_QUOTES, 'UTF-8') ?></h1>
                <span class="date-badge"><i class="far fa-calendar-alt"></i><?= date('d M Y') ?></span>
            </div>
            <?php if ($topbar_actions): ?>
            <div class="topbar-actions">
                <?= $topbar_actions ?>
            </div>
            <?php endif; ?>
        </div>

        <!-- Page content starts here -->
