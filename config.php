<?php
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

function parseEnvFile($path) {
    if (!file_exists($path)) return [];
    $vars = [];
    foreach (file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
        if (strpos(trim($line), '#') === 0) continue;
        if (strpos($line, '=') === false) continue;
        [$key, $val] = explode('=', $line, 2);
        $vars[trim($key)] = trim($val);
    }
    return $vars;
}

$env = parseEnvFile(__DIR__ . '/.env');

$localConfig = [
    'servername' => $env['LOCAL_DB_HOST'] ?? 'localhost',
    'username'   => $env['LOCAL_DB_USER'] ?? 'root',
    'password'   => $env['LOCAL_DB_PASS'] ?? '',
    'dbname'     => $env['LOCAL_DB_NAME'] ?? '',
    'port'       => (int)($env['LOCAL_DB_PORT'] ?? 3306),
];

$prodConfig = [
    'servername' => $env['PROD_DB_HOST'] ?? '127.0.0.1',
    'username'   => $env['PROD_DB_USER'] ?? '',
    'password'   => $env['PROD_DB_PASS'] ?? '',
    'dbname'     => $env['PROD_DB_NAME'] ?? '',
    'port'       => (int)($env['PROD_DB_PORT'] ?? 3306),
];

function testConnection($config) {
    try {
        $testConn = new mysqli($config['servername'], $config['username'], $config['password'], $config['dbname'], $config['port']);
        return !$testConn->connect_error;
    } catch (mysqli_sql_exception $e) {
        return false;
    }
}

$config = testConnection($localConfig) ? $localConfig : $prodConfig;

$conn = new mysqli($config['servername'], $config['username'], $config['password'], $config['dbname'], $config['port']);

if ($conn->connect_error) {
    die("Conexión fallida.");
}

require_once __DIR__ . '/includes/auth_check.php';
require_once __DIR__ . '/utils/db.php';
require_once __DIR__ . '/utils/pagination.php';
require_once __DIR__ . '/utils/system_settings.php';
systemSettingsBootstrap($conn);
?>
