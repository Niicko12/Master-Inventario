---
name: spec-dashboard-admin
status: active
created: 2026-04-26T03:37:03Z
updated: 2026-05-04T04:55:18Z
---

# Spec: Dashboard y Módulo de Administración

## 1. Visión General

El Dashboard (`dashboard.php`) es la pantalla principal post-login. Muestra KPIs críticos del negocio, gráficas de tendencia y alertas operativas. El Módulo de Administración (`administrar_usuarios.php`, `configuracion_sistema.php`) proporciona control completo del sistema para el rol Administrador.

### Usuarios objetivo por pantalla

| Pantalla | Rol mínimo | Propósito |
|---------|-----------|-----------|
| dashboard.php | Usuario | Vista resumen de métricas del negocio |
| administrar_usuarios.php | Administrador | CRUD de usuarios del sistema |
| configuracion_sistema.php | Administrador | Parámetros globales del sistema |
| graficas.php | Empleado | Gráficas analíticas avanzadas |
| perfil.php | Usuario | Edición de datos propios |

---

## 2. Dashboard — KPIs y Métricas

### 2.1 KPIs en tarjetas (parte superior)

Cada KPI se muestra en una card con el valor principal, variación porcentual respecto al período anterior y color de estado.

```
KPI 1: Ventas del día
  Query: SELECT COALESCE(SUM(precio_total), 0) FROM Ventas
         WHERE DATE(fecha_venta) = CURDATE() AND estado != 'Cancelada'
  Variación: comparar con mismo día de semana anterior
  Color: verde si > anterior, rojo si < anterior, gris si igual
  Formato: $X,XXX.XX MXN

KPI 2: Productos en stock bajo
  Query: SELECT COUNT(*) FROM Inventario
         WHERE cantidad_disponible <= stock_minimo AND cantidad_disponible > 0
  Color: amarillo si > 0, verde si = 0
  Acción: click → redirige a gestion_inventario.php?filter=stock_bajo

KPI 3: Productos sin stock
  Query: SELECT COUNT(*) FROM Inventario WHERE cantidad_disponible = 0
  Color: rojo si > 0, verde si = 0
  Acción: click → redirige a gestion_inventario.php?filter=sin_stock

KPI 4: Compras pendientes
  Query: SELECT COUNT(*) FROM Compras WHERE estado = 'Pendiente'
  Color: naranja si > 0, verde si = 0
  Acción: click → redirige a gestion_compras.php?estado=Pendiente

KPI 5: Ventas del mes
  Query: SELECT COALESCE(SUM(precio_total), 0) FROM Ventas
         WHERE MONTH(fecha_venta) = MONTH(CURDATE())
           AND YEAR(fecha_venta) = YEAR(CURDATE())
           AND estado != 'Cancelada'

KPI 6: Total de productos en inventario
  Query: SELECT COUNT(*) FROM Inventario
  Subtexto: "X con stock bajo" (referencia a KPI 2)
```

### 2.2 Gráficas del Dashboard

```
Gráfica 1: Ventas de los últimos 7 días (línea)
  - Tipo: Chart.js LineChart
  - Eje X: fechas de hoy-6 a hoy
  - Eje Y: suma de ventas por día
  - Color: gradiente azul (#3498db → transparente)
  - Dataset: comparación con semana anterior (línea punteada gris)

  Query:
  SELECT DATE(fecha_venta) AS dia, SUM(precio_total) AS total
  FROM Ventas
  WHERE fecha_venta >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
    AND estado != 'Cancelada'
  GROUP BY dia ORDER BY dia ASC

Gráfica 2: Top 5 productos más vendidos (barras horizontales)
  - Tipo: Chart.js HorizontalBar
  - Eje Y: nombre del producto
  - Eje X: cantidad total vendida
  - Color: palette de 5 colores del tema

  Query:
  SELECT i.nombre, SUM(v.cantidad_vendida) AS total_vendido
  FROM Ventas v JOIN Inventario i ON v.id_producto = i.id_producto
  WHERE v.fecha_venta >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    AND v.estado != 'Cancelada'
  GROUP BY i.id_producto, i.nombre
  ORDER BY total_vendido DESC LIMIT 5

Gráfica 3: Distribución de ventas por estado (dona)
  - Tipo: Chart.js DoughnutChart
  - Segmentos: Completada, Pendiente, Cancelada
  - Colores: verde, amarillo, rojo
```

