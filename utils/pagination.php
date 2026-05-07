<?php
/**
 * Helpers de paginación server-side — Sistema de Gestión de Inventario
 */

function getPaginationParams(int $defaultLimit = 25): array {
    $page  = max(1, intval($_GET['page'] ?? 1));
    $limit = in_array(intval($_GET['limit'] ?? $defaultLimit), [10, 25, 50, 100])
        ? intval($_GET['limit'] ?? $defaultLimit)
        : $defaultLimit;
    $offset = ($page - 1) * $limit;
    return ['page' => $page, 'limit' => $limit, 'offset' => $offset];
}

function countTotal(mysqli $conn, string $countSql, string $types = '', mixed ...$params): int {
    $result = dbFetchOne($conn, $countSql, $types, ...$params);
    return $result ? intval(array_values($result)[0]) : 0;
}

function renderPagination(int $total, int $page, int $limit, array $extraParams = []): string {
    $totalPages = (int) ceil($total / $limit);
    if ($totalPages <= 1) return '';

    $base = array_merge($_GET, $extraParams, ['limit' => $limit]);
    unset($base['page']);

    $makeUrl = fn(int $p) => '?' . http_build_query(array_merge($base, ['page' => $p]));

    $from = ($page - 1) * $limit + 1;
    $to   = min($page * $limit, $total);

    $html  = "<div class='d-flex justify-content-between align-items-center mt-3 mb-2'>";
    $html .= "<small class='text-muted'>Mostrando {$from}–{$to} de {$total} registros</small>";
    $html .= "<div class='d-flex align-items-center gap-2'>";

    $currentPage = $page;
    $html .= "<select class='form-select form-select-sm' style='width:auto' onchange=\"window.location='" . htmlspecialchars($makeUrl(1), ENT_QUOTES) . "&limit='+this.value\">";
    foreach ([10, 25, 50, 100] as $opt) {
        $sel  = $opt === $limit ? 'selected' : '';
        $html .= "<option value='{$opt}' {$sel}>{$opt} por página</option>";
    }
    $html .= "</select>";

    $html .= "<nav><ul class='pagination pagination-sm mb-0'>";
    $html .= "<li class='page-item" . ($page <= 1 ? ' disabled' : '') . "'><a class='page-link' href='" . htmlspecialchars($makeUrl(1), ENT_QUOTES) . "'>«</a></li>";
    $html .= "<li class='page-item" . ($page <= 1 ? ' disabled' : '') . "'><a class='page-link' href='" . htmlspecialchars($makeUrl($page - 1), ENT_QUOTES) . "'>‹</a></li>";

    for ($i = max(1, $page - 2); $i <= min($totalPages, $page + 2); $i++) {
        $active = $i === $page ? ' active' : '';
        $html .= "<li class='page-item{$active}'><a class='page-link' href='" . htmlspecialchars($makeUrl($i), ENT_QUOTES) . "'>{$i}</a></li>";
    }

    $html .= "<li class='page-item" . ($page >= $totalPages ? ' disabled' : '') . "'><a class='page-link' href='" . htmlspecialchars($makeUrl($page + 1), ENT_QUOTES) . "'>›</a></li>";
    $html .= "<li class='page-item" . ($page >= $totalPages ? ' disabled' : '') . "'><a class='page-link' href='" . htmlspecialchars($makeUrl($totalPages), ENT_QUOTES) . "'>»</a></li>";
    $html .= "</ul></nav></div></div>";

    return $html;
}
