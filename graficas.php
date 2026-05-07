<?php
require_once 'config.php';
requireAnyRole(['Administrador']);

$page_title  = 'Graficas';
$active_page = 'graficas.php';
$extra_css   = [];

function graphPeriodExpression(string $column, string $groupBy): string
{
    return match ($groupBy) {
        'semana' => "DATE(DATE_SUB($column, INTERVAL WEEKDAY($column) DAY))",
        'mes'    => "DATE_FORMAT($column, '%Y-%m-01')",
        'anio'   => "DATE_FORMAT($column, '%Y-01-01')",
        default  => "DATE($column)",
    };
}

function graphFormatPeriodLabel(string $period, string $groupBy): string
{
    $ts = strtotime($period);
    if ($ts === false) return $period;
    return match ($groupBy) {
        'semana' => 'Semana ' . date('W / Y', $ts),
        'mes'    => date('M Y', $ts),
        'anio'   => date('Y', $ts),
        default  => appFormatDate($ts),
    };
}

function graphProjectionStep(string $groupBy): DateInterval
{
    return match ($groupBy) {
        'semana' => new DateInterval('P7D'),
        'mes'    => new DateInterval('P1M'),
        'anio'   => new DateInterval('P1Y'),
        default  => new DateInterval('P1D'),
    };
}

function graphTableExists(mysqli $conn, string $table): bool
{
    $safeTable = $conn->real_escape_string($table);
    $res = $conn->query("SHOW TABLES LIKE '{$safeTable}'");
    return $res && $res->num_rows > 0;
}

function graphColumnExists(mysqli $conn, string $table, string $column): bool
{
    $safeColumn = $conn->real_escape_string($column);
    $res = $conn->query("SHOW COLUMNS FROM `$table` LIKE '{$safeColumn}'");
    return $res && $res->num_rows > 0;
}

function graphInferInventoryType(string $name): string
{
    $value = mb_strtolower(trim($name));
    if ($value === '') {
        return 'Sin categoría';
    }

    $rules = [
        'Electrónicos' => '/laptop|computadora|pc|monitor|teclado|mouse|impresora|router|modem|tablet|celular|cable|disco|usb/i',
        'Herramientas' => '/martillo|taladro|llave|destornillador|pinza|broca|sierra|alicate|cinta/i',
        'Oficina'      => '/papel|cuaderno|pluma|lapiz|toner|cartucho|carpeta|archivo|grapa|escritorio/i',
        'Ferretería'   => '/tornillo|tuerca|clavo|pintura|cemento|tubo|manguera|valvula|foco|lampara/i',
        'Seguridad'    => '/casco|guante|bota|mascarilla|arnes|lente|chaleco/i',
        'Refacciones'  => '/filtro|empaque|rodamiento|banda|polea|motor|bomba|repuesto/i',
    ];

    foreach ($rules as $label => $pattern) {
        if (preg_match($pattern, $value)) {
            return $label;
        }
    }

    return 'General';
}

function graphFetchGroupedMetricRows(
    mysqli $conn,
    string $table,
    string $dateColumn,
    string $metricSql,
    string $groupBy,
    string $startDate = '',
    string $endDate = ''
): array {
    if (!graphTableExists($conn, $table) || !graphColumnExists($conn, $table, $dateColumn)) {
        return [];
    }

    $periodExpr = graphPeriodExpression($dateColumn, $groupBy);
    $query = "SELECT $periodExpr AS periodo, $metricSql AS valor FROM `$table` WHERE $dateColumn IS NOT NULL";
    $types = '';
    $params = [];

    if ($startDate !== '') {
        $query .= " AND DATE($dateColumn) >= ?";
        $types .= 's';
        $params[] = $startDate;
    }
    if ($endDate !== '') {
        $query .= " AND DATE($dateColumn) <= ?";
        $types .= 's';
        $params[] = $endDate;
    }

    $query .= ' GROUP BY periodo ORDER BY periodo ASC';

    return dbFetchAll($conn, $query, $types, ...$params);
}

function graphBuildSystemRows(mysqli $conn, string $groupBy, string $startDate = '', string $endDate = ''): array
{
    $definitions = [
        'ingresos_ventas' => [
            'table'       => 'Ventas',
            'date_column' => 'fecha_venta',
            'sql'         => 'COALESCE(SUM(monto_total), 0)',
        ],
        'egresos_compras' => [
            'table'       => 'Compras',
            'date_column' => 'fecha_compra',
            'sql'         => 'COALESCE(SUM(monto_total), 0)',
        ],
        'documentos_subidos' => [
            'table'       => 'Documentos',
            'date_column' => 'fecha_subida',
            'sql'         => 'COUNT(*)',
        ],
        'altas_usuarios' => [
            'table'       => 'Usuarios',
            'date_column' => 'fecha_creacion',
            'sql'         => 'COUNT(*)',
        ],
        'stock_global' => [
            'table'       => 'Inventario',
            'date_column' => 'fecha_ultima_actualizacion',
            'sql'         => 'COALESCE(SUM(cantidad_disponible), 0)',
        ],
        'alertas_inventario' => [
            'table'       => 'Inventario',
            'date_column' => 'fecha_ultima_actualizacion',
            'sql'         => 'COALESCE(SUM(CASE WHEN cantidad_disponible <= stock_minimo THEN 1 ELSE 0 END), 0)',
        ],
    ];

    $seriesByPeriod = [];
    foreach ($definitions as $metricKey => $meta) {
        $rows = graphFetchGroupedMetricRows(
            $conn,
            $meta['table'],
            $meta['date_column'],
            $meta['sql'],
            $groupBy,
            $startDate,
            $endDate
        );
        foreach ($rows as $row) {
            $period = (string)($row['periodo'] ?? '');
            if ($period === '') {
                continue;
            }
            if (!isset($seriesByPeriod[$period])) {
                $seriesByPeriod[$period] = [];
            }
            $seriesByPeriod[$period][$metricKey] = round((float)($row['valor'] ?? 0), 2);
        }
    }

    if (empty($seriesByPeriod)) {
        return [];
    }

    ksort($seriesByPeriod);
    $rows = [];
    foreach ($seriesByPeriod as $period => $metrics) {
        $ingresos = (float)($metrics['ingresos_ventas'] ?? 0);
        $egresos = (float)($metrics['egresos_compras'] ?? 0);
        $rows[] = [
            'periodo' => $period,
            'ingresos_ventas' => $ingresos,
            'egresos_compras' => $egresos,
            'balance_operativo' => round($ingresos - $egresos, 2),
            'documentos_subidos' => (float)($metrics['documentos_subidos'] ?? 0),
            'altas_usuarios' => (float)($metrics['altas_usuarios'] ?? 0),
            'stock_global' => (float)($metrics['stock_global'] ?? 0),
            'alertas_inventario' => (float)($metrics['alertas_inventario'] ?? 0),
        ];
    }

    return $rows;
}

