# Especificación Técnica — Módulo Ventas

---
name: spec-ventas
module: ventas
status: active
created: 2026-04-24T21:19:11Z
updated: 2026-04-24T21:19:11Z
---

## Índice

1. [Visión General](#1-visión-general)
2. [Archivos del Módulo](#2-archivos-del-módulo)
3. [Máquinas de Estado](#3-máquinas-de-estado)
4. [Casos de Uso Detallados](#4-casos-de-uso-detallados)
5. [Reglas de Negocio](#5-reglas-de-negocio)
6. [Validaciones](#6-validaciones)
7. [Operaciones de Base de Datos](#7-operaciones-de-base-de-datos)
8. [Integración con otros módulos](#8-integración-con-otros-módulos)
9. [Schema de BD](#9-schema-de-bd)
10. [Organización Interna de Código](#10-organización-interna-de-código)
11. [Quality Requirements](#11-quality-requirements)
12. [Testing Scenarios](#12-testing-scenarios)

---

## 1. Visión General

### Propósito
El módulo de Ventas gestiona el ciclo completo de una transacción comercial: desde la creación de una orden hasta su cierre, incluyendo la actualización automática de stock y el mantenimiento del historial de ventas.

### Responsabilidades
1. Creación de ventas con verificación de stock disponible
2. Gestión del ciclo de vida de una venta (estados)
3. Actualización automática del inventario al vender
4. Listado y seguimiento de ventas existentes
5. Eliminación de ventas con reposición de stock
6. Generación de detalle de venta (líneas de producto)

### Principios de diseño
- Atomicidad: venta + actualización de inventario ocurren en la misma transacción
- Protección doble: validación PHP + trigger de BD contra stock insuficiente
- Historial inmutable: el historial de cambios no puede modificarse
- Precio histórico: el precio de venta se captura al momento de la transacción

---

## 2. Archivos del Módulo

| Archivo | Responsabilidad | Acceso |
|---------|----------------|--------|
| `gestion_ventas.php` | CRUD de ventas + listado | Autenticado |
| `detalle_venta.php` | Vista detallada de una venta | Autenticado |
| `generar_factura.php` | Generación de factura PDF | Autenticado |

### Dependencias
- `config.php` — conexión BD
- `header.php` — layout + sesión
- `fetch_inventario.php` — productos disponibles para selector
- `fpdf/fpdf.php` — generación de facturas PDF
- `styles/gestion_ventas.css` — estilos

---

## 3. Máquinas de Estado

### 3.1 Estado de una Venta

```
                    [Petición Realizada]
                          │
                          │ Admin/Empleado procesa
                          ▼
                     [En Proceso]
                    /           \
                   /             \
          [Completada]       [Cancelada]
          (stock ya           (reponer stock
          decrementado)       si es necesario)
```

**Transiciones de estado**:

| Estado actual | Transición | Estado siguiente | Acción en inventario |
|--------------|-----------|-----------------|---------------------|
| — | Crear venta | Petición Realizada | Stock decrementado (trigger) |
| Petición Realizada | Confirmar | En Proceso | Sin cambio |
| En Proceso | Completar | Completada | Sin cambio |
| En Proceso | Cancelar | Cancelada | Reponer stock |
| Petición Realizada | Cancelar | Cancelada | Reponer stock |
| Cualquiera | Eliminar (Admin) | — (eliminada) | Reponer stock |

**Regla importante**: El stock se descuenta al CREAR la venta (trigger `before_insert_venta`), no al completarla. Esto garantiza que el stock reservado no se venda dos veces.

### 3.2 Estado del stock en el contexto de ventas

```
[Stock normal]
    │ Se crea venta por N unidades
    │ trigger: cantidad_disponible -= N
    ▼
[Stock reducido]
    │ Venta se cancela/elimina
    │ PHP: cantidad_disponible += N
    ▼
[Stock normal]
```

---

## 4. Casos de Uso Detallados

### CU-VEN-001: Crear venta

**Actor**: Administrador o Empleado  
**Precondición**: Hay productos con stock > 0, existen usuarios con rol 'Usuario' (clientes)  
**Postcondición**: Venta registrada, stock decrementado, historial actualizado

**Flujo principal**:
1. Usuario abre formulario de nueva venta (modal o formulario inline)
2. Selecciona cliente del dropdown (usuarios con rol = 'Usuario')
3. Selecciona producto del dropdown (productos con cantidad_disponible > 0)
4. Ingresa cantidad vendida (máximo = cantidad_disponible del producto)
5. Ingresa monto total
6. POST a `gestion_ventas.php` con `submit_sale`
7. PHP valida campos
8. PHP verifica stock suficiente: `SELECT cantidad_disponible WHERE id_producto = ?`
9. Si stock suficiente:
   - INSERT en `Ventas` (cabecera)
   - INSERT en `Detalle_Ventas` (trigger descuenta stock automáticamente)
10. Si stock insuficiente: mostrar error, no crear la venta
11. Mostrar confirmación o error
12. Recargar listado

**Flujo alternativo — Stock insuficiente detectado por PHP**:
- En paso 8: `cantidad_disponible < cantidad_vendida`
- PHP muestra mensaje: "Stock insuficiente. Disponible: {X} unidades"
- No ejecuta ningún INSERT

**Flujo alternativo — Stock insuficiente detectado por trigger**:
- En paso 9: MySQL trigger lanza `SIGNAL SQLSTATE '45000'`
- PHP captura el error de MySQL
- Hace rollback si hay transacción
- Muestra el mensaje del trigger al usuario

---

### CU-VEN-002: Ver listado de ventas

**Actor**: Cualquier usuario autenticado  
**Precondición**: Sesión activa  
**Postcondición**: Lista de ventas mostrada

**Flujo**:
1. PHP ejecuta JOIN entre Ventas, Usuarios, Detalle_Ventas, Inventario
2. Muestra tabla con: ID, Cliente, Fecha, Monto Total, Cantidad, Producto, Estado
3. Para Administrador: columna de acciones (Eliminar)
4. Para Empleado: columna de acciones (Eliminar de su propio turno)
5. Botón para cambiar estado de la venta

**Filtros futuros recomendados**:
- Por fecha (desde/hasta)
- Por estado
- Por cliente
- Por producto

---

### CU-VEN-003: Ver detalle de venta

**Actor**: Cualquier usuario autenticado  
**Precondición**: Venta existe  
**Postcondición**: Detalle completo mostrado

**Flujo**:
1. Usuario hace clic en ID de venta o botón "Ver detalle"
2. GET a `detalle_venta.php?id={id_venta}`
3. PHP valida que `id_venta` pertenece al usuario (o es admin)
4. PHP ejecuta queries para obtener cabecera + líneas de detalle
5. Muestra: datos del cliente, fecha, productos, cantidades, precios, total

---

### CU-VEN-004: Eliminar venta

**Actor**: Solo Administrador  
**Precondición**: Venta existe  
**Postcondición**: Venta eliminada, stock repuesto

**Flujo**:
1. Admin hace clic en "Eliminar" con confirmación
2. GET a `gestion_ventas.php?delete={id_venta}`
3. PHP valida ID con intval()
4. PHP abre transacción
5. PHP obtiene todas las líneas de Detalle_Ventas para la venta
6. PHP repone stock: `UPDATE Inventario SET cantidad_disponible = cantidad_disponible + {qty}`
7. PHP elimina Detalle_Ventas de la venta
8. PHP elimina Ventas registro cabecera
9. Commit de transacción
10. Recargar listado

**Nota importante**: La eliminación debe ser en transacción. Si falla la reposición de stock, no se debe eliminar la venta.

---

### CU-VEN-005: Cambiar estado de venta

**Actor**: Administrador o Empleado  
**Precondición**: Venta existe, transición válida según máquina de estados  
**Postcondición**: Estado actualizado en BD

**Flujo**:
1. Usuario hace clic en botón de cambio de estado (ej: "Confirmar", "Completar", "Cancelar")
2. POST a `gestion_ventas.php` con `action = 'change_status'`, `id_venta`, `nuevo_estado`
3. PHP valida: estado actual → nuevo estado es transición válida
4. Si nuevo_estado = 'Cancelada': reponer stock (como en CU-VEN-004 pero sin eliminar el registro)
5. PHP actualiza `Ventas.estado`
6. Mostrar confirmación

---

### CU-VEN-006: Generar factura PDF

**Actor**: Administrador  
**Precondición**: Venta existe en estado Completada  
**Postcondición**: PDF descargado o guardado en `reportes/`

**Flujo**:
1. Admin hace clic en "Generar Factura"
2. GET a `generar_factura.php?id={id_venta}`
3. PHP obtiene datos completos de la venta
4. PHP instancia FPDF, diseña la factura
5. PHP retorna PDF como descarga directa

---

## 5. Reglas de Negocio

### 5.1 Reglas de creación de venta

```
RN-VEN-001: Solo usuarios con rol 'Usuario' pueden ser clientes en una venta
  → Dropdown de clientes filtra: WHERE rol = 'Usuario'

RN-VEN-002: Solo productos con cantidad_disponible > 0 pueden ser seleccionados
  → fetch_inventario.php retorna WHERE cantidad_disponible > 0

RN-VEN-003: La cantidad vendida no puede exceder la cantidad disponible del producto
  → Validación PHP (doble protección con trigger de BD)

RN-VEN-004: El precio unitario se calcula como monto_total / cantidad_vendida
  → No puede haber división por cero (validar cantidad > 0)

RN-VEN-005: El estado inicial de una venta es 'Petición Realizada'

RN-VEN-006: El stock se descuenta EN EL MOMENTO de crear la venta, no al completarla
  → Trigger before_insert_venta en BD
```

### 5.2 Reglas de eliminación

```
RN-VEN-007: Solo el Administrador puede eliminar ventas

RN-VEN-008: Al eliminar una venta, el stock de TODOS los productos del detalle debe reponerse
  → Operación atómica en transacción

RN-VEN-009: No se pueden eliminar ventas en estado 'Completada' directamente
  → Requiere cancelación previa (pendiente implementar)
```

### 5.3 Reglas de precios

```
RN-VEN-010: El precio_unitario en Detalle_Ventas es el precio real de la transacción
  → Se calcula: monto_total / cantidad_vendida
  → No necesariamente igual al precio_unitario de Inventario
  → Esto permite descuentos o precios especiales

RN-VEN-011: El monto_total de Ventas debe ser coherente con la suma de sus líneas de detalle
  → Actualmente: monto_total se ingresa manualmente
  → Mejora futura: calcular automáticamente desde líneas de detalle
```

### 5.4 Reglas de acceso por rol

```
RN-VEN-012: Todos los autenticados pueden VER el listado de ventas
RN-VEN-013: Administrador y Empleado pueden CREAR ventas
RN-VEN-014: Solo Administrador puede ELIMINAR ventas
RN-VEN-015: Administrador y Empleado pueden CAMBIAR ESTADO de ventas
```

---

## 6. Validaciones

### 6.1 Validación de nueva venta

```php
function validateNewSale(mysqli $conn, array $data): array {
    $errors = [];
    
    // id_cliente
    $id_cliente = intval($data['id_cliente'] ?? 0);
    if ($id_cliente <= 0) {
        $errors['cliente'] = "Selecciona un cliente válido";
    } else {
        // Verificar que el cliente existe y tiene rol = 'Usuario'
        $stmt = $conn->prepare(
            "SELECT id_usuario FROM Usuarios WHERE id_usuario = ? AND rol = 'Usuario' AND estado = 'Activo'"
        );
        $stmt->bind_param("i", $id_cliente);
        $stmt->execute();
        $stmt->store_result();
        if ($stmt->num_rows === 0) {
            $errors['cliente'] = "Cliente no válido";
        }
        $stmt->close();
    }
    
    // id_producto
    $id_producto = intval($data['id_producto'] ?? 0);
    if ($id_producto <= 0) {
        $errors['producto'] = "Selecciona un producto válido";
    }
    
    // cantidad_vendida
    $cantidad = intval($data['cantidad_vendida'] ?? 0);
    if ($cantidad <= 0) {
        $errors['cantidad'] = "La cantidad debe ser mayor a 0";
    }
    
    // monto_total
    $monto = floatval($data['monto_total'] ?? 0);
    if ($monto <= 0) {
        $errors['monto'] = "El monto total debe ser mayor a 0";
    }
    
    // Verificar stock si los campos anteriores son válidos
    if (empty($errors) && $id_producto > 0 && $cantidad > 0) {
        $stmt = $conn->prepare(
            "SELECT cantidad_disponible FROM Inventario WHERE id_producto = ?"
        );
        $stmt->bind_param("i", $id_producto);
        $stmt->execute();
        $row = $stmt->get_result()->fetch_assoc();
        $stmt->close();
        
        if (!$row) {
            $errors['producto'] = "Producto no encontrado en inventario";
        } elseif ($row['cantidad_disponible'] < $cantidad) {
            $errors['stock'] = "Stock insuficiente. Disponible: {$row['cantidad_disponible']} unidades";
        }
    }
    
    return $errors;
}
```

### 6.2 Validación de cambio de estado

```php
$valid_transitions = [
    'Petición Realizada' => ['En Proceso', 'Cancelada'],
    'En Proceso'         => ['Completada', 'Cancelada'],
    'Completada'         => [],  // estado final
    'Cancelada'          => [],  // estado final
];

function validateStateTransition(string $current, string $new): bool {
    global $valid_transitions;
    return in_array($new, $valid_transitions[$current] ?? []);
}
```

---

## 7. Operaciones de Base de Datos

### 7.1 Listar ventas con JOIN

```php
$stmt = $conn->prepare(
    "SELECT V.id_venta, U.nombre AS cliente, V.fecha_venta, 
            V.monto_total, DV.cantidad_vendida, 
            I.nombre_producto, V.estado
     FROM Ventas V
     JOIN Usuarios U       ON V.id_cliente  = U.id_usuario
     JOIN Detalle_Ventas DV ON V.id_venta    = DV.id_venta
     JOIN Inventario I      ON DV.id_producto = I.id_producto
     ORDER BY V.fecha_venta DESC"
);
$stmt->execute();
$ventas = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
$stmt->close();
```

### 7.2 Crear venta (transacción completa)

```php
$conn->begin_transaction();

try {
    // 1. Insertar cabecera de venta
    $estado = 'Petición Realizada';
    $fecha_venta = date('Y-m-d H:i:s');
    
    $stmt1 = $conn->prepare(
        "INSERT INTO Ventas (id_cliente, fecha_venta, monto_total, estado) 
         VALUES (?, ?, ?, ?)"
    );
    $stmt1->bind_param("isds", $id_cliente, $fecha_venta, $monto_total, $estado);
    $stmt1->execute();
    $id_venta = $conn->insert_id;
    $stmt1->close();
    
    // 2. Calcular precio unitario (evitar división por cero)
    $precio_unitario = ($cantidad_vendida > 0) ? ($monto_total / $cantidad_vendida) : 0;
    
    // 3. Insertar detalle (trigger descuenta stock aquí)
    $stmt2 = $conn->prepare(
        "INSERT INTO Detalle_Ventas (id_venta, id_producto, cantidad_vendida, precio_unitario)
         VALUES (?, ?, ?, ?)"
    );
    $stmt2->bind_param("iiid", $id_venta, $id_producto, $cantidad_vendida, $precio_unitario);
    $stmt2->execute();
    $stmt2->close();
    
    $conn->commit();
    $success = true;
    
} catch (mysqli_sql_exception $e) {
    $conn->rollback();
    // El trigger puede lanzar error de stock insuficiente
    if (str_contains($e->getMessage(), 'Stock insuficiente')) {
        $error = "Stock insuficiente para completar la venta";
    } else {
        $error = "Error al registrar la venta";
    }
}
```

### 7.3 Eliminar venta con reposición de stock

```php
$conn->begin_transaction();

try {
    $sale_id = intval($_GET['delete']);
    
    // 1. Obtener líneas de detalle
    $stmt = $conn->prepare(
        "SELECT id_producto, cantidad_vendida FROM Detalle_Ventas WHERE id_venta = ?"
    );
    $stmt->bind_param("i", $sale_id);
    $stmt->execute();
    $items = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
    $stmt->close();
    
    // 2. Reponer stock para cada producto
    $stmt_update = $conn->prepare(
        "UPDATE Inventario 
         SET cantidad_disponible = cantidad_disponible + ?,
             fecha_ultima_actualizacion = NOW()
         WHERE id_producto = ?"
    );
    foreach ($items as $item) {
        $stmt_update->bind_param("ii", $item['cantidad_vendida'], $item['id_producto']);
        $stmt_update->execute();
    }
    $stmt_update->close();
    
    // 3. Eliminar detalle
    $stmt2 = $conn->prepare("DELETE FROM Detalle_Ventas WHERE id_venta = ?");
    $stmt2->bind_param("i", $sale_id);
    $stmt2->execute();
    $stmt2->close();
    
    // 4. Eliminar cabecera
    $stmt3 = $conn->prepare("DELETE FROM Ventas WHERE id_venta = ?");
    $stmt3->bind_param("i", $sale_id);
    $stmt3->execute();
    $stmt3->close();
    
    $conn->commit();
    
} catch (Exception $e) {
    $conn->rollback();
    $error = "Error al eliminar la venta";
}
```

### 7.4 Actualizar estado de venta

```php
$stmt = $conn->prepare(
    "UPDATE Ventas SET estado = ? WHERE id_venta = ?"
);
$stmt->bind_param("si", $nuevo_estado, $id_venta);
$stmt->execute();
$stmt->close();
```

### 7.5 Detalle completo de una venta

```php
// Cabecera
$stmt_header = $conn->prepare(
    "SELECT V.id_venta, U.nombre AS cliente, U.correo_electronico AS email_cliente,
            V.fecha_venta, V.monto_total, V.estado
     FROM Ventas V
     JOIN Usuarios U ON V.id_cliente = U.id_usuario
     WHERE V.id_venta = ?"
);
$stmt_header->bind_param("i", $id_venta);
$stmt_header->execute();
$venta = $stmt_header->get_result()->fetch_assoc();
$stmt_header->close();

// Líneas de detalle
$stmt_items = $conn->prepare(
    "SELECT DV.id_detalle, I.nombre_producto, DV.cantidad_vendida,
            DV.precio_unitario,
            (DV.cantidad_vendida * DV.precio_unitario) AS subtotal
     FROM Detalle_Ventas DV
     JOIN Inventario I ON DV.id_producto = I.id_producto
     WHERE DV.id_venta = ?"
);
$stmt_items->bind_param("i", $id_venta);
$stmt_items->execute();
$items = $stmt_items->get_result()->fetch_all(MYSQLI_ASSOC);
$stmt_items->close();
```

---

## 8. Integración con otros módulos

### 8.1 Con Inventario

- **Al crear venta**: trigger `before_insert_venta` descuenta stock
- **Al eliminar venta**: PHP repone stock manualmente
- **Formulario de nueva venta**: usa `fetch_inventario.php` para el dropdown de productos

### 8.2 Con Usuarios

- **Clientes**: el dropdown de clientes carga `SELECT FROM Usuarios WHERE rol = 'Usuario'`
- La relación `Ventas.id_cliente → Usuarios.id_usuario` mantiene el historial de quién compró

### 8.3 Con Reportes

```php
// Query para reporte de ventas por período
"SELECT DATE_FORMAT(V.fecha_venta, '%Y-%m') AS mes,
        COUNT(V.id_venta) AS num_ventas,
        SUM(V.monto_total) AS total_ventas,
        AVG(V.monto_total) AS promedio_venta
 FROM Ventas V
 WHERE V.fecha_venta BETWEEN ? AND ?
 GROUP BY mes
 ORDER BY mes ASC"
```

### 8.4 Con Gráficas

```php
// Ventas por producto (para gráfica de barras)
"SELECT I.nombre_producto, SUM(DV.cantidad_vendida) AS total_vendido
 FROM Detalle_Ventas DV
 JOIN Inventario I ON DV.id_producto = I.id_producto
 GROUP BY DV.id_producto
 ORDER BY total_vendido DESC
 LIMIT 10"
```

---

## 9. Schema de BD

### Tabla: Ventas

```sql
CREATE TABLE `Ventas` (
  `id_venta`    INT(11) AUTO_INCREMENT PRIMARY KEY,
  `id_cliente`  INT(11) DEFAULT NULL,
  `fecha_venta` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `monto_total` DECIMAL(10,2) DEFAULT 0.00,
  `estado`      VARCHAR(50) DEFAULT 'Petición Realizada',
  FOREIGN KEY (id_cliente) REFERENCES Usuarios(id_usuario),
  INDEX idx_ventas_cliente (id_cliente),
  INDEX idx_ventas_fecha   (fecha_venta),
  INDEX idx_ventas_estado  (estado)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Tabla: Detalle_Ventas

```sql
CREATE TABLE `Detalle_Ventas` (
  `id_detalle`       INT(11) AUTO_INCREMENT PRIMARY KEY,
  `id_venta`         INT(11) DEFAULT NULL,
  `id_producto`      INT(11) DEFAULT NULL,
  `cantidad_vendida` INT(11) DEFAULT NULL,
  `precio_unitario`  DECIMAL(10,2) DEFAULT NULL,
  FOREIGN KEY (id_venta)    REFERENCES Ventas(id_venta),
  FOREIGN KEY (id_producto) REFERENCES Inventario(id_producto),
  INDEX idx_dv_venta    (id_venta),
  INDEX idx_dv_producto (id_producto)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Trigger crítico (ya existe)

```sql
-- before_insert_venta: verifica stock y descuenta
CREATE TRIGGER `before_insert_venta` BEFORE INSERT ON `Detalle_Ventas` FOR EACH ROW BEGIN
    DECLARE stock_disponible INT;
    SELECT cantidad_disponible INTO stock_disponible
    FROM Inventario WHERE id_producto = NEW.id_producto;
    
    IF stock_disponible IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El producto no existe en inventario.';
    ELSEIF stock_disponible < NEW.cantidad_vendida THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Stock insuficiente para completar la venta.';
    ELSE
        UPDATE Inventario
        SET cantidad_disponible = cantidad_disponible - NEW.cantidad_vendida
        WHERE id_producto = NEW.id_producto;
    END IF;
END
```

---

## 10. Organización Interna de Código

### 10.1 Estructura de gestion_ventas.php

```
Líneas 1-10:    includes + rol setup
Líneas 11-40:   Procesamiento GET delete (con transacción)
Líneas 41-90:   Procesamiento POST submit_sale (con transacción)
Líneas 91-120:  Queries de datos: clientes, productos, listado ventas
---
Líneas 121-170: HTML — cabecera + botón nueva venta
Líneas 171-240: HTML — tabla de ventas con estado y acciones
---
Líneas 241-310: Modal — Crear nueva venta
Líneas 311-350: JavaScript — lógica de modales + AJAX para productos
---
Líneas 351-352: include footer

TOTAL objetivo: ~350 líneas
```

### 10.2 Cálculo de precio unitario (evitar división por cero)

```php
$precio_unitario = ($cantidad_vendida > 0) 
    ? round($monto_total / $cantidad_vendida, 4) 
    : 0.00;
```

### 10.3 Renderizado de estado con badge Bootstrap

```php
function getEstadoBadge(string $estado): string {
    $classes = [
        'Petición Realizada' => 'badge bg-secondary',
        'En Proceso'         => 'badge bg-primary',
        'Completada'         => 'badge bg-success',
        'Cancelada'          => 'badge bg-danger',
    ];
    $class = $classes[$estado] ?? 'badge bg-light text-dark';
    return "<span class=\"{$class}\">" . htmlspecialchars($estado) . "</span>";
}
```

---

## 11. Quality Requirements

### 11.1 Performance

| Operación | Target | Condición |
|-----------|--------|-----------|
| Listar ventas | < 300ms | Hasta 500 ventas |
| Crear venta (con transacción) | < 400ms | Incluye trigger de BD |
| Eliminar venta (con reposición) | < 500ms | Con múltiples productos |
| Generar factura PDF | < 2s | Venta simple |

### 11.2 Integridad de datos

```
- Atomicidad garantizada por transacciones PHP + triggers BD
- Stock nunca negativo (trigger before_insert_venta)
- Precio unitario calculado automáticamente (sin división por cero)
- FK constraints entre Ventas, Detalle_Ventas, Inventario, Usuarios
- Historial inmutable via triggers after_insert/update/delete
```

---

## 12. Testing Scenarios

### Happy path
- [ ] Crear venta con stock suficiente → venta en BD, stock decrementado
- [ ] Listar ventas → todas las ventas con datos correctos del JOIN
- [ ] Ver detalle de venta → cabecera + líneas correctas
- [ ] Eliminar venta → venta eliminada + stock repuesto
- [ ] Cambiar estado a "En Proceso" → BD actualizada
- [ ] Cambiar estado a "Completada" → BD actualizada
- [ ] Cambiar estado a "Cancelada" → stock repuesto
- [ ] Generar factura PDF → PDF descargado correctamente

### Error paths
- [ ] Crear venta con stock insuficiente (detectado por PHP) → error claro, sin INSERT
- [ ] Crear venta con stock insuficiente (detectado por trigger) → rollback, error claro
- [ ] Eliminar venta con ID inexistente → error controlado
- [ ] Crear venta con cantidad = 0 → error de validación
- [ ] Crear venta con monto = 0 → error de validación
- [ ] Transición de estado inválida (Completada → En Proceso) → bloqueada

### Seguridad
- [ ] DELETE venta como Empleado → verificar que rol no permite eliminar
- [ ] Manipulación de `id_venta` en GET → intval() previene inyección
- [ ] Manipulación de `id_producto` en POST → prepared statement seguro
- [ ] Acceso a detalle de venta de otro usuario → verificar autorización

### Integración
- [ ] Crear venta → Inventario.cantidad_disponible decrementado correctamente
- [ ] Eliminar venta → Inventario.cantidad_disponible repuesto correctamente
- [ ] Producto agotado → no aparece en dropdown de nueva venta
- [ ] Historial_Detalle_Ventas → trigger registra correctamente

---

*Spec generada: 2026-04-24T21:19:11Z*

---

## 13. Mejoras Técnicas Pendientes

### 13.1 Multi-producto por venta

**Problema actual**: El formulario actual solo permite un producto por venta.

**Mejora**: Agregar un carrito de compras dentro del modal que permita múltiples líneas de detalle:

```javascript
// Estado del carrito (JavaScript)
let cart = [];

function addToCart(id_producto, nombre, cantidad, precio) {
    const existing = cart.find(item => item.id_producto === id_producto);
    if (existing) {
        existing.cantidad += cantidad;
    } else {
        cart.push({ id_producto, nombre, cantidad, precio });
    }
    renderCart();
}

function renderCart() {
    const total = cart.reduce((sum, item) => sum + (item.cantidad * item.precio), 0);
    document.getElementById('cart-total').textContent = total.toFixed(2);
    // Actualizar tabla del carrito...
}
```

```php
// PHP: recibir múltiples productos
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['cart'])) {
    $cart = json_decode($_POST['cart'], true);
    
    $conn->begin_transaction();
    try {
        $id_venta = insertVentaCabecera($conn, $id_cliente, $monto_total);
        
        foreach ($cart as $item) {
            insertDetalleVenta(
                $conn, $id_venta,
                intval($item['id_producto']),
                intval($item['cantidad']),
                floatval($item['precio'])
            );
        }
        $conn->commit();
    } catch (Exception $e) {
        $conn->rollback();
    }
}
```

### 13.2 Filtros y búsqueda en listado

```php
// Filtros adicionales en gestion_ventas.php
$where_conditions = ['1=1'];
$params = [];
$param_types = '';

if (!empty($_GET['estado'])) {
    $where_conditions[] = 'V.estado = ?';
    $params[] = $_GET['estado'];
    $param_types .= 's';
}

if (!empty($_GET['fecha_desde'])) {
    $where_conditions[] = 'V.fecha_venta >= ?';
    $params[] = $_GET['fecha_desde'] . ' 00:00:00';
    $param_types .= 's';
}

if (!empty($_GET['fecha_hasta'])) {
    $where_conditions[] = 'V.fecha_venta <= ?';
    $params[] = $_GET['fecha_hasta'] . ' 23:59:59';
    $param_types .= 's';
}

$where_sql = implode(' AND ', $where_conditions);
$sql = "SELECT ... FROM Ventas V ... WHERE {$where_sql} ORDER BY V.fecha_venta DESC";
```

### 13.3 Descuento en ventas

```sql
-- Agregar campo descuento a Detalle_Ventas
ALTER TABLE Detalle_Ventas
  ADD COLUMN descuento DECIMAL(5,2) DEFAULT 0.00 AFTER precio_unitario,
  ADD COLUMN subtotal DECIMAL(10,2) GENERATED ALWAYS AS 
    (cantidad_vendida * precio_unitario * (1 - descuento / 100)) STORED;
```

### 13.4 Reporte de ventas con filtros de fecha

```php
function getVentasByPeriod(mysqli $conn, string $desde, string $hasta): array {
    $stmt = $conn->prepare(
        "SELECT DATE_FORMAT(V.fecha_venta, '%Y-%m-%d') AS fecha,
                COUNT(V.id_venta) AS num_ventas,
                SUM(V.monto_total) AS total,
                GROUP_CONCAT(I.nombre_producto SEPARATOR ', ') AS productos
         FROM Ventas V
         JOIN Detalle_Ventas DV ON V.id_venta = DV.id_venta
         JOIN Inventario I ON DV.id_producto = I.id_producto
         WHERE V.fecha_venta BETWEEN ? AND ?
         GROUP BY DATE_FORMAT(V.fecha_venta, '%Y-%m-%d')
         ORDER BY fecha ASC"
    );
    $desde_full = $desde . ' 00:00:00';
    $hasta_full  = $hasta  . ' 23:59:59';
    $stmt->bind_param("ss", $desde_full, $hasta_full);
    $stmt->execute();
    $result = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
    $stmt->close();
    return $result;
}
```

---

*Spec actualizada: 2026-04-24T21:19:11Z*
