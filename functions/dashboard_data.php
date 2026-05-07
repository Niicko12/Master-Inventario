<?php

function dashboardTableExists(mysqli $conn, string $table): bool
{
    static $cache = [];

    if (array_key_exists($table, $cache)) {
        return $cache[$table];
    }

    $row = dbFetchOne(
        $conn,
        "SELECT COUNT(*) AS total
         FROM information_schema.tables
         WHERE table_schema = DATABASE() AND table_name = ?",
        "s",
        $table
    );

    $cache[$table] = (int)($row['total'] ?? 0) > 0;
    return $cache[$table];
}

function getDashboardData(mysqli $conn): array
{
    $stockThreshold = max(0, (int)systemSetting('umbral_stock_bajo', 5));
    $hasInventario   = dashboardTableExists($conn, 'Inventario');
    $hasVentas       = dashboardTableExists($conn, 'Ventas');
    $hasDetalleVenta = dashboardTableExists($conn, 'Detalle_Ventas');
    $hasCompras      = dashboardTableExists($conn, 'Compras');
    $hasProveedores  = dashboardTableExists($conn, 'Proveedores');
    $hasDocumentos   = dashboardTableExists($conn, 'Documentos');
    $hasUsuarios     = dashboardTableExists($conn, 'Usuarios');
    $hasReportes     = dashboardTableExists($conn, 'Reportes');

    $ventas_mes      = ['cnt' => 0, 'monto' => 0];
    $ventas_totales  = ['cnt' => 0, 'monto' => 0];
    $compras_mes     = ['cnt' => 0, 'monto' => 0];
    $compras_totales = ['cnt' => 0, 'monto' => 0];

    if ($hasVentas) {
        $ventas_mes = dbFetchOne(
            $conn,
            "SELECT COUNT(*) AS cnt, COALESCE(SUM(monto_total), 0) AS monto
             FROM Ventas
             WHERE MONTH(fecha_venta) = MONTH(NOW()) AND YEAR(fecha_venta) = YEAR(NOW())"
        ) ?? $ventas_mes;

        $ventas_totales = dbFetchOne(
            $conn,
            "SELECT COUNT(*) AS cnt, COALESCE(SUM(monto_total), 0) AS monto
             FROM Ventas"
        ) ?? $ventas_totales;
    }

    if ($hasCompras) {
        $compras_mes = dbFetchOne(
            $conn,
            "SELECT COUNT(*) AS cnt, COALESCE(SUM(monto_total), 0) AS monto
             FROM Compras
             WHERE MONTH(fecha_compra) = MONTH(NOW()) AND YEAR(fecha_compra) = YEAR(NOW())"
        ) ?? $compras_mes;

        $compras_totales = dbFetchOne(
            $conn,
            "SELECT COUNT(*) AS cnt, COALESCE(SUM(monto_total), 0) AS monto
             FROM Compras"
        ) ?? $compras_totales;
    }

    $total_productos = 0;
    $sin_stock       = 0;
    $stock_bajo      = 0;
    $stock_normal    = 0;
    $alertas_stock   = 0;

    if ($hasInventario) {
        $inv = dbFetchOne(
            $conn,
            "SELECT
                COUNT(*) AS total,
                SUM(CASE WHEN cantidad_disponible <= 0 THEN 1 ELSE 0 END) AS sin_stock,
                SUM(CASE WHEN cantidad_disponible > 0 AND cantidad_disponible <= ? THEN 1 ELSE 0 END) AS stock_bajo,
                SUM(CASE WHEN cantidad_disponible > ? THEN 1 ELSE 0 END) AS stock_normal
             FROM Inventario",
            "ii",
            $stockThreshold,
            $stockThreshold
        ) ?? [];

        $total_productos = (int)($inv['total'] ?? 0);
        $sin_stock       = (int)($inv['sin_stock'] ?? 0);
        $stock_bajo      = (int)($inv['stock_bajo'] ?? 0);
        $stock_normal    = (int)($inv['stock_normal'] ?? 0);
        $alertas_stock   = $sin_stock + $stock_bajo;
    }

    $total_proveedores = $hasProveedores
        ? (int)(dbFetchOne($conn, "SELECT COUNT(*) AS total FROM Proveedores")['total'] ?? 0)
        : 0;

    $total_documentos = 0;
    $documentos_mes   = 0;
    if ($hasDocumentos) {
        $docs = dbFetchOne(
            $conn,
            "SELECT
                COUNT(*) AS total,
                SUM(CASE WHEN MONTH(fecha_subida) = MONTH(NOW()) AND YEAR(fecha_subida) = YEAR(NOW()) THEN 1 ELSE 0 END) AS mes
             FROM Documentos"
        ) ?? [];
        $total_documentos = (int)($docs['total'] ?? 0);
        $documentos_mes   = (int)($docs['mes'] ?? 0);
    }

    $total_usuarios  = 0;
    $usuarios_activos = 0;
    if ($hasUsuarios) {
        $users = dbFetchOne(
            $conn,
            "SELECT
                COUNT(*) AS total,
                SUM(CASE WHEN estado = 'Activo' THEN 1 ELSE 0 END) AS activos
             FROM Usuarios"
        ) ?? [];
        $total_usuarios   = (int)($users['total'] ?? 0);
        $usuarios_activos = (int)($users['activos'] ?? 0);
    }

    $total_reportes = 0;
    $reportes_mes   = 0;
    if ($hasReportes) {
        $reports = dbFetchOne(
            $conn,
            "SELECT
                COUNT(*) AS total,
                SUM(CASE WHEN MONTH(fecha_generacion) = MONTH(NOW()) AND YEAR(fecha_generacion) = YEAR(NOW()) THEN 1 ELSE 0 END) AS mes
             FROM Reportes"
        ) ?? [];
        $total_reportes = (int)($reports['total'] ?? 0);
        $reportes_mes   = (int)($reports['mes'] ?? 0);
    }

    // Chart 1 – ventas diarias (últimos 30 días)
    $line_rows = $hasVentas
        ? dbFetchAll(
            $conn,
            "SELECT DATE(fecha_venta) AS fecha, SUM(monto_total) AS total
             FROM Ventas
             WHERE fecha_venta >= DATE_SUB(CURDATE(), INTERVAL 29 DAY)
             GROUP BY DATE(fecha_venta)
             ORDER BY fecha ASC"
        )
        : [];

    $line_labels = array_map(
        static fn($r) => date('d/m', strtotime($r['fecha'])),
        $line_rows
    );
    $line_data = array_map(static fn($r) => (float)$r['total'], $line_rows);

    // Chart 3 – top 5 productos vendidos
    $bar_rows = ($hasDetalleVenta && $hasInventario)
        ? dbFetchAll(
            $conn,
            "SELECT I.nombre_producto, SUM(DV.cantidad_vendida) AS total
             FROM Detalle_Ventas DV
             JOIN Inventario I ON DV.id_producto = I.id_producto
             GROUP BY DV.id_producto, I.nombre_producto
             ORDER BY total DESC
             LIMIT 5"
        )
        : [];

    $bar_labels = array_map(static fn($r) => mb_strimwidth($r['nombre_producto'], 0, 28, '…'), $bar_rows);
    $bar_data   = array_map(static fn($r) => (int)$r['total'], $bar_rows);

    // Chart 4 – ventas vs compras (últimos 6 meses con datos)
    $vc_v_rows = $hasVentas
        ? dbFetchAll(
            $conn,
            "SELECT DATE_FORMAT(fecha_venta, '%Y-%m') AS mes, SUM(monto_total) AS total
             FROM Ventas
             WHERE fecha_venta >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
             GROUP BY mes
             ORDER BY mes ASC"
        )
        : [];

    $vc_c_rows = $hasCompras
        ? dbFetchAll(
            $conn,
            "SELECT DATE_FORMAT(fecha_compra, '%Y-%m') AS mes, SUM(monto_total) AS total
             FROM Compras
             WHERE fecha_compra >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
             GROUP BY mes
             ORDER BY mes ASC"
        )
        : [];

    $vc_keys = array_values(array_unique(array_merge(
        array_column($vc_v_rows, 'mes'),
        array_column($vc_c_rows, 'mes')
    )));
    sort($vc_keys);
    if (count($vc_keys) > 6) {
        $vc_keys = array_slice($vc_keys, -6);
    }

    $vc_v_map = array_column($vc_v_rows, 'total', 'mes');
    $vc_c_map = array_column($vc_c_rows, 'total', 'mes');
    $meses_es = [1 => 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

    $vc_labels  = [];
    $vc_ventas  = [];
    $vc_compras = [];
    foreach ($vc_keys as $key) {
        $year = substr($key, 2, 2);
        $mes  = (int)substr($key, 5, 2);
        $vc_labels[]  = ($meses_es[$mes] ?? $key) . ' ' . $year;
        $vc_ventas[]  = (float)($vc_v_map[$key] ?? 0);
        $vc_compras[] = (float)($vc_c_map[$key] ?? 0);
    }

    // Ventas recientes
    if ($hasVentas && $hasUsuarios) {
        $recientes = dbFetchAll(
            $conn,
            "SELECT V.id_venta, U.nombre AS cliente, V.fecha_venta, V.monto_total
             FROM Ventas V
             JOIN Usuarios U ON V.id_cliente = U.id_usuario
             ORDER BY V.fecha_venta DESC
             LIMIT 6"
        );
    } elseif ($hasVentas) {
        $recientes = dbFetchAll(
            $conn,
            "SELECT id_venta, CONCAT('Cliente #', id_cliente) AS cliente, fecha_venta, monto_total
             FROM Ventas
             ORDER BY fecha_venta DESC
             LIMIT 6"
        );
    } else {
        $recientes = [];
    }

    // Resumen por módulos
    $module_cards = [
        [
            'nombre'  => 'Inventario',
            'icono'   => 'fas fa-boxes-stacked',
            'valor'   => $total_productos,
            'detalle' => $alertas_stock . ' alerta(s) de stock',
            'url'     => 'gestion_inventario.php',
            'admin'   => false,
        ],
        [
            'nombre'  => 'Ventas',
            'icono'   => 'fas fa-cart-shopping',
            'valor'   => (int)$ventas_totales['cnt'],
            'detalle' => appFormatCurrency((float)$ventas_totales['monto']) . ' acumulado',
            'url'     => 'gestion_ventas.php',
            'admin'   => false,
        ],
        [
            'nombre'  => 'Compras',
            'icono'   => 'fas fa-truck',
            'valor'   => (int)$compras_totales['cnt'],
            'detalle' => appFormatCurrency((float)$compras_totales['monto']) . ' acumulado',
            'url'     => 'gestion_compras.php',
            'admin'   => false,
        ],
        [
            'nombre'  => 'Proveedores',
            'icono'   => 'fas fa-building',
            'valor'   => $total_proveedores,
            'detalle' => 'Registrados en el sistema',
            'url'     => 'gestion_proveedores.php',
            'admin'   => false,
        ],
        [
            'nombre'  => 'Documentos',
            'icono'   => 'fas fa-file-lines',
            'valor'   => $total_documentos,
            'detalle' => $documentos_mes . ' subido(s) este mes',
            'url'     => 'documentos.php',
            'admin'   => false,
        ],
    ];

    if ($hasUsuarios) {
        $module_cards[] = [
            'nombre'  => 'Usuarios',
            'icono'   => 'fas fa-users',
            'valor'   => $total_usuarios,
            'detalle' => $usuarios_activos . ' activo(s)',
            'url'     => 'administrar_usuarios.php',
            'admin'   => true,
        ];
    }

    if ($hasReportes) {
        $module_cards[] = [
            'nombre'  => 'Reportes',
            'icono'   => 'fas fa-chart-bar',
            'valor'   => $total_reportes,
            'detalle' => $reportes_mes . ' generado(s) este mes',
            'url'     => 'reportes.php',
            'admin'   => true,
        ];
    }

    // Actividad reciente combinada (múltiples módulos)
    $actividad_reciente = [];

    if ($hasVentas) {
        $ventas_recientes = $hasUsuarios
            ? dbFetchAll(
                $conn,
                "SELECT V.id_venta, V.fecha_venta, V.monto_total, U.nombre AS cliente
                 FROM Ventas V
                 LEFT JOIN Usuarios U ON V.id_cliente = U.id_usuario
                 ORDER BY V.fecha_venta DESC
                 LIMIT 5"
            )
            : dbFetchAll(
                $conn,
                "SELECT id_venta, fecha_venta, monto_total, CONCAT('Cliente #', id_cliente) AS cliente
                 FROM Ventas
                 ORDER BY fecha_venta DESC
                 LIMIT 5"
            );

        foreach ($ventas_recientes as $v) {
            $actividad_reciente[] = [
                'modulo' => 'Ventas',
                'icono'  => 'fas fa-cart-shopping',
                'titulo' => 'Venta #' . (int)$v['id_venta'],
                'detalle'=> 'Cliente: ' . ($v['cliente'] ?: 'N/A') . ' · ' . appFormatCurrency((float)$v['monto_total']),
                'fecha'  => $v['fecha_venta'],
                'url'    => 'gestion_ventas.php',
            ];
        }
    }

    if ($hasCompras) {
        $compras_recientes = $hasProveedores
            ? dbFetchAll(
                $conn,
                "SELECT C.id_compra, C.fecha_compra, C.monto_total, COALESCE(P.nombre_proveedor, 'Proveedor N/A') AS proveedor
                 FROM Compras C
                 LEFT JOIN Proveedores P ON C.id_proveedor = P.id_proveedor
                 ORDER BY C.fecha_compra DESC
                 LIMIT 5"
            )
            : dbFetchAll(
                $conn,
                "SELECT id_compra, fecha_compra, monto_total, CONCAT('Proveedor #', id_proveedor) AS proveedor
                 FROM Compras
                 ORDER BY fecha_compra DESC
                 LIMIT 5"
            );

        foreach ($compras_recientes as $c) {
            $actividad_reciente[] = [
                'modulo' => 'Compras',
                'icono'  => 'fas fa-truck',
                'titulo' => 'Compra #' . (int)$c['id_compra'],
                'detalle'=> 'Proveedor: ' . ($c['proveedor'] ?: 'N/A') . ' · ' . appFormatCurrency((float)$c['monto_total']),
                'fecha'  => $c['fecha_compra'],
                'url'    => 'gestion_compras.php',
            ];
        }
    }

    if ($hasDocumentos) {
        $documentos_recientes = $hasUsuarios
            ? dbFetchAll(
                $conn,
                "SELECT D.id_documento, D.tipo_documento, D.nombre_archivo, D.fecha_subida, COALESCE(U.nombre, 'Usuario N/A') AS usuario_nombre
                 FROM Documentos D
                 LEFT JOIN Usuarios U ON D.usuario_subio = U.id_usuario
                 ORDER BY D.fecha_subida DESC
                 LIMIT 5"
            )
            : dbFetchAll(
                $conn,
                "SELECT id_documento, tipo_documento, nombre_archivo, fecha_subida, 'Usuario N/A' AS usuario_nombre
                 FROM Documentos
                 ORDER BY fecha_subida DESC
                 LIMIT 5"
            );

        foreach ($documentos_recientes as $d) {
            $actividad_reciente[] = [
                'modulo' => 'Documentos',
                'icono'  => 'fas fa-file-lines',
                'titulo' => 'Documento #' . (int)$d['id_documento'] . ' · ' . ($d['tipo_documento'] ?: 'Sin tipo'),
                'detalle'=> 'Subido por ' . ($d['usuario_nombre'] ?: 'N/A') . ' · ' . ($d['nombre_archivo'] ?: 'Archivo'),
                'fecha'  => $d['fecha_subida'],
                'url'    => 'documentos.php',
            ];
        }
    }

    usort(
        $actividad_reciente,
        static fn($a, $b) => strtotime((string)$b['fecha']) <=> strtotime((string)$a['fecha'])
    );
    $actividad_reciente = array_slice($actividad_reciente, 0, 8);

    return compact(
        'ventas_mes', 'ventas_totales', 'compras_mes', 'compras_totales',
        'total_productos', 'alertas_stock', 'total_proveedores',
        'total_documentos', 'documentos_mes', 'total_usuarios', 'usuarios_activos', 'total_reportes', 'reportes_mes',
        'line_labels', 'line_data',
        'sin_stock', 'stock_bajo', 'stock_normal',
        'bar_labels', 'bar_data',
        'vc_labels', 'vc_ventas', 'vc_compras',
        'recientes', 'module_cards', 'actividad_reciente'
    );
}