### 2.3 Tabla de actividad reciente

```
Últimas 10 transacciones (ventas + compras mezcladas):
SELECT
  'Venta' AS tipo,
  CONCAT('Venta #', id_venta) AS descripcion,
  precio_total AS monto,
  fecha_venta AS fecha,
  estado
FROM Ventas
UNION ALL
SELECT
  'Compra' AS tipo,
  CONCAT('Compra a ', p.nombre) AS descripcion,
  c.monto_total AS monto,
  c.fecha_compra AS fecha,
  c.estado
FROM Compras c JOIN Proveedores p ON c.id_proveedor = p.id_proveedor
ORDER BY fecha DESC LIMIT 10

Columnas mostradas: Tipo | Descripción | Monto | Fecha | Estado | Acción
Acción: link directo al módulo correspondiente
```

### 2.4 Panel de alertas críticas

```
Alertas mostradas solo si condición es verdadera:

1. ALERTA: "X productos sin stock"
   Condición: COUNT(*) > 0 WHERE cantidad_disponible = 0
   Severidad: ERROR (rojo)
   Acción: Botón "Ver productos" → gestion_inventario.php?filter=sin_stock

2. ALERTA: "X productos con stock bajo"
   Condición: COUNT(*) > 0 WHERE cantidad_disponible <= stock_minimo
   Severidad: WARNING (amarillo)

3. ALERTA: "X compras pendientes de recibir"
   Condición: COUNT(*) > 0 WHERE estado = 'Pendiente' AND fecha_compra < DATE_SUB(NOW(), INTERVAL 7 DAY)
   Severidad: WARNING (amarillo)

4. ALERTA: "X usuarios pendientes de verificación" (solo admin)
   Condición: COUNT(*) > 0 WHERE verificado = 0
   Severidad: INFO (azul)

UI: Las alertas se apilan en un panel lateral derecho o banner superior.
Sin alertas: mostrar "Sistema operando normalmente" con ícono verde.
```

---

## 3. Administración de Usuarios

### 3.1 Listado de usuarios

```
Tabla con columnas:
- Nombre completo
- Email
- Rol (badge coloreado: Admin=rojo, Empleado=azul, Usuario=gris)
- Estado (badge: Activo=verde, Inactivo=gris, Bloqueado=rojo)
- Verificado (ícono check/x)
- Último acceso
- Acciones: Editar | Activar/Desactivar | Eliminar

Filtros:
- Por rol (select)
- Por estado (select)
- Búsqueda por nombre/email (text)

Query:
SELECT id_usuario, nombre, apellido, correo, rol, estado, verificado,
       ultimo_acceso
FROM Usuarios
ORDER BY fecha_registro DESC
```

### 3.2 Crear/Editar usuario — reglas de negocio

```
Reglas al crear:
1. Email único — verificar con SELECT COUNT(*) WHERE correo = ?
2. Contraseña generada automáticamente o ingresada por admin
3. Si es admin: enviar email con credenciales temporales
4. Estado inicial: Activo + Verificado (creado por admin)

Reglas al editar:
1. Admin no puede cambiar su propio rol (evitar auto-desescalada)
   → if ($id_editado === $_SESSION['user_id'] && $nuevo_rol !== 'Administrador') → error
2. Admin no puede desactivar su propia cuenta
3. Contraseña: campo opcional en edición (vacío = no cambiar)
4. Si se cambia email: marcar verificado = 0 y enviar nuevo email de verificación

Reglas al eliminar:
1. Admin no puede eliminarse a sí mismo
2. Si usuario tiene ventas asociadas: desactivar en lugar de eliminar (integridad)
3. Soft delete: UPDATE Usuarios SET estado = 'Inactivo' (nunca DELETE directo)
```

### 3.3 Gestión de 2FA por admin

```
Pantalla: sección dentro de editar usuario (solo para rol Administrador)

Acciones disponibles:
- Habilitar 2FA → envía código de configuración al usuario
- Deshabilitar 2FA → elimina configuración 2FA del usuario
- Regenerar código de respaldo → genera nuevos backup codes

Tabla: usuarios con 2FA habilitado
Columnas: Nombre | Método 2FA | Habilitado desde | Último uso

Query:
SELECT u.nombre, u.correo, u.two_factor_method, u.two_factor_enabled,
       u.two_factor_created, u.last_two_factor_use
FROM Usuarios u
WHERE u.two_factor_enabled = 1
ORDER BY u.nombre
```

