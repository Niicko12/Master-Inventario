<?php
require_once 'config.php';
$page_title  = 'Configuración';
$active_page = 'configuracion_sistema.php';

authRequire('Administrador');

$flash_message = '';
$flash_type    = 'info';
$backup_file_relative = '';

$currency_map = getSystemCurrencyMap();
$date_format_options = [
    'd/m/Y' => 'DD/MM/YYYY',
    'Y-m-d' => 'YYYY-MM-DD',
    'd-m-Y' => 'DD-MM-YYYY',
];
$time_format_options = [
    'H:i'   => '24 horas (HH:mm)',
    'h:i A' => '12 horas (hh:mm AM/PM)',
];
$timezone_options = [
    'America/Mexico_City' => 'México (Centro) - Tabasco',
    'America/Merida'      => 'México (Sureste) - Mérida',
    'America/Monterrey'   => 'México (Noreste) - Monterrey',
    'America/Bogota'      => 'Colombia - Bogotá',
    'UTC'                 => 'UTC',
];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? 'save_settings';

    if ($action === 'backup_sql') {
        $backupDir = __DIR__ . '/backups';
        if (!is_dir($backupDir)) {
            @mkdir($backupDir, 0775, true);
        }

        $backupName = 'respaldo_' . date('Y-m-d_H-i-s') . '.sql';
        $backupAbsolutePath = $backupDir . '/' . $backupName;
        $backup_file_relative = 'backups/' . $backupName;

        $ok = false;
        $fh = @fopen($backupAbsolutePath, 'wb');
        if ($fh) {
            fwrite($fh, "-- Respaldo SQL generado por {$page_title}\n");
            fwrite($fh, "-- Fecha: " . date('Y-m-d H:i:s') . "\n");
            fwrite($fh, "-- Instancia: " . systemSetting('nombre_instancia', 'Master Inventario') . "\n\n");
            fwrite($fh, "SET FOREIGN_KEY_CHECKS=0;\n\n");

            $tablesResult = $conn->query("SHOW TABLES");
            if ($tablesResult) {
                $ok = true;
                while ($tableRow = $tablesResult->fetch_array(MYSQLI_NUM)) {
                    $table = $tableRow[0];
                    $tableSafe = str_replace('`', '``', $table);

                    $createResult = $conn->query("SHOW CREATE TABLE `{$tableSafe}`");
                    if (!$createResult) continue;
                    $createRow = $createResult->fetch_assoc();
                    if (!$createRow || !isset($createRow['Create Table'])) continue;

                    fwrite($fh, "-- --------------------------------------------------------\n");
                    fwrite($fh, "-- Tabla: {$table}\n");
                    fwrite($fh, "DROP TABLE IF EXISTS `{$tableSafe}`;\n");
                    fwrite($fh, $createRow['Create Table'] . ";\n\n");

                    $dataResult = $conn->query("SELECT * FROM `{$tableSafe}`");
                    if ($dataResult && $dataResult->num_rows > 0) {
                        while ($dataRow = $dataResult->fetch_assoc()) {
                            $values = [];
                            foreach ($dataRow as $value) {
                                if ($value === null) {
                                    $values[] = 'NULL';
                                } else {
                                    $values[] = "'" . $conn->real_escape_string((string)$value) . "'";
                                }
                            }
                            fwrite($fh, "INSERT INTO `{$tableSafe}` VALUES (" . implode(', ', $values) . ");\n");
                        }
                        fwrite($fh, "\n");
                    }
                }
            }

            fwrite($fh, "SET FOREIGN_KEY_CHECKS=1;\n");
            fclose($fh);
        }

        if ($ok && file_exists($backupAbsolutePath)) {
            $flash_message = 'Respaldo SQL generado correctamente.';
            $flash_type    = 'success';
        } else {
            $flash_message = 'No se pudo generar el respaldo SQL.';
            $flash_type    = 'error';
            $backup_file_relative = '';
        }
    } else {
        $currentSettings = getSystemSettings();

        $umbral_stock_bajo = max(0, (int)($_POST['umbral_stock_bajo'] ?? 5));
        $permitir_inventario_negativo = isset($_POST['permitir_inventario_negativo']) ? 1 : 0;
        $categorizacion_automatica = isset($_POST['categorizacion_automatica']) ? 1 : 0;
        $modo_oscuro_permanente = isset($_POST['modo_oscuro_permanente']) ? 1 : 0;
        $logs_actividad = isset($_POST['logs_actividad']) ? 1 : 0;

        $tamano_fuente = $_POST['tamano_fuente'] ?? 'mediano';
        if (!in_array($tamano_fuente, ['pequeño', 'mediano', 'grande'], true)) {
            $tamano_fuente = 'mediano';
        }

        $nombre_instancia = trim((string)($_POST['nombre_instancia'] ?? 'Master Inventario'));
        if ($nombre_instancia === '') $nombre_instancia = 'Master Inventario';
        $nombre_instancia = mb_substr($nombre_instancia, 0, 120);

        $color_acento = normalizeHexColor($_POST['color_acento'] ?? '#5d87ff', '#5d87ff');
        $banner_overlay_color = normalizeHexColor($_POST['banner_overlay_color'] ?? '#0f172a', '#0f172a');
        $banner_overlay_opacidad = max(0.15, min(0.90, (float)($_POST['banner_overlay_opacidad'] ?? 0.56)));
        $banner_texto_primario = normalizeHexColor($_POST['banner_texto_primario'] ?? '#ffffff', '#ffffff');
        $banner_texto_secundario = normalizeHexColor($_POST['banner_texto_secundario'] ?? '#e2e8f0', '#e2e8f0');

        $moneda_codigo = $_POST['moneda_codigo'] ?? 'MXN';
        if (!isset($currency_map[$moneda_codigo])) $moneda_codigo = 'MXN';

        $posicion_moneda = $_POST['posicion_moneda'] ?? 'antes';
        if (!in_array($posicion_moneda, ['antes', 'despues'], true)) $posicion_moneda = 'antes';

        $formato_fecha = $_POST['formato_fecha'] ?? 'd/m/Y';
        if (!isset($date_format_options[$formato_fecha])) $formato_fecha = 'd/m/Y';

        $formato_hora = $_POST['formato_hora'] ?? 'H:i';
        if (!isset($time_format_options[$formato_hora])) $formato_hora = 'H:i';

        $zona_horaria = $_POST['zona_horaria'] ?? 'America/Mexico_City';
        if (!in_array($zona_horaria, timezone_identifiers_list(), true)) $zona_horaria = 'America/Mexico_City';

        $densidad_tablas = $_POST['densidad_tablas'] ?? 'comoda';
        if (!in_array($densidad_tablas, ['comoda', 'compacta'], true)) $densidad_tablas = 'comoda';
        // ── Banner global de módulos ──────────────────────────────────
        $banner_imagen = $currentSettings['banner_imagen'] ?? null;
        $bannerUploadErrorMessage = '';
        $bannerUploadAttempted = !empty($_FILES['banner_imagen']['name'])
            || (int)($_FILES['banner_imagen']['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_NO_FILE;
        if (!empty($_POST['remove_banner_imagen'])) {
            if (!empty($banner_imagen) && str_starts_with((string)$banner_imagen, 'assets/images/breadcrumb/')) {
                $oldBanner = __DIR__ . '/' . $banner_imagen;
                if (file_exists($oldBanner)) @unlink($oldBanner);
            }
            $banner_imagen = null;
        } elseif ($bannerUploadAttempted) {
            $bannerErrorCode = (int)($_FILES['banner_imagen']['error'] ?? UPLOAD_ERR_NO_FILE);
            if ($bannerErrorCode !== UPLOAD_ERR_OK) {
                $uploadErrors = [
                    UPLOAD_ERR_INI_SIZE   => 'El archivo del banner supera el límite del servidor.',
                    UPLOAD_ERR_FORM_SIZE  => 'El archivo del banner supera el límite permitido por el formulario.',
                    UPLOAD_ERR_PARTIAL    => 'La carga del banner quedó incompleta. Intenta nuevamente.',
                    UPLOAD_ERR_NO_TMP_DIR => 'Falta la carpeta temporal del servidor para cargar el banner.',
                    UPLOAD_ERR_CANT_WRITE => 'No se pudo escribir el archivo del banner en disco.',
                    UPLOAD_ERR_EXTENSION  => 'Una extensión del servidor bloqueó la carga del banner.',
                    UPLOAD_ERR_NO_FILE    => 'No se seleccionó ninguna imagen de banner.',
                ];
                $bannerUploadErrorMessage = $uploadErrors[$bannerErrorCode] ?? 'No se pudo cargar la imagen del banner.';
            } else {
                $bannerTmp  = $_FILES['banner_imagen']['tmp_name'];
                $bannerSize = (int)($_FILES['banner_imagen']['size'] ?? 0);
                $bannerAllowedMimes = [
                    'image/jpeg'     => 'jpg',
                    'image/png'      => 'png',
                    'image/webp'     => 'webp',
                    'image/gif'      => 'gif',
                    'image/bmp'      => 'bmp',
                    'image/x-ms-bmp' => 'bmp',
                    'image/avif'     => 'avif',
                ];

                if (!is_uploaded_file($bannerTmp)) {
                    $bannerUploadErrorMessage = 'No se detectó un archivo válido para el banner.';
                } elseif ($bannerSize > 12 * 1024 * 1024) {
                    $bannerUploadErrorMessage = 'La imagen del banner supera el tamaño máximo de 12 MB.';
                } else {
                    $bannerInfo = @getimagesize($bannerTmp);
                    $bannerMime = is_array($bannerInfo) && !empty($bannerInfo['mime']) ? strtolower((string)$bannerInfo['mime']) : '';
                    if (!isset($bannerAllowedMimes[$bannerMime])) {
                        $bannerUploadErrorMessage = 'Formato de imagen no permitido. Usa JPG, PNG, WEBP, GIF, BMP o AVIF.';
                    } else {
                        $bannerExt = $bannerAllowedMimes[$bannerMime];
                        $bannerDir = __DIR__ . '/assets/images/breadcrumb';
                        if (!is_dir($bannerDir) && !@mkdir($bannerDir, 0755, true) && !is_dir($bannerDir)) {
                            $bannerUploadErrorMessage = 'No se pudo crear la carpeta de destino para el banner.';
                        } else {
                            try {
                                $token = bin2hex(random_bytes(5));
                            } catch (Throwable $e) {
                                $token = uniqid('', true);
                            }
                            $token = preg_replace('/[^a-zA-Z0-9]/', '', (string)$token);
                            $bannerName = 'banner_' . date('Ymd_His') . '_' . $token . '.' . $bannerExt;
                            $bannerDest = $bannerDir . '/' . $bannerName;

                            if (@move_uploaded_file($bannerTmp, $bannerDest)) {
                                if (!empty($banner_imagen) && str_starts_with((string)$banner_imagen, 'assets/images/breadcrumb/')) {
                                    $oldBanner = __DIR__ . '/' . $banner_imagen;
                                    if (file_exists($oldBanner)) @unlink($oldBanner);
                                }
                                $banner_imagen = 'assets/images/breadcrumb/' . $bannerName;
                            } else {
                                $bannerUploadErrorMessage = 'No se pudo guardar la imagen del banner en el servidor.';
                            }
                        }
                    }
                }
            }
        }

        // ── Background image ──────────────────────────────────────────
        $bg_imagen  = $currentSettings['bg_imagen'] ?? null;
        $bg_opacidad = max(0.03, min(0.80, (float)($_POST['bg_opacidad'] ?? 0.22)));

        // Remove background if requested
        if (!empty($_POST['remove_bg_imagen'])) {
            if (!empty($bg_imagen)) {
                $oldBg = __DIR__ . '/' . $bg_imagen;
                if (file_exists($oldBg)) @unlink($oldBg);
            }
            $bg_imagen = null;
        } elseif (!empty($_FILES['bg_imagen']['name']) && (int)($_FILES['bg_imagen']['error'] ?? UPLOAD_ERR_NO_FILE) === UPLOAD_ERR_OK) {
            $bgTmp  = $_FILES['bg_imagen']['tmp_name'];
            $bgExt  = strtolower(pathinfo($_FILES['bg_imagen']['name'], PATHINFO_EXTENSION));
            $bgMime = mime_content_type($bgTmp);
            $bgAllowedMimes = ['image/jpeg','image/png','image/webp','image/gif'];
            $bgAllowedExts  = ['jpg','jpeg','png','webp','gif'];

            if (in_array($bgMime, $bgAllowedMimes, true) && in_array($bgExt, $bgAllowedExts, true) && $_FILES['bg_imagen']['size'] <= 5 * 1024 * 1024) {
                $bgDir = __DIR__ . '/assets/images/bg';
                if (!is_dir($bgDir)) @mkdir($bgDir, 0755, true);
                try { $token = bin2hex(random_bytes(5)); } catch (Throwable $e) { $token = uniqid(); }
                $bgName  = 'bg_' . date('Ymd_His') . '_' . $token . '.' . $bgExt;
                $bgDest  = $bgDir . '/' . $bgName;
                if (@move_uploaded_file($bgTmp, $bgDest)) {
                    if (!empty($bg_imagen) && str_starts_with((string)$bg_imagen, 'assets/images/bg/')) {
                        $oldBg = __DIR__ . '/' . $bg_imagen;
                        if (file_exists($oldBg)) @unlink($oldBg);
                    }
                    $bg_imagen = 'assets/images/bg/' . $bgName;
                }
            }
        }

        $logo_path = $currentSettings['logo_path'] ?? null;
        $logoUploadError = false;
        if (!empty($_FILES['logo_corporativo']['name']) && (int)($_FILES['logo_corporativo']['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_NO_FILE) {
            if ((int)$_FILES['logo_corporativo']['error'] === UPLOAD_ERR_OK) {
                $uploadDir = __DIR__ . '/assets/uploads/logos';
                if (!is_dir($uploadDir)) {
                    @mkdir($uploadDir, 0775, true);
                }

                $tmp = $_FILES['logo_corporativo']['tmp_name'];
                $ext = strtolower(pathinfo($_FILES['logo_corporativo']['name'], PATHINFO_EXTENSION));
                $allowedExt = ['png', 'jpg', 'jpeg', 'svg', 'webp'];

                if (!in_array($ext, $allowedExt, true)) {
                    $logoUploadError = true;
                } else {
                    try {
                        $token = bin2hex(random_bytes(5));
                    } catch (Throwable $e) {
                        $token = uniqid('logo_', true);
                    }
                    $newName = 'logo_' . date('Ymd_His') . '_' . preg_replace('/[^a-zA-Z0-9_]/', '', (string)$token) . '.' . $ext;
                    $absoluteTarget = $uploadDir . '/' . $newName;
                    $relativeTarget = 'assets/uploads/logos/' . $newName;

                    if (@move_uploaded_file($tmp, $absoluteTarget)) {
                        if (!empty($logo_path) && str_starts_with((string)$logo_path, 'assets/uploads/logos/')) {
                            $oldAbs = __DIR__ . '/' . $logo_path;
                            if (file_exists($oldAbs)) @unlink($oldAbs);
                        }
                        $logo_path = $relativeTarget;
                    } else {
                        $logoUploadError = true;
                    }
                }
            } else {
                $logoUploadError = true;
            }
        }

        $stmt = $conn->prepare(
            "UPDATE configuracion_sistema_global
             SET umbral_stock_bajo = ?,
                 permitir_inventario_negativo = ?,
                 categorizacion_automatica = ?,
                 logo_path = ?,
                 banner_imagen = ?,
                 banner_overlay_color = ?,
                 banner_overlay_opacidad = ?,
                 banner_texto_primario = ?,
                 banner_texto_secundario = ?,
                 color_acento = ?,
                 nombre_instancia = ?,
                 moneda_codigo = ?,
                 posicion_moneda = ?,
                 formato_fecha = ?,
                 formato_hora = ?,
                 zona_horaria = ?,
                 densidad_tablas = ?,
                 modo_oscuro_permanente = ?,
                 logs_actividad = ?,
                 tamano_fuente = ?,
                 bg_imagen = ?,
                 bg_opacidad = ?
             WHERE id = 1"
        );

        if ($stmt) {
            $stmt->bind_param(
                "iiisssdssssssssssiissd",
                $umbral_stock_bajo,
                $permitir_inventario_negativo,
                $categorizacion_automatica,
                $logo_path,
                $banner_imagen,
                $banner_overlay_color,
                $banner_overlay_opacidad,
                $banner_texto_primario,
                $banner_texto_secundario,
                $color_acento,
                $nombre_instancia,
                $moneda_codigo,
                $posicion_moneda,
                $formato_fecha,
                $formato_hora,
                $zona_horaria,
                $densidad_tablas,
                $modo_oscuro_permanente,
                $logs_actividad,
                $tamano_fuente,
                $bg_imagen,
                $bg_opacidad
            );
            if ($stmt->execute()) {
                refreshSystemSettings($conn);
                $warnings = [];
                if ($logoUploadError) {
                    $warnings[] = 'no se pudo cargar el logotipo';
                }
                if ($bannerUploadErrorMessage !== '') {
                    $warnings[] = mb_strtolower($bannerUploadErrorMessage);
                }
                if (!empty($warnings)) {
                    $flash_message = 'Configuración guardada, pero ' . implode(' y ', $warnings);
                    $flash_type = 'warning';
                } else {
                    $flash_message = 'Configuración guardada correctamente.';
                    $flash_type = 'success';
                }
            } else {
                $flash_message = 'No se pudo guardar la configuración.';
                $flash_type    = 'error';
            }
            $stmt->close();
        } else {
            $flash_message = 'No se pudo preparar la actualización de configuración.';
            $flash_type    = 'error';
        }
    }
}

$settings = getSystemSettings();
$currentLogo = appResolveLogoPath();
$currentBanner = appResolveBannerPath();
$customBannerPath = (string)($settings['banner_imagen'] ?? '');
$hasCustomBanner = ($customBannerPath !== '' && file_exists(__DIR__ . '/' . $customBannerPath));
$currentBannerVersion = file_exists(__DIR__ . '/' . $currentBanner)
    ? (string)filemtime(__DIR__ . '/' . $currentBanner)
    : (string)time();
$currentBannerUrl = $currentBanner . '?v=' . $currentBannerVersion;
$bannerFileDisplayName = $hasCustomBanner
    ? basename($customBannerPath)
    : basename($currentBanner);
$bannerOverlayColorValue = normalizeHexColor((string)($settings['banner_overlay_color'] ?? '#0f172a'), '#0f172a');
$bannerOverlayOpacityValue = max(0.15, min(0.90, (float)($settings['banner_overlay_opacidad'] ?? 0.56)));
$bannerTextPrimaryValue = normalizeHexColor((string)($settings['banner_texto_primario'] ?? '#ffffff'), '#ffffff');
$bannerTextSecondaryValue = normalizeHexColor((string)($settings['banner_texto_secundario'] ?? '#e2e8f0'), '#e2e8f0');

$currentBannerAbsolute = __DIR__ . '/' . ltrim($currentBanner, '/');
$bannerDimensionLabel = 'Resolución actual: adaptable';
$bannerSizeData = @getimagesize($currentBannerAbsolute);
if (is_array($bannerSizeData) && !empty($bannerSizeData[0]) && !empty($bannerSizeData[1])) {
    $bannerDimensionLabel = 'Resolución actual: ' . (int)$bannerSizeData[0] . ' × ' . (int)$bannerSizeData[1] . ' px';
}

if (!isset($timezone_options[$settings['zona_horaria']])) {
    $timezone_options[$settings['zona_horaria']] = $settings['zona_horaria'];
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

<div class="page-banner">
    <div class="page-banner-content">
        <h1>Configuración del Sistema</h1>
        <div class="page-banner-breadcrumb">
            <a href="dashboard.php">Inicio</a>
            <span class="sep">•</span>
            <span>Configuración</span>
        </div>
    </div>
    <img src="<?= htmlspecialchars($currentBanner, ENT_QUOTES, 'UTF-8') ?>?v=<?= htmlspecialchars($currentBannerVersion, ENT_QUOTES, 'UTF-8') ?>" alt="Banner de configuración del sistema" class="page-banner-img">
</div>

<div class="module-shell">
    <form action="configuracion_sistema.php" method="post" enctype="multipart/form-data" class="settings-panel-form">
        <input type="hidden" name="action" value="save_settings">

        <div class="settings-grid">
            <section class="surface-card settings-section">
                <div class="settings-section-head">
                    <h3><i class="fas fa-boxes-stacked"></i> Reglas de Inventario</h3>
                    <p>Controla alertas y comportamiento operativo del stock.</p>
                </div>

                <div class="form-group">
                    <label class="form-label" for="umbral_stock_bajo">Umbral de Stock Bajo</label>
                    <input type="number" min="0" class="form-control" id="umbral_stock_bajo" name="umbral_stock_bajo" value="<?= (int)$settings['umbral_stock_bajo'] ?>" required>
                    <span class="form-helper">Cuando la cantidad disponible sea menor o igual a este valor, el producto se marcará en alerta amarilla.</span>
                </div>

                <label class="switch-row" for="permitir_inventario_negativo">
                    <span class="switch-copy">
                        <strong>Permitir Inventario Negativo</strong>
                        <small>Autoriza registrar ventas incluso sin stock físico.</small>
                    </span>
                    <span class="switch-control">
                        <input type="checkbox" id="permitir_inventario_negativo" name="permitir_inventario_negativo" <?= !empty($settings['permitir_inventario_negativo']) ? 'checked' : '' ?>>
                        <span class="switch-slider"></span>
                    </span>
                </label>

                <label class="switch-row" for="categorizacion_automatica">
                    <span class="switch-copy">
                        <strong>Categorización Automática</strong>
                        <small>Sugiere categorías por nombre de producto (y proveedor cuando esté disponible).</small>
                    </span>
                    <span class="switch-control">
                        <input type="checkbox" id="categorizacion_automatica" name="categorizacion_automatica" <?= !empty($settings['categorizacion_automatica']) ? 'checked' : '' ?>>
                        <span class="switch-slider"></span>
                    </span>
                </label>
            </section>

            <section class="surface-card settings-section">
                <div class="settings-section-head">
                    <h3><i class="fas fa-palette"></i> Identidad y Branding</h3>
                    <p>Personaliza la apariencia principal de la instancia.</p>
                </div>

                <div class="form-grid-two">
                    <div class="form-group">
                        <label class="form-label" for="nombre_instancia">Nombre de la Instancia</label>
                        <input type="text" class="form-control" id="nombre_instancia" name="nombre_instancia" maxlength="120" value="<?= htmlspecialchars((string)$settings['nombre_instancia'], ENT_QUOTES, 'UTF-8') ?>" required>
                        <span class="form-helper">Se muestra en el título del navegador y encabezados de reportes.</span>
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="color_acento">Color de Acento</label>
                        <input type="color" class="form-control form-color-picker" id="color_acento" name="color_acento" value="<?= htmlspecialchars((string)$settings['color_acento'], ENT_QUOTES, 'UTF-8') ?>">
                        <span class="form-helper">Afecta botones, banners y elementos destacados.</span>
                    </div>
                </div>

                <div class="form-group">
                    <label class="form-label" for="logo_corporativo">Logotipo Corporativo</label>
                    <input type="file" class="form-control" id="logo_corporativo" name="logo_corporativo" accept=".png,.jpg,.jpeg,.svg,.webp">
                    <span class="form-helper">Sube PNG, JPG, SVG o WEBP para reemplazar el logo actual del sistema.</span>
                </div>

                <div class="settings-logo-preview">
                    <img src="<?= htmlspecialchars($currentLogo, ENT_QUOTES, 'UTF-8') ?>" alt="Vista previa del logo">
                    <span>Logo activo</span>
                </div>
            </section>

            <section class="surface-card settings-section settings-section-banner-global">
                <div class="banner-settings-panel">
                    <div class="settings-section-head banner-settings-head">
                        <h3><i class="fas fa-panorama"></i> Banner Global de Módulos</h3>
                        <p>Ajusta imagen, contraste y colores del encabezado en un apartado dedicado.</p>
                    </div>
                    <div class="banner-settings-layout">
                    <div class="banner-settings-block">

                <div class="form-group">
                    <label class="form-label" for="banner_imagen">Imagen de Banner Global</label>
                    <input type="file" class="form-control" id="banner_imagen" name="banner_imagen" accept="image/*">
                    <div class="banner-upload-status">
                        <span>Estado de carga:</span>
                        <strong id="bannerUploadFilename"><?= htmlspecialchars((string)$bannerFileDisplayName, ENT_QUOTES, 'UTF-8') ?></strong>
                    </div>
                    <span class="banner-upload-meta" id="bannerUploadMeta"><?= htmlspecialchars($bannerDimensionLabel, ENT_QUOTES, 'UTF-8') ?></span>
                    <span class="form-helper banner-global-helper">Este banner se aplicará y ajustará automáticamente a todos los módulos. Los colores de la interfaz se han adaptado para un contraste óptimo.</span>
                    <span class="form-helper">Acepta imágenes de cualquier dimensión (sin restricción de ancho/alto). Recomendado para mayor nitidez: 1600 × 320 px o superior. Tamaño máximo: 12 MB.</span>
                </div>
                <div class="banner-global-studio" id="bannerGlobalStudio" data-initial-banner="<?= htmlspecialchars($currentBannerUrl, ENT_QUOTES, 'UTF-8') ?>">
                    <div class="banner-global-preview-shell">
                        <div class="banner-global-preview-topbar">
                            <span class="banner-preview-dot"></span>
                            <span class="banner-preview-dot"></span>
                            <span class="banner-preview-dot"></span>
                            <strong>Previsualización dinámica del encabezado global</strong>
                        </div>
                        <div class="banner-global-preview-body">
                            <aside class="banner-global-preview-sidebar">
                                <h5>Inventario</h5>
                                <ul>
                                    <li><i class="fas fa-chart-line"></i><span>Dashboard</span></li>
                                    <li><i class="fas fa-boxes-stacked"></i><span>Inventario</span></li>
                                    <li><i class="fas fa-cart-shopping"></i><span>Ventas</span></li>
                                    <li><i class="fas fa-truck"></i><span>Compras</span></li>
                                    <li><i class="fas fa-file-lines"></i><span>Reportes</span></li>
                                </ul>
                            </aside>
                            <section class="banner-global-preview-main">
                                <div class="banner-global-preview-header" id="bannerGlobalPreviewHeader" style="background-image:url('<?= htmlspecialchars($currentBannerUrl, ENT_QUOTES, 'UTF-8') ?>');">
                                    <div class="banner-global-preview-overlay" id="bannerGlobalPreviewOverlay"></div>
                                    <div class="banner-global-preview-content">
                                        <h4 id="bannerPreviewTitle">Inventario</h4>
                                        <p id="bannerPreviewSubtitle">Encabezado adaptado automáticamente para todos los módulos</p>
                                    </div>
                                </div>
                                <div class="banner-global-preview-cards">
                                    <article class="banner-mini-card">
                                        <span>Productos activos</span>
                                        <strong>1,248</strong>
                                    </article>
                                    <article class="banner-mini-card">
                                        <span>Alertas pendientes</span>
                                        <strong>07</strong>
                                    </article>
                                    <article class="banner-mini-card">
                                        <span>Operación global</span>
                                        <strong>Estable</strong>
                                    </article>
                                </div>
                            </section>
                        </div>
                    </div>
                    <aside class="banner-color-results">
                        <h4>Resultados de la Adaptación de Color</h4>
                        <div class="banner-color-sample">
                            <span class="banner-color-chip" id="bannerColorBgChip"></span>
                            <div>
                                <strong>Fondo</strong>
                                <small id="bannerColorBgValue">#1f2937</small>
                            </div>
                        </div>
                        <div class="banner-color-sample">
                            <span class="banner-color-chip" id="bannerColorPrimaryChip"></span>
                            <div>
                                <strong>Texto primario</strong>
                                <small id="bannerColorPrimaryValue">#f8fafc</small>
                            </div>
                        </div>
                        <div class="banner-color-sample">
                            <span class="banner-color-chip" id="bannerColorSecondaryChip"></span>
                            <div>
                                <strong>Texto secundario</strong>
                                <small id="bannerColorSecondaryValue">#cbd5e1</small>
                            </div>
                        </div>
                        <div class="banner-contrast-report">
                            <div class="banner-contrast-item" id="bannerContrastPrimaryItem">
                                <span><i class="fas fa-circle-check"></i> Contraste texto primario</span>
                                <strong id="bannerContrastPrimaryValue">7.1:1</strong>
                            </div>
                            <div class="banner-contrast-item" id="bannerContrastSecondaryItem">
                                <span><i class="fas fa-circle-check"></i> Contraste texto secundario</span>
                                <strong id="bannerContrastSecondaryValue">4.8:1</strong>
                            </div>
                        </div>
                    </aside>
                </div>
                </div>
                <div class="banner-settings-block banner-settings-block-controls">
                <div class="banner-color-controls">
                    <div class="form-group">
                        <label class="form-label" for="banner_overlay_color">Color de superposición</label>
                        <input type="color" class="form-control form-color-picker" id="banner_overlay_color" name="banner_overlay_color" value="<?= htmlspecialchars($bannerOverlayColorValue, ENT_QUOTES, 'UTF-8') ?>">
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="banner_overlay_opacidad">Intensidad de superposición <strong id="bannerOverlayOpacityValue"><?= (int)round($bannerOverlayOpacityValue * 100) ?>%</strong></label>
                        <input type="range" class="bg-opacity-slider" id="banner_overlay_opacidad" name="banner_overlay_opacidad" min="0.15" max="0.90" step="0.01" value="<?= htmlspecialchars((string)$bannerOverlayOpacityValue, ENT_QUOTES, 'UTF-8') ?>">
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="banner_texto_primario">Texto primario del banner</label>
                        <input type="color" class="form-control form-color-picker" id="banner_texto_primario" name="banner_texto_primario" value="<?= htmlspecialchars($bannerTextPrimaryValue, ENT_QUOTES, 'UTF-8') ?>">
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="banner_texto_secundario">Texto secundario del banner</label>
                        <input type="color" class="form-control form-color-picker" id="banner_texto_secundario" name="banner_texto_secundario" value="<?= htmlspecialchars($bannerTextSecondaryValue, ENT_QUOTES, 'UTF-8') ?>">
                    </div>
                </div>

                <div class="banner-global-actions">
                    <span class="form-helper">Banner activo en módulos: <strong><?= htmlspecialchars((string)$bannerFileDisplayName, ENT_QUOTES, 'UTF-8') ?></strong></span>
                        <?php if ($hasCustomBanner): ?>
                        <button type="submit" name="remove_banner_imagen" value="1" class="btn-danger-sm" onclick="return confirm('¿Eliminar banner personalizado?');">
                            <i class="fas fa-trash-alt"></i> Eliminar banner
                        </button>
                        <?php endif; ?>
                </div>
                </div>
                </div>
                </div>
            </section>

            <!-- ── Fondo del Sistema ── -->
            <section class="surface-card settings-section">
                <div class="settings-section-head">
                    <h3><i class="fas fa-image"></i> Fondo del Sistema</h3>
                    <p>Sube una imagen de fondo personalizada y ajusta su visibilidad en tiempo real.</p>
                </div>

                <div class="form-group">
                    <label class="form-label" for="bg_imagen">Imagen de Fondo</label>
                    <input type="file" class="form-control" id="bg_imagen" name="bg_imagen"
                           accept=".jpg,.jpeg,.png,.webp,.gif">
                    <span class="form-helper">PNG, JPG, WEBP o GIF · máximo 5 MB. Se mostrará como patrón de fondo en todo el sistema.</span>
                </div>

                <?php
                    $currentBg = (string)($settings['bg_imagen'] ?? '');
                    $hasBg     = ($currentBg !== '' && file_exists(__DIR__ . '/' . $currentBg));
                    $bgOpVal   = (float)($settings['bg_opacidad'] ?? 0.22);
                ?>

                <?php if ($hasBg): ?>
                <div class="bg-preview-wrap">
                    <img src="<?= htmlspecialchars($currentBg, ENT_QUOTES) ?>?v=<?= filemtime(__DIR__ . '/' . $currentBg) ?>"
                         alt="Fondo activo" class="bg-preview-thumb">
                    <div class="bg-preview-meta">
                        <span class="form-helper">Fondo activo</span>
                        <button type="submit" name="remove_bg_imagen" value="1"
                                class="btn-danger-sm"
                                onclick="return confirm('¿Eliminar el fondo personalizado?')">
                            <i class="fas fa-trash-alt"></i> Eliminar fondo
                        </button>
                    </div>
                </div>
                <?php endif; ?>

                <div class="form-group" style="margin-top:20px;">
                    <label class="form-label" for="bg_opacidad">
                        Tonalidad / Opacidad
                        <strong id="bg_opacity_val"><?= round($bgOpVal * 100) ?>%</strong>
                    </label>
                    <input type="range" class="bg-opacity-slider" id="bg_opacidad" name="bg_opacidad"
                           min="0.03" max="0.80" step="0.01"
                           value="<?= $bgOpVal ?>"
                           oninput="updateBgOpacity(this.value)">
                    <div class="bg-opacity-labels">
                        <span>Muy sutil</span>
                        <span>Equilibrado</span>
                        <span>Intenso</span>
                    </div>
                </div>

                <!-- Live preview strip -->
                <div class="bg-live-preview" id="bgLivePreview"
                     style="background-image:url('<?= $hasBg ? htmlspecialchars($currentBg, ENT_QUOTES) : 'assets/images/bg/pattern-bg.png' ?>'); opacity:<?= $bgOpVal ?>;">
                </div>
            </section>

            <section class="surface-card settings-section">
                <div class="settings-section-head">
                    <h3><i class="fas fa-earth-americas"></i> Configuración Regional y Formatos</h3>
                    <p>Define moneda, fecha, hora y zona horaria de operación.</p>
                </div>

                <div class="form-grid-two">
                    <div class="form-group">
                        <label class="form-label" for="moneda_codigo">Moneda</label>
                        <select class="form-control" id="moneda_codigo" name="moneda_codigo">
                            <?php foreach ($currency_map as $code => $meta): ?>
                            <option value="<?= htmlspecialchars($code, ENT_QUOTES, 'UTF-8') ?>" <?= $settings['moneda_codigo'] === $code ? 'selected' : '' ?>>
                                <?= htmlspecialchars($meta['label'], ENT_QUOTES, 'UTF-8') ?>
                            </option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="posicion_moneda">Posición del símbolo</label>
                        <select class="form-control" id="posicion_moneda" name="posicion_moneda">
                            <option value="antes" <?= $settings['posicion_moneda'] === 'antes' ? 'selected' : '' ?>>Antes del monto</option>
                            <option value="despues" <?= $settings['posicion_moneda'] === 'despues' ? 'selected' : '' ?>>Después del monto</option>
                        </select>
                    </div>
                </div>

                <div class="form-grid-two">
                    <div class="form-group">
                        <label class="form-label" for="formato_fecha">Formato de Fecha</label>
                        <select class="form-control" id="formato_fecha" name="formato_fecha">
                            <?php foreach ($date_format_options as $fmt => $label): ?>
                            <option value="<?= htmlspecialchars($fmt, ENT_QUOTES, 'UTF-8') ?>" <?= $settings['formato_fecha'] === $fmt ? 'selected' : '' ?>>
                                <?= htmlspecialchars($label, ENT_QUOTES, 'UTF-8') ?>
                            </option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="formato_hora">Formato de Hora</label>
                        <select class="form-control" id="formato_hora" name="formato_hora">
                            <?php foreach ($time_format_options as $fmt => $label): ?>
                            <option value="<?= htmlspecialchars($fmt, ENT_QUOTES, 'UTF-8') ?>" <?= $settings['formato_hora'] === $fmt ? 'selected' : '' ?>>
                                <?= htmlspecialchars($label, ENT_QUOTES, 'UTF-8') ?>
                            </option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                </div>

                <div class="form-group">
                    <label class="form-label" for="zona_horaria">Zona Horaria</label>
                    <select class="form-control" id="zona_horaria" name="zona_horaria">
                        <?php foreach ($timezone_options as $tz => $label): ?>
                        <option value="<?= htmlspecialchars($tz, ENT_QUOTES, 'UTF-8') ?>" <?= $settings['zona_horaria'] === $tz ? 'selected' : '' ?>>
                            <?= htmlspecialchars($label, ENT_QUOTES, 'UTF-8') ?>
                        </option>
                        <?php endforeach; ?>
                    </select>
                </div>
            </section>

            <section class="surface-card settings-section">
                <div class="settings-section-head">
                    <h3><i class="fas fa-desktop"></i> Preferencias de Visualización y Seguridad</h3>
                    <p>Ajusta densidad visual, tema y auditoría de movimientos.</p>
                </div>

                <div class="form-grid-two">
                    <div class="form-group">
                        <label class="form-label" for="densidad_tablas">Densidad de Tablas</label>
                        <select class="form-control" id="densidad_tablas" name="densidad_tablas">
                            <option value="comoda" <?= $settings['densidad_tablas'] === 'comoda' ? 'selected' : '' ?>>Cómoda</option>
                            <option value="compacta" <?= $settings['densidad_tablas'] === 'compacta' ? 'selected' : '' ?>>Compacta</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="tamano_fuente">Tamaño de Fuente Base</label>
                        <select class="form-control" id="tamano_fuente" name="tamano_fuente">
                            <option value="pequeño" <?= $settings['tamano_fuente'] === 'pequeño' ? 'selected' : '' ?>>Pequeño</option>
                            <option value="mediano" <?= $settings['tamano_fuente'] === 'mediano' ? 'selected' : '' ?>>Mediano</option>
                            <option value="grande" <?= $settings['tamano_fuente'] === 'grande' ? 'selected' : '' ?>>Grande</option>
                        </select>
                    </div>
                </div>

                <label class="switch-row" for="modo_oscuro_permanente">
                    <span class="switch-copy">
                        <strong>Modo Oscuro Permanente</strong>
                        <small>Fuerza el tema oscuro sin depender del sistema operativo.</small>
                    </span>
                    <span class="switch-control">
                        <input type="checkbox" id="modo_oscuro_permanente" name="modo_oscuro_permanente" <?= !empty($settings['modo_oscuro_permanente']) ? 'checked' : '' ?>>
                        <span class="switch-slider"></span>
                    </span>
                </label>

                <label class="switch-row" for="logs_actividad">
                    <span class="switch-copy">
                        <strong>Logs de Actividad (Inventario)</strong>
                        <small>Registra quién creó, editó o eliminó productos.</small>
                    </span>
                    <span class="switch-control">
                        <input type="checkbox" id="logs_actividad" name="logs_actividad" <?= !empty($settings['logs_actividad']) ? 'checked' : '' ?>>
                        <span class="switch-slider"></span>
                    </span>
                </label>
            </section>
        </div>

        <div class="form-actions-row">
            <button type="submit" class="btn-primary-master">
                <i class="fas fa-save"></i> Guardar Configuración
            </button>
        </div>
    </form>

    <div class="surface-card settings-section">
        <div class="settings-section-head">
            <h3><i class="fas fa-database"></i> Respaldo Automatizado</h3>
            <p>Genera una copia SQL inmediata de la base de datos.</p>
        </div>
        <form action="configuracion_sistema.php" method="post" class="form-actions-row">
            <input type="hidden" name="action" value="backup_sql">
            <button type="submit" class="btn-secondary-master">
                <i class="fas fa-file-arrow-down"></i> Generar Respaldo SQL
            </button>
            <?php if ($backup_file_relative): ?>
            <a href="<?= htmlspecialchars($backup_file_relative, ENT_QUOTES, 'UTF-8') ?>" download class="btn-primary-master">
                <i class="fas fa-download"></i> Descargar Respaldo
            </a>
            <?php endif; ?>
        </form>
        <span class="form-helper">El respaldo se guarda en la carpeta <code>backups/</code> del proyecto.</span>
    </div>
</div>

<script>
function updateBgOpacity(val) {
    var pct = Math.round(val * 100);
    var opacityLabel = document.getElementById('bg_opacity_val');
    if (opacityLabel) opacityLabel.textContent = pct + '%';
    var preview = document.getElementById('bgLivePreview');
    if (preview) preview.style.opacity = val;
    var tmpStyle = document.getElementById('__bg_tmp');
    if (!tmpStyle) {
        tmpStyle = document.createElement('style');
        tmpStyle.id = '__bg_tmp';
        document.head.appendChild(tmpStyle);
    }
    tmpStyle.textContent = 'body::before { opacity: ' + val + ' !important; }';
}

(function () {
    var studio = document.getElementById('bannerGlobalStudio');
    var bannerInput = document.getElementById('banner_imagen');
    var uploadFilenameEl = document.getElementById('bannerUploadFilename');
    var previewHeader = document.getElementById('bannerGlobalPreviewHeader');
    var previewOverlay = document.getElementById('bannerGlobalPreviewOverlay');

    var colorBgChip = document.getElementById('bannerColorBgChip');
    var colorPrimaryChip = document.getElementById('bannerColorPrimaryChip');
    var colorSecondaryChip = document.getElementById('bannerColorSecondaryChip');
    var colorBgValue = document.getElementById('bannerColorBgValue');
    var colorPrimaryValue = document.getElementById('bannerColorPrimaryValue');
    var colorSecondaryValue = document.getElementById('bannerColorSecondaryValue');
    var contrastPrimaryItem = document.getElementById('bannerContrastPrimaryItem');
    var contrastSecondaryItem = document.getElementById('bannerContrastSecondaryItem');
    var contrastPrimaryValue = document.getElementById('bannerContrastPrimaryValue');
    var contrastSecondaryValue = document.getElementById('bannerContrastSecondaryValue');
    var uploadMetaEl = document.getElementById('bannerUploadMeta');
    var overlayColorInput = document.getElementById('banner_overlay_color');
    var overlayOpacityInput = document.getElementById('banner_overlay_opacidad');
    var textPrimaryInput = document.getElementById('banner_texto_primario');
    var textSecondaryInput = document.getElementById('banner_texto_secundario');
    var overlayOpacityValueEl = document.getElementById('bannerOverlayOpacityValue');

    if (!studio || !previewHeader || !previewOverlay) return;

    var activeObjectUrl = null;
    var currentBgHex = '#1f2937';
    var initialUploadMeta = uploadMetaEl ? uploadMetaEl.textContent : '';

    function clamp(v, min, max) {
        return Math.min(max, Math.max(min, v));
    }

    function componentToHex(c) {
        var hex = clamp(Math.round(c), 0, 255).toString(16);
        return hex.length === 1 ? '0' + hex : hex;
    }

    function rgbToHex(r, g, b) {
        return '#' + componentToHex(r) + componentToHex(g) + componentToHex(b);
    }

    function hexToRgb(hex) {
        var clean = String(hex || '').replace('#', '');
        if (clean.length === 3) {
            clean = clean.split('').map(function (s) { return s + s; }).join('');
        }
        if (!/^[0-9a-fA-F]{6}$/.test(clean)) return { r: 31, g: 41, b: 55 };
        return {
            r: parseInt(clean.slice(0, 2), 16),
            g: parseInt(clean.slice(2, 4), 16),
            b: parseInt(clean.slice(4, 6), 16)
        };
    }

    function relativeLuminance(hex) {
        var rgb = hexToRgb(hex);
        function channel(v) {
            var c = v / 255;
            return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
        }
        var r = channel(rgb.r);
        var g = channel(rgb.g);
        var b = channel(rgb.b);
        return (0.2126 * r) + (0.7152 * g) + (0.0722 * b);
    }

    function contrastRatio(hexA, hexB) {
        var l1 = relativeLuminance(hexA);
        var l2 = relativeLuminance(hexB);
        var high = Math.max(l1, l2);
        var low = Math.min(l1, l2);
        return (high + 0.05) / (low + 0.05);
    }

    function setSwatch(chipEl, valueEl, hex) {
        if (chipEl) chipEl.style.backgroundColor = hex;
        if (valueEl) valueEl.textContent = hex.toUpperCase();
    }

    function setContrastRow(rowEl, valueEl, ratio) {
        if (!rowEl || !valueEl) return;
        var isPass = ratio >= 4.5;
        rowEl.classList.toggle('is-fail', !isPass);
        var icon = rowEl.querySelector('i');
        if (icon) {
            icon.className = isPass ? 'fas fa-circle-check' : 'fas fa-circle-xmark';
        }
        valueEl.textContent = ratio.toFixed(1) + ':1';
    }

    function updateBannerUploadMeta(text) {
        if (uploadMetaEl) uploadMetaEl.textContent = text;
    }

    function updateOverlayOpacityLabel(value) {
        if (!overlayOpacityValueEl) return;
        overlayOpacityValueEl.textContent = Math.round(value * 100) + '%';
    }

    function setColorInputValue(input, value) {
        if (!input) return;
        if (/^#[0-9a-fA-F]{6}$/.test(String(value || ''))) {
            input.value = value;
        }
    }

    function buildOverlayGradient(overlayHex, overlayOpacity) {
        var rgb = hexToRgb(overlayHex);
        var strong = clamp(overlayOpacity, 0.15, 0.90);
        var mid = Math.max(0.08, strong - 0.22);
        var soft = Math.max(0.04, strong - 0.40);
        return 'linear-gradient(108deg, rgba(' + rgb.r + ', ' + rgb.g + ', ' + rgb.b + ', ' + strong.toFixed(2) + ') 0%, rgba(' + rgb.r + ', ' + rgb.g + ', ' + rgb.b + ', ' + mid.toFixed(2) + ') 52%, rgba(' + rgb.r + ', ' + rgb.g + ', ' + rgb.b + ', ' + soft.toFixed(2) + ') 100%)';
    }

    function applyManualPalette() {
        var overlayHex = overlayColorInput ? overlayColorInput.value : '#0f172a';
        var overlayOpacity = overlayOpacityInput ? clamp(parseFloat(overlayOpacityInput.value || '0.56'), 0.15, 0.90) : 0.56;
        var textPrimary = textPrimaryInput ? textPrimaryInput.value : '#f8fafc';
        var textSecondary = textSecondaryInput ? textSecondaryInput.value : '#cbd5e1';

        previewHeader.style.setProperty('--banner-adapt-text-primary', textPrimary);
        previewHeader.style.setProperty('--banner-adapt-text-secondary', textSecondary);
        previewOverlay.style.background = buildOverlayGradient(overlayHex, overlayOpacity);

        setSwatch(colorBgChip, colorBgValue, currentBgHex);
        setSwatch(colorPrimaryChip, colorPrimaryValue, textPrimary);
        setSwatch(colorSecondaryChip, colorSecondaryValue, textSecondary);
        setContrastRow(contrastPrimaryItem, contrastPrimaryValue, contrastRatio(currentBgHex, textPrimary));
        setContrastRow(contrastSecondaryItem, contrastSecondaryValue, contrastRatio(currentBgHex, textSecondary));
        updateOverlayOpacityLabel(overlayOpacity);
    }

    function applyAdaptivePalette(baseHex, preserveCurrentInputs) {
        currentBgHex = baseHex || '#1f2937';
        if (preserveCurrentInputs) {
            applyManualPalette();
            return;
        }

        var bgLum = relativeLuminance(currentBgHex);
        var recommendedTextPrimary = bgLum > 0.58 ? '#0f172a' : '#f8fafc';
        var recommendedTextSecondary = bgLum > 0.58 ? '#334155' : '#cbd5e1';
        var recommendedOverlayColor = '#0f172a';
        var recommendedOverlayOpacity = bgLum > 0.58 ? 0.62 : 0.42;

        setColorInputValue(overlayColorInput, recommendedOverlayColor);
        if (overlayOpacityInput) overlayOpacityInput.value = recommendedOverlayOpacity.toFixed(2);
        setColorInputValue(textPrimaryInput, recommendedTextPrimary);
        setColorInputValue(textSecondaryInput, recommendedTextSecondary);

        applyManualPalette();
    }

    function getAverageColorFromImage(imageUrl, callback) {
        var image = new Image();
        image.decoding = 'async';
        if (!/^blob:/.test(imageUrl)) {
            image.crossOrigin = 'anonymous';
        }
        image.onload = function () {
            try {
                var canvas = document.createElement('canvas');
                var ctx = canvas.getContext('2d', { willReadFrequently: true });
                var targetWidth = 64;
                var targetHeight = 64;
                canvas.width = targetWidth;
                canvas.height = targetHeight;
                ctx.drawImage(image, 0, 0, targetWidth, targetHeight);
                var data = ctx.getImageData(0, 0, targetWidth, targetHeight).data;

                var r = 0, g = 0, b = 0, count = 0;
                for (var i = 0; i < data.length; i += 4) {
                    var alpha = data[i + 3];
                    if (alpha < 18) continue;
                    r += data[i];
                    g += data[i + 1];
                    b += data[i + 2];
                    count++;
                }

                if (!count) {
                    callback('#1f2937');
                    return;
                }

                callback(rgbToHex(r / count, g / count, b / count));
            } catch (err) {
                callback('#1f2937');
            }
        };
        image.onerror = function () {
            callback('#1f2937');
        };
        image.src = imageUrl;
    }

    function safeCssUrl(url) {
        return String(url || '').replace(/'/g, '%27');
    }

    function applyBannerPreview(imageUrl, loadedFilename, preserveCurrentInputs) {
        if (!imageUrl) return;
        previewHeader.style.backgroundImage = "url('" + safeCssUrl(imageUrl) + "')";
        if (loadedFilename && uploadFilenameEl) {
            uploadFilenameEl.textContent = loadedFilename;
        }
        getAverageColorFromImage(imageUrl, function (avgHex) {
            applyAdaptivePalette(avgHex, !!preserveCurrentInputs);
        });
    }

    function detectImageDimensions(file) {
        if (!file) return;
        var tempObjectUrl = URL.createObjectURL(file);
        var img = new Image();
        img.onload = function () {
            updateBannerUploadMeta('Resolución seleccionada: ' + img.naturalWidth + ' × ' + img.naturalHeight + ' px');
            URL.revokeObjectURL(tempObjectUrl);
        };
        img.onerror = function () {
            updateBannerUploadMeta('Resolución seleccionada: adaptable');
            URL.revokeObjectURL(tempObjectUrl);
        };
        img.src = tempObjectUrl;
    }

    var initialBannerUrl = studio.getAttribute('data-initial-banner') || '';
    [
        overlayColorInput,
        overlayOpacityInput,
        textPrimaryInput,
        textSecondaryInput
    ].forEach(function (inputEl) {
        if (!inputEl) return;
        inputEl.addEventListener('input', function () {
            applyManualPalette();
        });
    });
    if (initialBannerUrl) {
        applyBannerPreview(initialBannerUrl, uploadFilenameEl ? uploadFilenameEl.textContent : '', true);
    } else {
        applyManualPalette();
    }

    if (bannerInput) {
        bannerInput.addEventListener('change', function (event) {
            var file = event.target.files && event.target.files[0];
            if (!file) {
                updateBannerUploadMeta(initialUploadMeta || 'Resolución actual: adaptable');
                if (initialBannerUrl) applyBannerPreview(initialBannerUrl, uploadFilenameEl ? uploadFilenameEl.textContent : '', true);
                return;
            }

            if (activeObjectUrl) {
                URL.revokeObjectURL(activeObjectUrl);
                activeObjectUrl = null;
            }

            activeObjectUrl = URL.createObjectURL(file);
            detectImageDimensions(file);
            applyBannerPreview(activeObjectUrl, file.name || 'Mi_Nueva_Imagen_Banner.png', false);
        });
    }

    window.addEventListener('beforeunload', function () {
        if (activeObjectUrl) URL.revokeObjectURL(activeObjectUrl);
    });
})();
</script>

<?php include('layout/footer_main.php'); ?>
