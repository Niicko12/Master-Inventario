<?php
require_once 'config.php';
$page_title  = 'Mi Perfil';
$active_page = 'perfil.php';

// Auto-migrate: add foto_perfil column if it doesn't exist yet
$col = $conn->query("SHOW COLUMNS FROM Usuarios LIKE 'foto_perfil'");
if ($col && $col->num_rows === 0) {
    $conn->query("ALTER TABLE Usuarios ADD COLUMN foto_perfil VARCHAR(255) DEFAULT NULL AFTER direccion");
}
$fit_col = $conn->query("SHOW COLUMNS FROM Usuarios LIKE 'avatar_fit'");
if ($fit_col && $fit_col->num_rows === 0) {
    $conn->query("ALTER TABLE Usuarios ADD COLUMN avatar_fit ENUM('cover','contain') NOT NULL DEFAULT 'cover' AFTER foto_perfil");
}

$user_id = intval($_SESSION['user_id']);
$stmt = $conn->prepare("SELECT id_usuario, correo_electronico, nombre, rol, contrasena, foto_perfil, avatar_fit FROM Usuarios WHERE id_usuario = ?");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();
$user = $result->fetch_assoc();
$stmt->close();
$user['avatar_fit'] = in_array((string)($user['avatar_fit'] ?? 'cover'), ['cover', 'contain'], true)
    ? (string)$user['avatar_fit']
    : 'cover';
$_SESSION['avatar_fit'] = $user['avatar_fit'];

$flash_message = '';
$flash_type    = 'info';
$currentBanner = appResolveBannerPath();
$currentBannerVersion = file_exists(__DIR__ . '/' . $currentBanner)
    ? (string)filemtime(__DIR__ . '/' . $currentBanner)
    : (string)time();