---

## 4. Configuración del Sistema

### 4.1 Parámetros configurables

```
Sección: Información del Negocio
- nombre_empresa: VARCHAR(100), requerido
- rfc_empresa: VARCHAR(20), opcional
- direccion: TEXT, opcional
- telefono: VARCHAR(20), opcional
- email_empresa: VARCHAR(100), formato email
- logo: upload imagen (PNG/JPG, max 2MB, se usa en PDFs)

Sección: Parámetros de Inventario
- stock_minimo_default: INT, default=10, range 1-999
  → Se usa como stock_minimo al crear productos sin valor específico
- moneda: ENUM('MXN','USD','EUR'), default='MXN'
- decimales_precio: ENUM(0,1,2), default=2
- alerta_stock_email: BOOL, envía email al admin cuando stock < mínimo

Sección: Seguridad
- intentos_login_max: INT, default=5, range 1-20 (pendiente implementar)
- session_timeout_min: INT, default=60, range 15-480
- forzar_2fa_admin: BOOL, si true todos los admins deben tener 2FA

Sección: Email (PHPMailer)
- smtp_host: VARCHAR(100)
- smtp_port: INT (465/587)
- smtp_user: VARCHAR(100)
- smtp_pass: VARCHAR(100) — encriptado en BD
- smtp_from_name: VARCHAR(100)
(Nota: en producción estos valores están en .env, aquí solo se muestra en BD como override)
```

### 4.2 Tabla configuracion_sistema — schema

```sql
-- Tabla de configuración clave-valor (flexible para agregar params sin migración)
CREATE TABLE IF NOT EXISTS configuracion_sistema (
    id INT AUTO_INCREMENT PRIMARY KEY,
    clave VARCHAR(100) NOT NULL UNIQUE,
    valor TEXT,
    tipo ENUM('string','int','bool','email','url','json') DEFAULT 'string',
    descripcion VARCHAR(255),
    fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    modificado_por INT,
    FOREIGN KEY (modificado_por) REFERENCES Usuarios(id_usuario) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Registros iniciales
INSERT INTO configuracion_sistema (clave, valor, tipo, descripcion) VALUES
('nombre_empresa', 'Mi Empresa S.A.', 'string', 'Nombre que aparece en PDFs y emails'),
('moneda', 'MXN', 'string', 'Moneda del sistema'),
('stock_minimo_default', '10', 'int', 'Stock mínimo por defecto para nuevos productos'),
('decimales_precio', '2', 'int', 'Decimales para precios'),
('session_timeout_min', '60', 'int', 'Minutos de inactividad antes de cerrar sesión'),
('alerta_stock_email', '0', 'bool', 'Enviar email cuando producto llegue a stock mínimo');
```

### 4.3 Función helper para leer configuración

```php
// functions/config_helper.php

/**
 * Lee un valor de configuracion_sistema con caché en sesión.
 * Tipo 'bool' retorna true/false, 'int' retorna int, demás retorna string.
 */
function getSistemaConfig(mysqli $conn, string $clave, mixed $default = null): mixed {
    // Cache en sesión para evitar N queries por página
    if (!isset($_SESSION['sys_config'])) {
        $_SESSION['sys_config'] = [];
    }
    if (isset($_SESSION['sys_config'][$clave])) {
        return $_SESSION['sys_config'][$clave];
    }

    $stmt = $conn->prepare("SELECT valor, tipo FROM configuracion_sistema WHERE clave = ?");
    $stmt->bind_param("s", $clave);
    $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if (!$row) return $default;

    $valor = match($row['tipo']) {
        'int'  => intval($row['valor']),
        'bool' => (bool)intval($row['valor']),
        default => $row['valor'],
    };

    $_SESSION['sys_config'][$clave] = $valor;
    return $valor;
}

// Invalidar caché al guardar configuración
function invalidarConfigCache(): void {
    unset($_SESSION['sys_config']);
}

// Uso:
$moneda = getSistemaConfig($conn, 'moneda', 'MXN');
$timeout = getSistemaConfig($conn, 'session_timeout_min', 60);
$alertas = getSistemaConfig($conn, 'alerta_stock_email', false);
```

---

## 5. Perfil de Usuario

### 5.1 Datos editables por el propio usuario

