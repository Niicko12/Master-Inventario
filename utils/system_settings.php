<?php
/**
 * Configuración global del sistema (singleton) + utilidades de formato/UI.
 */

function getSystemCurrencyMap(): array
{
    return [
        'MXN' => ['label' => '$ MXN', 'symbol' => '$ MXN'],
        'USD' => ['label' => 'USD $', 'symbol' => 'USD $'],
        'EUR' => ['label' => 'EUR €', 'symbol' => '€'],
    ];
}

function getSystemSettingsDefaults(): array
{
    return [
        'umbral_stock_bajo'            => 5,
        'permitir_inventario_negativo' => 0,
        'categorizacion_automatica'    => 0,
        'logo_path'                    => null,
        'banner_imagen'                => null,
        'banner_overlay_color'         => '#0f172a',
        'banner_overlay_opacidad'      => 0.56,
        'banner_texto_primario'        => '#ffffff',
        'banner_texto_secundario'      => '#e2e8f0',
        'color_acento'                 => '#5d87ff',
        'nombre_instancia'             => 'Master Inventario',
        'moneda_codigo'                => 'MXN',
        'posicion_moneda'              => 'antes',
        'formato_fecha'                => 'd/m/Y',
        'formato_hora'                 => 'H:i',
        'zona_horaria'                 => 'America/Mexico_City',
        'densidad_tablas'              => 'comoda',
        'modo_oscuro_permanente'       => 0,
        'logs_actividad'               => 1,
        'tamano_fuente'                => 'mediano',
        'bg_imagen'                    => null,
        'bg_opacidad'                  => 0.22,
    ];
}

function normalizeHexColor(?string $value, string $fallback = '#5d87ff'): string
{
    $value = trim((string)$value);
    if ($value === '') return $fallback;
    if ($value[0] !== '#') $value = '#' . $value;
    if (!preg_match('/^#([A-Fa-f0-9]{6})$/', $value)) return $fallback;
    return strtolower($value);
}

function hexToRgbArray(string $hex): array
{
    $hex = normalizeHexColor($hex);
    return [
        'r' => hexdec(substr($hex, 1, 2)),
        'g' => hexdec(substr($hex, 3, 2)),
        'b' => hexdec(substr($hex, 5, 2)),
    ];
}

function rgbaFromHex(string $hex, float $alpha): string
{
    $rgb = hexToRgbArray($hex);
    $alpha = max(0, min(1, $alpha));
    return 'rgba(' . $rgb['r'] . ', ' . $rgb['g'] . ', ' . $rgb['b'] . ', ' . $alpha . ')';
}

function lightenHexColor(string $hex, float $percent): string
{
    $rgb = hexToRgbArray($hex);
    $p = max(0, min(100, $percent)) / 100;
    $r = (int)round($rgb['r'] + (255 - $rgb['r']) * $p);
    $g = (int)round($rgb['g'] + (255 - $rgb['g']) * $p);
    $b = (int)round($rgb['b'] + (255 - $rgb['b']) * $p);
    return sprintf('#%02x%02x%02x', $r, $g, $b);
}

function darkenHexColor(string $hex, float $percent): string
{
    $rgb = hexToRgbArray($hex);
    $p = max(0, min(100, $percent)) / 100;
    $r = (int)round($rgb['r'] * (1 - $p));
    $g = (int)round($rgb['g'] * (1 - $p));
    $b = (int)round($rgb['b'] * (1 - $p));
    return sprintf('#%02x%02x%02x', $r, $g, $b);
}

