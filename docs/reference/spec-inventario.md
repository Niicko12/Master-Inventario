# Especificación Técnica — Módulo Inventario

---
name: spec-inventario
module: inventario
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
8. [APIs del Módulo](#8-apis-del-módulo)
9. [Integración con otros módulos](#9-integración-con-otros-módulos)
10. [Schema de BD](#10-schema-de-bd)
11. [Organización Interna de Código](#11-organización-interna-de-código)
12. [Quality Requirements](#12-quality-requirements)
13. [Testing Scenarios](#13-testing-scenarios)

---

## 1. Visión General

### Propósito
El módulo de Inventario es el núcleo del sistema. Gestiona el catálogo de productos, controla el stock disponible, emite alertas de stock bajo y sirve como fuente de verdad para ventas y compras.

### Responsabilidades
1. CRUD completo de productos
2. Control de stock (cantidad disponible vs stock mínimo)
3. Registro de entradas y salidas de inventario
4. Alertas visuales de stock bajo
5. Consulta de productos disponibles para módulo de Ventas

### Relaciones con otros módulos
- **Ventas**: descuenta stock al crear venta (vía trigger de BD)
- **Compras**: incrementa stock al registrar compra completada
- **Reportes**: provee datos para reportes de inventario
- **Gráficas**: provee datos para visualizaciones analíticas
- **Integraciones**: recibe datos de importación CSV

---

## 2. Archivos del Módulo

| Archivo | Responsabilidad | Acceso |
|---------|----------------|--------|
| `gestion_inventario.php` | CRUD de productos + listado | Autenticado |
| `fetch_inventario.php` | AJAX — productos disponibles | Autenticado |

### Dependencias
- `config.php` — conexión BD
- `header.php` — layout + sesión
- `styles/gestion_inventario.css` — estilos del módulo

---

## 3. Máquinas de Estado

### 3.1 Estado de un Producto

```
[Creado — Stock Normal]
    │ cantidad_disponible <= stock_minimo
    ▼
[Stock Bajo — Alerta Visual]
    │ Nueva entrada de inventario
    ▼
[Creado — Stock Normal]

[Creado — Stock Normal]
    │ cantidad_disponible = 0
    ▼
[Sin Stock — No disponible para venta]
    │ Nueva entrada
    ▼
[Creado — Stock Normal]
```

**Estados implícitos** (sin campo explícito en BD):
- `Stock Normal`: `cantidad_disponible > stock_minimo`
- `Stock Bajo`: `0 < cantidad_disponible <= stock_minimo`
- `Sin Stock`: `cantidad_disponible = 0`
- `Stock Negativo`: **NUNCA debe ocurrir** (protegido por trigger)

### 3.2 Estado de una Entrada de Inventario

```
[Registrada]  — estado final, no cambia
```

Las entradas son inmutables una vez registradas (historial de auditoría).

---

## 4. Casos de Uso Detallados

### CU-INV-001: Listar productos

**Actor**: Cualquier usuario autenticado  
**Precondición**: Sesión activa  
**Postcondición**: Lista de productos mostrada con estado visual de stock

**Flujo**:
1. Usuario accede a `gestion_inventario.php`
2. PHP ejecuta `SELECT * FROM Inventario ORDER BY nombre_producto ASC`
3. Para cada producto, PHP determina estado de stock:
   - `cantidad_disponible > stock_minimo` → fila normal
   - `0 < cantidad_disponible <= stock_minimo` → fila resaltada (amarillo)
   - `cantidad_disponible = 0` → fila resaltada (rojo)
4. Tabla renderizada con columnas: ID, Nombre, Cantidad, Stock Mínimo, [Acciones]
5. Columna "Acciones" visible solo para Administrador y Empleado

---

### CU-INV-002: Crear producto

**Actor**: Administrador o Empleado  
**Precondición**: Sesión activa, rol permitido  
**Postcondición**: Nuevo producto en BD, inventario actualizado

**Flujo**:
1. Usuario hace clic en "Añadir Producto"
2. Modal de creación se abre
3. Usuario completa: Nombre, Cantidad Disponible, Stock Mínimo
4. Usuario hace clic en "Guardar Producto"
5. POST a `gestion_inventario.php` con `action = 'add'`
6. PHP valida campos (ver sección 6)
7. PHP ejecuta INSERT con prepared statement
8. Muestra mensaje de éxito vía alert de JavaScript
9. Página se recarga para mostrar el nuevo producto

**Campos del formulario**:
```html
<input type="text"   name="nombre_producto"     required maxlength="100">
<input type="number" name="cantidad_disponible"  required min="0">
<input type="number" name="stock_minimo"         required min="0">
```

---

### CU-INV-003: Editar producto

**Actor**: Administrador o Empleado  
**Precondición**: Producto existe  
**Postcondición**: Datos del producto actualizados en BD

**Flujo**:
1. Usuario hace clic en "Editar" en la fila del producto
2. Modal de edición se abre con datos pre-cargados via JavaScript:
   ```javascript
   function openEditModal(id, nombre, cantidad, stock) {
       document.getElementById('id_producto').value = id;
       document.getElementById('nombre_producto_edit').value = nombre;
       document.getElementById('cantidad_disponible_edit').value = cantidad;
       document.getElementById('stock_minimo_edit').value = stock;
       openModal('editProductModal');
   }
   ```
3. Usuario modifica los campos deseados
4. POST a `gestion_inventario.php` con `action = 'update'`
5. PHP valida campos y que `id_producto` sea un entero válido
6. PHP ejecuta UPDATE con prepared statement
7. Muestra mensaje de éxito
8. Página se recarga

**Campos adicionales en modal de edición**:
```html
<input type="hidden" name="id_producto" id="id_producto">
```

---

### CU-INV-004: Eliminar producto

**Actor**: Solo Administrador  
**Precondición**: Producto existe  
**Postcondición**: Producto eliminado de BD (si no tiene dependencias)

**Flujo**:
1. Usuario hace clic en "Eliminar" (solo visible para Administrador)
2. Confirmación via `onclick="return confirm('¿Estás seguro?')"`
3. GET a `gestion_inventario.php?delete={id_producto}`
4. PHP valida que `id_producto` es entero con `intval()`
5. PHP ejecuta DELETE
6. Si FK constraint falla (producto tiene ventas/compras) → mostrar error
7. Muestra mensaje de éxito o error
8. Página se recarga

**Regla**: Un producto con ventas, compras o entradas asociadas NO puede eliminarse (FK constraint de MySQL). Debe inactivarse en su lugar.

**Mejora pendiente**: En lugar de eliminación física, implementar campo `activo TINYINT(1)` y hacer soft delete:
```sql
UPDATE Inventario SET activo = 0 WHERE id_producto = ?
```

---

### CU-INV-005: Registrar entrada de inventario

**Actor**: Administrador o Empleado  
**Precondición**: Producto existe  
**Postcondición**: Stock incrementado, entrada registrada en historial

**Flujo**:
1. Usuario accede al form de entrada (modal o página separada)
2. Selecciona producto, ingresa cantidad, fecha (default hoy)
3. POST a endpoint de entradas
4. PHP valida campos
5. PHP inserta en `Entradas_Inventario`
6. PHP actualiza `Inventario.cantidad_disponible += cantidad`
7. Trigger `Entradas_Inventario_after_insert` registra en historial
8. Muestra confirmación

**SQL de actualización de stock**:
```sql
-- En transacción
INSERT INTO Entradas_Inventario (id_producto, cantidad_entrada, fecha_entrada, usuario_registro)
VALUES (?, ?, NOW(), ?);

UPDATE Inventario 
SET cantidad_disponible = cantidad_disponible + ?,
    fecha_ultima_actualizacion = NOW()
WHERE id_producto = ?;
```

---

### CU-INV-006: Consultar inventario disponible (AJAX)

**Actor**: Módulo de Ventas (interno)  
**Precondición**: Sesión activa  
**Postcondición**: JSON con productos disponibles retornado

**Flujo**:
1. JavaScript llama a `fetch_inventario.php`
2. PHP verifica sesión
3. PHP ejecuta:
   ```sql
   SELECT id_producto, nombre_producto, cantidad_disponible
   FROM Inventario
   WHERE cantidad_disponible > 0
   ORDER BY nombre_producto ASC
   ```
4. PHP retorna JSON array de productos

---

## 5. Reglas de Negocio

### 5.1 Reglas de stock

```
RN-INV-001: El stock disponible NUNCA puede ser negativo.
  → Protección: trigger before_insert_venta en BD
  → Protección adicional: validación PHP antes de venta

RN-INV-002: Si cantidad_disponible <= stock_minimo → mostrar alerta visual
  → Implementación: clase CSS en la fila de la tabla

RN-INV-003: Si cantidad_disponible = 0 → producto NO aparece en selector de ventas
  → Implementación: WHERE cantidad_disponible > 0 en fetch_inventario.php

RN-INV-004: La fecha_ultima_actualizacion se actualiza en cada modificación de stock
  → Implementación: SET fecha_ultima_actualizacion = NOW() en UPDATE

RN-INV-005: Las entradas de inventario son inmutables
  → No existe función de editar/eliminar entradas

RN-INV-006: Un producto con historial (ventas, compras, entradas) no puede eliminarse físicamente
  → Protección: FK constraints de MySQL
  → Solución: implementar soft delete con campo activo
```

### 5.2 Reglas de precios

```
RN-INV-007: El precio_unitario en Inventario es el precio de venta sugerido
  → El precio real de venta se captura en Detalle_Ventas.precio_unitario al momento de la venta
  → Esto permite ventas con precio diferente al catálogo

RN-INV-008: El precio_unitario en Detalle_Compras es el precio pagado al proveedor
  → Se mantiene histórico del precio de compra por transacción
```

### 5.3 Reglas de acceso por rol

```
RN-INV-009: Todos los usuarios autenticados pueden VER el inventario completo
RN-INV-010: Solo Administrador y Empleado pueden CREAR y EDITAR productos
RN-INV-011: Solo Administrador puede ELIMINAR productos
RN-INV-012: Solo Administrador y Empleado pueden REGISTRAR entradas
```

---

## 6. Validaciones

### 6.1 Validaciones de formulario (server-side PHP)

```php
function validateProductInput(array $data): array {
    $errors = [];
    
    // nombre_producto
    if (empty(trim($data['nombre_producto']))) {
        $errors['nombre'] = "El nombre del producto es requerido";
    } elseif (strlen($data['nombre_producto']) > 100) {
        $errors['nombre'] = "El nombre no puede superar 100 caracteres";
    }
    
    // cantidad_disponible
    if (!isset($data['cantidad_disponible']) || !is_numeric($data['cantidad_disponible'])) {
        $errors['cantidad'] = "La cantidad debe ser un número";
    } elseif (intval($data['cantidad_disponible']) < 0) {
        $errors['cantidad'] = "La cantidad no puede ser negativa";
    }
    
    // stock_minimo
    if (!isset($data['stock_minimo']) || !is_numeric($data['stock_minimo'])) {
        $errors['stock'] = "El stock mínimo debe ser un número";
    } elseif (intval($data['stock_minimo']) < 0) {
        $errors['stock'] = "El stock mínimo no puede ser negativo";
    }
    
    // precio_unitario (si aplica)
    if (isset($data['precio_unitario'])) {
        if (!is_numeric($data['precio_unitario']) || floatval($data['precio_unitario']) < 0) {
            $errors['precio'] = "El precio debe ser un número positivo";
        }
    }
    
    return $errors;
}
```

### 6.2 Validaciones de entrada de inventario

```php
function validateStockEntry(array $data): array {
    $errors = [];
    
    $id_producto = intval($data['id_producto'] ?? 0);
    if ($id_producto <= 0) {
        $errors['producto'] = "Selecciona un producto válido";
    }
    
    $cantidad = intval($data['cantidad_entrada'] ?? 0);
    if ($cantidad <= 0) {
        $errors['cantidad'] = "La cantidad de entrada debe ser mayor a 0";
    }
    
    return $errors;
}
```

### 6.3 Sanitización de input

```php
// Para strings
$nombre = htmlspecialchars(strip_tags(trim($_POST['nombre_producto'])), ENT_QUOTES, 'UTF-8');

// Para enteros
$cantidad = intval($_POST['cantidad_disponible']);
$stock_min = intval($_POST['stock_minimo']);
$id = intval($_GET['delete'] ?? 0);

// Para decimales
$precio = round(floatval($_POST['precio_unitario']), 2);
```

---

## 7. Operaciones de Base de Datos

### 7.1 Listar todos los productos

```php
$stmt = $conn->prepare(
    "SELECT id_producto, nombre_producto, cantidad_disponible, 
            stock_minimo, precio_unitario, fecha_ultima_actualizacion
     FROM Inventario
     ORDER BY nombre_producto ASC"
);
$stmt->execute();
$result = $stmt->get_result();
$stmt->close();
```

### 7.2 Crear producto

```php
$stmt = $conn->prepare(
    "INSERT INTO Inventario 
        (nombre_producto, cantidad_disponible, stock_minimo, precio_unitario, fecha_ultima_actualizacion)
     VALUES (?, ?, ?, ?, NOW())"
);
$stmt->bind_param("siid", $nombre, $cantidad, $stock_min, $precio);
$stmt->execute();
$new_id = $conn->insert_id;
$stmt->close();
```

### 7.3 Actualizar producto

```php
$stmt = $conn->prepare(
    "UPDATE Inventario 
     SET nombre_producto = ?,
         cantidad_disponible = ?,
         stock_minimo = ?,
         precio_unitario = ?,
         fecha_ultima_actualizacion = NOW()
     WHERE id_producto = ?"
);
$stmt->bind_param("siidi", $nombre, $cantidad, $stock_min, $precio, $id);
$stmt->execute();
$stmt->close();
```

### 7.4 Eliminar producto (con manejo de FK)

```php
$stmt = $conn->prepare("DELETE FROM Inventario WHERE id_producto = ?");
$stmt->bind_param("i", $id);

if (!$stmt->execute()) {
    // FK constraint violada — producto tiene historial
    if ($conn->errno === 1451) {
        $error = "No se puede eliminar: el producto tiene ventas o compras registradas";
    } else {
        $error = "Error al eliminar: " . $conn->error;
    }
}
$stmt->close();
```

### 7.5 Consultar productos con stock bajo

```php
$stmt = $conn->prepare(
    "SELECT id_producto, nombre_producto, cantidad_disponible, stock_minimo
     FROM Inventario
     WHERE cantidad_disponible <= stock_minimo
       AND cantidad_disponible > 0
     ORDER BY (cantidad_disponible / stock_minimo) ASC"
);
$stmt->execute();
$bajo_stock = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
$stmt->close();
```

### 7.6 Registrar entrada de inventario (transacción)

```php
$conn->begin_transaction();
try {
    // 1. Registrar entrada
    $stmt1 = $conn->prepare(
        "INSERT INTO Entradas_Inventario 
            (id_producto, cantidad_entrada, fecha_entrada, usuario_registro)
         VALUES (?, ?, NOW(), ?)"
    );
    $stmt1->bind_param("iii", $id_producto, $cantidad, $user_id);
    $stmt1->execute();
    $stmt1->close();
    
    // 2. Actualizar stock
    $stmt2 = $conn->prepare(
        "UPDATE Inventario 
         SET cantidad_disponible = cantidad_disponible + ?,
             fecha_ultima_actualizacion = NOW()
         WHERE id_producto = ?"
    );
    $stmt2->bind_param("ii", $cantidad, $id_producto);
    $stmt2->execute();
    $stmt2->close();
    
    $conn->commit();
} catch (Exception $e) {
    $conn->rollback();
    throw $e;
}
```

---

## 8. APIs del Módulo

### GET /fetch_inventario.php

**Propósito**: Retornar productos disponibles para formularios de venta

**Query params**: ninguno (retorna todos los productos con stock > 0)

**Response**:
```json
[
  { "id_producto": 4, "nombre_producto": "Vinil", "cantidad_disponible": 50 },
  { "id_producto": 13, "nombre_producto": "Tinta Negra", "cantidad_disponible": 120 }
]
```

**Response — sin productos disponibles**:
```json
[]
```

**Errores**:
```json
{ "error": "No autorizado" }
```

### Endpoints futuros recomendados

| Method | URL | Descripción |
|--------|-----|-------------|
| GET | `/api/inventario` | Listar con paginación y filtros |
| GET | `/api/inventario/{id}` | Detalle de un producto |
| POST | `/api/inventario` | Crear producto |
| PUT | `/api/inventario/{id}` | Actualizar producto |
| DELETE | `/api/inventario/{id}` | Eliminar/desactivar producto |
| GET | `/api/inventario/stock-bajo` | Productos con stock bajo |
| POST | `/api/inventario/{id}/entrada` | Registrar entrada de stock |

---

## 9. Integración con otros módulos

### 9.1 Con Módulo Ventas

**Flujo**: Al crear una venta, el trigger `before_insert_venta` en `Detalle_Ventas` verifica y actualiza el stock automáticamente.

```sql
-- Trigger de protección (ya existe en BD)
CREATE TRIGGER `before_insert_venta` BEFORE INSERT ON `Detalle_Ventas` FOR EACH ROW BEGIN
    DECLARE stock_disponible INT;
    
    SELECT cantidad_disponible INTO stock_disponible
    FROM Inventario WHERE id_producto = NEW.id_producto;
    
    IF stock_disponible IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: El producto especificado no existe.';
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

**Al eliminar una venta**: PHP debe reponer el stock manualmente (el trigger no lo hace en reversa).

```php
// Al eliminar venta — reponer stock
$conn->begin_transaction();
try {
    // 1. Obtener líneas de la venta
    $stmt = $conn->prepare(
        "SELECT id_producto, cantidad_vendida FROM Detalle_Ventas WHERE id_venta = ?"
    );
    $stmt->bind_param("i", $sale_id);
    $stmt->execute();
    $items = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
    $stmt->close();
    
    // 2. Reponer stock para cada producto
    foreach ($items as $item) {
        $stmt2 = $conn->prepare(
            "UPDATE Inventario 
             SET cantidad_disponible = cantidad_disponible + ?,
                 fecha_ultima_actualizacion = NOW()
             WHERE id_producto = ?"
        );
        $stmt2->bind_param("ii", $item['cantidad_vendida'], $item['id_producto']);
        $stmt2->execute();
        $stmt2->close();
    }
    
    // 3. Eliminar detalle y venta
    $conn->query("DELETE FROM Detalle_Ventas WHERE id_venta = " . intval($sale_id));
    $conn->query("DELETE FROM Ventas WHERE id_venta = " . intval($sale_id));
    
    $conn->commit();
} catch (Exception $e) {
    $conn->rollback();
}
```

### 9.2 Con Módulo Compras

Al registrar una compra completada, el stock debe incrementarse:
```php
// En update_purchase.php cuando estado cambia a 'Completada'
$stmt = $conn->prepare(
    "UPDATE Inventario 
     SET cantidad_disponible = cantidad_disponible + ?,
         fecha_ultima_actualizacion = NOW()
     WHERE nombre_producto = ?"  // o id_producto si está vinculado
);
```

### 9.3 Con Módulo Reportes

```php
// Query para reporte de inventario
$sql = "SELECT nombre_producto, cantidad_disponible, stock_minimo,
               precio_unitario,
               CASE 
                 WHEN cantidad_disponible = 0 THEN 'Sin Stock'
                 WHEN cantidad_disponible <= stock_minimo THEN 'Stock Bajo'
                 ELSE 'Normal'
               END AS estado_stock
        FROM Inventario
        ORDER BY nombre_producto ASC";
```

---

## 10. Schema de BD

### Tabla: Inventario

```sql
CREATE TABLE `Inventario` (
  `id_producto`                INT(11) AUTO_INCREMENT PRIMARY KEY,
  `nombre_producto`            VARCHAR(100) NOT NULL,
  `cantidad_disponible`        INT(11) NOT NULL DEFAULT 0,
  `stock_minimo`               INT(11) NOT NULL DEFAULT 0,
  `precio_unitario`            DECIMAL(10,2) DEFAULT 0.00,
  `activo`                     TINYINT(1) NOT NULL DEFAULT 1,
  `fecha_ultima_actualizacion` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Índices recomendados
ALTER TABLE Inventario 
  ADD INDEX idx_inv_stock (cantidad_disponible),
  ADD INDEX idx_inv_activo (activo),
  ADD INDEX idx_inv_nombre (nombre_producto);
```

### Tabla: Entradas_Inventario

```sql
CREATE TABLE `Entradas_Inventario` (
  `id_entrada`        INT(11) AUTO_INCREMENT PRIMARY KEY,
  `id_producto`       INT(11) NOT NULL,
  `cantidad_entrada`  INT(11) NOT NULL,
  `fecha_entrada`     DATETIME DEFAULT CURRENT_TIMESTAMP,
  `usuario_registro`  INT(11) DEFAULT NULL,
  FOREIGN KEY (id_producto)      REFERENCES Inventario(id_producto),
  FOREIGN KEY (usuario_registro) REFERENCES Usuarios(id_usuario),
  INDEX idx_ei_producto (id_producto),
  INDEX idx_ei_fecha (fecha_entrada)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Tabla: Historial_Inventario (pendiente crear)

```sql
CREATE TABLE `Historial_Inventario` (
  `id_historial`         INT AUTO_INCREMENT PRIMARY KEY,
  `id_producto`          INT NOT NULL,
  `tipo_accion`          ENUM('INSERT','UPDATE','DELETE') NOT NULL,
  `campo_modificado`     VARCHAR(50),
  `valor_anterior`       VARCHAR(255),
  `valor_nuevo`          VARCHAR(255),
  `fecha_modificacion`   DATETIME DEFAULT CURRENT_TIMESTAMP,
  `usuario_modifico`     INT,
  INDEX idx_hi_producto (id_producto),
  INDEX idx_hi_fecha (fecha_modificacion)
) ENGINE=InnoDB;
```

---

## 11. Organización Interna de Código

### 11.1 Estructura de gestion_inventario.php

```
Líneas 1-10:   includes + verificación de permisos
Líneas 11-50:  Procesamiento POST action='add'
Líneas 51-90:  Procesamiento POST action='update'
Líneas 91-120: Procesamiento GET delete
Líneas 121-150: Query SELECT para listado
---
Líneas 151-200: HTML — cabecera + botón "Añadir"
Líneas 201-260: HTML — tabla de productos con PHP embebido
---
Líneas 261-330: Modal — Crear producto
Líneas 331-400: Modal — Editar producto
Líneas 401-430: JavaScript — funciones de modal
---
Líneas 431-432: include footer

TOTAL objetivo: ~430 líneas (actualmente ~200 sin algunos campos)
```

### 11.2 Lógica de colores de stock en tabla

```php
// Determinar clase CSS por estado de stock
function getStockClass(int $cantidad, int $minimo): string {
    if ($cantidad === 0) return 'stock-critical';       // rojo
    if ($cantidad <= $minimo) return 'stock-warning';   // amarillo
    return '';                                           // normal
}
```

```css
/* styles/gestion_inventario.css */
.stock-critical { background-color: #ffcccc; }
.stock-warning  { background-color: #fff3cd; }
```

---

## 12. Quality Requirements

### 12.1 Performance

| Operación | Target | Condición |
|-----------|--------|-----------|
| Listar productos | < 200ms | Hasta 1000 productos |
| Crear/editar producto | < 300ms | Incluye redirect |
| Fetch AJAX (ventas) | < 100ms | Hasta 1000 productos |
| Registro de entrada | < 300ms | Con transacción |

### 12.2 Integridad de datos

```
- cantidad_disponible nunca negativo (trigger BD)
- FK constraints activos entre Inventario y tablas relacionadas
- fecha_ultima_actualizacion se actualiza en cada modificación
- Historial completo via triggers en Entradas_Inventario
```

### 12.3 Índices de BD requeridos

```sql
INDEX idx_inv_stock    ON Inventario(cantidad_disponible)
INDEX idx_inv_activo   ON Inventario(activo)
INDEX idx_ei_producto  ON Entradas_Inventario(id_producto)
INDEX idx_ei_fecha     ON Entradas_Inventario(fecha_entrada)
```

---

## 13. Testing Scenarios

### Happy path
- [ ] Listar productos — tabla renderizada correctamente
- [ ] Crear producto nuevo — aparece en tabla
- [ ] Editar producto existente — cambios persistidos
- [ ] Eliminar producto sin historial — eliminado de BD
- [ ] Stock bajo → alerta visual amarilla
- [ ] Stock = 0 → alerta visual roja + no aparece en ventas
- [ ] Registrar entrada de inventario → stock incrementado
- [ ] Fetch AJAX → retorna productos con stock > 0

### Error paths
- [ ] Crear producto con nombre vacío → error de validación
- [ ] Crear producto con cantidad negativa → error de validación
- [ ] Eliminar producto con ventas asociadas → error FK, mensaje claro
- [ ] Editar con ID manipulado en POST → intval() previene inyección
- [ ] Registrar entrada con cantidad 0 → error de validación

### Seguridad
- [ ] POST create con nombre que contiene SQL injection → prepared statement lo bloquea
- [ ] GET delete sin sesión → redirect a login
- [ ] POST create como Usuario (rol sin permiso) → redirect a index
- [ ] Manipulación de `id_producto` en POST → intval() previene

### Integración
- [ ] Crear venta → stock de Inventario decrementado
- [ ] Eliminar venta → stock de Inventario repuesto
- [ ] Compra completada → stock incrementado
- [ ] Importar CSV → productos creados/actualizados en Inventario

---

## 14. Especificaciones de Búsqueda y Filtrado

### 14.1 Filtros disponibles en gestion_inventario.php

```
Filtro 1: Búsqueda por nombre (texto libre)
- Input: text, minLength=2
- Backend: WHERE nombre LIKE ? con '%nombre%'
- Sensible a tildes: SÍ (utf8mb4_unicode_ci es case-insensitive y acento-sensitive)
- Resultado: productos cuyo nombre contenga el texto buscado

Filtro 2: Stock bajo
- Input: checkbox / botón "Solo Stock Bajo"
- Backend: WHERE cantidad_disponible <= stock_minimo
- Resultado: productos con alerta de stock activa

Filtro 3: Sin stock
- Input: checkbox / botón "Sin Stock"
- Backend: WHERE cantidad_disponible = 0
- Resultado: productos agotados

Filtro 4: Por proveedor (futuro)
- Input: select proveedor
- Backend: JOIN con Compras → id_proveedor
- Estado: No implementado (pendiente Fase 3)
```

### 14.2 Ordenamiento

```
Columnas ordenables:
- nombre ASC/DESC
- cantidad_disponible ASC/DESC (útil para gestión de stock)
- precio_unitario ASC/DESC
- fecha_modificacion DESC (default — más reciente primero)

Implementación via parámetro GET:
?sort=cantidad_disponible&dir=asc

Validación de columna (whitelist — NUNCA usar columna de $_GET directamente):
$cols_permitidas = ['nombre', 'cantidad_disponible', 'precio_unitario', 'fecha_modificacion'];
$col = in_array($_GET['sort'] ?? '', $cols_permitidas) ? $_GET['sort'] : 'fecha_modificacion';
$dir = ($_GET['dir'] ?? 'desc') === 'asc' ? 'ASC' : 'DESC';
$sql .= " ORDER BY $col $dir"; // seguro — columna viene de whitelist
```

### 14.3 Paginación

```
Parámetros:
- page: número de página (default 1, mínimo 1)
- per_page: resultados por página (default 25, opciones: 10/25/50/100)

Cálculo:
$page     = max(1, intval($_GET['page'] ?? 1));
$per_page = in_array(intval($_GET['per_page'] ?? 25), [10,25,50,100]) ? intval($_GET['per_page']) : 25;
$offset   = ($page - 1) * $per_page;

Query con paginación:
SELECT SQL_CALC_FOUND_ROWS * FROM Inventario
WHERE {filtros}
ORDER BY {col} {dir}
LIMIT ? OFFSET ?

Total de registros:
SELECT FOUND_ROWS() AS total;

Metadata de paginación retornada:
{
  "data": [...],
  "pagination": {
    "page": 2,
    "per_page": 25,
    "total": 247,
    "total_pages": 10,
    "has_next": true,
    "has_prev": true
  }
}
```

---

## 15. Operaciones en Lote (Bulk Operations)

### 15.1 Eliminación masiva

```
Casos de uso:
- Seleccionar múltiples productos y eliminar en una sola acción
- Aplicar solo si rol = Administrador

UI:
- Checkbox en cada fila de la tabla
- Checkbox en header para seleccionar todos
- Barra de acciones aparece al seleccionar ≥1 elemento
- Botón "Eliminar seleccionados" con confirmación

Backend (eliminar_masivo.php):
POST body: ids[]=1&ids[]=2&ids[]=5

Validación:
1. Verificar sesión y rol Administrador
2. Validar array de IDs (todos deben ser enteros positivos)
3. Verificar que ningún producto tiene ventas activas asociadas
4. Ejecutar eliminación en transacción

Respuesta:
{
  "success": true,
  "deleted": 3,
  "skipped": [{"id": 5, "reason": "Tiene ventas asociadas"}]
}
```

### 15.2 Actualización masiva de precios

```
Casos de uso:
- Aplicar porcentaje de incremento a categoría de productos
- Redondeo automático a .99 o entero

UI:
- Seleccionar productos (o todos)
- Modal: "Aumentar precio X%" o "Precio fijo"
- Preview de cambios antes de confirmar

Backend:
POST body: ids[]=[...], tipo=porcentaje, valor=15
o          ids[]=[...], tipo=fijo, valor=299.99

SQL:
-- Porcentaje:
UPDATE Inventario SET precio_unitario = ROUND(precio_unitario * (1 + ?/100), 2)
WHERE id_producto IN (?, ?, ?)

-- Validación: precio resultante no puede ser < 0.01

Registro en Historial:
INSERT INTO Historial_Inventario (id_producto, accion, detalle, id_usuario, fecha)
SELECT id_producto, 'PRECIO_ACTUALIZADO',
       CONCAT('Anterior: ', precio_unitario, ' → Nuevo: ', nuevo_precio),
       ?, NOW()
FROM Inventario WHERE id_producto IN (...)
```

---

## 16. Integraciones del Módulo Inventario

### 16.1 Relación con módulo Ventas

```
Dependencia: Ventas.id_producto → Inventario.id_producto (FK)

Flujo al crear venta:
1. Verificar cantidad_disponible >= cantidad_vendida
2. Si no: retornar error "Stock insuficiente"
3. Si sí: INSERT INTO Ventas + UPDATE Inventario SET cantidad_disponible = cantidad_disponible - ?

Flujo al eliminar venta:
1. Obtener cantidad_vendida de la venta a eliminar
2. UPDATE Inventario SET cantidad_disponible = cantidad_disponible + cantidad_vendida
3. DELETE FROM Ventas
(Proceso manejado por trigger o lógica PHP — documentar cuál aplica)

Fetch para formulario de nueva venta:
- Solo mostrar productos con cantidad_disponible > 0
- Incluir precio_unitario como sugerencia de precio de venta
- Endpoint: fetch_inventario.php → retorna JSON con id + nombre + precio + stock
```

### 16.2 Relación con módulo Compras

```
Dependencia: Compras.id_producto → Inventario.id_producto (FK)

Flujo al completar compra:
1. Estado de compra cambia a 'Completada'
2. UPDATE Inventario SET cantidad_disponible = cantidad_disponible + cantidad_comprada
3. INSERT INTO Entradas_Inventario (registro de entrada)

Alerta de stock mínimo en compras:
- Al registrar nueva compra: sugerir cantidad si producto está en stock bajo
- Sugerencia: MAX(stock_minimo * 3, 10) unidades como cantidad recomendada
```

### 16.3 Relación con módulo Reportes

```
Reportes que usan datos de Inventario:
1. "Inventario Actual" — snapshot de todos los productos con stock y precio
2. "Valorización de Inventario" — SUM(cantidad_disponible * precio_unitario) por producto
3. "Productos sin movimiento" — productos sin ventas en N días
4. "Rotación de inventario" — ventas / stock promedio en período

Query de valorización:
SELECT
  nombre,
  cantidad_disponible,
  precio_unitario,
  (cantidad_disponible * precio_unitario) AS valor_total
FROM Inventario
WHERE cantidad_disponible > 0
ORDER BY valor_total DESC;

Query de productos sin movimiento (últimos 30 días):
SELECT i.nombre, i.cantidad_disponible, i.precio_unitario,
       MAX(v.fecha_venta) AS ultima_venta
FROM Inventario i
LEFT JOIN Ventas v ON i.id_producto = v.id_producto
  AND v.fecha_venta >= DATE_SUB(NOW(), INTERVAL 30 DAY)
WHERE v.id_venta IS NULL
GROUP BY i.id_producto;
```

---

*Spec actualizada: 2026-04-26T03:37:03Z — Búsqueda/filtrado, bulk ops, integraciones.*