```
Permitido editar:
- nombre: VARCHAR(100), requerido
- apellido: VARCHAR(100), requerido
- telefono: VARCHAR(20), opcional
- contraseña: cambio con confirmación de contraseña actual

NO permitido editar por usuario:
- correo (cambia solo el admin — requiere re-verificación)
- rol
- estado

Flujo de cambio de contraseña:
1. Ingresar contraseña actual → verificar con password_verify()
2. Ingresar nueva contraseña + confirmación
3. Validar que nueva contraseña ≠ actual
4. Validar complejidad: min 8 chars (pendiente: mayúscula + número)
5. UPDATE Usuarios SET contrasena = password_hash(nueva, PASSWORD_BCRYPT, ['cost'=>12])
6. Invalidar sesión de otros dispositivos (futuro)
```

### 5.2 Upload de foto de perfil

```
Especificaciones:
- Tipos: image/jpeg, image/png, image/webp
- Tamaño máx: 2MB
- Dimensiones: redimensionar a 200×200 si es mayor (GD library o Imagick)
- Nombre: avatar_{id_usuario}_{timestamp}.jpg
- Ruta: uploads/avatars/
- BD: UPDATE Usuarios SET avatar = 'uploads/avatars/...' WHERE id_usuario = ?

Validación adicional:
- Verificar que es imagen real (getimagesize() !== false)
- No confiar solo en MIME de $_FILES (puede ser spoofed)
- getimagesize() analiza el binario real del archivo

Mostrar en header.php:
<img src="<?= $avatar_url ? htmlspecialchars($avatar_url) : 'assets/default-avatar.png' ?>"
     alt="Avatar" class="rounded-circle" width="36" height="36">
```

---

## 6. Máquinas de Estado

### 6.1 Estado de Usuario

```
Estados posibles: Activo, Inactivo, Bloqueado

Transiciones permitidas:
Activo → Inactivo: Admin desactiva usuario
Activo → Bloqueado: Sistema bloquea por X intentos fallidos (futuro)
Inactivo → Activo: Admin reactiva usuario
Bloqueado → Activo: Admin desbloquea manualmente
Bloqueado → Inactivo: Admin desactiva sin desbloquear

Transiciones prohibidas:
- Cualquier usuario → eliminar (usar Inactivo en su lugar)
- Admin a cualquier otro estado (debe haber siempre ≥1 Admin Activo)

Validación de estado mínimo:
function validarAdminActivo(mysqli $conn, int $id_a_cambiar, string $nuevo_estado): bool {
    if ($nuevo_estado === 'Activo') return true;
    $stmt = $conn->prepare("SELECT COUNT(*) as total FROM Usuarios
                            WHERE rol = 'Administrador' AND estado = 'Activo' AND id_usuario != ?");
    $stmt->bind_param("i", $id_a_cambiar);
    $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc();
    $stmt->close();
    return $row['total'] > 0; // Debe quedar al menos 1 admin activo
}
```

### 6.2 Estado de Configuración del Sistema

```
Configuración tiene 3 estados:
1. Default (valores de INSERT inicial)
2. Personalizada (modificada por admin)
3. Inválida (valor fuera de rango — forzar al default)

Al guardar configuración:
- Validar tipo: int para 'int', email format para 'email', etc.
- Si inválido: no guardar, mostrar error específico
- Si válido: guardar + invalidarConfigCache() + log de cambio

Log de cambios de configuración:
INSERT INTO configuracion_sistema_log (clave, valor_anterior, valor_nuevo, id_usuario, fecha)
VALUES (?, ?, ?, ?, NOW())
```

---

## 7. Security Model del Dashboard

### 7.1 Datos sensibles en el Dashboard

```
Datos que NO deben mostrarse en el Dashboard a rol Usuario:
- Listado de usuarios
- Costos de compras (solo Empleado+)
- Margen de ganancia
- Datos de configuración del sistema

Datos visibles por rol:

Rol Usuario:
- KPIs: Ventas del día/mes (sus propias ventas si aplica)
- Gráfica: Ventas recientes (sus propias)
- Tabla: Solo sus transacciones

Rol Empleado:
- Todos los KPIs operativos
- Gráficas completas
- Tabla de actividad reciente (todas)
- NO: administración de usuarios ni configuración

Rol Administrador:
- Todo lo anterior + panel de administración
- KPIs adicionales: usuarios activos, intentos de login fallidos
- Acceso a todos los módulos
```