function ensureSystemSettingsTable(mysqli $conn): void
{
    $conn->query(
        "CREATE TABLE IF NOT EXISTS configuracion_sistema_global (
            id TINYINT UNSIGNED NOT NULL PRIMARY KEY,
            umbral_stock_bajo INT NOT NULL DEFAULT 5,
            permitir_inventario_negativo TINYINT(1) NOT NULL DEFAULT 0,
            categorizacion_automatica TINYINT(1) NOT NULL DEFAULT 0,
            logo_path VARCHAR(255) NULL,
            banner_imagen VARCHAR(255) NULL,
            banner_overlay_color VARCHAR(7) NOT NULL DEFAULT '#0f172a',
            banner_overlay_opacidad DECIMAL(4,2) NOT NULL DEFAULT 0.56,
            banner_texto_primario VARCHAR(7) NOT NULL DEFAULT '#ffffff',
            banner_texto_secundario VARCHAR(7) NOT NULL DEFAULT '#e2e8f0',
            color_acento VARCHAR(7) NOT NULL DEFAULT '#5d87ff',
            nombre_instancia VARCHAR(120) NOT NULL DEFAULT 'Master Inventario',
            moneda_codigo VARCHAR(10) NOT NULL DEFAULT 'MXN',
            posicion_moneda ENUM('antes','despues') NOT NULL DEFAULT 'antes',
            formato_fecha VARCHAR(20) NOT NULL DEFAULT 'd/m/Y',
            formato_hora VARCHAR(20) NOT NULL DEFAULT 'H:i',
            zona_horaria VARCHAR(64) NOT NULL DEFAULT 'America/Mexico_City',
            densidad_tablas ENUM('comoda','compacta') NOT NULL DEFAULT 'comoda',
            modo_oscuro_permanente TINYINT(1) NOT NULL DEFAULT 0,
            logs_actividad TINYINT(1) NOT NULL DEFAULT 1,
            tamano_fuente VARCHAR(20) NOT NULL DEFAULT 'mediano',
            actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci"
    );

    $conn->query("INSERT IGNORE INTO configuracion_sistema_global (id) VALUES (1)");

    // Auto-migrate: add global banner column if not present
    $chkBanner = $conn->query("SHOW COLUMNS FROM configuracion_sistema_global LIKE 'banner_imagen'");
    if ($chkBanner && $chkBanner->num_rows === 0) {
        $conn->query("ALTER TABLE configuracion_sistema_global ADD COLUMN banner_imagen VARCHAR(255) NULL AFTER logo_path");
    }

    $chkBannerOverlayColor = $conn->query("SHOW COLUMNS FROM configuracion_sistema_global LIKE 'banner_overlay_color'");
    if ($chkBannerOverlayColor && $chkBannerOverlayColor->num_rows === 0) {
        $conn->query("ALTER TABLE configuracion_sistema_global ADD COLUMN banner_overlay_color VARCHAR(7) NOT NULL DEFAULT '#0f172a' AFTER banner_imagen");
    }

    $chkBannerOverlayOpacity = $conn->query("SHOW COLUMNS FROM configuracion_sistema_global LIKE 'banner_overlay_opacidad'");
    if ($chkBannerOverlayOpacity && $chkBannerOverlayOpacity->num_rows === 0) {
        $conn->query("ALTER TABLE configuracion_sistema_global ADD COLUMN banner_overlay_opacidad DECIMAL(4,2) NOT NULL DEFAULT 0.56 AFTER banner_overlay_color");
    }

    $chkBannerTextPrimary = $conn->query("SHOW COLUMNS FROM configuracion_sistema_global LIKE 'banner_texto_primario'");
    if ($chkBannerTextPrimary && $chkBannerTextPrimary->num_rows === 0) {
        $conn->query("ALTER TABLE configuracion_sistema_global ADD COLUMN banner_texto_primario VARCHAR(7) NOT NULL DEFAULT '#ffffff' AFTER banner_overlay_opacidad");
    }

    $chkBannerTextSecondary = $conn->query("SHOW COLUMNS FROM configuracion_sistema_global LIKE 'banner_texto_secundario'");
    if ($chkBannerTextSecondary && $chkBannerTextSecondary->num_rows === 0) {
        $conn->query("ALTER TABLE configuracion_sistema_global ADD COLUMN banner_texto_secundario VARCHAR(7) NOT NULL DEFAULT '#e2e8f0' AFTER banner_texto_primario");
    }

    // Auto-migrate: add background columns if not present
    $chk = $conn->query("SHOW COLUMNS FROM configuracion_sistema_global LIKE 'bg_imagen'");
    if ($chk && $chk->num_rows === 0) {
        $conn->query("ALTER TABLE configuracion_sistema_global ADD COLUMN bg_imagen VARCHAR(255) NULL");
        $conn->query("ALTER TABLE configuracion_sistema_global ADD COLUMN bg_opacidad DECIMAL(4,2) NOT NULL DEFAULT 0.22");
    }
}

function ensureActivityLogsTable(mysqli $conn): void
{
    $conn->query(
        "CREATE TABLE IF NOT EXISTS actividad_sistema (
            id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
            id_usuario INT NULL,
            modulo VARCHAR(80) NOT NULL,
            accion VARCHAR(80) NOT NULL,
            detalle TEXT NULL,
            entidad VARCHAR(80) NULL,
            entidad_id INT NULL,
            creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_modulo_fecha (modulo, creado_en),
            INDEX idx_usuario_fecha (id_usuario, creado_en),
            CONSTRAINT fk_actividad_sistema_usuario
                FOREIGN KEY (id_usuario) REFERENCES Usuarios(id_usuario)
                ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci"
    );
}

