<?php
// config.php is NOT included here intentionally — logout must work even if the
// database is unreachable. Guard session_start() in case a partial include already
// started the session (e.g., header.php included from an error page).
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// Overwrite all session variables so no data leaks after destruction.
$_SESSION = [];

// Expire the session cookie on the client side.
if (ini_get('session.use_cookies')) {
    $params = session_get_cookie_params();
    setcookie(
        session_name(),
        '',
        time() - 42000,
        $params['path'],
        $params['domain'],
        $params['secure'],
        $params['httponly']
    );
}

// Destroy the server-side session data.
session_destroy();

// Redirect to login.
header('Location: login.php');
exit;