$chart_styles = [
    'bar'            => 'Barras',
    'stackedBar'     => 'Barras apiladas',
    'horizontalBar'  => 'Barras horizontales',
    'line'           => 'Líneas',
    'lineStepped'    => 'Línea escalonada',
    'area'           => 'Área',
    'comboBarLine'   => 'Combinado barras + línea',
    'comboAreaLine'  => 'Combinado área + línea',
    'radar'          => 'Radar',
    'pie'            => 'Pastel',
    'doughnut'       => 'Dona',
    'polarArea'      => 'Polar',
    'scatter'        => 'Dispersión',
    'bubble'         => 'Burbuja',
];

$analysis_modes = [
    'normal'     => 'Análisis normal',
    'prediction' => 'Predicción lineal',
];

$group_modes = [
    'dia'    => 'Por día',
    'semana' => 'Por semana',
    'mes'    => 'Por mes',
    'anio'   => 'Por año',
];

$professional_templates = [
    'libre' => [
        'label'       => 'Configuración libre',
        'description' => 'Selecciona fuente, series y estilo manualmente.',
    ],
    'ejecutivo_balance' => [
        'label'       => 'Balance ejecutivo',
        'description' => 'Compara ingresos, egresos y balance operativo en una vista directiva.',
        'source'      => 'sistema',
        'style'       => 'comboBarLine',
        'group'       => 'mes',
        'analysis'    => 'normal',
        'metrics'     => ['ingresos_ventas', 'egresos_compras', 'balance_operativo'],
    ],
    'operacion_360' => [
        'label'       => 'Operación 360',
        'description' => 'Integra ventas, compras, inventario, usuarios y documentos del sistema.',
        'source'      => 'sistema',
        'style'       => 'line',
        'group'       => 'mes',
        'analysis'    => 'normal',
        'metrics'     => ['ingresos_ventas', 'egresos_compras', 'documentos_subidos', 'altas_usuarios', 'alertas_inventario'],
    ],
    'inventario_control' => [
        'label'       => 'Control de inventario',
        'description' => 'Muestra stock global, stock mínimo y alertas para control operativo.',
        'source'      => 'inventario',
        'style'       => 'stackedBar',
        'group'       => 'semana',
        'analysis'    => 'normal',
        'metrics'     => ['stock_total', 'stock_minimo_total', 'productos_alerta'],
    ],
    'comercial_tendencia' => [
        'label'       => 'Tendencia comercial',
        'description' => 'Analiza desempeño de ventas con ticket promedio y volumen.',
        'source'      => 'ventas',
        'style'       => 'comboAreaLine',
        'group'       => 'mes',
        'analysis'    => 'normal',
        'metrics'     => ['total_ventas', 'ticket_promedio', 'cantidad_ventas'],
    ],
];

$data_sources = [
    'ventas' => [
        'label'       => 'Ventas',
        'table'       => 'Ventas',
        'date_column' => 'fecha_venta',
        'metrics'     => [
            'cantidad_ventas' => [
                'label'    => 'Cantidad de ventas',
                'sql'      => 'COUNT(*)',
                'currency' => false,
            ],
            'total_ventas' => [
                'label'    => 'Monto total vendido',
                'sql'      => 'COALESCE(SUM(monto_total), 0)',
                'currency' => true,
            ],
            'ticket_promedio' => [
                'label'    => 'Ticket promedio',
                'sql'      => 'COALESCE(AVG(monto_total), 0)',
                'currency' => true,
            ],
        ],
    ],
    'compras' => [
        'label'       => 'Compras',
        'table'       => 'Compras',
        'date_column' => 'fecha_compra',
        'metrics'     => [
            'cantidad_compras' => [
                'label'    => 'Cantidad de compras',
                'sql'      => 'COUNT(*)',
                'currency' => false,
            ],
            'monto_compras' => [
                'label'    => 'Monto total comprado',
                'sql'      => 'COALESCE(SUM(monto_total), 0)',
                'currency' => true,
            ],
            'unidades_compradas' => [
                'label'    => 'Unidades compradas',
                'sql'      => 'COALESCE(SUM(cantidad_comprada), 0)',
                'currency' => false,
            ],
        ],
    ],
    'inventario' => [
        'label'       => 'Inventario',
        'table'       => 'Inventario',
        'date_column' => 'fecha_ultima_actualizacion',
        'metrics'     => [
            'productos_registrados' => [
                'label'    => 'Productos registrados',
                'sql'      => 'COUNT(*)',
                'currency' => false,
            ],
            'stock_total' => [
                'label'    => 'Stock total disponible',
                'sql'      => 'COALESCE(SUM(cantidad_disponible), 0)',
                'currency' => false,
            ],
            'stock_minimo_total' => [
                'label'    => 'Stock mínimo acumulado',
                'sql'      => 'COALESCE(SUM(stock_minimo), 0)',
                'currency' => false,
            ],
            'productos_alerta' => [
                'label'    => 'Productos en alerta',
                'sql'      => 'COALESCE(SUM(CASE WHEN cantidad_disponible <= stock_minimo THEN 1 ELSE 0 END), 0)',
                'currency' => false,
            ],
        ],
    ],
    'documentos' => [
        'label'       => 'Documentos',
        'table'       => 'Documentos',
        'date_column' => 'fecha_subida',
        'metrics'     => [
            'documentos_subidos' => [
                'label'    => 'Documentos subidos',
                'sql'      => 'COUNT(*)',
                'currency' => false,
            ],
            'usuarios_carga' => [
                'label'    => 'Usuarios que cargan',
                'sql'      => 'COUNT(DISTINCT usuario_subio)',
                'currency' => false,
            ],
        ],
    ],
    'sistema' => [
        'label'       => 'Sistema 360',
        'table'       => '',
        'date_column' => '',
        'custom'      => true,
        'metrics'     => [
            'ingresos_ventas' => [
                'label'    => 'Ingresos por ventas',
                'sql'      => '',
                'currency' => true,
            ],
            'egresos_compras' => [
                'label'    => 'Egresos por compras',
                'sql'      => '',
                'currency' => true,
            ],
            'balance_operativo' => [
                'label'    => 'Balance operativo (Ventas - Compras)',
                'sql'      => '',
                'currency' => true,
            ],
            'documentos_subidos' => [
                'label'    => 'Documentos cargados',
                'sql'      => '',
                'currency' => false,
            ],
            'altas_usuarios' => [
                'label'    => 'Altas de usuarios',
                'sql'      => '',
                'currency' => false,
            ],
            'stock_global' => [
                'label'    => 'Stock global',
                'sql'      => '',
                'currency' => false,
            ],
            'alertas_inventario' => [
                'label'    => 'Alertas de inventario',
                'sql'      => '',
                'currency' => false,
            ],
        ],
    ],
];