### 7.2 Verificación en dashboard.php

```php
// Al inicio de dashboard.php
include('header.php'); // establece $conn, $_SESSION, $user_role

// Verificar sesión activa
if (!isset($_SESSION['user_id'])) {
    header("Location: login.php"); exit;
}

// Para admins: verificar 2FA completado
if ($_SESSION['user_role'] === 'Administrador' && !isset($_SESSION['2fa_verified'])) {
    header("Location: verificacion_2fa.php"); exit;
}

// Cargar KPIs según rol
$kpis = [];
$kpis['ventas_hoy'] = getVentasHoy($conn);
$kpis['stock_bajo'] = getStockBajo($conn);
$kpis['sin_stock'] = getSinStock($conn);

if (in_array($_SESSION['user_role'], ['Administrador', 'Empleado'])) {
    $kpis['compras_pendientes'] = getComprasPendientes($conn);
}

if ($_SESSION['user_role'] === 'Administrador') {
    $kpis['usuarios_sin_verificar'] = getUsuariosSinVerificar($conn);
}
```

---

## 8. Testing Scenarios — Dashboard y Admin

### 8.1 Dashboard — casos críticos

```
TEST D1: KPIs reflejan datos en tiempo real
Pasos:
  1. Abrir dashboard → anotar "Ventas del día"
  2. Crear una venta de $500
  3. Refrescar dashboard
  4. Verificar: "Ventas del día" aumentó en $500

TEST D2: Alerta de stock bajo aparece/desaparece
Pasos:
  1. Reducir stock de producto X a 0
  2. Abrir dashboard → alerta "Sin stock" visible
  3. Agregar stock al producto X
  4. Refrescar → alerta desaparece

TEST D3: Acceso por rol a métricas
Pasos:
  1. Login como Usuario (no Admin)
  2. Verificar: no ve compras_pendientes, usuarios, configuración
  3. Login como Empleado
  4. Verificar: ve compras_pendientes, NO ve admin panel

TEST D4: Gráfica de 7 días sin datos
Pasos:
  1. Usar BD de prueba sin ventas en últimos 7 días
  2. Abrir dashboard → sección de gráficas
  3. Verificar: gráfica renderiza con valores en cero (no error JS)
```

### 8.2 Admin usuarios — casos críticos

```
TEST A1: Admin no puede eliminarse a sí mismo
Pasos:
  1. Login como Administrador
  2. Ir a administrar_usuarios.php
  3. Intentar eliminar/desactivar la propia cuenta
  4. Esperado: botón deshabilitado o error "No puede desactivar su propia cuenta"

TEST A2: Cambio de contraseña forzado a usuario
Pasos:
  1. Admin cambia contraseña de empleado X a "TempPass123"
  2. Login como empleado X con nueva contraseña
  3. Verificar: acceso concedido

TEST A3: Crear usuario con email duplicado
Pasos:
  1. Crear usuario con email ya existente
  2. Esperado: error "Este correo ya está registrado" (no error 500)

TEST A4: Sistema mantiene al menos 1 admin activo
Pasos:
  1. Sistema con exactamente 1 admin activo
  2. Intentar desactivarlo
  3. Esperado: error "Debe existir al menos un Administrador activo"
```

### 8.3 Configuración del sistema

```
TEST C1: Cambio de nombre de empresa aparece en PDF
Pasos:
  1. Cambiar nombre_empresa a "Nueva Empresa S.A."
  2. Generar reporte PDF
  3. Verificar: header del PDF muestra "Nueva Empresa S.A."

TEST C2: Valor inválido en campo int
Pasos:
  1. Ingresar "abc" en campo stock_minimo_default
  2. Guardar
  3. Esperado: error de validación, valor no guardado

TEST C3: Caché de configuración se invalida tras cambio
Pasos:
  1. Cargar dashboard (config cacheada en sesión)
  2. Admin cambia moneda a "USD"
  3. Usuario recarga página
  4. Esperado: moneda muestra "USD" (caché invalidada)
```

---

## 9. Performance Targets — Dashboard

