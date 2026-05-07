# Especificación Técnica — Módulos Compras y Proveedores

---
name: spec-compras-proveedores
modules: compras, proveedores
status: active
created: 2026-04-24T21:19:11Z
updated: 2026-04-24T21:19:11Z
---

## Índice

1. [Visión General](#1-visión-general)
2. [Archivos de los Módulos](#2-archivos-de-los-módulos)
3. [Máquinas de Estado](#3-máquinas-de-estado)
4. [Casos de Uso — Proveedores](#4-casos-de-uso--proveedores)
5. [Casos de Uso — Compras](#5-casos-de-uso--compras)
6. [Reglas de Negocio](#6-reglas-de-negocio)
7. [Validaciones](#7-validaciones)
8. [Operaciones de Base de Datos](#8-operaciones-de-base-de-datos)
9. [APIs de los Módulos](#9-apis-de-los-módulos)
10. [Schema de BD](#10-schema-de-bd)
11. [Organización Interna de Código](#11-organización-interna-de-código)
12. [Quality Requirements](#12-quality-requirements)
13. [Testing Scenarios](#13-testing-scenarios)

---

## 1. Visión General

### Proveedores
Directorio de empresas o personas que suministran productos al negocio. Cada compra está asociada a un proveedor.

### Compras
Registro de órdenes de compra realizadas a proveedores. Cuando una compra se completa, incrementa el stock del producto correspondiente en el inventario.

### Relación entre módulos
```
Proveedores  ←──────── Compras
    │ id_proveedor (FK)      │
    │                        │ Al completarse
    │                        ▼
    │                    Inventario.cantidad_disponible++
    │
    └── Módulo externo: importación CSV de proveedores
```

---

## 2. Archivos de los Módulos

| Archivo | Módulo | Responsabilidad | Acceso |
|---------|--------|----------------|--------|
| `gestion_proveedores.php` | Proveedores | CRUD de proveedores | Autenticado |
| `get_provider_details.php` | Proveedores | AJAX — detalle de proveedor | Autenticado |
| `update_provider.php` | Proveedores | AJAX — actualizar proveedor | Admin |
| `gestion_compras.php` | Compras | CRUD de compras | Autenticado |
| `get_purchase_details.php` | Compras | AJAX — detalle de compra | Autenticado |
| `update_purchase.php` | Compras | AJAX — actualizar compra | Admin/Empleado |

---

## 3. Máquinas de Estado

### 3.1 Estado de una Compra

```
        [En Curso]
       /          \
      /            \
[Completada]    [Cancelada]
(stock++         (sin cambio
por PHP)          de stock)
```

**Transiciones**:
| De | A | Acción en inventario |
|----|---|---------------------|
| — | En Curso | Ninguna (stock no cambia al crear la orden) |
| En Curso | Completada | `Inventario.cantidad_disponible += cantidad_comprada` |
| En Curso | Cancelada | Sin cambio en inventario |
| Completada | Cancelada | `Inventario.cantidad_disponible -= cantidad_comprada` (devolución) |

**Regla crítica**: El stock solo se actualiza cuando la compra pasa a "Completada", no al crearla. Esto diferencia el módulo de compras del de ventas (que descuenta al crear).

### 3.2 Estado de un Proveedor (implícito)

```
[Activo] ←──── default al crear
    │
    │ Admin elimina (solo si no tiene compras)
    ▼
[Eliminado]
```

Los proveedores no tienen un campo `estado` explícito. La "desactivación" es la eliminación física, protegida por FK constraint.

---

## 4. Casos de Uso — Proveedores

### CU-PROV-001: Listar proveedores

**Flujo**:
1. PHP ejecuta `SELECT * FROM Proveedores ORDER BY nombre_proveedor ASC`
2. Tabla renderizada con: ID, Nombre, Teléfono, Email, Dirección, Acciones

---

### CU-PROV-002: Crear proveedor

**Flujo**:
1. Admin abre modal de creación
2. Completa: nombre, teléfono, email, dirección
3. POST a `gestion_proveedores.php`
4. PHP valida campos
5. INSERT en Proveedores con prepared statement
6. Mostrar confirmación

---

### CU-PROV-003: Ver detalle de proveedor (AJAX)

**Actor**: Administrador  
**Flujo**:
1. Admin hace clic en "Ver detalle"
2. JavaScript llama a `get_provider_details.php?id={id_proveedor}`
3. PHP retorna JSON con datos del proveedor
4. Modal muestra los datos

---

### CU-PROV-004: Editar proveedor (AJAX)

**Actor**: Administrador  
**Flujo**:
1. Admin modifica datos en modal de edición
2. JavaScript llama a `update_provider.php` via POST
3. PHP valida y ejecuta UPDATE
4. JavaScript actualiza la tabla sin recargar la página

---

### CU-PROV-005: Eliminar proveedor

**Actor**: Administrador  
**Restricción**: Solo si el proveedor no tiene compras asociadas

**Flujo**:
1. Admin hace clic en "Eliminar" con confirmación
2. PHP verifica que no existen compras con `id_proveedor`
3. Si tiene compras → mostrar error: "No se puede eliminar: tiene compras registradas"
4. Si no tiene compras → DELETE

---

## 5. Casos de Uso — Compras

### CU-COMP-001: Listar compras

**Flujo**:
1. PHP ejecuta JOIN entre Compras y Proveedores
2. Tabla con: ID, Proveedor, Producto, Cantidad, Fecha, Monto, Estado, Acciones

---

### CU-COMP-002: Crear orden de compra

**Actor**: Administrador o Empleado  
**Postcondición**: Compra en estado "En Curso", sin cambio en inventario todavía

**Flujo**:
1. Usuario abre formulario de nueva compra
2. Selecciona proveedor del dropdown
3. Ingresa: nombre del producto, cantidad, monto total, fecha
4. POST a `gestion_compras.php`
5. PHP valida campos
6. INSERT en Compras con estado = 'En Curso'
7. **No actualiza inventario** — solo cuando se complete la compra

**Diferencia clave con ventas**: El stock no cambia al crear la orden. Se espera la recepción física.

---

### CU-COMP-003: Completar compra (recepción de mercancía)

**Actor**: Administrador o Empleado  
**Precondición**: Compra en estado "En Curso"  
**Postcondición**: Compra en estado "Completada", stock incrementado

**Flujo**:
1. Usuario hace clic en "Completar" en la fila de la compra
2. POST a `update_purchase.php` con `action = 'complete'`
3. PHP abre transacción
4. PHP actualiza `Compras.estado = 'Completada'`
5. PHP busca el producto en Inventario por `nombre_producto`
6. PHP incrementa `cantidad_disponible += cantidad_comprada`
7. Commit
8. Mostrar confirmación

**Nota técnica**: La tabla Compras tiene `nombre_producto` como texto, no como FK a Inventario. Esto requiere búsqueda por nombre para actualizar el stock, lo que puede fallar si los nombres no coinciden exactamente.

**Mejora pendiente**: Agregar campo `id_producto` FK a la tabla Compras.

---

### CU-COMP-004: Cancelar compra

**Actor**: Administrador  
**Flujo**:
1. Admin selecciona "Cancelar"
2. Si estado = "Completada": reponer stock (devolución)
3. Si estado = "En Curso": solo cambiar estado
4. UPDATE `Compras.estado = 'Cancelada'`

---

### CU-COMP-005: Ver detalle de compra (AJAX)

**Flujo**:
1. Usuario hace clic en "Ver detalle"
2. `get_purchase_details.php?id={id_compra}`
3. PHP retorna datos de la compra + datos del proveedor
4. Modal muestra información completa

---

### CU-COMP-006: Editar compra (AJAX)

**Actor**: Administrador o Empleado  
**Restricción**: Solo en estado "En Curso"

**Flujo**:
1. Usuario modifica datos en modal de edición
2. POST a `update_purchase.php` con datos actualizados
3. PHP valida y ejecuta UPDATE
4. Si monto_total cambió y compra está Completada → recalcular diferencia de stock (edge case)

---

## 6. Reglas de Negocio

### Proveedores
```
RN-PROV-001: El nombre del proveedor es requerido
RN-PROV-002: Un proveedor con compras asociadas no puede eliminarse (FK constraint)
RN-PROV-003: El email del proveedor no es único (puede haber múltiples contactos del mismo proveedor)
RN-PROV-004: Solo Administrador puede gestionar proveedores completamente
```

### Compras
```
RN-COMP-001: Toda compra debe tener un proveedor asociado
RN-COMP-002: El stock NO se incrementa al crear la compra, solo al completarla
RN-COMP-003: Una compra completada puede cancelarse, con reposición de stock
RN-COMP-004: La cantidad_comprada debe ser mayor a 0
RN-COMP-005: El monto_total puede ser 0 (para compras de muestra/cortesía)
RN-COMP-006: Administrador y Empleado pueden crear compras
RN-COMP-007: Solo Administrador puede eliminar compras
```

---

## 7. Validaciones

### 7.1 Proveedor

```php
function validateProvider(array $data): array {
    $errors = [];
    
    if (empty(trim($data['nombre_proveedor'] ?? ''))) {
        $errors['nombre'] = "El nombre del proveedor es requerido";
    } elseif (strlen($data['nombre_proveedor']) > 100) {
        $errors['nombre'] = "El nombre no puede superar 100 caracteres";
    }
    
    if (!empty($data['email']) && !filter_var($data['email'], FILTER_VALIDATE_EMAIL)) {
        $errors['email'] = "El email no tiene un formato válido";
    }
    
    if (!empty($data['telefono']) && strlen($data['telefono']) > 15) {
        $errors['telefono'] = "El teléfono no puede superar 15 caracteres";
    }
    
    return $errors;
}
```

### 7.2 Compra

```php
function validatePurchase(mysqli $conn, array $data): array {
    $errors = [];
    
    $id_proveedor = intval($data['id_proveedor'] ?? 0);
    if ($id_proveedor <= 0) {
        $errors['proveedor'] = "Selecciona un proveedor válido";
    } else {
        // Verificar que el proveedor existe
        $stmt = $conn->prepare("SELECT id_proveedor FROM Proveedores WHERE id_proveedor = ?");
        $stmt->bind_param("i", $id_proveedor);
        $stmt->execute();
        $stmt->store_result();
        if ($stmt->num_rows === 0) {
            $errors['proveedor'] = "Proveedor no encontrado";
        }
        $stmt->close();
    }
    
    if (empty(trim($data['nombre_producto'] ?? ''))) {
        $errors['producto'] = "El nombre del producto es requerido";
    }
    
    $cantidad = intval($data['cantidad_comprada'] ?? 0);
    if ($cantidad <= 0) {
        $errors['cantidad'] = "La cantidad debe ser mayor a 0";
    }
    
    $monto = floatval($data['monto_total'] ?? -1);
    if ($monto < 0) {
        $errors['monto'] = "El monto total no puede ser negativo";
    }
    
    return $errors;
}
```

---

## 8. Operaciones de Base de Datos

### 8.1 Listar compras con proveedor

```php
$stmt = $conn->prepare(
    "SELECT C.id_compra, P.nombre_proveedor, C.nombre_producto, 
            C.cantidad_comprada, C.fecha_compra, C.monto_total, C.estado
     FROM Compras C
     LEFT JOIN Proveedores P ON C.id_proveedor = P.id_proveedor
     ORDER BY C.fecha_compra DESC"
);
$stmt->execute();
$compras = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
$stmt->close();
```

### 8.2 Crear orden de compra

```php
$estado = 'En Curso';
$fecha = date('Y-m-d H:i:s');

$stmt = $conn->prepare(
    "INSERT INTO Compras 
        (id_proveedor, nombre_producto, cantidad_comprada, fecha_compra, monto_total, estado)
     VALUES (?, ?, ?, ?, ?, ?)"
);
$stmt->bind_param("isidds", 
    $id_proveedor, $nombre_producto, $cantidad_comprada, 
    $monto_total, $fecha, $estado
);
$stmt->execute();
$stmt->close();
```

### 8.3 Completar compra (actualizar inventario)

```php
$conn->begin_transaction();
try {
    // 1. Cambiar estado de la compra
    $stmt1 = $conn->prepare("UPDATE Compras SET estado = 'Completada' WHERE id_compra = ?");
    $stmt1->bind_param("i", $id_compra);
    $stmt1->execute();
    $stmt1->close();
    
    // 2. Obtener datos de la compra
    $stmt2 = $conn->prepare(
        "SELECT nombre_producto, cantidad_comprada FROM Compras WHERE id_compra = ?"
    );
    $stmt2->bind_param("i", $id_compra);
    $stmt2->execute();
    $compra = $stmt2->get_result()->fetch_assoc();
    $stmt2->close();
    
    // 3. Incrementar stock en Inventario
    // NOTA: búsqueda por nombre — mejora futura: usar id_producto FK
    $stmt3 = $conn->prepare(
        "UPDATE Inventario 
         SET cantidad_disponible = cantidad_disponible + ?,
             fecha_ultima_actualizacion = NOW()
         WHERE nombre_producto = ?"
    );
    $stmt3->bind_param("is", $compra['cantidad_comprada'], $compra['nombre_producto']);
    $stmt3->execute();
    
    if ($stmt3->affected_rows === 0) {
        // Producto no encontrado en inventario — crear nuevo
        $stmt4 = $conn->prepare(
            "INSERT INTO Inventario (nombre_producto, cantidad_disponible, stock_minimo)
             VALUES (?, ?, 0)"
        );
        $stmt4->bind_param("si", $compra['nombre_producto'], $compra['cantidad_comprada']);
        $stmt4->execute();
        $stmt4->close();
    }
    $stmt3->close();
    
    $conn->commit();
} catch (Exception $e) {
    $conn->rollback();
    throw $e;
}
```

### 8.4 Detalle de proveedor (AJAX)

```php
// get_provider_details.php
header('Content-Type: application/json');

$id = intval($_GET['id'] ?? 0);
if ($id <= 0) {
    echo json_encode(['error' => 'ID inválido']);
    exit;
}

$stmt = $conn->prepare(
    "SELECT id_proveedor, nombre_proveedor, telefono, email, direccion
     FROM Proveedores WHERE id_proveedor = ?"
);
$stmt->bind_param("i", $id);
$stmt->execute();
$proveedor = $stmt->get_result()->fetch_assoc();
$stmt->close();

echo json_encode($proveedor ?: ['error' => 'Proveedor no encontrado']);
```

### 8.5 Actualizar proveedor (AJAX)

```php
// update_provider.php
$stmt = $conn->prepare(
    "UPDATE Proveedores 
     SET nombre_proveedor = ?, telefono = ?, email = ?, direccion = ?
     WHERE id_proveedor = ?"
);
$stmt->bind_param("ssssi", $nombre, $telefono, $email, $direccion, $id);
$stmt->execute();
$stmt->close();

echo json_encode(['success' => true, 'message' => 'Proveedor actualizado']);
```

---

## 9. APIs de los Módulos

### GET /get_provider_details.php?id={id}

**Response exitosa**:
```json
{
  "id_proveedor": 824,
  "nombre_proveedor": "Distribuidora XYZ",
  "telefono": "+50312345678",
  "email": "ventas@xyz.com",
  "direccion": "Calle Principal #123"
}
```

### POST /update_provider.php

**Request**:
```json
{
  "id_proveedor": 824,
  "nombre_proveedor": "Distribuidora XYZ",
  "telefono": "+50312345678",
  "email": "ventas@xyz.com",
  "direccion": "Calle Principal #123"
}
```

**Response**: `{ "success": true }`

### GET /get_purchase_details.php?id={id}

**Response**:
```json
{
  "id_compra": 20,
  "nombre_proveedor": "Distribuidora XYZ",
  "nombre_producto": "Gaseosas",
  "cantidad_comprada": 200,
  "fecha_compra": "2025-02-06 12:15:29",
  "monto_total": "150000.00",
  "estado": "En Curso"
}
```

### POST /update_purchase.php

**Request**:
```json
{
  "id_compra": 20,
  "action": "complete",
  "nombre_producto": "Gaseosas",
  "cantidad_comprada": 200
}
```

**Response**: `{ "success": true, "message": "Compra completada. Stock actualizado." }`

---

## 10. Schema de BD

### Tabla: Proveedores

```sql
CREATE TABLE `Proveedores` (
  `id_proveedor`    INT(11) AUTO_INCREMENT PRIMARY KEY,
  `nombre_proveedor` VARCHAR(100) NOT NULL,
  `telefono`        VARCHAR(15) DEFAULT NULL,
  `email`           VARCHAR(100) DEFAULT NULL,
  `direccion`       TEXT DEFAULT NULL,
  INDEX idx_prov_nombre (nombre_proveedor)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Tabla: Compras

```sql
CREATE TABLE `Compras` (
  `id_compra`         INT(11) AUTO_INCREMENT PRIMARY KEY,
  `id_proveedor`      INT(11) DEFAULT NULL,
  `nombre_producto`   VARCHAR(100) NOT NULL,
  `cantidad_comprada` INT(11) NOT NULL,
  `fecha_compra`      DATETIME DEFAULT CURRENT_TIMESTAMP,
  `monto_total`       DECIMAL(10,2) DEFAULT 0.00,
  `estado`            VARCHAR(50) DEFAULT 'En Curso',
  -- Mejora futura: agregar id_producto FK
  -- `id_producto`    INT(11) DEFAULT NULL,
  FOREIGN KEY (id_proveedor) REFERENCES Proveedores(id_proveedor),
  INDEX idx_comp_proveedor (id_proveedor),
  INDEX idx_comp_estado    (estado),
  INDEX idx_comp_fecha     (fecha_compra)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Tabla: Historial_Compras (ya existe)

```sql
CREATE TABLE `Historial_Compras` (
  `id_historial`        INT AUTO_INCREMENT PRIMARY KEY,
  `id_compra`           INT NOT NULL,
  `tipo_accion`         ENUM('INSERT','UPDATE','DELETE') NOT NULL,
  `fecha_modificacion`  DATETIME DEFAULT CURRENT_TIMESTAMP,
  `usuario_modifico`    VARCHAR(100) DEFAULT NULL,
  `ip_origen`           VARCHAR(45) DEFAULT NULL,
  `descripcion_cambio`  TEXT DEFAULT NULL,
  INDEX idx_hc_compra (id_compra)
) ENGINE=InnoDB;
```

---

## 11. Organización Interna de Código

### 11.1 Estructura de gestion_compras.php

```
Líneas 1-10:    includes + verificación de permisos
Líneas 11-50:   Procesamiento POST crear compra
Líneas 51-80:   Procesamiento GET delete compra
Líneas 81-110:  Queries: proveedores (dropdown) + listado compras
---
Líneas 111-160: HTML tabla de compras con estado y acciones
---
Líneas 161-230: Modal — crear compra
Líneas 231-270: Modal — editar compra (si aplica)
Líneas 271-320: JavaScript — AJAX para detail/update
---
Líneas 321-322: include footer

TOTAL objetivo: ~320 líneas
```

### 11.2 Estructura de get_provider_details.php (AJAX)

```
Líneas 1-5:   require_once config + session check
Líneas 6-8:   header Content-Type: application/json
Líneas 9-15:  validar id param
Líneas 16-30: query proveedor con prepared statement
Líneas 31-35: echo json_encode + exit

TOTAL objetivo: ~35 líneas
```

---

## 12. Quality Requirements

| Operación | Target |
|-----------|--------|
| Listar compras | < 300ms |
| Crear orden de compra | < 300ms |
| Completar compra + actualizar stock | < 500ms |
| AJAX detail de proveedor | < 100ms |
| AJAX update de proveedor | < 200ms |

---

## 13. Testing Scenarios

### Proveedores — Happy path
- [ ] Crear proveedor con todos los campos → aparece en listado
- [ ] Ver detalle vía AJAX → datos correctos en modal
- [ ] Editar proveedor vía AJAX → cambios persistidos sin recargar
- [ ] Eliminar proveedor sin compras → eliminado de BD

### Proveedores — Error paths
- [ ] Crear proveedor sin nombre → error de validación
- [ ] Crear proveedor con email inválido → error de validación
- [ ] Eliminar proveedor con compras → error FK, mensaje claro

### Compras — Happy path
- [ ] Crear compra → estado "En Curso", inventario sin cambio
- [ ] Completar compra → estado "Completada", stock incrementado
- [ ] Cancelar compra "En Curso" → estado "Cancelada", sin cambio de stock
- [ ] Cancelar compra "Completada" → estado "Cancelada", stock repuesto
- [ ] Ver detalle vía AJAX → datos correctos del proveedor y producto

### Compras — Error paths
- [ ] Crear compra sin proveedor → error de validación
- [ ] Crear compra sin producto → error de validación
- [ ] Crear compra con cantidad = 0 → error de validación
- [ ] Completar compra con producto inexistente en Inventario → crear nuevo producto

### Seguridad
- [ ] Acceso a update_purchase.php como Usuario → bloqueado por rol
- [ ] Manipulación de id_compra en GET → intval() previene inyección
- [ ] Payload SQL en nombre_proveedor → prepared statement previene

---

*Spec generada: 2026-04-24T21:19:11Z*

---

## 14. Mejoras Técnicas Pendientes

### 14.1 Agregar id_producto FK a Compras

**Problema actual**: La tabla `Compras` usa `nombre_producto` (texto) en lugar de `id_producto` (FK).

**Impacto**:
- Al completar una compra, la búsqueda de inventario es por nombre exacto
- Si el nombre no coincide exactamente → producto no actualizado
- No hay integridad referencial entre Compras e Inventario

**Solución**:
```sql
-- Migración para agregar FK
ALTER TABLE Compras 
  ADD COLUMN id_producto INT DEFAULT NULL AFTER id_proveedor,
  ADD FOREIGN KEY (id_producto) REFERENCES Inventario(id_producto);

-- Poblar id_producto desde nombre_producto (migración de datos)
UPDATE Compras C
JOIN Inventario I ON I.nombre_producto = C.nombre_producto
SET C.id_producto = I.id_producto;
```

**Impacto en código**: `update_purchase.php` debe usar `id_producto` en lugar de búsqueda por nombre.

### 14.2 Detalle de compra multi-producto

**Problema actual**: La tabla `Compras` tiene `nombre_producto` como columna directa (solo un producto por compra).

**La tabla `Detalle_Compras` ya existe** pero no está integrada al flujo actual de `gestion_compras.php`.

**Solución**: Migrar el formulario de compras para permitir múltiples productos por orden, usando la relación Compras → Detalle_Compras similar a como Ventas → Detalle_Ventas.

```sql
-- Flujo correcto
INSERT INTO Compras (id_proveedor, fecha_compra, monto_total, estado) ...
INSERT INTO Detalle_Compras (id_compra, id_producto, cantidad_comprada, precio_unitario) ...
-- Trigger en Detalle_Compras actualiza Inventario al completarse
```

### 14.3 Trigger para actualización automática de stock al completar compra

Actualmente el stock se actualiza manualmente desde PHP. Mejor enfoque:

```sql
-- Trigger: al cambiar estado de compra a 'Completada'
-- Nota: MySQL triggers no se activan en UPDATE, 
-- pero se puede hacer via stored procedure o trigger en Detalle_Compras

DELIMITER $$
CREATE TRIGGER `after_detalle_compra_insert` AFTER INSERT ON `Detalle_Compras` 
FOR EACH ROW BEGIN
    -- Solo si la compra padre está 'Completada'
    DECLARE compra_estado VARCHAR(50);
    SELECT estado INTO compra_estado FROM Compras WHERE id_compra = NEW.id_compra;
    
    IF compra_estado = 'Completada' THEN
        UPDATE Inventario
        SET cantidad_disponible = cantidad_disponible + NEW.cantidad_comprada
        WHERE id_producto = NEW.id_producto;
    END IF;
END
$$
DELIMITER ;
```

### 14.4 Validación de unicidad de proveedor por email

```php
// Verificar email único si se proporciona
if (!empty($email)) {
    $stmt = $conn->prepare(
        "SELECT id_proveedor FROM Proveedores WHERE email = ? AND id_proveedor != ?"
    );
    $stmt->bind_param("si", $email, $id_proveedor);
    $stmt->execute();
    $stmt->store_result();
    if ($stmt->num_rows > 0) {
        $errors['email'] = "Ya existe un proveedor con este email";
    }
    $stmt->close();
}
```

### 14.5 Paginación en listados

```php
// Implementar paginación simple
$page = max(1, intval($_GET['page'] ?? 1));
$per_page = 20;
$offset = ($page - 1) * $per_page;

// Query con LIMIT
$stmt = $conn->prepare(
    "SELECT ... FROM Compras ... LIMIT ? OFFSET ?"
);
$stmt->bind_param("ii", $per_page, $offset);

// Contar total
$total_stmt = $conn->prepare("SELECT COUNT(*) FROM Compras");
$total_stmt->execute();
$total = $total_stmt->get_result()->fetch_row()[0];
$total_pages = ceil($total / $per_page);
```

### 14.6 Exportación de compras a Excel

```php
// Usando PhpSpreadsheet
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;

function exportComprasToExcel(array $compras): void {
    $spreadsheet = new Spreadsheet();
    $sheet = $spreadsheet->getActiveSheet();
    $sheet->setTitle('Compras');
    
    // Headers
    $headers = ['ID', 'Proveedor', 'Producto', 'Cantidad', 'Fecha', 'Monto', 'Estado'];
    foreach (array_values($headers) as $col => $header) {
        $sheet->setCellValueByColumnAndRow($col + 1, 1, $header);
    }
    
    // Datos
    foreach ($compras as $row_idx => $compra) {
        $sheet->setCellValueByColumnAndRow(1, $row_idx + 2, $compra['id_compra']);
        $sheet->setCellValueByColumnAndRow(2, $row_idx + 2, $compra['nombre_proveedor']);
        $sheet->setCellValueByColumnAndRow(3, $row_idx + 2, $compra['nombre_producto']);
        $sheet->setCellValueByColumnAndRow(4, $row_idx + 2, $compra['cantidad_comprada']);
        $sheet->setCellValueByColumnAndRow(5, $row_idx + 2, $compra['fecha_compra']);
        $sheet->setCellValueByColumnAndRow(6, $row_idx + 2, $compra['monto_total']);
        $sheet->setCellValueByColumnAndRow(7, $row_idx + 2, $compra['estado']);
    }
    
    header('Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    header('Content-Disposition: attachment;filename="compras.xlsx"');
    
    $writer = new Xlsx($spreadsheet);
    $writer->save('php://output');
}
```

---

*Spec actualizada: 2026-04-24T21:19:11Z*
