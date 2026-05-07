<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once 'config.php';

$email    = 'admin@inventario.local';
$password = 'Admin1234!';
$nombre   = 'Administrador';
$hash     = password_hash($password, PASSWORD_BCRYPT);

echo "<pre>";
echo "DB conectada: OK\n";
echo "Hash generado: $hash\n\n";

// Borra si existe para hacer insert limpio
$del = $conn->query("DELETE FROM Usuarios WHERE correo_electronico = '$email'");
echo "Delete previo: " . ($del ? "OK" : $conn->error) . "\n";

// Insert directo sin prepared para debug
$sql = "INSERT INTO Usuarios (nombre, correo_electronico, contrasena, rol, estado, telefono, fecha_creacion)
        VALUES ('$nombre', '$email', '$hash', 'Administrador', 'Activo', '00000000', NOW())";

$result = $conn->query($sql);
if ($result) {
    echo "✅ Usuario creado OK\n";
    echo "----------------------------\n";
    echo "EMAIL:    $email\n";
    echo "PASSWORD: $password\n";
    echo "----------------------------\n";
    echo "Ahora ve a: http://localhost:8000/login.php\n";
} else {
    echo "❌ ERROR: " . $conn->error . "\n";
    echo "SQL: $sql\n";
}
echo "</pre>";
?>