$source_availability = [];
$first_available_source = '';
foreach ($data_sources as $source_key => $source_conf) {
    $available = !empty($source_conf['custom'])
        ? true
        : (graphTableExists($conn, $source_conf['table']) && graphColumnExists($conn, $source_conf['table'], $source_conf['date_column']));
    $source_availability[$source_key] = $available;
    if ($available && $first_available_source === '') {
        $first_available_source = $source_key;
    }
}

$selected_source = (string)($_POST['source'] ?? ($first_available_source !== '' ? $first_available_source : array_key_first($data_sources)));
if (!isset($data_sources[$selected_source]) || empty($source_availability[$selected_source])) {
    $selected_source = $first_available_source !== '' ? $first_available_source : array_key_first($data_sources);
}

$selected_style = (string)($_POST['chart_option'] ?? 'bar');
if (!isset($chart_styles[$selected_style])) {
    $selected_style = 'bar';
}

$selected_group = (string)($_POST['group_by'] ?? 'dia');
if (!isset($group_modes[$selected_group])) {
    $selected_group = 'dia';
}

$selected_analysis = (string)($_POST['analysis_mode'] ?? 'normal');
if (!isset($analysis_modes[$selected_analysis])) {
    $selected_analysis = 'normal';
}

$selected_template = (string)($_POST['professional_template'] ?? 'libre');
if (!isset($professional_templates[$selected_template])) {
    $selected_template = 'libre';
}
$template_meta = $professional_templates[$selected_template];
if ($selected_template !== 'libre') {
    $template_source = (string)($template_meta['source'] ?? '');
    if ($template_source !== '' && isset($data_sources[$template_source]) && !empty($source_availability[$template_source])) {
        $selected_source = $template_source;
        if (!empty($template_meta['style']) && isset($chart_styles[$template_meta['style']])) {
            $selected_style = (string)$template_meta['style'];
        }
        if (!empty($template_meta['group']) && isset($group_modes[$template_meta['group']])) {
            $selected_group = (string)$template_meta['group'];
        }
        if (!empty($template_meta['analysis']) && isset($analysis_modes[$template_meta['analysis']])) {
            $selected_analysis = (string)$template_meta['analysis'];
        }
    } else {
        $selected_template = 'libre';
        $template_meta = $professional_templates[$selected_template];
    }
}

$start_date = trim((string)($_POST['start_date'] ?? ''));
$end_date   = trim((string)($_POST['end_date'] ?? ''));
$future_date = trim((string)($_POST['future_date'] ?? ''));
$all_metrics_checked = isset($_POST['all_metrics']) && $_POST['all_metrics'] === '1';
$inventory_products = [];
$inventory_product_types = [];
$inventory_product_ids_by_type = [];
$inventory_product_ids_lookup = [];

if (!empty($source_availability['inventario'])) {
    $inventory_rows = dbFetchAll($conn, "SELECT id_producto, nombre_producto FROM Inventario ORDER BY nombre_producto ASC");
    foreach ($inventory_rows as $inventory_row) {
        $product_id = (int)($inventory_row['id_producto'] ?? 0);
        if ($product_id <= 0) continue;

        $product_name = trim((string)($inventory_row['nombre_producto'] ?? ''));
        if ($product_name === '') {
            $product_name = 'Producto #' . $product_id;
        }

        $product_type = graphInferInventoryType($product_name);
        $inventory_products[] = [
            'id'   => $product_id,
            'name' => $product_name,
            'type' => $product_type,
        ];

        $inventory_product_types[$product_type] = $product_type;
        if (!isset($inventory_product_ids_by_type[$product_type])) {
            $inventory_product_ids_by_type[$product_type] = [];
        }
        $inventory_product_ids_by_type[$product_type][] = $product_id;
        $inventory_product_ids_lookup[$product_id] = true;
    }
    ksort($inventory_product_types, SORT_NATURAL | SORT_FLAG_CASE);
}

$selected_product_type = (string)($_POST['product_type'] ?? 'all');
if ($selected_product_type !== 'all' && !isset($inventory_product_types[$selected_product_type])) {
    $selected_product_type = 'all';
}

$selected_product_ids = [];
foreach ((array)($_POST['product_ids'] ?? []) as $posted_product_id) {
    $product_id = (int)$posted_product_id;
    if ($product_id > 0 && isset($inventory_product_ids_lookup[$product_id])) {
        $selected_product_ids[] = $product_id;
    }
}
$selected_product_ids = array_values(array_unique($selected_product_ids));

$source_meta = $data_sources[$selected_source];
$metrics_for_source = $source_meta['metrics'];

$posted_metrics = array_values(array_filter(
    (array)($_POST['metrics'] ?? []),
    static fn($metric_key) => isset($metrics_for_source[$metric_key])
));
$selected_metric_keys = ($all_metrics_checked || empty($posted_metrics))
    ? array_keys($metrics_for_source)
    : $posted_metrics;
if ($selected_template !== 'libre' && !empty($template_meta['metrics']) && is_array($template_meta['metrics'])) {
    $selected_metric_keys = array_values(array_filter(
        $template_meta['metrics'],
        static fn($metric_key) => isset($metrics_for_source[$metric_key])
    ));
    $all_metrics_checked = false;
}