$defaultAvatarReference = 'assets/images/avatars/image_0.png';
$hasDefaultAvatarReference = file_exists(__DIR__ . '/' . $defaultAvatarReference);
$defaultAvatarVersion = $hasDefaultAvatarReference
    ? (string)filemtime(__DIR__ . '/' . $defaultAvatarReference)
    : (string)time();

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (!empty($_POST['remove_foto_perfil'])) {
        $foto_actual = (string)($user['foto_perfil'] ?? '');
        if ($foto_actual !== '' && str_starts_with($foto_actual, 'uploads/avatars/')) {
            $old_path = __DIR__ . '/' . $foto_actual;
            if (file_exists($old_path)) {
                @unlink($old_path);
            }
        }

        $stmt_remove = $conn->prepare("UPDATE Usuarios SET foto_perfil = NULL WHERE id_usuario = ?");
        if ($stmt_remove) {
            $stmt_remove->bind_param("i", $user_id);
            if ($stmt_remove->execute()) {
                $flash_message = 'Imagen de perfil eliminada. Se aplicó el avatar por defecto.';
                $flash_type    = 'success';
                $user['foto_perfil'] = null;
                $_SESSION['foto_perfil'] = '';
                $_SESSION['foto_v'] = time();
            } else {
                $flash_message = 'No se pudo eliminar la imagen de perfil.';
                $flash_type    = 'error';
            }
            $stmt_remove->close();
        } else {
            $flash_message = 'No se pudo preparar la eliminación de la imagen.';
            $flash_type    = 'error';
        }

        $stmt_refresh = $conn->prepare("SELECT id_usuario, correo_electronico, nombre, rol, contrasena, foto_perfil, avatar_fit FROM Usuarios WHERE id_usuario = ?");
        if ($stmt_refresh) {
            $stmt_refresh->bind_param("i", $user_id);
            $stmt_refresh->execute();
            $user = $stmt_refresh->get_result()->fetch_assoc();
            $stmt_refresh->close();
            $user['avatar_fit'] = in_array((string)($user['avatar_fit'] ?? 'cover'), ['cover', 'contain'], true)
                ? (string)$user['avatar_fit']
                : 'cover';
            $_SESSION['avatar_fit'] = $user['avatar_fit'];
        }
    } else {
        $nombre = trim($_POST['nombre'] ?? '');
        $correo = trim($_POST['correo'] ?? '');
        $avatar_fit = in_array((string)($_POST['avatar_fit'] ?? ''), ['cover', 'contain'], true)
            ? (string)$_POST['avatar_fit']
            : (string)($user['avatar_fit'] ?? 'cover');

        // Handle profile image upload
        if (!empty($_FILES['foto_perfil']['name'])) {
            $allowed_types = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
            $max_size      = 2 * 1024 * 1024; // 2MB
            $file_tmp      = $_FILES['foto_perfil']['tmp_name'];
            $file_size     = $_FILES['foto_perfil']['size'];
            $file_type     = mime_content_type($file_tmp);
            $ext           = strtolower(pathinfo($_FILES['foto_perfil']['name'], PATHINFO_EXTENSION));

            if (!in_array($file_type, $allowed_types)) {
                $flash_message = 'Solo se permiten imágenes JPG, PNG, WEBP o GIF.';
                $flash_type    = 'error';
            } elseif ($file_size > $max_size) {
                $flash_message = 'La imagen no puede superar los 2MB.';
                $flash_type    = 'error';
            } else {
                $upload_dir = __DIR__ . '/uploads/avatars/';
                if (!is_dir($upload_dir)) {
                    mkdir($upload_dir, 0755, true);
                }
                // Remove old avatar if exists
                if (!empty($user['foto_perfil'])) {
                    $old_path = __DIR__ . '/' . $user['foto_perfil'];
                    if (file_exists($old_path)) {
                        unlink($old_path);
                    }
                }
                $filename  = 'avatar_' . $user_id . '_' . time() . '.' . $ext;
                $dest      = $upload_dir . $filename;
                if (move_uploaded_file($file_tmp, $dest)) {
                    $new_foto = 'uploads/avatars/' . $filename;
                    $stmt_foto = $conn->prepare("UPDATE Usuarios SET foto_perfil=? WHERE id_usuario=?");
                    $stmt_foto->bind_param("si", $new_foto, $user_id);
                    $stmt_foto->execute();
                    $stmt_foto->close();
                    $user['foto_perfil'] = $new_foto;
                    $_SESSION['foto_perfil'] = $new_foto;
                    $_SESSION['foto_v'] = time(); // cache-bust for <img> src
                } else {
                    $flash_message = 'Error al subir la imagen.';
                    $flash_type    = 'error';
                }
            }
        }

        if ($user['rol'] == 'Administrador' && isset($_POST['rol'])) {
            $rol = $_POST['rol'];
            if (!empty($_POST['password'])) {
                $password = password_hash($_POST['password'], PASSWORD_DEFAULT);
                $stmt = $conn->prepare("UPDATE Usuarios SET nombre=?, correo_electronico=?, contrasena=?, rol=?, avatar_fit=? WHERE id_usuario=?");
                $stmt->bind_param("sssssi", $nombre, $correo, $password, $rol, $avatar_fit, $user_id);
            } else {
                $stmt = $conn->prepare("UPDATE Usuarios SET nombre=?, correo_electronico=?, rol=?, avatar_fit=? WHERE id_usuario=?");
                $stmt->bind_param("ssssi", $nombre, $correo, $rol, $avatar_fit, $user_id);
            }
        } elseif (!empty($_POST['password'])) {
            $password = password_hash($_POST['password'], PASSWORD_DEFAULT);
            $stmt = $conn->prepare("UPDATE Usuarios SET nombre=?, correo_electronico=?, contrasena=? WHERE id_usuario=?");
            $stmt->bind_param("sssi", $nombre, $correo, $password, $user_id);
        } else {
            $stmt = $conn->prepare("UPDATE Usuarios SET nombre=?, correo_electronico=? WHERE id_usuario=?");
            $stmt->bind_param("ssi", $nombre, $correo, $user_id);
        }

        if ($stmt->execute()) {
            $flash_message = 'Perfil actualizado correctamente.';
            $flash_type    = 'success';
            $_SESSION['username'] = $correo;
            // Refresh user data
            $stmt2 = $conn->prepare("SELECT id_usuario, correo_electronico, nombre, rol, contrasena, foto_perfil, avatar_fit FROM Usuarios WHERE id_usuario = ?");
            $stmt2->bind_param("i", $user_id);
            $stmt2->execute();
            $user = $stmt2->get_result()->fetch_assoc();
            $stmt2->close();
            $user['avatar_fit'] = in_array((string)($user['avatar_fit'] ?? 'cover'), ['cover', 'contain'], true)
                ? (string)$user['avatar_fit']
                : 'cover';
            $_SESSION['avatar_fit'] = $user['avatar_fit'];
        } else {
            $flash_message = 'Error al actualizar el perfil.';
            $flash_type    = 'error';
        }
        $stmt->close();
    }
}

include('layout/sidebar.php');
?>

<?php if ($flash_message): ?>
<script>
    document.addEventListener('DOMContentLoaded', function() {
        showToast(<?= json_encode($flash_message) ?>, <?= json_encode($flash_type) ?>);
    });
</script>
<?php endif; ?>

<!-- Page Banner -->
<div class="page-banner">
    <div class="page-banner-content">
        <h1>Mi Perfil</h1>
        <div class="page-banner-breadcrumb">
            <a href="dashboard.php">Inicio</a>
            <span class="sep">•</span>
            <span>Perfil</span>
        </div>
    </div>
    <img src="<?= htmlspecialchars($currentBanner, ENT_QUOTES, 'UTF-8') ?>?v=<?= htmlspecialchars($currentBannerVersion, ENT_QUOTES, 'UTF-8') ?>" alt="Banner de inventario de productos" class="page-banner-img">
</div>