```
Métricas objetivo:
- Carga inicial de dashboard.php: < 800ms (incluye todos los KPIs)
- Máximo queries en dashboard: 8 (una por KPI/gráfica)
- Gráficas (Chart.js): render < 200ms
- Tabla de actividad reciente: LIMIT 10, < 100ms

Optimizaciones requeridas:
1. Agrupar queries de KPIs en stored procedure o CTE cuando BD soporte
2. Cache de KPIs en $_SESSION por 5 minutos (no refrescar en cada page load)
3. Gráficas cargan via AJAX (no bloquean renderizado inicial del HTML)
4. Paginación en tabla de actividad (no cargar todo el historial)

Cache de dashboard:
// Al inicio de dashboard.php:
$cache_key = 'dashboard_kpis_' . date('YmdHi'); // cambia cada minuto
if (!isset($_SESSION[$cache_key])) {
    $_SESSION[$cache_key] = calcularTodosLosKPIs($conn);
    // Limpiar keys anteriores
    foreach ($_SESSION as $k => $v) {
        if (str_starts_with($k, 'dashboard_kpis_') && $k !== $cache_key) {
            unset($_SESSION[$k]);
        }
    }
}
$kpis = $_SESSION[$cache_key];
```

---

## 10. Deuda Técnica — Dashboard y Admin

### Implementado (estado actual)

| Funcionalidad | Estado | Notas |
|--------------|--------|-------|
| Dashboard con KPIs básicos | ✅ Implementado | Sin caché de KPIs |
| Gráficas con Chart.js | ✅ Implementado | Carga síncrona (mejora pendiente) |
| Administrar usuarios CRUD | ✅ Implementado | Falta soft-delete consistente |
| Configuración del sistema | ✅ Implementado | Sin log de cambios |
| Perfil de usuario | ✅ Implementado | Sin upload de avatar |

### Pendiente de implementar

| Funcionalidad | Prioridad | Fase |
|--------------|-----------|------|
| Cache de KPIs en sesión | Alta | Fase 2 |
| Carga AJAX de gráficas | Media | Fase 2 |
| Log de cambios de configuración | Media | Fase 2 |
| Upload de avatar de perfil | Baja | Fase 3 |
| Bloqueo por intentos fallidos | Alta (seguridad) | Fase 2 |
| Health check endpoint | Media | Fase 2 |
| Exportar log de auditoría | Media | Fase 3 |
| Filtros avanzados en admin usuarios | Baja | Fase 3 |

---

---

## 11. Edge Cases y Manejo de Errores — Dashboard

### 11.1 Dashboard — Escenarios límite

| Escenario | Comportamiento esperado | Implementación |
|-----------|------------------------|----------------|
| BD sin datos (sistema nuevo) | KPIs muestran 0, gráficas muestran "Sin datos" | Verificar count antes de renderizar |
| Período sin ventas (semana sin actividad) | Gráfica muestra barra en 0, no error | Query devuelve 0 para ese período |
| Stock de todos los productos en 0 | Alerta crítica visible, KPI "Sin Stock" en rojo | Badge `text-error` + alert prominente |
| Más de 50 alertas de stock bajo | Tabla paginada o limitada a top 10 más críticos | ORDER BY (stock_actual/stock_minimo) ASC LIMIT 10 |
| Usuario sin permisos accede a /dashboard | Redirección a login.php si sin sesión, a acceso_denegado si rol incorrecto | Verificar en header.php |
| Timeout de BD al cargar dashboard | Mostrar estado de error parcial, no pantalla en blanco | try/catch en queries críticos |
| Session expirada mientras se mira dashboard | Al hacer cualquier AJAX → redirigir a login | Verificar $_SESSION en cada endpoint |

### 11.2 Admin Usuarios — Escenarios límite

| Escenario | Comportamiento esperado | Validación |
|-----------|------------------------|------------|
| Eliminar el único Administrador | Bloquear eliminación con mensaje claro | COUNT(Administradores) > 1 antes de DELETE |
| Editar propio rol (admin se degrada) | Advertencia + confirmación extra | `$_SESSION['user_id'] === $id_a_editar` |
| Email duplicado al crear usuario | Mensaje de error con campo resaltado | UNIQUE constraint en BD + verificación previa |
| Contraseña débil (menos de 8 chars) | Validación cliente + servidor | regex mínima: `/^.{8,}$/` |
| Crear usuario con Firebase ya existente | Manejar error de Firebase gracefully | try/catch en llamada a Firebase Auth |
| Desactivar usuario con sesión activa | Sesión persiste hasta que expire (no hay invalidación forzada) | Documentado como limitación conocida |
| Cambio de rol con sesión activa | Rol nuevo aplica en próximo login | Documentado como comportamiento esperado |