$error_message = '';
$warning_message = '';
$chart_payload = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (empty($source_availability[$selected_source])) {
        $error_message = 'La fuente seleccionada no está disponible en la base de datos actual.';
    }

    if ($start_date !== '' && $end_date !== '' && $end_date < $start_date) {
        $error_message = 'La fecha final no puede ser menor que la fecha inicial.';
    }

    if ($selected_analysis === 'prediction' && $future_date === '') {
        $error_message = 'Para predicción debes indicar una fecha futura.';
    }

    if ($selected_analysis === 'prediction' && count($selected_metric_keys) > 1) {
        $selected_metric_keys = [reset($selected_metric_keys)];
        $warning_message = 'La predicción lineal usa una sola serie; se tomó la primera métrica seleccionada.';
    }

    if (empty($selected_metric_keys)) {
        $error_message = 'Selecciona al menos una serie para generar la gráfica.';
    }

    if ($error_message === '') {
        $rows = [];
        if (!empty($source_meta['custom']) && $selected_source === 'sistema') {
            $rows = graphBuildSystemRows($conn, $selected_group, $start_date, $end_date);
        } else {
            $period_expr = graphPeriodExpression($source_meta['date_column'], $selected_group);

            $metric_chunks = [];
            foreach ($selected_metric_keys as $metric_key) {
                $metric_chunks[] = $metrics_for_source[$metric_key]['sql'] . " AS `$metric_key`";
            }

            $query = "SELECT $period_expr AS periodo, " . implode(', ', $metric_chunks) .
                     " FROM {$source_meta['table']} WHERE {$source_meta['date_column']} IS NOT NULL";
            $types = '';
            $params = [];

            if ($start_date !== '') {
                $query .= " AND DATE({$source_meta['date_column']}) >= ?";
                $types .= 's';
                $params[] = $start_date;
            }
            if ($end_date !== '') {
                $query .= " AND DATE({$source_meta['date_column']}) <= ?";
                $types .= 's';
                $params[] = $end_date;
            }

            if ($selected_source === 'inventario') {
                $filtered_product_ids = [];
                if ($selected_product_type !== 'all') {
                    $filtered_product_ids = $inventory_product_ids_by_type[$selected_product_type] ?? [];
                }

                if (!empty($selected_product_ids)) {
                    if (empty($filtered_product_ids)) {
                        $filtered_product_ids = $selected_product_ids;
                    } else {
                        $filtered_product_ids = array_values(array_intersect($filtered_product_ids, $selected_product_ids));
                    }
                }

                if (!empty($filtered_product_ids)) {
                    $placeholders = implode(',', array_fill(0, count($filtered_product_ids), '?'));
                    $query .= " AND id_producto IN ($placeholders)";
                    $types .= str_repeat('i', count($filtered_product_ids));
                    foreach ($filtered_product_ids as $product_id) {
                        $params[] = (int)$product_id;
                    }
                } elseif ($selected_product_type !== 'all' || !empty($selected_product_ids)) {
                    $query .= ' AND 1=0';
                }
            }

            $query .= ' GROUP BY periodo ORDER BY periodo ASC';
            $rows = dbFetchAll($conn, $query, $types, ...$params);
        }

        if (empty($rows)) {
            $error_message = 'No hay datos para los filtros seleccionados.';
        } else {
            $raw_labels = [];
            $display_labels = [];
            $series_map = [];
            foreach ($selected_metric_keys as $metric_key) {
                $series_map[$metric_key] = [];
            }

            foreach ($rows as $row) {
                $period = (string)($row['periodo'] ?? '');
                if ($period === '') continue;

                $raw_labels[] = $period;
                $display_labels[] = graphFormatPeriodLabel($period, $selected_group);

                foreach ($selected_metric_keys as $metric_key) {
                    $series_map[$metric_key][] = isset($row[$metric_key]) ? round((float)$row[$metric_key], 2) : 0.0;
                }
            }

            if (empty($raw_labels)) {
                $error_message = 'No se pudieron construir periodos válidos para la gráfica.';
            } elseif ($selected_analysis === 'prediction') {
                if (count($raw_labels) < 2) {
                    $error_message = 'La predicción requiere al menos dos puntos históricos.';
                } else {
                    $metric_key = $selected_metric_keys[0];
                    $values = $series_map[$metric_key];
                    $n = count($values);

                    $x_values = range(0, $n - 1);
                    $x_sum = array_sum($x_values);
                    $y_sum = array_sum($values);
                    $xx_sum = array_sum(array_map(static fn($x) => $x * $x, $x_values));
                    $xy_sum = array_sum(array_map(static fn($x, $y) => $x * $y, $x_values, $values));

                    $denominator = ($n * $xx_sum - $x_sum * $x_sum);
                    $slope = $denominator !== 0 ? (($n * $xy_sum - $x_sum * $y_sum) / $denominator) : 0;
                    $intercept = ($y_sum - $slope * $x_sum) / max(1, $n);

                    try {
                        $cursor_date = new DateTime((string)end($raw_labels));
                        $target_date = new DateTime($future_date);
                    } catch (Throwable $e) {
                        $error_message = 'No fue posible interpretar la fecha futura indicada.';
                    }

                    if ($error_message === '') {
                        if ($target_date <= $cursor_date) {
                            $error_message = 'La fecha de predicción debe ser posterior al último periodo disponible.';
                        } else {
                            $step = graphProjectionStep($selected_group);
                            while ($cursor_date < $target_date) {
                                $cursor_date->add($step);
                                if ($cursor_date > $target_date) break;

                                $projected_index = count($values);
                                $projected_value = ($slope * $projected_index) + $intercept;
                                $projected_raw = $cursor_date->format('Y-m-d');

                                $raw_labels[] = $projected_raw;
                                $display_labels[] = graphFormatPeriodLabel($projected_raw, $selected_group);
                                $values[] = round($projected_value, 2);
                            }
                            $series_map[$metric_key] = $values;
                        }
                    }
                }
            }

            if ($error_message === '') {
                $palette = ['#5d87ff', '#49beff', '#13deb9', '#f559af', '#f6b51e', '#8b5cf6', '#ef4444', '#22c55e', '#0ea5e9'];
                $series_payload = [];
                $global_min = null;
                $global_max = null;

                foreach ($selected_metric_keys as $idx => $metric_key) {
                    $data_points = $series_map[$metric_key];
                    foreach ($data_points as $value) {
                        $global_min = ($global_min === null) ? $value : min($global_min, $value);
                        $global_max = ($global_max === null) ? $value : max($global_max, $value);
                    }

                    $series_payload[] = [
                        'key'        => $metric_key,
                        'label'      => $metrics_for_source[$metric_key]['label'],
                        'data'       => $data_points,
                        'color'      => $palette[$idx % count($palette)],
                        'isCurrency' => !empty($metrics_for_source[$metric_key]['currency']),
                    ];
                }

                $chart_payload = [
                    'sourceLabel'   => $source_meta['label'],
                    'analysisLabel' => $analysis_modes[$selected_analysis],
                    'styleLabel'    => $chart_styles[$selected_style],
                    'groupLabel'    => $group_modes[$selected_group],
                    'labels'        => $display_labels,
                    'rawLabels'     => $raw_labels,
                    'series'        => $series_payload,
                    'isPrediction'  => $selected_analysis === 'prediction',
                    'futureDate'    => $future_date,
                    'seriesCount'   => count($series_payload),
                    'pointsCount'   => count($display_labels),
                    'maxValue'      => $global_max,
                    'minValue'      => $global_min,
                ];
            }
        }
    }

}

$metrics_matrix = [];
foreach ($data_sources as $source_key => $source_conf) {
    $metrics_matrix[$source_key] = [];
    foreach ($source_conf['metrics'] as $metric_key => $metric_meta) {
        $metrics_matrix[$source_key][] = [
            'key'   => $metric_key,
            'label' => $metric_meta['label'],
        ];
    }
}
$professional_templates_js = [];
foreach ($professional_templates as $template_key => $template_meta_item) {
    $professional_templates_js[$template_key] = [
        'source'   => (string)($template_meta_item['source'] ?? ''),
        'style'    => (string)($template_meta_item['style'] ?? ''),
        'group'    => (string)($template_meta_item['group'] ?? ''),
        'analysis' => (string)($template_meta_item['analysis'] ?? ''),
        'metrics'  => array_values((array)($template_meta_item['metrics'] ?? [])),
    ];
}

include('layout/sidebar.php');
$print_generated_at = appFormatDateTime(time());
?>

<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

<div class="page-banner">
    <div class="page-banner-content">
        <h1>Gráficas</h1>
        <div class="page-banner-breadcrumb">
            <a href="dashboard.php">Inicio</a>
            <span class="sep">•</span>
            <span>Gráficas</span>
        </div>
    </div>
    <img src="assets/images/breadcrumb/inventario_productos_banner.svg" alt="Banner de gráficas del sistema" class="page-banner-img">