<!-- Profile card -->
<div class="profile-grid">

    <!-- Avatar / info card -->
    <div class="card-master profile-summary-card">
        <div class="profile-avatar-wrap">
            <div class="profile-avatar-stage">
                <?php if (!empty($user['foto_perfil']) && file_exists(__DIR__ . '/' . $user['foto_perfil'])): ?>
                    <img src="<?= htmlspecialchars($user['foto_perfil'], ENT_QUOTES, 'UTF-8') ?>?v=<?= time() ?>"
                         alt="Foto de perfil"
                         class="profile-avatar-img profile-avatar-fit-<?= htmlspecialchars((string)$user['avatar_fit'], ENT_QUOTES, 'UTF-8') ?>">
                <?php elseif ($hasDefaultAvatarReference): ?>
                    <img src="<?= htmlspecialchars($defaultAvatarReference, ENT_QUOTES, 'UTF-8') ?>?v=<?= htmlspecialchars($defaultAvatarVersion, ENT_QUOTES, 'UTF-8') ?>"
                         alt="Avatar base de referencia"
                         class="profile-avatar-img profile-avatar-fit-cover">
                <?php else: ?>
                    <div class="profile-avatar-gradient">
                        <?= strtoupper(mb_substr($user['nombre'], 0, 1)) ?>
                    </div>
                <?php endif; ?>
            </div>
            <label for="foto_perfil_input" class="profile-avatar-edit-btn" title="Cambiar foto">
                <i class="fas fa-camera"></i>
            </label>
        </div>
        <div class="profile-name"><?= htmlspecialchars($user['nombre']) ?></div>
        <div class="profile-email"><?= htmlspecialchars($user['correo_electronico']) ?></div>
        <span class="badge-pill <?= $user['rol'] === 'Administrador' ? 'badge-danger' : ($user['rol'] === 'Empleado' ? 'badge-info' : 'badge-neutral') ?>">
            <?= htmlspecialchars($user['rol']) ?>
        </span>
        <?php if (!empty($user['foto_perfil']) && file_exists(__DIR__ . '/' . (string)$user['foto_perfil'])): ?>
        <form action="perfil.php" method="post" style="margin-top:12px;">
            <input type="hidden" name="remove_foto_perfil" value="1">
            <button type="submit" class="btn-danger-sm" onclick="return confirm('¿Eliminar imagen de perfil y volver al avatar por defecto?');">
                <i class="fas fa-trash-alt"></i> Eliminar imagen
            </button>
        </form>
        <?php endif; ?>
    </div>

    <!-- Edit form card -->
    <div class="card-master profile-form-card">
        <div class="card-header-master">
            <h3><i class="fas fa-user-edit icon-cyan"></i>Editar Información</h3>
        </div>
        <form action="perfil.php" method="post" enctype="multipart/form-data" class="form-stack">
            <!-- Hidden file input triggered from the camera button in the avatar card -->
            <input type="file" id="foto_perfil_input" name="foto_perfil"
                   accept="image/jpeg,image/png,image/webp,image/gif"
                   style="display:none;"
                   onchange="this.form.submit()">
            <div class="form-group">
                <label class="form-label" for="nombre">Nombre</label>
                <input type="text" class="form-control" id="nombre" name="nombre" value="<?= htmlspecialchars($user['nombre']) ?>" required>
            </div>
            <div class="form-group">
                <label class="form-label" for="correo">Correo Electrónico</label>
                <input type="email" class="form-control" id="correo" name="correo" value="<?= htmlspecialchars($user['correo_electronico']) ?>" required>
            </div>
            <div class="form-group">
                <label class="form-label" for="password">Nueva Contraseña <span class="text-muted-inline">(dejar en blanco para no cambiar)</span></label>
                <input type="password" class="form-control" id="password" name="password">
            </div>
            <?php if ($user['rol'] == 'Administrador'): ?>
            <div class="form-group">
                <label class="form-label" for="rol">Rol</label>
                <select class="form-control" id="rol" name="rol">
                    <option value="Administrador" <?= $user['rol'] == 'Administrador' ? 'selected' : '' ?>>Administrador</option>
                    <option value="Empleado"      <?= $user['rol'] == 'Empleado'      ? 'selected' : '' ?>>Empleado</option>
                    <option value="Usuario"       <?= $user['rol'] == 'Usuario'       ? 'selected' : '' ?>>Usuario</option>
                </select>
            </div>
            <div class="form-group">
                <label class="form-label" for="avatar_fit">Ajuste de Imagen de Perfil</label>
                <select class="form-control" id="avatar_fit" name="avatar_fit">
                    <option value="cover" <?= (($user['avatar_fit'] ?? 'cover') === 'cover') ? 'selected' : '' ?>>Rellenar recuadro (cover)</option>
                    <option value="contain" <?= (($user['avatar_fit'] ?? 'cover') === 'contain') ? 'selected' : '' ?>>Mostrar imagen completa (contain)</option>
                </select>
                <span class="form-helper">Permite ajustar la foto del administrador para encajar mejor en el recuadro y bordes.</span>
            </div>
            <?php endif; ?>
            <div class="form-actions-row">
                <button type="submit" class="btn-primary-master">
                    <i class="fas fa-save"></i>Actualizar Perfil
                </button>
            </div>
        </form>
    </div>

</div>

<?php include('layout/footer_main.php'); ?>