function loadSystemSettings(mysqli $conn): array
{
    $defaults = getSystemSettingsDefaults();
    $row = dbFetchOne($conn, "SELECT * FROM configuracion_sistema_global WHERE id = 1");
    $settings = array_merge($defaults, $row ?? []);

    $settings['umbral_stock_bajo'] = max(0, (int)$settings['umbral_stock_bajo']);
    $settings['permitir_inventario_negativo'] = (int)!empty($settings['permitir_inventario_negativo']);
    $settings['categorizacion_automatica'] = (int)!empty($settings['categorizacion_automatica']);
    $settings['modo_oscuro_permanente'] = (int)!empty($settings['modo_oscuro_permanente']);
    $settings['logs_actividad'] = (int)!empty($settings['logs_actividad']);
    $settings['color_acento'] = normalizeHexColor((string)$settings['color_acento'], $defaults['color_acento']);
    $settings['banner_overlay_color'] = normalizeHexColor((string)$settings['banner_overlay_color'], $defaults['banner_overlay_color']);
    $settings['banner_texto_primario'] = normalizeHexColor((string)$settings['banner_texto_primario'], $defaults['banner_texto_primario']);
    $settings['banner_texto_secundario'] = normalizeHexColor((string)$settings['banner_texto_secundario'], $defaults['banner_texto_secundario']);
    $settings['banner_overlay_opacidad'] = max(0.15, min(0.90, (float)($settings['banner_overlay_opacidad'] ?? $defaults['banner_overlay_opacidad'])));

    $settings['nombre_instancia'] = trim((string)$settings['nombre_instancia']);
    if ($settings['nombre_instancia'] === '') {
        $settings['nombre_instancia'] = $defaults['nombre_instancia'];
    }
    $settings['nombre_instancia'] = mb_substr($settings['nombre_instancia'], 0, 120);

    $currencies = getSystemCurrencyMap();
    if (!isset($currencies[$settings['moneda_codigo']])) {
        $settings['moneda_codigo'] = $defaults['moneda_codigo'];
    }

    if (!in_array($settings['posicion_moneda'], ['antes', 'despues'], true)) {
        $settings['posicion_moneda'] = $defaults['posicion_moneda'];
    }

    $allowedDateFormats = ['d/m/Y', 'Y-m-d', 'd-m-Y'];
    if (!in_array($settings['formato_fecha'], $allowedDateFormats, true)) {
        $settings['formato_fecha'] = $defaults['formato_fecha'];
    }

    $allowedTimeFormats = ['H:i', 'h:i A'];
    if (!in_array($settings['formato_hora'], $allowedTimeFormats, true)) {
        $settings['formato_hora'] = $defaults['formato_hora'];
    }

    if (!in_array($settings['zona_horaria'], timezone_identifiers_list(), true)) {
        $settings['zona_horaria'] = $defaults['zona_horaria'];
    }

    if (!in_array($settings['densidad_tablas'], ['comoda', 'compacta'], true)) {
        $settings['densidad_tablas'] = $defaults['densidad_tablas'];
    }

    if (!in_array($settings['tamano_fuente'], ['pequeño', 'mediano', 'grande'], true)) {
        $settings['tamano_fuente'] = $defaults['tamano_fuente'];
    }

    if (!empty($settings['logo_path']) && !preg_match('#^[a-zA-Z0-9_/\.\-]+$#', (string)$settings['logo_path'])) {
        $settings['logo_path'] = null;
    }
    if (!empty($settings['banner_imagen']) && !preg_match('~^[a-zA-Z0-9_./-]+$~', (string)$settings['banner_imagen'])) {
        $settings['banner_imagen'] = null;
    }

    $settings['bg_opacidad'] = max(0.03, min(0.80, (float)($settings['bg_opacidad'] ?? 0.22)));

    if (!empty($settings['bg_imagen']) && !preg_match('#^[a-zA-Z0-9_/\.\-]+$#', (string)$settings['bg_imagen'])) {
        $settings['bg_imagen'] = null;
    }

    return $settings;
}

function systemSettingsBootstrap(mysqli $conn): void
{
    static $bootstrapped = false;
    if ($bootstrapped) return;

    ensureSystemSettingsTable($conn);
    ensureActivityLogsTable($conn);

    $GLOBALS['SYSTEM_SETTINGS'] = loadSystemSettings($conn);
    $_SESSION['system_settings'] = $GLOBALS['SYSTEM_SETTINGS'];

    $timezone = $GLOBALS['SYSTEM_SETTINGS']['zona_horaria'] ?? 'America/Mexico_City';
    if (!@date_default_timezone_set($timezone)) {
        date_default_timezone_set('America/Mexico_City');
    }

    $bootstrapped = true;
}