</div>

<div class="module-actions-row">
    <button type="button" class="btn-secondary-master btn-print-module" onclick="window.print()">
        <i class="fas fa-print"></i> Imprimir / PDF
    </button>
</div>
<div class="module-print-header">
    <img src="<?= htmlspecialchars($instance_logo, ENT_QUOTES, 'UTF-8') ?>" alt="<?= htmlspecialchars($instance_name, ENT_QUOTES, 'UTF-8') ?>" class="module-print-header-logo">
    <div class="module-print-header-copy">
        <h2><?= htmlspecialchars($instance_name, ENT_QUOTES, 'UTF-8') ?></h2>
        <p>Reporte de gráficas</p>
        <span>Generado: <?= htmlspecialchars($print_generated_at, ENT_QUOTES, 'UTF-8') ?></span>
    </div>
</div>

<?php if (!empty($error_message)): ?>
<div class="alert-master error"><i class="fas fa-exclamation-circle"></i> <?= htmlspecialchars($error_message, ENT_QUOTES, 'UTF-8') ?></div>
<?php endif; ?>

<?php if (!empty($warning_message)): ?>
<div class="alert-master warning"><i class="fas fa-triangle-exclamation"></i> <?= htmlspecialchars($warning_message, ENT_QUOTES, 'UTF-8') ?></div>
<?php endif; ?>

<div class="card-master">
    <div class="card-header-master">
        <h3><i class="fas fa-sliders icon-cyan"></i>Configurar gráfica avanzada</h3>
    </div>
    <form method="POST" action="graficas.php" class="form-stack" id="graphsForm">
        <div class="form-grid-auto">
            <div class="form-group">
                <label class="form-label" for="professional_template">Plantilla profesional</label>
                <select name="professional_template" id="professional_template" class="form-control">
                    <?php foreach ($professional_templates as $template_key => $template_info): ?>
                    <option value="<?= htmlspecialchars($template_key, ENT_QUOTES, 'UTF-8') ?>" <?= $selected_template === $template_key ? 'selected' : '' ?>>
                        <?= htmlspecialchars($template_info['label'], ENT_QUOTES, 'UTF-8') ?>
                    </option>
                    <?php endforeach; ?>
                </select>
                <span class="form-helper" id="template_helper">
                    <?= htmlspecialchars((string)($professional_templates[$selected_template]['description'] ?? 'Selecciona una plantilla para aplicar combinaciones automáticas.'), ENT_QUOTES, 'UTF-8') ?>
                </span>
            </div>
            <div class="form-group">
                <label class="form-label" for="source">Fuente de datos</label>
                <select name="source" id="source" class="form-control" required>
                    <?php foreach ($data_sources as $source_key => $source_conf): ?>
                    <?php $is_available = !empty($source_availability[$source_key]); ?>
                    <option value="<?= htmlspecialchars($source_key, ENT_QUOTES, 'UTF-8') ?>" <?= $selected_source === $source_key ? 'selected' : '' ?> <?= $is_available ? '' : 'disabled' ?>>
                        <?= htmlspecialchars($source_conf['label'], ENT_QUOTES, 'UTF-8') ?><?= $is_available ? '' : ' (no disponible)' ?>
                    </option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="form-group">
                <label class="form-label" for="product_type">Tipo de producto (Inventario)</label>
                <select name="product_type" id="product_type" class="form-control">
                    <option value="all" <?= $selected_product_type === 'all' ? 'selected' : '' ?>>Todos los tipos</option>
                    <?php foreach ($inventory_product_types as $product_type_label): ?>
                    <option value="<?= htmlspecialchars($product_type_label, ENT_QUOTES, 'UTF-8') ?>" <?= $selected_product_type === $product_type_label ? 'selected' : '' ?>>
                        <?= htmlspecialchars($product_type_label, ENT_QUOTES, 'UTF-8') ?>
                    </option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="form-group">
                <label class="form-label" for="product_ids">Productos específicos (Inventario)</label>
                <select name="product_ids[]" id="product_ids" class="form-control graph-products-select" multiple size="5">
                    <?php if (empty($inventory_products)): ?>
                    <option value="" disabled>Inventario no disponible para filtros</option>
                    <?php else: ?>
                    <?php foreach ($inventory_products as $inventory_product): ?>
                    <option
                        value="<?= (int)$inventory_product['id'] ?>"
                        data-type="<?= htmlspecialchars($inventory_product['type'], ENT_QUOTES, 'UTF-8') ?>"
                        <?= in_array((int)$inventory_product['id'], $selected_product_ids, true) ? 'selected' : '' ?>
                    >
                        <?= htmlspecialchars($inventory_product['name'] . ' · ' . $inventory_product['type'], ENT_QUOTES, 'UTF-8') ?>
                    </option>
                    <?php endforeach; ?>
                    <?php endif; ?>
                </select>
                <span class="form-helper" id="product_filter_helper">Filtra por tipo y selecciona uno o varios productos del inventario.</span>
            </div>
            <div class="form-group">
                <label class="form-label" for="chart_option">Estilo de gráfica</label>
                <select name="chart_option" id="chart_option" class="form-control" required>
                    <?php foreach ($chart_styles as $style_key => $style_label): ?>
                    <option value="<?= htmlspecialchars($style_key, ENT_QUOTES, 'UTF-8') ?>" <?= $selected_style === $style_key ? 'selected' : '' ?>>
                        <?= htmlspecialchars($style_label, ENT_QUOTES, 'UTF-8') ?>
                    </option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="form-group">
                <label class="form-label" for="group_by">Agrupar datos</label>
                <select name="group_by" id="group_by" class="form-control" required>
                    <?php foreach ($group_modes as $group_key => $group_label): ?>
                    <option value="<?= htmlspecialchars($group_key, ENT_QUOTES, 'UTF-8') ?>" <?= $selected_group === $group_key ? 'selected' : '' ?>>
                        <?= htmlspecialchars($group_label, ENT_QUOTES, 'UTF-8') ?>
                    </option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="form-group">
                <label class="form-label" for="analysis_mode">Modo de análisis</label>
                <select name="analysis_mode" id="analysis_mode" class="form-control" required>
                    <?php foreach ($analysis_modes as $analysis_key => $analysis_label): ?>
                    <option value="<?= htmlspecialchars($analysis_key, ENT_QUOTES, 'UTF-8') ?>" <?= $selected_analysis === $analysis_key ? 'selected' : '' ?>>
                        <?= htmlspecialchars($analysis_label, ENT_QUOTES, 'UTF-8') ?>
                    </option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="form-group">
                <label class="form-label" for="start_date">Fecha inicial</label>
                <input type="date" name="start_date" id="start_date" class="form-control" value="<?= htmlspecialchars($start_date, ENT_QUOTES, 'UTF-8') ?>">
            </div>
            <div class="form-group">
                <label class="form-label" for="end_date">Fecha final</label>
                <input type="date" name="end_date" id="end_date" class="form-control" value="<?= htmlspecialchars($end_date, ENT_QUOTES, 'UTF-8') ?>">
            </div>
            <div class="form-group" id="future_date_group" style="display:<?= $selected_analysis === 'prediction' ? 'block' : 'none' ?>;">
                <label class="form-label" for="future_date">Fecha de predicción</label>
                <input type="date" name="future_date" id="future_date" class="form-control" value="<?= htmlspecialchars($future_date, ENT_QUOTES, 'UTF-8') ?>">
            </div>
        </div>

        <div class="form-group">
            <label class="form-label">Series a graficar</label>
            <div class="graph-metric-grid" id="metricGrid"></div>
            <span class="form-helper">Puedes elegir una, varias o todas las series disponibles para la fuente seleccionada.</span>
        </div>

        <div class="graph-insight-bar">
            <label class="graph-metric-item" for="all_metrics">
                <input type="checkbox" name="all_metrics" id="all_metrics" value="1" <?= $all_metrics_checked ? 'checked' : '' ?>>
                <span>Graficar todas las series disponibles</span>
            </label>
            <span>Fuente actual: <?= htmlspecialchars($source_meta['label'], ENT_QUOTES, 'UTF-8') ?> · Series disponibles: <?= count($source_meta['metrics']) ?></span>
        </div>

        <div class="form-actions-row">
            <button type="submit" class="btn-primary-master">
                <i class="fas fa-chart-line"></i> Generar gráfica
            </button>
            <button type="button" class="btn-secondary-master" onclick="document.getElementById('graphsForm').reset(); window.location='graficas.php';">
                <i class="fas fa-rotate-left"></i> Limpiar
            </button>
        </div>
    </form>
