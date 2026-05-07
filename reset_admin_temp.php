<?php
/**
 * ARCHIVO TEMPORAL — ELIMINAR DESPUÉS DE USAR
 * Resetea la contraseña del admin a: Admin123!
 */
require_once 'config.php';

$hash = password_hash('Admin123!', PASSWORD_BCRYPT);

// Resetear contraseña de admin@gmail.com
$stmt = $conn->prepare("UPDATE Usuarios SET contrasena = ? WHERE correo_electronico = 'admin@gmail.com' AND rol = 'Administrador'");
$stmt->bind_param("s", $hash);
$stmt->execute();
$affected = $stmt->affected_rows;
$stmt->close();

if ($affected > 0) {
    echo "<h2 style='color:green'>✅ Contraseña reseteada</h2>";
    echo "<p><strong>Email:</strong> admin@gmail.com</p>";
    echo "<p><strong>Contraseña:</strong> Admin123!</p>";
    echo "<p><a href='login.php'>Ir al Login</a></p>";
    echo "<hr><p style='color:red'><strong>⚠️ ELIMINA ESTE ARCHIVO AHORA: reset_admin_temp.php</strong></p>";
} else {
    echo "<h2 style='color:red'>❌ Usuario no encontrado</h2>";
    echo "<p>El usuario admin@gmail.com no existe o no es Administrador en esta BD.</p>";

    // Crear nuevo admin si no existe
    $hash2 = password_hash('Admin123!', PASSWORD_BCRYPT);
    $stmt2 = $conn->prepare("INSERT IGNORE INTO Usuarios (nombre, correo_electronico, contrasena, rol, estado) VALUES ('Admin Temp', 'admin@gmail.com', ?, 'Administrador', 'Activo')");
    $stmt2->bind_param("s", $hash2);
    $stmt2->execute();
    $ins = $stmt2->affected_rows;
    $stmt2->close();

    if ($ins > 0) {
        echo "<p style='color:green'>✅ Admin creado.</p>";
        echo "<p><strong>Email:</strong> admin@gmail.com</p>";
        echo "<p><strong>Contraseña:</strong> Admin123!</p>";
        echo "<p><a href='login.php'>Ir al Login</a></p>";
    }
    echo "<p style='color:red'><strong>⚠️ ELIMINA ESTE ARCHIVO: reset_admin_temp.php</strong></p>";
}
?>