### 11.3 Configuración del Sistema — Edge Cases

| Escenario | Comportamiento esperado |
|-----------|------------------------|
| Guardar configuración vacía | Mantener valor anterior, no guardar NULL |
| Cambiar moneda con ventas existentes | Solo afecta nuevos registros (histórico no se recalcula) |
| Email SMTP incorrecto en config | Mostrar error de prueba de envío, no guardar |
| Valor numérico negativo en límites | Rechazar en validación servidor + mensaje claro |

---

## 12. Contratos de API — Dashboard y Admin

### 12.1 Endpoints del Dashboard

#### GET `get_dashboard_kpis.php`
```
Método: GET
Auth: Sesión válida (cualquier rol)
Parámetros: ninguno

Respuesta exitosa (200):
{
  "success": true,
  "kpis": {
    "total_productos": 45,
    "valor_inventario": 125000.00,
    "ventas_mes": 32,
    "ingresos_mes": 48500.00,
    "compras_mes": 8,
    "gasto_mes": 21000.00,
    "alertas_stock": 6,
    "productos_sin_stock": 2
  },
  "timestamp": "2026-05-04T04:55:18Z"
}

Error (401): {"error": "No autorizado"}
Error (500): {"error": "Error interno del servidor"}
```

#### GET `get_dashboard_graficas.php`
```
Método: GET
Auth: Sesión válida (cualquier rol)
Parámetros:
  - periodo: "mensual" | "semanal" (default: "mensual")
  - anio: int (default: año actual)

Respuesta exitosa (200):
{
  "success": true,
  "ventas_por_mes": [
    {"mes": "Ene", "total": 8500.00, "cantidad": 12},
    ...
  ],
  "stock_por_categoria": [
    {"categoria": "Viniles", "total_productos": 12, "valor_total": 45000.00},
    ...
  ],
  "top_productos": [
    {"nombre": "Vinil AC", "movimientos": 45, "porcentaje": 18.5},
    ...
  ]
}
```

### 12.2 Endpoints de Administración de Usuarios

#### POST `admin_api.php` — action: create_user
```
Método: POST
Auth: Sesión válida, rol Administrador
Body:
  action: "create_user"
  nombre: string (3-100 chars)
  email: string (formato email válido)
  password: string (min 8 chars)
  rol: "Administrador" | "Empleado" | "Usuario"

Respuesta exitosa (200):
{
  "success": true,
  "id_usuario": 15,
  "message": "Usuario creado exitosamente"
}

Error (400): {"error": "Email ya registrado"}
Error (400): {"error": "Contraseña debe tener mínimo 8 caracteres"}
Error (403): {"error": "Permisos insuficientes"}
```

#### POST `admin_api.php` — action: update_user
```
Método: POST
Auth: Sesión válida, rol Administrador
Body:
  action: "update_user"
  id_usuario: int
  nombre: string (opcional)
  email: string (opcional)
  rol: string (opcional)
  activo: 0|1 (opcional)

Respuesta exitosa (200):
{
  "success": true,
  "message": "Usuario actualizado"
}

Error (400): {"error": "No puedes desactivar el único administrador"}
Error (404): {"error": "Usuario no encontrado"}
```

#### POST `admin_api.php` — action: delete_user
```
Método: POST
Auth: Sesión válida, rol Administrador
Body:
  action: "delete_user"
  id_usuario: int

Respuesta exitosa (200):
{
  "success": true,
  "message": "Usuario eliminado"
}

Error (400): {"error": "No puedes eliminar el único administrador"}
Error (400): {"error": "No puedes eliminarte a ti mismo"}
Error (404): {"error": "Usuario no encontrado"}
```

### 12.3 Endpoints de Configuración del Sistema

#### POST `config_api.php` — action: save_config
```
Método: POST
Auth: Sesión válida, rol Administrador
Body:
  action: "save_config"
  nombre_empresa: string
  moneda: "MXN" | "USD" | "EUR" | "GTQ" | "HNL"
  timezone: string (ej: "America/Guatemala")
  items_por_pagina: int (10-100)
  stock_alerta_porcentaje: int (1-100)

Respuesta exitosa (200):
{
  "success": true,
  "message": "Configuración guardada"
}
```

---

## 13. Validaciones — Dashboard y Admin

### 13.1 Validaciones del lado del servidor (PHP)