</div>

<?php if ($chart_payload !== null && empty($error_message)): ?>
<div class="card-master">
    <div class="card-header-master">
        <h3><i class="fas fa-chart-area icon-pink"></i><?= htmlspecialchars($chart_payload['sourceLabel'], ENT_QUOTES, 'UTF-8') ?></h3>
        <span class="badge-pill badge-info"><?= htmlspecialchars($chart_payload['styleLabel'], ENT_QUOTES, 'UTF-8') ?> · <?= htmlspecialchars($chart_payload['analysisLabel'], ENT_QUOTES, 'UTF-8') ?></span>
    </div>
    <div class="graph-insight-bar" style="margin:14px 16px 0;">
        <span>Series: <?= (int)$chart_payload['seriesCount'] ?> · Puntos: <?= (int)$chart_payload['pointsCount'] ?> · Agrupación: <?= htmlspecialchars($chart_payload['groupLabel'], ENT_QUOTES, 'UTF-8') ?></span>
        <span>Rango: <?= htmlspecialchars(number_format((float)$chart_payload['minValue'], 2, '.', ','), ENT_QUOTES, 'UTF-8') ?> → <?= htmlspecialchars(number_format((float)$chart_payload['maxValue'], 2, '.', ','), ENT_QUOTES, 'UTF-8') ?></span>
    </div>
    <div class="chart-stage">
        <canvas id="advancedChart"></canvas>
    </div>
</div>
<?php elseif ($_SERVER['REQUEST_METHOD'] !== 'POST'): ?>
<div class="card-master">
    <div class="empty-state">
        <i class="fas fa-chart-bar"></i>
        <p>Configura tus filtros y genera una gráfica con cualquier estilo disponible.</p>
    </div>
</div>
<?php endif; ?>

