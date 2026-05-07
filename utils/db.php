<?php
/**
 * Helpers de base de datos — Sistema de Gestión de Inventario
 */

function dbQuery(mysqli $conn, string $sql, string $types = '', mixed ...$params): mysqli_result|bool {
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        error_log("DB prepare error: " . $conn->error . " | SQL: $sql");
        return false;
    }
    if ($types && $params) {
        $stmt->bind_param($types, ...$params);
    }
    if (!$stmt->execute()) {
        error_log("DB execute error: " . $stmt->error . " | SQL: $sql");
        $stmt->close();
        return false;
    }
    $result = $stmt->get_result();
    $stmt->close();
    return $result ?: true;
}

function dbFetchAll(mysqli $conn, string $sql, string $types = '', mixed ...$params): array {
    $result = dbQuery($conn, $sql, $types, ...$params);
    if (!$result || $result === true) return [];
    return $result->fetch_all(MYSQLI_ASSOC);
}

function dbFetchOne(mysqli $conn, string $sql, string $types = '', mixed ...$params): ?array {
    $result = dbQuery($conn, $sql, $types, ...$params);
    if (!$result || $result === true) return null;
    return $result->fetch_assoc() ?: null;
}

function dbExecute(mysqli $conn, string $sql, string $types = '', mixed ...$params): bool {
    return dbQuery($conn, $sql, $types, ...$params) !== false;
}

function dbLastInsertId(mysqli $conn): int {
    return $conn->insert_id;
}