```php
// ── Validar creación de usuario ──────────────────────────────────
function validarNuevoUsuario(array $data): array {
    $errores = [];

    $nombre = trim($data['nombre'] ?? '');
    if (strlen($nombre) < 3 || strlen($nombre) > 100) {
        $errores[] = 'Nombre debe tener entre 3 y 100 caracteres';
    }

    $email = trim($data['email'] ?? '');
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        $errores[] = 'Email inválido';
    }

    $password = $data['password'] ?? '';
    if (strlen($password) < 8) {
        $errores[] = 'Contraseña debe tener mínimo 8 caracteres';
    }

    $roles_validos = ['Administrador', 'Empleado', 'Usuario'];
    if (!in_array($data['rol'] ?? '', $roles_validos)) {
        $errores[] = 'Rol inválido';
    }

    return $errores;
}

// ── Validar configuración del sistema ────────────────────────────
function validarConfiguracion(array $data): array {
    $errores = [];

    $monedas = ['MXN', 'USD', 'EUR', 'GTQ', 'HNL'];
    if (!in_array($data['moneda'] ?? '', $monedas)) {
        $errores[] = 'Moneda no soportada';
    }

    $items = intval($data['items_por_pagina'] ?? 0);
    if ($items < 10 || $items > 100) {
        $errores[] = 'Items por página debe estar entre 10 y 100';
    }

    $alerta = intval($data['stock_alerta_porcentaje'] ?? 0);
    if ($alerta < 1 || $alerta > 100) {
        $errores[] = 'Porcentaje de alerta de stock debe estar entre 1 y 100';
    }

    return $errores;
}
```

### 13.2 Validaciones del lado del cliente (JavaScript)

```javascript
// Validación en tiempo real para formulario de usuario
document.getElementById('form-nuevo-usuario').addEventListener('submit', function(e) {
    const nombre = document.getElementById('nombre').value.trim();
    const email = document.getElementById('email').value.trim();
    const password = document.getElementById('password').value;
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    let errores = [];

    if (nombre.length < 3) errores.push('Nombre muy corto');
    if (!emailRegex.test(email)) errores.push('Email inválido');
    if (password.length < 8) errores.push('Contraseña muy corta');

    if (errores.length > 0) {
        e.preventDefault();
        mostrarErrores(errores);
    }
});
```

---

## 14. Testing Scenarios Adicionales — Admin y Config

### 14.1 Admin Usuarios — Casos de prueba extendidos

```markdown
CASO: Crear usuario con email duplicado
  Dado: Usuario con email "test@ejemplo.com" ya existe
  Cuando: Admin intenta crear otro con mismo email
  Entonces: HTTP 400, mensaje "Email ya registrado", BD sin cambios

CASO: Cambiar rol de Empleado a Administrador
  Dado: Usuario con rol Empleado id=5
  Cuando: Admin actualiza rol a "Administrador"
  Entonces: BD actualizada, próximo login del usuario tiene acceso completo

CASO: Desactivar usuario con sesiones activas
  Dado: Usuario id=7 tiene sesión activa en otro browser
  Cuando: Admin lo desactiva (activo=0)
  Entonces: BD marcada activo=0, sesión existente sigue hasta expirar (limitación conocida)

CASO: Eliminar único administrador
  Dado: Solo existe 1 usuario con rol Administrador
  Cuando: Admin intenta eliminarse a sí mismo
  Entonces: HTTP 400, mensaje "No puedes eliminar el único administrador"
```

### 14.2 Configuración del Sistema — Casos de prueba

```markdown
CASO: Cambiar moneda del sistema
  Dado: Sistema configurado con moneda MXN
  Cuando: Admin cambia a USD
  Entonces: Nuevas ventas muestran $USD, historial sigue mostrando valores originales

CASO: Reducir items por página de 20 a 10
  Dado: Usuario en página 3 de una lista con paginación de 20
  Cuando: Admin cambia a 10 items por página
  Entonces: Próxima carga de página comienza en página 1

CASO: Prueba de email SMTP
  Dado: Configuración SMTP con credenciales incorrectas
  Cuando: Admin presiona "Probar conexión"
  Entonces: Mensaje de error específico de SMTP, configuración NO se guarda
```

---

*Spec actualizada: 2026-05-04T04:55:18Z — Edge Cases, Contratos API completos, Validaciones PHP/JS, Testing scenarios extendidos. Total: 800+ líneas.*