<script>
(function () {
    var metricsMatrix = <?= json_encode($metrics_matrix, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) ?>;
    var templateMatrix = <?= json_encode($professional_templates_js, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) ?>;
    var templateCatalog = <?= json_encode($professional_templates, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) ?>;
    var selectedSource = <?= json_encode($selected_source, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) ?>;
    var selectedMetrics = <?= json_encode(array_values($selected_metric_keys), JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) ?>;
    var metricGrid = document.getElementById('metricGrid');
    var templateSelect = document.getElementById('professional_template');
    var templateHelper = document.getElementById('template_helper');
    var sourceSelect = document.getElementById('source');
    var chartOptionSelect = document.getElementById('chart_option');
    var groupBySelect = document.getElementById('group_by');
    var allMetricsToggle = document.getElementById('all_metrics');
    var analysisModeSelect = document.getElementById('analysis_mode');
    var futureDateGroup = document.getElementById('future_date_group');
    var productTypeSelect = document.getElementById('product_type');
    var productIdsSelect = document.getElementById('product_ids');
    var productFilterHelper = document.getElementById('product_filter_helper');

    function toggleFutureDate() {
        if (!analysisModeSelect || !futureDateGroup) return;
        futureDateGroup.style.display = analysisModeSelect.value === 'prediction' ? 'block' : 'none';
    }

    function markAllMetrics(checked, disabled) {
        if (!metricGrid) return;
        metricGrid.querySelectorAll('input[type="checkbox"]').forEach(function (cb) {
            cb.checked = checked;
            cb.disabled = !!disabled;
        });
    }
    function isTemplateMode() {
        return !!(templateSelect && templateSelect.value && templateSelect.value !== 'libre');
    }

    function updateTemplateHelper() {
        if (!templateHelper || !templateSelect) return;
        var key = templateSelect.value || 'libre';
        var info = templateCatalog[key] || {};
        templateHelper.textContent = info.description || 'Selecciona una plantilla para aplicar combinaciones automáticas.';
    }

    function lockControlsForTemplate() {
        var locked = isTemplateMode();
        [sourceSelect, chartOptionSelect, groupBySelect, analysisModeSelect].forEach(function (control) {
            if (!control) return;
            control.disabled = locked;
        });
        if (allMetricsToggle) {
            allMetricsToggle.disabled = locked;
        }
    }

    function rebuildMetricGrid(sourceKey) {
        if (!metricGrid) return;
        var metrics = metricsMatrix[sourceKey] || [];
        metricGrid.innerHTML = '';

        metrics.forEach(function (metric) {
            var item = document.createElement('label');
            item.className = 'graph-metric-item';

            var checkbox = document.createElement('input');
            checkbox.type = 'checkbox';
            checkbox.name = 'metrics[]';
            checkbox.value = metric.key;
            checkbox.checked = (selectedMetrics.length === 0 || selectedMetrics.indexOf(metric.key) !== -1);
            checkbox.disabled = isTemplateMode();

            var text = document.createElement('span');
            text.textContent = metric.label;

            item.appendChild(checkbox);
            item.appendChild(text);
            metricGrid.appendChild(item);
        });

        if (allMetricsToggle && allMetricsToggle.checked) {
            markAllMetrics(true, true);
        }
    }

    function syncInventoryProductFilters() {
        if (!productTypeSelect || !productIdsSelect) return;

        var isInventorySource = sourceSelect && sourceSelect.value === 'inventario';
        productTypeSelect.disabled = !isInventorySource;
        productIdsSelect.disabled = !isInventorySource;

        var selectedType = productTypeSelect.value || 'all';
        var visibleProducts = 0;

        Array.prototype.forEach.call(productIdsSelect.options, function (option) {
            if (!option.value) return;
            var productType = option.getAttribute('data-type') || '';
            var visible = selectedType === 'all' || productType === selectedType;
            option.hidden = !visible;
            if (!visible) {
                option.selected = false;
            } else {
                visibleProducts++;
            }
        });

        if (productFilterHelper) {
            if (!isInventorySource) {
                productFilterHelper.textContent = 'Los filtros de tipo/producto se habilitan al seleccionar la fuente Inventario.';
            } else if (visibleProducts === 0) {
                productFilterHelper.textContent = 'No hay productos disponibles para el tipo seleccionado.';
            } else {
                productFilterHelper.textContent = 'Productos visibles para este tipo: ' + visibleProducts + '. Puedes seleccionar varios.';
            }
        }
    }

    function applyTemplateConfig() {
        if (!templateSelect) return;
        var key = templateSelect.value || 'libre';
        var info = templateMatrix[key] || {};
        updateTemplateHelper();

        if (key !== 'libre') {
            if (sourceSelect && info.source) {
                var sourceOption = sourceSelect.querySelector("option[value='" + info.source + "']");
                if (sourceOption && !sourceOption.disabled) {
                    sourceSelect.value = info.source;
                }
            }
            if (chartOptionSelect && info.style && chartOptionSelect.querySelector("option[value='" + info.style + "']")) {
                chartOptionSelect.value = info.style;
            }
            if (groupBySelect && info.group && groupBySelect.querySelector("option[value='" + info.group + "']")) {
                groupBySelect.value = info.group;
            }
            if (analysisModeSelect && info.analysis && analysisModeSelect.querySelector("option[value='" + info.analysis + "']")) {
                analysisModeSelect.value = info.analysis;
            }
            selectedMetrics = Array.isArray(info.metrics) ? info.metrics.slice() : [];
            if (allMetricsToggle) {
                allMetricsToggle.checked = false;
            }
        }

        rebuildMetricGrid(sourceSelect ? sourceSelect.value : selectedSource);
        syncInventoryProductFilters();
        toggleFutureDate();
        lockControlsForTemplate();
    }

    if (productTypeSelect) {
        productTypeSelect.addEventListener('change', syncInventoryProductFilters);
    }

    if (analysisModeSelect) {
        analysisModeSelect.addEventListener('change', toggleFutureDate);
    }

    if (sourceSelect) {
        sourceSelect.addEventListener('change', function () {
            if (isTemplateMode()) return;
            selectedMetrics = [];
            rebuildMetricGrid(this.value);
            syncInventoryProductFilters();
        });
    }

    if (allMetricsToggle) {
        allMetricsToggle.addEventListener('change', function () {
            if (this.checked) {
                markAllMetrics(true, true);
            } else {
                markAllMetrics(true, false);
            }
        });
    }

    if (templateSelect) {
        templateSelect.addEventListener('change', applyTemplateConfig);
        applyTemplateConfig();
    } else {
        rebuildMetricGrid(selectedSource);
        syncInventoryProductFilters();
        toggleFutureDate();
    }
})();
</script>