function refreshSystemSettings(mysqli $conn): array
{
    $GLOBALS['SYSTEM_SETTINGS'] = loadSystemSettings($conn);
    $_SESSION['system_settings'] = $GLOBALS['SYSTEM_SETTINGS'];

    $timezone = $GLOBALS['SYSTEM_SETTINGS']['zona_horaria'] ?? 'America/Mexico_City';
    if (!@date_default_timezone_set($timezone)) {
        date_default_timezone_set('America/Mexico_City');
    }

    return $GLOBALS['SYSTEM_SETTINGS'];
}

function getSystemSettings(): array
{
    if (isset($GLOBALS['SYSTEM_SETTINGS']) && is_array($GLOBALS['SYSTEM_SETTINGS'])) {
        return $GLOBALS['SYSTEM_SETTINGS'];
    }
    if (isset($_SESSION['system_settings']) && is_array($_SESSION['system_settings'])) {
        return $_SESSION['system_settings'];
    }
    return getSystemSettingsDefaults();
}

function systemSetting(string $key, mixed $default = null): mixed
{
    $settings = getSystemSettings();
    return $settings[$key] ?? $default;
}

function isSystemSettingEnabled(string $key): bool
{
    return !empty(systemSetting($key, 0));
}

function appCurrencySymbol(): string
{
    $map = getSystemCurrencyMap();
    $code = systemSetting('moneda_codigo', 'MXN');
    return $map[$code]['symbol'] ?? '$ MXN';
}

function appFormatCurrency(float $amount, int $decimals = 2): string
{
    $symbol = appCurrencySymbol();
    $position = systemSetting('posicion_moneda', 'antes');
    $sign = $amount < 0 ? '-' : '';
    $formatted = number_format(abs($amount), $decimals, '.', ',');

    if ($position === 'despues') {
        return $sign . $formatted . ' ' . $symbol;
    }
    return $sign . $symbol . ' ' . $formatted;
}

function parseDateToTimestamp(mixed $value): ?int
{
    if ($value === null || $value === '') return null;
    if (is_int($value)) return $value;
    if (is_numeric($value)) return (int)$value;

    $ts = strtotime((string)$value);
    return $ts !== false ? $ts : null;
}

function appFormatDate(mixed $value): string
{
    $ts = parseDateToTimestamp($value);
    if ($ts === null) return '';
    $format = systemSetting('formato_fecha', 'd/m/Y');
    return date($format, $ts);
}

function appFormatDateTime(mixed $value): string
{
    $ts = parseDateToTimestamp($value);
    if ($ts === null) return '';
    $dateFormat = systemSetting('formato_fecha', 'd/m/Y');
    $timeFormat = systemSetting('formato_hora', 'H:i');
    return date($dateFormat . ' ' . $timeFormat, $ts);
}

function appResolveLogoPath(): string
{
    $custom = (string)systemSetting('logo_path', '');
    if ($custom !== '' && preg_match('#^[a-zA-Z0-9_/\.\-]+$#', $custom)) {
        $full = __DIR__ . '/../' . $custom;
        if (file_exists($full)) {
            return $custom;
        }
    }
    return '../logo.png';
}

function appResolveBannerPath(): string
{
    $default = 'assets/images/breadcrumb/inventario_productos_banner.svg';
    $custom = (string)systemSetting('banner_imagen', '');

    if ($custom !== '' && preg_match('~^[a-zA-Z0-9_./-]+$~', $custom)) {
        $full = __DIR__ . '/../' . $custom;
        if (file_exists($full)) {
            return $custom;
        }
    }

    return $default;
}

function appFontSizePx(): int
{
    return match (systemSetting('tamano_fuente', 'mediano')) {
        'pequeño' => 13,
        'grande'  => 16,
        default   => 14,
    };
}

