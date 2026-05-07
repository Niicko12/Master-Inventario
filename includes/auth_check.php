<?php
/**
 * Helpers de autenticación y autorización — Sistema de Gestión de Inventario
 */

// ── Auto-enforcement: pages that DON'T need auth (whitelist) ──────────────
$_AUTH_PUBLIC_PAGES = [
    'login.php',
    'register.php',
    'recuperar_contraseña.php',
    'cambiar_contraseña.php',
    'verificar_codigo.php',
    'verificacion_correo.php',
    'logout.php',
    'reset_admin_temp.php',
    'crear_admin.php',
];

$_auth_current_page = basename($_SERVER['PHP_SELF'] ?? '');

if (!in_array($_auth_current_page, $_AUTH_PUBLIC_PAGES, true)) {
    if (!isset($_SESSION['user_id'])) {
        header("Location: login.php");
        exit;
    }
}

unset($_AUTH_PUBLIC_PAGES, $_auth_current_page);
// ── End auto-enforcement ──────────────────────────────────────────────────

function requireAuth(): void {
    if (!isset($_SESSION['user_id'])) {
        header("Location: login.php");
        exit;
    }
}

function requireRole(string $role): void {
    requireAuth();
    if (!isset($_SESSION['user_role']) || $_SESSION['user_role'] !== $role) {
        header("Location: index.php");
        exit;
    }
}

function requireAnyRole(array $roles): void {
    requireAuth();
    if (!isset($_SESSION['user_role']) || !in_array($_SESSION['user_role'], $roles, true)) {
        header("Location: index.php");
        exit;
    }
}

function hasRole(string $role): bool {
    return isset($_SESSION['user_role']) && $_SESSION['user_role'] === $role;
}

function hasAnyRole(array $roles): bool {
    return isset($_SESSION['user_role']) && in_array($_SESSION['user_role'], $roles, true);
}

/**
 * Verifica sesión activa y nivel de rol mínimo.
 * Compatible con la convención authRequire('Administrador').
 *
 * Roles jerárquicos: Usuario (1) < Empleado (2) < Administrador (3)
 */
function authRequire(string $min_role = 'Usuario'): void {
    if (empty($_SESSION['user_id'])) {
        header('Location: login.php');
        exit;
    }

    $roles      = ['Usuario' => 1, 'Empleado' => 2, 'Administrador' => 3];
    $user_level = $roles[$_SESSION['user_role'] ?? 'Usuario'] ?? 1;
    $required   = $roles[$min_role] ?? 1;

    if ($user_level < $required) {
        header('Location: acceso_denegado.php');
        exit;
    }
}
