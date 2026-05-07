<?php
// Security headers — must fire before any output
header("Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.jsdelivr.net https://cdnjs.cloudflare.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com https://cdn.jsdelivr.net https://cdnjs.cloudflare.com; font-src 'self' https://fonts.gstatic.com https://cdnjs.cloudflare.com; img-src 'self' data: https:; object-src 'none'; base-uri 'self';");
header("X-Content-Type-Options: nosniff");
header("Referrer-Policy: strict-origin-when-cross-origin");

require_once 'config.php';
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}
$user_logged_in = isset($_SESSION['user_id']);
$user_role      = isset($_SESSION['user_role']) ? $_SESSION['user_role'] : null;
$tamano_fuente  = isset($_SESSION['tamano_fuente']) ? $_SESSION['tamano_fuente'] : 'mediano';

// Stock alert badge count
$alertas_nav = 0;
if ($user_logged_in) {
    $stmt_alerta = $conn->prepare("SELECT COUNT(*) as total FROM Inventario WHERE cantidad_disponible <= stock_minimo");
    $stmt_alerta->execute();
    $alertas_nav = (int) $stmt_alerta->get_result()->fetch_assoc()['total'];
    $stmt_alerta->close();
}
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sistema de Gestión</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="styles/header.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
    <link rel="stylesheet" href="styles/dark-theme.css">
    <style>
        body {
            font-size: <?php echo ($tamano_fuente == 'pequeño') ? '14px' : (($tamano_fuente == 'grande') ? '18px' : '16px'); ?>;
        }
    </style>
</head>

<body>
    <header>
        <nav class="navbar">
            <a class="navbar-brand" href="#">Sistema de Gestión</a>
            <button class="menu-button" id="menuButton" aria-label="Menú">
                <svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <path d="M25 16C25 16.1989 24.921 16.3897 24.7803 16.5303C24.6397 16.671 24.4489 16.75 24.25 16.75H7.75C7.55109 16.75 7.36032 16.671 7.21967 16.5303C7.07902 16.3897 7 16.1989 7 16C7 15.8011 7.07902 15.6103 7.21967 15.4697C7.36032 15.329 7.55109 15.25 7.75 15.25H24.25C24.4489 15.25 24.6397 15.329 24.7803 15.4697C24.921 15.6103 25 15.8011 25 16ZM7.75 10.75H24.25C24.4489 10.75 24.6397 10.671 24.7803 10.5303C24.921 10.3897 25 10.1989 25 10C25 9.80109 24.921 9.61032 24.7803 9.46967C24.6397 9.32902 24.4489 9.25 24.25 9.25H7.75C7.55109 9.25 7.36032 9.32902 7.21967 9.46967C7.07902 9.61032 7 9.80109 7 10C7 10.1989 7.07902 10.3897 7.21967 10.5303C7.36032 10.671 7.55109 10.75 7.75 10.75ZM24.25 21.25H7.75C7.55109 21.25 7.36032 21.329 7.21967 21.4697C7.07902 21.6103 7 21.8011 7 22C7 22.1989 7.07902 22.3897 7.21967 22.5303C7.36032 22.671 7.55109 22.75 7.75 22.75H24.25C24.4489 22.75 24.6397 22.671 24.7803 22.5303C24.921 22.3897 25 22.1989 25 22C25 21.8011 24.921 21.6103 24.7803 21.4697C24.6397 21.329 24.4489 21.25 24.25 21.25Z" fill="currentColor"/>
                </svg>
            </button>
            <div class="nav-items" id="navItems">
                <a class="nav-item" href="index.php">Inicio</a>
                <?php if ($user_logged_in): ?>
                    <a class="nav-item" href="dashboard.php">Dashboard</a>
                    <a class="nav-item" href="perfil.php">Mi Perfil</a>
                    <a class="nav-item" href="gestion_inventario.php">
                        Inventario
                        <?php if ($alertas_nav > 0): ?>
                            <span class="stock-alert-badge"><?= $alertas_nav ?></span>
                        <?php endif; ?>
                    </a>
                    <a class="nav-item" href="gestion_ventas.php">Gestión de Ventas</a>
                    <a class="nav-item" href="gestion_compras.php">Gestión de Compras</a>
                    <a class="nav-item" href="soporte_mantenimiento.php">Soporte y Mantenimiento</a>
                    <?php if ($user_role == 'Empleado' || $user_role == 'Administrador'): ?>
                    <a class="nav-item" href="documentos.php">Gestión Documental</a>
                    <?php endif; ?>
                    <?php if ($user_role == 'Administrador'): ?>
                        <div class="dropdown">
                            <a class="nav-item dropdown-toggle" href="#">Administración</a>
                            <div class="dropdown-menu">
                                <a class="nav-item" href="gestion_proveedores.php">Gestión de proveedores</a>
                                <a class="dropdown-item" href="administrar_usuarios.php">Administrar Usuarios</a>
                                <a class="dropdown-item" href="reportes.php">Reportes</a>
                                <a class="dropdown-item" href="graficas.php">Graficas</a>
                                <a class="dropdown-item" href="configuracion_sistema.php">Configuración del Sistema</a>
                                <a class="dropdown-item" href="integraciones_externas.php">Integraciones Externas</a>
                            </div>
                        </div>
                    <?php endif; ?>
                <?php else: ?>
                    <a class="nav-item" href="login.php">Iniciar Sesión</a>
                    <a class="nav-item" href="register.php">Registrarse</a>
                <?php endif; ?>
                <?php if ($user_logged_in): ?>
                    <a class="logout-button" href="logout.php">Cerrar Sesión</a>
                <?php endif; ?>
            </div>
        </nav>
    </header>

    <script src="js/ui-feedback.js"></script>
    <script>
    // Función para manejar el menú hamburguesa
    document.getElementById('menuButton').addEventListener('click', function() {
        document.getElementById('navItems').classList.toggle('active');
    });

    // Función para manejar el cambio de tamaño de pantalla
    function handleResize() {
        const navItems = document.getElementById('navItems');
        const menuButton = document.getElementById('menuButton');
        
        if (window.innerWidth > 768) {
            // En pantallas grandes, asegurarse que el menú esté visible
            navItems.classList.remove('active');
            menuButton.style.display = 'none';
            // Resetear los dropdowns
            document.querySelectorAll('.dropdown').forEach(dropdown => {
                dropdown.classList.remove('active');
            });
        } else {
            // En pantallas pequeñas, mostrar el botón de menú
            menuButton.style.display = 'block';
        }
    }

    // Manejar clicks en los dropdowns en móvil
    document.querySelectorAll('.dropdown-toggle').forEach(toggle => {
        toggle.addEventListener('click', function(e) {
            if (window.innerWidth <= 768) {
                e.preventDefault();
                const dropdown = this.parentElement;
                dropdown.classList.toggle('active');
            }
        });
    });

    // Ejecutar al cargar y cuando cambie el tamaño de la ventana
    window.addEventListener('load', handleResize);
    window.addEventListener('resize', handleResize);
    </script>
</body>
</html>