function appBuildDynamicThemeCss(): string
{
    $primary = normalizeHexColor((string)systemSetting('color_acento', '#5d87ff'));
    $secondary = lightenHexColor($primary, 16);
    $accentViolet = darkenHexColor($primary, 18);
    $bannerOverlayColor = normalizeHexColor((string)systemSetting('banner_overlay_color', '#0f172a'), '#0f172a');
    $bannerOverlayOpacity = max(0.15, min(0.90, (float)systemSetting('banner_overlay_opacidad', 0.56)));
    $bannerTextPrimary = normalizeHexColor((string)systemSetting('banner_texto_primario', '#ffffff'), '#ffffff');
    $bannerTextSecondary = normalizeHexColor((string)systemSetting('banner_texto_secundario', '#e2e8f0'), '#e2e8f0');
    $fontPx = appFontSizePx();

    $lightPrimary = rgbaFromHex($primary, 0.12);
    $lightSecondary = rgbaFromHex($secondary, 0.12);
    $bannerOverlayStrong = rgbaFromHex($bannerOverlayColor, $bannerOverlayOpacity);
    $bannerOverlayMedium = rgbaFromHex($bannerOverlayColor, max(0.08, $bannerOverlayOpacity - 0.22));
    $bannerOverlaySoft = rgbaFromHex($bannerOverlayColor, max(0.04, $bannerOverlayOpacity - 0.40));

    return "
        :root{
            --primary: {$primary};
            --secondary: {$secondary};
            --accent-violet: {$accentViolet};
            --primaryemphasis: " . darkenHexColor($primary, 22) . ";
            --secondaryemphasis: " . darkenHexColor($secondary, 22) . ";
            --lightprimary: {$lightPrimary};
            --lightsecondary: {$lightSecondary};
        }
        html, body { font-size: {$fontPx}px; }
        .page-banner{
            background: linear-gradient(120deg, var(--lightprimary), var(--lightsecondary));
            border-color: " . rgbaFromHex($primary, 0.24) . ";
            box-shadow: 0 12px 30px " . rgbaFromHex($primary, 0.18) . ";
        }
        .page-banner::before{
            background: linear-gradient(90deg, {$bannerOverlayStrong} 0%, {$bannerOverlayMedium} 48%, {$bannerOverlaySoft} 100%);
        }
        .page-banner-content h1{
            color: {$bannerTextPrimary};
        }
        .page-banner-breadcrumb,
        .page-banner-breadcrumb a{
            color: {$bannerTextSecondary};
        }
        .dashboard-hero{
            background: linear-gradient(120deg, " . rgbaFromHex($secondary, 0.22) . ", " . rgbaFromHex($primary, 0.16) . ");
            border-color: " . rgbaFromHex($secondary, 0.24) . ";
        }
        .dashboard-hero::after{
            content: '';
            position: absolute;
            inset: 0;
            background: linear-gradient(90deg, {$bannerOverlayStrong} 0%, {$bannerOverlayMedium} 48%, {$bannerOverlaySoft} 100%);
            z-index: 1;
            pointer-events: none;
        }
        .dashboard-hero-content,
        .dashboard-hero .page-header-right{
            position: relative;
            z-index: 2;
        }
        .dashboard-hero .dashboard-hero-user h2{
            color: {$bannerTextPrimary} !important;
        }
        .dashboard-hero .dashboard-hero-user p{
            color: {$bannerTextSecondary} !important;
        }" . appBuildBackgroundCss();
}

function appBuildBackgroundCss(): string
{
    $bgImg     = (string)systemSetting('bg_imagen', '');
    $bgOpacity = (float)systemSetting('bg_opacidad', 0.22);
    $bgOpacity = max(0.03, min(0.80, $bgOpacity));
    $darkOpacity = round($bgOpacity * 0.35, 3);

    if ($bgImg !== '' && preg_match('#^[a-zA-Z0-9_/\.\-]+$#', $bgImg) && file_exists(__DIR__ . '/../' . $bgImg)) {
        $bgUrl = "url('" . $bgImg . "')";
    } else {
        $bgUrl = "url('assets/images/bg/pattern-bg.png')";
    }

    return "
        body::before { background-image: {$bgUrl}; opacity: {$bgOpacity}; }
        html.dark body::before { opacity: {$darkOpacity}; }";
}

function logInventoryActivity(mysqli $conn, string $action, string $detail, ?int $productId = null): void
{
    if (!isSystemSettingEnabled('logs_actividad')) return;

    $userId = isset($_SESSION['user_id']) ? (int)$_SESSION['user_id'] : null;
    $detail = mb_substr(trim($detail), 0, 2000);

    $stmt = $conn->prepare(
        "INSERT INTO actividad_sistema (id_usuario, modulo, accion, detalle, entidad, entidad_id)
         VALUES (?, 'Inventario', ?, ?, 'Producto', ?)"
    );
    if (!$stmt) return;

    $stmt->bind_param("issi", $userId, $action, $detail, $productId);
    $stmt->execute();
    $stmt->close();
}