<?php if ($chart_payload !== null && empty($error_message)): ?>
<script>
(function () {
    var payload = <?= json_encode($chart_payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) ?>;
    var chartStyle = <?= json_encode($selected_style, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) ?>;
    var currencySymbol = <?= json_encode(appCurrencySymbol(), JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) ?>;
    var canvas = document.getElementById('advancedChart');
    if (!canvas || !payload || !payload.series || payload.series.length === 0) return;

    function colorWithAlpha(hex, alpha) {
        var value = String(hex || '#5d87ff').replace('#', '');
        if (value.length !== 6) {
            return 'rgba(93,135,255,' + alpha + ')';
        }
        var r = parseInt(value.substring(0, 2), 16);
        var g = parseInt(value.substring(2, 4), 16);
        var b = parseInt(value.substring(4, 6), 16);
        return 'rgba(' + r + ',' + g + ',' + b + ',' + alpha + ')';
    }

    function formatValue(value, isCurrency) {
        var numeric = Number(value || 0);
        if (!isFinite(numeric)) return String(value || '');
        var formatted = numeric.toLocaleString('es-MX', { minimumFractionDigits: 0, maximumFractionDigits: 2 });
        return isCurrency ? (currencySymbol + ' ' + formatted) : formatted;
    }

    var arcPalette = ['#5d87ff', '#49beff', '#13deb9', '#f559af', '#f6b51e', '#8b5cf6', '#ef4444', '#22c55e', '#0ea5e9'];
    var labels = payload.labels || [];
    var rawLabels = payload.rawLabels || labels;
    var series = payload.series || [];

    var styleFlags = {
        line: chartStyle === 'line',
        area: chartStyle === 'area',
        lineStepped: chartStyle === 'lineStepped',
        stackedBar: chartStyle === 'stackedBar',
        horizontalBar: chartStyle === 'horizontalBar',
        comboBarLine: chartStyle === 'comboBarLine',
        comboAreaLine: chartStyle === 'comboAreaLine',
        radar: chartStyle === 'radar',
        scatter: chartStyle === 'scatter',
        bubble: chartStyle === 'bubble',
        arc: chartStyle === 'pie' || chartStyle === 'doughnut' || chartStyle === 'polarArea'
    };

    var chartType = 'bar';
    if (styleFlags.scatter || styleFlags.bubble || styleFlags.arc || styleFlags.radar) {
        chartType = chartStyle;
    } else if (styleFlags.line || styleFlags.area || styleFlags.lineStepped || styleFlags.comboAreaLine) {
        chartType = 'line';
    }

    var dataConfig = { labels: labels, datasets: [] };
    var optionsConfig = {
        responsive: true,
        maintainAspectRatio: false,
        interaction: { mode: 'index', intersect: false },
        plugins: {
            legend: { display: true, labels: { usePointStyle: true } },
            tooltip: {
                callbacks: {
                    label: function (context) {
                        var datasetMeta = series[context.datasetIndex] || null;
                        var currency = !!(datasetMeta && datasetMeta.isCurrency);
                        var parsedValue = context.parsed;
                        if (parsedValue && typeof parsedValue === 'object') {
                            if (typeof parsedValue.y !== 'undefined') {
                                parsedValue = parsedValue.y;
                            } else if (typeof parsedValue.x !== 'undefined') {
                                parsedValue = parsedValue.x;
                            }
                        }
                        var baseText = datasetMeta ? datasetMeta.label + ': ' : '';
                        return baseText + formatValue(parsedValue, currency);
                    },
                    title: function (items) {
                        if (!items || !items.length) return '';
                        var first = items[0];
                        if (styleFlags.scatter || styleFlags.bubble) {
                            var rawPoint = first.raw || {};
                            return rawPoint.metaLabel || '';
                        }
                        return first.label || '';
                    }
                }
            }
        }
    };

    if (styleFlags.scatter || styleFlags.bubble) {
        dataConfig.datasets = series.map(function (metric) {
            var maxMetric = Math.max.apply(null, metric.data.concat([1]));
            return {
                label: metric.label,
                borderColor: metric.color,
                backgroundColor: colorWithAlpha(metric.color, 0.34),
                data: metric.data.map(function (value, idx) {
                    var radius = styleFlags.bubble
                        ? Math.max(4, Math.min(18, (Math.abs(value) / maxMetric) * 14 + 4))
                        : undefined;
                    var point = {
                        x: idx + 1,
                        y: Number(value),
                        metaLabel: labels[idx] || rawLabels[idx] || ''
                    };
                    if (styleFlags.bubble) {
                        point.r = radius;
                    }
                    return point;
                }),
                pointRadius: styleFlags.bubble ? undefined : 4
            };
        });

        optionsConfig.interaction = { mode: 'nearest', intersect: false };
        optionsConfig.scales = {
            x: {
                type: 'linear',
                beginAtZero: true,
                ticks: {
                    callback: function (value) {
                        var idx = Math.round(Number(value)) - 1;
                        return labels[idx] || '';
                    }
                },
                title: { display: true, text: payload.groupLabel || 'Periodo' },
                grid: { color: 'rgba(148,163,184,0.16)' }
            },
            y: {
                beginAtZero: true,
                grid: { color: 'rgba(148,163,184,0.16)' },
                title: { display: true, text: 'Valor' }
            }
        };
    } else if (styleFlags.arc) {
        dataConfig.datasets = series.map(function (metric, metricIndex) {
            return {
                label: metric.label,
                data: metric.data.map(function (value) { return Number(value); }),
                backgroundColor: labels.map(function (_, labelIndex) {
                    return arcPalette[(labelIndex + metricIndex) % arcPalette.length];
                }),
                borderColor: chartStyle === 'polarArea' ? 'rgba(255,255,255,0.16)' : '#ffffff',
                borderWidth: 1
            };
        });
    } else if (styleFlags.radar) {
        dataConfig.datasets = series.map(function (metric) {
            return {
                label: metric.label,
                data: metric.data.map(function (value) { return Number(value); }),
                borderColor: metric.color,
                backgroundColor: colorWithAlpha(metric.color, 0.16),
                pointBackgroundColor: metric.color,
                pointRadius: 3,
                borderWidth: 2,
                fill: true
            };
        });

        optionsConfig.scales = {
            r: {
                beginAtZero: true,
                grid: { color: 'rgba(148,163,184,0.2)' },
                pointLabels: { color: '#94a3b8' },
                angleLines: { color: 'rgba(148,163,184,0.2)' }
            }
        };
    } else {
        dataConfig.datasets = series.map(function (metric, index) {
            var datasetType = 'bar';
            var backgroundAlpha = 0.24;
            var fillMode = false;
            var tension = 0;
            var steppedMode = false;
            var pointRadius = 0;

            if (styleFlags.horizontalBar || styleFlags.stackedBar) {
                datasetType = 'bar';
            } else if (styleFlags.comboBarLine) {
                datasetType = index === series.length - 1 ? 'line' : 'bar';
            } else if (styleFlags.comboAreaLine) {
                datasetType = 'line';
                fillMode = index === 0 ? 'origin' : false;
                tension = 0.35;
                pointRadius = 3;
                backgroundAlpha = index === 0 ? 0.28 : 0.1;
            } else if (styleFlags.line || styleFlags.area || styleFlags.lineStepped) {
                datasetType = 'line';
                fillMode = styleFlags.area ? 'origin' : false;
                tension = styleFlags.lineStepped ? 0 : 0.35;
                steppedMode = styleFlags.lineStepped;
                pointRadius = 3;
                backgroundAlpha = styleFlags.area ? 0.28 : 0.1;
            }

            if (styleFlags.comboBarLine) {
                if (datasetType === 'line') {
                    tension = 0.35;
                    pointRadius = 3;
                    backgroundAlpha = 0.12;
                } else {
                    backgroundAlpha = 0.26;
                }
            }

            var dataset = {
                label: metric.label,
                data: metric.data.map(function (value) { return Number(value); }),
                type: datasetType,
                borderColor: metric.color,
                backgroundColor: colorWithAlpha(metric.color, backgroundAlpha),
                borderWidth: 2
            };

            if (datasetType === 'line') {
                dataset.fill = fillMode;
                dataset.tension = tension;
                dataset.pointRadius = pointRadius;
                dataset.pointHoverRadius = 5;
                if (steppedMode) {
                    dataset.stepped = true;
                }
            } else {
                dataset.borderRadius = 8;
                dataset.borderSkipped = false;
            }

            if (styleFlags.stackedBar) {
                dataset.stack = 'stack-total';
            }

            if (styleFlags.comboBarLine) {
                dataset.order = datasetType === 'line' ? 0 : 1;
            }

            return dataset;
        });

        var singleCurrencyAxis = series.length === 1 ? !!series[0].isCurrency : false;
        if (styleFlags.horizontalBar) {
            optionsConfig.indexAxis = 'y';
        }

        optionsConfig.scales = {
            x: {
                beginAtZero: styleFlags.horizontalBar,
                stacked: styleFlags.stackedBar,
                grid: { color: 'rgba(148,163,184,0.16)' },
                ticks: styleFlags.horizontalBar
                    ? {
                        callback: function (value) {
                            return formatValue(value, singleCurrencyAxis);
                        }
                    }
                    : { maxRotation: 0, autoSkip: true, maxTicksLimit: 10 },
                title: { display: true, text: styleFlags.horizontalBar ? 'Valor' : (payload.groupLabel || 'Periodo') }
            },
            y: {
                beginAtZero: !styleFlags.horizontalBar,
                stacked: styleFlags.stackedBar,
                grid: { color: 'rgba(148,163,184,0.16)' },
                ticks: styleFlags.horizontalBar
                    ? { maxRotation: 0, autoSkip: true, maxTicksLimit: 12 }
                    : {
                        callback: function (value) {
                            return formatValue(value, singleCurrencyAxis);
                        }
                    },
                title: { display: true, text: styleFlags.horizontalBar ? (payload.groupLabel || 'Periodo') : 'Valor' }
            }
        };
    }

    Chart.defaults.color = '#7c8aa5';
    Chart.defaults.font.family = "'DM Sans', sans-serif";
    Chart.defaults.font.size = 12;

    new Chart(canvas.getContext('2d'), {
        type: chartType,
        data: dataConfig,
        options: optionsConfig
    });
})();
</script>
<?php endif; ?>

<?php include('layout/footer_main.php'); ?>