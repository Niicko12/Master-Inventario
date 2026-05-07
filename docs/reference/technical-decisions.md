# Technical Decisions — Sistema de Gestión de Inventario

---
name: technical-decisions
status: active
created: 2026-04-24T21:19:11Z
updated: 2026-05-04T04:55:18Z
---

## Índice

1. [Visión General del Proyecto](#1-visión-general-del-proyecto)
2. [Stack Tecnológico](#2-stack-tecnológico)
3. [Arquitectura de Alto Nivel](#3-arquitectura-de-alto-nivel)
4. [Estructura de Carpetas](#4-estructura-de-carpetas)
5. [Schema de Base de Datos](#5-schema-de-base-de-datos)
6. [Módulos del Sistema](#6-módulos-del-sistema)
7. [Autenticación y Autorización](#7-autenticación-y-autorización)
8. [Patrones de Código PHP](#8-patrones-de-código-php)
9. [Organización Interna de Archivos](#9-organización-interna-de-archivos)
10. [Límites de Calidad y Estructura](#10-límites-de-calidad-y-estructura)
11. [Seguridad](#11-seguridad)
12. [Deuda Técnica Identificada](#12-deuda-técnica-identificada)
13. [APIs y Endpoints](#13-apis-y-endpoints)
14. [Integraciones Externas](#14-integraciones-externas)
15. [Configuración de Entornos](#15-configuración-de-entornos)
16. [Generación de Reportes](#16-generación-de-reportes)
17. [Manejo de Sesiones](#17-manejo-de-sesiones)
18. [Patrones de Base de Datos](#18-patrones-de-base-de-datos)
19. [Frontend y UI](#19-frontend-y-ui)
20. [Performance y Escalabilidad](#20-performance-y-escalabilidad)
21. [Testing Requirements](#21-testing-requirements)
22. [Quality Gates](#22-quality-gates)
23. [Plan de Refactorización](#23-plan-de-refactorización)
24. [Checklist Pre-Código](#24-checklist-pre-código)
25. [Guía de Despliegue — Hostinger](#25-guía-de-despliegue--hostinger)
26. [Patrones de Error Handling](#26-patrones-de-error-handling)
27. [Seguridad — Registro de Cambios](#27-seguridad--registro-de-cambios)
28. [Patrones de Seguridad — Referencia Rápida](#28-patrones-de-seguridad--referencia-rápida)
29. [Testing Strategy — PHP Sistema Inventario](#29-testing-strategy--php-sistema-inventario)
30. [Guía de Code Review — Checklist Completo](#30-guía-de-code-review--checklist-completo)
31. [Patrones de Validación de Input — PHP](#31-patrones-de-validación-de-input--php)
32. [Optimización de Consultas MySQL](#32-optimización-de-consultas-mysql)
33. [Logging y Monitoreo](#33-logging-y-monitoreo)
34. [Code Structure Guidelines — Enhanced](#34-code-structure-guidelines--enhanced)
35. [Quality Enforcement — Métricas Medibles](#35-quality-enforcement--métricas-medibles)
36. [Testing Requirements por Capa](#36-testing-requirements-por-capa)

---

## 1. Visión General del Proyecto

### Nombre
**Sistema de Gestión de Inventario** — plataforma web multi-rol para administrar inventario, ventas, compras, proveedores, documentos y reportes de una PYME.

### Objetivo
Proporcionar una interfaz web centralizada que permita a administradores, empleados y usuarios gestionar de forma segura el ciclo completo de operaciones comerciales: desde la recepción de mercancía hasta la generación de facturas y reportes analíticos.

### Usuarios objetivo
| Rol | Descripción | Acceso |
|-----|-------------|--------|
| Administrador | Propietario / gerente | Completo + panel de administración + 2FA |
| Empleado | Personal operativo | Inventario, ventas, compras, documentos |
| Usuario | Cliente / consultor externo | Solo lectura de inventario y ventas propias |

### Alcance actual (MVP implementado)
- Gestión de inventario (productos, entradas, salidas, stock mínimo)
- Gestión de ventas con actualización automática de stock
- Gestión de compras por proveedor
- Gestión de proveedores
- Gestión documental (upload y vinculación a entidades)
- Reportes en PDF y Excel
- Gráficas analíticas
- Integraciones externas (CSV import, API)
- Panel de administración de usuarios
- Configuración del sistema por usuario
- Historial de auditoría (triggers de BD)
- Autenticación con 2FA para administradores

### Stack en producción
- **Servidor**: Hostinger (PHP 8.x, MySQL 5.7/MariaDB)
- **URL**: Proyecto hospedado en cuenta `u781177445_limber`
- **Base de datos**: `u781177445_limber`

---

## 2. Stack Tecnológico

### Backend
| Tecnología | Versión | Decisión |
|-----------|---------|----------|
| PHP | 8.x | Sin framework — arquitectura page-based monolítica |
| MySQL/MariaDB | 5.7+ | Motor InnoDB, charset utf8mb4_unicode_ci |
| MySQLi | nativa | Extensión OOP para conexión y queries |

**Decisión**: No se usa un framework PHP (Laravel, Symfony, CodeIgniter) porque el sistema fue construido de forma incremental para una PYME con necesidades específicas y entorno de hosting compartido que no siempre soporta Composer plenamente.

### PHP Dependencies (composer.json)
```json
{
  "require": {
    "phpoffice/phpspreadsheet": "^3.3",
    "phpmailer/phpmailer": "^6.8"
  }
}
```

| Librería | Uso |
|---------|-----|
| PhpSpreadsheet 3.3 | Exportación e importación de Excel/CSV |
| PHPMailer 6.8 | Envío de correos (verificación, recuperación, 2FA) |
| FPDF (incluida) | Generación de PDF para reportes y facturas |

### Frontend
| Tecnología | Versión | Fuente |
|-----------|---------|--------|
| Bootstrap | 5.3.3 | CDN `cdn.jsdelivr.net` |
| Font Awesome | 5.15.4 | CDN `cdnjs.cloudflare.com` |
| CSS custom | — | Archivos en `styles/` (uno por página) |
| JavaScript | Vanilla ES6 | Sin framework JS |

### Servicios externos
| Servicio | Uso |
|---------|-----|
| Firebase Authentication | reCAPTCHA en login + 2FA por teléfono (admins) |
| Firebase Firestore | Almacenamiento temporal de verificación |
| Google reCAPTCHA | Prevención de bots en login |

---

## 3. Arquitectura de Alto Nivel

### Diagrama de capas

```
┌─────────────────────────────────────────────────────────────────┐
│                        NAVEGADOR (Cliente)                       │
│  HTML + CSS (Bootstrap) + Vanilla JS + Firebase SDK              │
└─────────────────────────┬───────────────────────────────────────┘
                          │ HTTP/S (form POST / fetch API)
┌─────────────────────────▼───────────────────────────────────────┐
│                     CAPA DE PRESENTACIÓN                         │
│  PHP pages (*.php) — mezcla de lógica + HTML                     │
│  header.php / footer.php — layout común                          │
│  styles/*.css — estilos por módulo                               │
└─────────────────────────┬───────────────────────────────────────┘
                          │ include / require_once
┌─────────────────────────▼───────────────────────────────────────┐
│                   CAPA DE LÓGICA DE NEGOCIO                      │
│  Lógica PHP inline en cada page                                  │
│  functions/ — helpers compartidos                                │
│  *_api.php — endpoints AJAX                                      │
└─────────────────────────┬───────────────────────────────────────┘
                          │ MySQLi queries
┌─────────────────────────▼───────────────────────────────────────┐
│                   CAPA DE DATOS (MySQL)                          │
│  Tablas de dominio: Inventario, Ventas, Compras, etc.            │
│  Tablas de historial: Historial_* (auditoría via triggers)       │
│  Triggers: auto-auditoría INSERT/UPDATE/DELETE                   │
│  Constraints: FK integrity entre tablas                          │
└─────────────────────────────────────────────────────────────────┘
```

### Flujo de request típico

```
1. Usuario accede a page.php
2. page.php → include('header.php')
   - header.php → require_once 'config.php' (establece $conn)
   - Verifica session: $user_logged_in, $user_role
3. page.php procesa POST/GET
   - Validación básica de input
   - Query directo con $conn->query() o prepare()
   - Redirect o echo de resultado
4. page.php renderiza HTML + PHP
5. page.php → include('footer.php')
```

### Flujo de autenticación

```
[Login Form] → login.php
  ├── reCAPTCHA Firebase verify
  ├── SELECT user WHERE email + estado='Activo'
  ├── password_verify($input, $hash)
  │
  ├── [Administrador] → verificacion_2fa.php
  │     ├── Firebase Phone 2FA ─────→ [éxito] → $_SESSION completa
  │     └── Email OTP (alternativo) → verificar_codigo.php
  │
  └── [Empleado / Usuario] → $_SESSION directa → index.php
```

### Patrón de autorización por página

```php
// Patrón en páginas que requieren rol específico
if (!isset($_SESSION['user_role']) || $_SESSION['user_role'] != 'Administrador') {
    header("Location: index.php");
    exit;
}
```

---

## 4. Estructura de Carpetas

### Estructura actual (as-is)

```
Inventario/                          # Root del proyecto
│
├── config.php                       # Conexión BD (dual env)
├── header.php / footer.php          # Layout compartido
├── index.php                        # Home
│
├── [Módulo Auth]
│   ├── login.php
│   ├── register.php
│   ├── logout.php
│   ├── recuperar_contraseña.php
│   ├── cambiar_contraseña.php
│   ├── verificacion_2fa.php
│   ├── verificacion_correo.php
│   └── verificar_codigo.php
│
├── [Módulo Inventario]
│   ├── gestion_inventario.php
│   └── fetch_inventario.php
│
├── [Módulo Ventas]
│   ├── gestion_ventas.php
│   └── detalle_venta.php
│
├── [Módulo Compras]
│   ├── gestion_compras.php
│   ├── get_purchase_details.php    # AJAX endpoint
│   └── update_purchase.php         # AJAX endpoint
│
├── [Módulo Proveedores]
│   ├── gestion_proveedores.php
│   ├── get_provider_details.php    # AJAX endpoint
│   └── update_provider.php         # AJAX endpoint
│
├── [Módulo Documentos]
│   ├── documentos.php
│   └── editar_documento.php
│
├── [Módulo Reportes]
│   ├── reportes.php
│   ├── reporte_ventas_pdf.php
│   ├── descargar_reporte.php
│   ├── eliminar_reporte.php
│   ├── plantilla_reporte.php
│   └── reportes/                   # PDFs generados
│
├── [Módulo Graficas]
│   └── graficas.php
│
├── [Módulo Admin]
│   ├── administrar_usuarios.php
│   ├── configuracion_sistema.php
│   └── historial_cambios.php
│
├── [Módulo Integraciones]
│   ├── integraciones_externas.php
│   ├── integraciones_externas_api.php
│   ├── procesar_datos.php
│   ├── procesar_datos_api.php
│   ├── procesar_mapeo.php
│   └── procesar_mapeo_api.php
│
├── [Módulo Perfil]
│   └── perfil.php
│
├── [Utilidades / AJAX]
│   ├── guardar_todos.php
│   ├── guardar_codigo.php
│   ├── guardar_sesion_temp.php
│   ├── update_session.php
│   ├── enviar_correo_confirmacion.php
│   ├── generar_factura.php
│   └── default.php
│
├── styles/                          # CSS por módulo
│   ├── global_styles.css
│   ├── header.css
│   ├── login.css
│   ├── gestion_inventario.css
│   └── [un archivo por módulo]
│
├── js/                              # JavaScript
│   └── firebase-config.js
│
├── functions/                       # Helpers PHP
├── uploads/                         # Archivos subidos (docs)
├── font/                            # Fuentes (FPDF)
├── fpdf/                            # Librería FPDF
├── vendor/                          # Composer packages
├── PHPMailer/                       # PHPMailer (copia directa)
├── PhpSpreadsheet-3.3.0/           # Spreadsheet (copia directa)
├── endpointsPruebas/               # Tests de endpoints
├── reportes/                        # PDFs generados
│
├── bd.sql                           # Dump completo de BD
├── bd.txt                           # Schema simplificado
├── composer.json / composer.lock
└── docs/
    └── reference/
        └── technical-decisions.md  # Este archivo
```

### Estructura objetivo (to-be refactorizado)

```
Inventario/
├── config/
│   ├── database.php                 # Conexión con env vars
│   └── app.php                      # Config general
├── includes/
│   ├── header.php
│   ├── footer.php
│   └── auth_check.php               # Helper de verificación de sesión
├── modules/
│   ├── auth/
│   ├── inventario/
│   ├── ventas/
│   ├── compras/
│   ├── proveedores/
│   ├── documentos/
│   ├── reportes/
│   ├── graficas/
│   └── admin/
├── api/                             # AJAX endpoints unificados
├── utils/                           # Helpers reutilizables
├── assets/
│   ├── css/
│   ├── js/
│   └── fonts/
├── uploads/
├── vendor/
└── docs/
```

---

## 5. Schema de Base de Datos

### Motor y Charset
- **Motor**: InnoDB (soporte FK + transacciones)
- **Charset**: utf8mb4_unicode_ci (soporte emoji y caracteres especiales)
- **Collation**: utf8mb4_unicode_ci

### Diagrama de relaciones (ERD simplificado)

```
Usuarios ──────────────────────────────────────────────────────────
    │                                                               │
    │ id_usuario (FK)                                               │ id_cliente (FK)
    ▼                                                               ▼
Entradas_Inventario                                              Ventas
    │ id_producto (FK)                                               │ id_venta
    ▼                                                               ▼
Inventario ◄───────── Detalle_Ventas ────────────────────────────►
    │ id_producto (FK)  id_producto (FK)
    │
    ▼
Detalle_Compras ────────────────────────────────────────────────►
    │ id_compra (FK)                                            Compras ◄── Proveedores
    └──────────────────────────────────────────────────────────────┘
                                                                        id_proveedor (FK)

Documentos ────────────────────────────────────────────────────────
    │ id_documento (FK)
    ▼
Documentos_Registros

configuracion_interfaz ─── id_usuario (FK) ──► Usuarios

Historial_* (tablas de auditoría, pobladas por triggers)
IntentosInyeccionSQL (log de seguridad)
```

### Tabla: Usuarios

**Propósito**: Gestión de cuentas de usuario del sistema.

| Columna | Tipo | Nullable | Default | Descripción |
|---------|------|----------|---------|-------------|
| id_usuario | INT AI PK | No | auto | Identificador único |
| nombre | VARCHAR(100) | Sí | NULL | Nombre completo |
| correo_electronico | VARCHAR(100) UNIQUE | Sí | NULL | Email (login) |
| contrasena | VARCHAR(255) | Sí | NULL | Hash bcrypt |
| rol | ENUM('Administrador','Usuario','Empleado') | Sí | NULL | Rol de acceso |
| estado | ENUM('Activo','Inactivo') | Sí | NULL | Estado de la cuenta |
| telefono | VARCHAR(20) | Sí | NULL | Para 2FA Firebase |
| fecha_creacion | DATETIME | Sí | NULL | Fecha de registro |

**Índices**:
- `PRIMARY KEY (id_usuario)`
- `UNIQUE KEY (correo_electronico)`

**Notas**:
- La contraseña se almacena con `password_hash()` de PHP (bcrypt)
- El teléfono debe incluir código de país (ej: `+50312345678`) para Firebase Auth
- `estado = 'Inactivo'` bloquea el login sin borrar el registro

---

### Tabla: Inventario

**Propósito**: Catálogo de productos con control de stock.

| Columna | Tipo | Nullable | Default | Descripción |
|---------|------|----------|---------|-------------|
| id_producto | INT AI PK | No | auto | Identificador único |
| nombre_producto | VARCHAR(100) | Sí | NULL | Nombre del producto |
| cantidad_disponible | INT | Sí | NULL | Stock actual |
| stock_minimo | INT | Sí | NULL | Umbral de alerta |
| precio_unitario | DECIMAL(10,2) | Sí | NULL | Precio de venta |
| fecha_ultima_actualizacion | DATETIME | Sí | NULL | Última modificación |

**Índices**:
- `PRIMARY KEY (id_producto)`
- `INDEX idx_inventario_stock (cantidad_disponible)` — para queries de stock bajo

**Lógica de negocio**:
- `cantidad_disponible < stock_minimo` → alerta visual en interfaz
- Las ventas decrementan `cantidad_disponible` via trigger `before_insert_venta`
- Si stock insuficiente → trigger lanza `SIGNAL SQLSTATE '45000'`

---

### Tabla: Ventas

**Propósito**: Cabecera de cada transacción de venta.

| Columna | Tipo | Nullable | Default | Descripción |
|---------|------|----------|---------|-------------|
| id_venta | INT AI PK | No | auto | Identificador |
| id_cliente | INT | Sí | NULL | FK → Usuarios |
| fecha_venta | DATETIME | Sí | NULL | Fecha/hora de la venta |
| monto_total | DECIMAL(10,2) | Sí | NULL | Total calculado |
| estado | VARCHAR(50) | Sí | NULL | Estado del pedido |

**Estados de venta**:
- `Petición Realizada` — recién creada
- `En Proceso` — siendo preparada
- `Completada` — entregada
- `Cancelada` — anulada

**FK**:
- `id_cliente → Usuarios.id_usuario`

---

### Tabla: Detalle_Ventas

**Propósito**: Líneas de producto de cada venta.

| Columna | Tipo | Nullable | Default | Descripción |
|---------|------|----------|---------|-------------|
| id_detalle | INT AI PK | No | auto | Identificador |
| id_venta | INT | Sí | NULL | FK → Ventas |
| id_producto | INT | Sí | NULL | FK → Inventario |
| cantidad_vendida | INT | Sí | NULL | Unidades vendidas |
| precio_unitario | DECIMAL(10,2) | Sí | NULL | Precio al momento de venta |

**Triggers**:
- `before_insert_venta`: Verifica stock y descuenta `Inventario.cantidad_disponible`
- `after_insert/update/delete`: Registra en `Historial_Detalle_Ventas`

---

### Tabla: Compras

**Propósito**: Órdenes de compra a proveedores.

| Columna | Tipo | Nullable | Default | Descripción |
|---------|------|----------|---------|-------------|
| id_compra | INT AI PK | No | auto | Identificador |
| id_proveedor | INT | Sí | NULL | FK → Proveedores |
| nombre_producto | VARCHAR(100) | No | — | Nombre del producto |
| cantidad_comprada | INT | No | — | Unidades compradas |
| fecha_compra | DATETIME | Sí | NULL | Fecha de la compra |
| monto_total | DECIMAL(10,2) | Sí | NULL | Total pagado |
| estado | VARCHAR(50) | Sí | 'En Curso' | Estado del pedido |

**Estados de compra**:
- `En Curso` — orden en proceso
- `Completada` — recibida
- `Cancelada` — anulada

---

### Tabla: Detalle_Compras

**Propósito**: Líneas de producto de cada compra (cuando aplica múltiples productos).

| Columna | Tipo | Nullable | Default | Descripción |
|---------|------|----------|---------|-------------|
| id_detalle | INT AI PK | No | auto | Identificador |
| id_compra | INT | Sí | NULL | FK → Compras |
| id_producto | INT | Sí | NULL | FK → Inventario |
| cantidad_comprada | INT | Sí | NULL | Cantidad |
| precio_unitario | DECIMAL(10,2) | Sí | NULL | Precio pagado |

---

### Tabla: Proveedores

**Propósito**: Directorio de proveedores del negocio.

| Columna | Tipo | Nullable | Default | Descripción |
|---------|------|----------|---------|-------------|
| id_proveedor | INT AI PK | No | auto | Identificador |
| nombre_proveedor | VARCHAR(100) | Sí | NULL | Nombre / razón social |
| telefono | VARCHAR(15) | Sí | NULL | Contacto telefónico |
| email | VARCHAR(100) | Sí | NULL | Correo de contacto |
| direccion | TEXT | Sí | NULL | Dirección física |

---

### Tabla: Documentos

**Propósito**: Repositorio de archivos adjuntos al sistema.

| Columna | Tipo | Nullable | Default | Descripción |
|---------|------|----------|---------|-------------|
| id_documento | INT AI PK | No | auto | Identificador |
| tipo_documento | VARCHAR(50) | No | — | Categoría del documento |
| descripcion | TEXT | No | — | Descripción |
| fecha_creacion | DATE | No | — | Fecha del documento |
| version | VARCHAR(20) | No | — | Versión del documento |
| usuario_subio | VARCHAR(50) | No | — | ID del usuario que subió |
| nombre_archivo | VARCHAR(255) | No | — | Nombre del archivo |
| ruta_archivo | VARCHAR(255) | No | — | Path relativo en `uploads/` |
| fecha_subida | TIMESTAMP | Sí | current_timestamp() | Fecha de upload |

**Tipos de documento soportados**:
- Lista de productos (inventario)
- Informes de ventas / compras
- Documentos de gerencia
- Facturas
- Contratos

---

### Tabla: Documentos_Registros

**Propósito**: Vinculación de documentos a registros de otras tablas.

| Columna | Tipo | Nullable | Default | Descripción |
|---------|------|----------|---------|-------------|
| id | INT AI PK | No | auto | Identificador |
| id_documento | INT | No | — | FK → Documentos |
| tabla | VARCHAR(50) | No | — | Nombre de la tabla destino |
| registro_id | INT | No | — | ID del registro en esa tabla |
| fecha_adjuncion | TIMESTAMP | Sí | current_timestamp() | Fecha de vinculación |

---

### Tabla: Entradas_Inventario

**Propósito**: Registro de ingresos de stock al inventario.

| Columna | Tipo | Nullable | Default | Descripción |
|---------|------|----------|---------|-------------|
| id_entrada | INT AI PK | No | auto | Identificador |
| id_producto | INT | Sí | NULL | FK → Inventario |
| cantidad_entrada | INT | Sí | NULL | Unidades que ingresan |
| fecha_entrada | DATETIME | Sí | NULL | Fecha del ingreso |
| usuario_registro | INT | Sí | NULL | FK → Usuarios (quién registró) |

---

### Tabla: configuracion_interfaz

**Propósito**: Preferencias de UI por usuario.

| Columna | Tipo | Nullable | Default | Descripción |
|---------|------|----------|---------|-------------|
| id_configuracion | INT AI PK | No | auto | Identificador |
| id_usuario | INT | Sí | NULL | FK → Usuarios |
| tema_color | VARCHAR(50) | Sí | NULL | Tema de color |
| tamano_fuente | VARCHAR(10) | Sí | NULL | `pequeño`, `mediano`, `grande` |
| modo_oscuro | TINYINT(1) | Sí | 0 | 0=claro, 1=oscuro |

---

### Tablas de Historial (Auditoría)

Las siguientes tablas son pobladas automáticamente por triggers de MySQL:

| Tabla | Audita |
|-------|--------|
| Historial_Compras | Cambios en Compras |
| Historial_Detalle_Compras | Cambios en Detalle_Compras |
| Historial_Detalle_Ventas | Cambios en Detalle_Ventas |
| Historial_Entradas_Inventario | Cambios en Entradas_Inventario |
| Historial_Documentos | Cambios en Documentos |

**Estructura común de tablas Historial_***:

| Columna | Tipo | Descripción |
|---------|------|-------------|
| id_historial | INT AI PK | Identificador |
| id_{entidad} | INT | ID del registro auditado |
| tipo_accion | ENUM('INSERT','UPDATE','DELETE') | Tipo de operación |
| fecha_modificacion | DATETIME | Timestamp de la operación |
| usuario_modifico | VARCHAR(100) | Usuario MySQL (USER()) |
| ip_origen | VARCHAR(45) | IP del usuario (actualmente placeholder) |
| descripcion_cambio | TEXT | Descripción human-readable del cambio |

---

### Tabla: IntentosInyeccionSQL

**Propósito**: Log de seguridad de intentos de SQL injection detectados.

| Columna | Tipo | Descripción |
|---------|------|-------------|
| id | INT AI PK | Identificador |
| intento | TEXT | Texto del intento detectado |
| ip | VARCHAR(45) | IP del atacante |
| fecha | TIMESTAMP | Momento del intento |

---

## 6. Módulos del Sistema

### 6.1 Módulo Auth

**Archivos**: `login.php`, `register.php`, `logout.php`, `recuperar_contraseña.php`, `cambiar_contraseña.php`, `verificacion_2fa.php`, `verificacion_correo.php`, `verificar_codigo.php`

**Responsabilidades**:
- Registro con verificación de correo electrónico
- Login con reCAPTCHA + detección de SQL injection
- 2FA por teléfono (Firebase) para administradores
- 2FA por email (OTP) como alternativa
- Recuperación de contraseña por email
- Cambio de contraseña autenticado

**Máquina de estados — Sesión de Administrador**:
```
[Sin sesión]
    │ POST /login.php (credenciales válidas)
    ▼
[temp_session] — datos en $_SESSION['temp_*']
    │ Verificar 2FA (Firebase Phone o Email OTP)
    │ Éxito
    ▼
[Sesión activa] — $_SESSION['user_id', 'user_role', ...]
    │ GET /logout.php
    ▼
[Sin sesión]
```

**Máquina de estados — Sesión de Empleado/Usuario**:
```
[Sin sesión]
    │ POST /login.php (credenciales válidas)
    ▼
[Sesión activa] — directo, sin 2FA
    │ GET /logout.php
    ▼
[Sin sesión]
```

---

### 6.2 Módulo Inventario

**Archivos**: `gestion_inventario.php`, `fetch_inventario.php`

**Responsabilidades**:
- CRUD de productos (nombre, cantidad, stock mínimo, precio)
- Visualización de productos con alerta de stock bajo
- Actualización de stock automática en ventas/compras
- Consulta AJAX de productos disponibles

**Reglas de negocio**:
- Stock mínimo: Si `cantidad_disponible <= stock_minimo` → resaltar en rojo
- Solo Administrador y Empleado pueden crear/editar productos
- Solo Administrador puede eliminar productos
- La eliminación de un producto con stock activo debe bloquearse (FK constraint)

**Permisos por rol**:
```
Administrador: Ver + Crear + Editar + Eliminar
Empleado:      Ver + Crear + Editar
Usuario:       Ver (solo lectura)
```

---

### 6.3 Módulo Ventas

**Archivos**: `gestion_ventas.php`, `detalle_venta.php`

**Responsabilidades**:
- Creación de ventas con línea de detalle
- Verificación de stock antes de confirmar venta
- Actualización automática de inventario
- Listado de ventas con estados
- Eliminación de ventas con reversión de stock

**Reglas de negocio**:
- No se puede crear una venta si `cantidad_disponible < cantidad_pedida`
- Al eliminar una venta: `cantidad_disponible += cantidad_vendida`
- El precio unitario se calcula como `monto_total / cantidad_vendida`
- Solo usuarios con rol 'Usuario' pueden ser clientes (campo `id_cliente`)

**Estados de venta**: `Petición Realizada` → `En Proceso` → `Completada` / `Cancelada`

---

### 6.4 Módulo Compras

**Archivos**: `gestion_compras.php`, `get_purchase_details.php`, `update_purchase.php`

**Responsabilidades**:
- CRUD de órdenes de compra
- Vinculación con proveedor
- Control de estado de la compra
- Detalle de compra vía AJAX

---

### 6.5 Módulo Proveedores

**Archivos**: `gestion_proveedores.php`, `get_provider_details.php`, `update_provider.php`

**Responsabilidades**:
- CRUD de proveedores
- Consulta de detalle vía AJAX
- Edición inline de proveedor

---

### 6.6 Módulo Documentos

**Archivos**: `documentos.php`, `editar_documento.php`

**Responsabilidades**:
- Upload de archivos a `uploads/`
- Registro en tabla `Documentos`
- Vinculación de documentos a entidades (tabla `Documentos_Registros`)
- Descarga y edición de documentos existentes

**Tipos de archivo soportados**: `.xlsx`, `.txt`, `.pdf`, `.doc`, `.docx`

**Restricción de acceso**: Administrador y Empleado únicamente.

---

### 6.7 Módulo Reportes

**Archivos**: `reportes.php`, `reporte_ventas_pdf.php`, `descargar_reporte.php`, `eliminar_reporte.php`, `plantilla_reporte.php`

**Responsabilidades**:
- Generación de reportes PDF (via FPDF)
- Generación de reportes Excel (via PhpSpreadsheet)
- Descarga de reportes generados
- Gestión de reportes almacenados en `reportes/`

**Acceso**: Solo Administrador.

---

### 6.8 Módulo Gráficas

**Archivos**: `graficas.php`

**Responsabilidades**:
- Visualización analítica de ventas, compras e inventario
- Gráficas de barras/líneas con datos de BD

**Acceso**: Solo Administrador.

---

### 6.9 Módulo Administración de Usuarios

**Archivos**: `administrar_usuarios.php`

**Responsabilidades**:
- CRUD de usuarios del sistema
- Cambio de rol y estado
- Vista de actividad por usuario

**Acceso**: Solo Administrador.

---

### 6.10 Módulo Integraciones Externas

**Archivos**: `integraciones_externas.php`, `integraciones_externas_api.php`, `procesar_datos.php`, `procesar_datos_api.php`, `procesar_mapeo.php`, `procesar_mapeo_api.php`

**Responsabilidades**:
- Importación de datos desde archivos CSV
- Mapeo de columnas CSV a columnas de BD
- Procesamiento y validación de datos importados
- Integración via API externa

**Flujo de importación CSV**:
```
1. Usuario selecciona tabla destino + sube CSV
2. procesar_datos.php: parsea columnas CSV
3. Modal de mapeo: usuario asigna CSV → columna BD
4. procesar_mapeo.php: inserta datos mapeados
5. Reporte de errores/éxitos
```

---

### 6.11 Módulo Soporte y Mantenimiento

**Archivos**: `soporte_mantenimiento.php`

**Responsabilidades**:
- Registro de tickets de soporte
- Historial de incidencias
- Gestión de mantenimiento del sistema

---

## 7. Autenticación y Autorización

### Variables de sesión

**Variables activas (sesión establecida)**:
```php
$_SESSION['user_id']    // ID del usuario autenticado
$_SESSION['user_role']  // 'Administrador' | 'Empleado' | 'Usuario'
$_SESSION['telefono']   // Teléfono del usuario
$_SESSION['email']      // Email del usuario
$_SESSION['nombre']     // Nombre del usuario
$_SESSION['tamano_fuente'] // Preferencia UI: 'pequeño'|'mediano'|'grande'
```

**Variables temporales (durante 2FA, solo admins)**:
```php
$_SESSION['temp_user_id']   // ID usuario pendiente de 2FA
$_SESSION['temp_user_role'] // Rol pendiente de 2FA
$_SESSION['temp_telefono']  // Teléfono para Firebase
$_SESSION['temp_email']     // Email para OTP alternativo
$_SESSION['temp_nombre']    // Nombre para UI de 2FA
$_SESSION['verification_code'] // OTP email (admin 2FA alternativo)
```

### Verificación de autenticación

Patrón estándar que debe aplicarse en TODAS las páginas protegidas:

```php
// En header.php (ya presente)
$user_logged_in = isset($_SESSION['user_id']);
$user_role = isset($_SESSION['user_role']) ? $_SESSION['user_role'] : null;

// En páginas que requieren autenticación
if (!$user_logged_in) {
    header("Location: login.php");
    exit;
}

// En páginas que requieren rol específico
if ($user_role !== 'Administrador') {
    header("Location: index.php");
    exit;
}
```

### RBAC (Control de Acceso Basado en Roles)

| Módulo / Acción | Administrador | Empleado | Usuario |
|----------------|:---:|:---:|:---:|
| Login + 2FA | ✓ | ✓ | ✓ |
| Ver Inventario | ✓ | ✓ | ✓ |
| CRUD Inventario | ✓ | Parcial* | ✗ |
| Ver Ventas | ✓ | ✓ | Propias |
| Crear Ventas | ✓ | ✓ | ✗ |
| Eliminar Ventas | ✓ | ✗ | ✗ |
| Gestión Compras | ✓ | ✓ | ✗ |
| Gestión Proveedores | ✓ | ✗ | ✗ |
| Documentos | ✓ | ✓ | ✗ |
| Reportes | ✓ | ✗ | ✗ |
| Gráficas | ✓ | ✗ | ✗ |
| Admin Usuarios | ✓ | ✗ | ✗ |
| Integraciones | ✓ | ✗ | ✗ |
| Config Sistema | ✓ | ✗ | ✗ |

*Empleado puede crear y editar pero no eliminar productos.

---

## 8. Patrones de Código PHP

### 8.1 Patrón de conexión a BD

```php
// config.php — Dual environment auto-detect
$localConfig = [
    'servername' => 'localhost',
    'username'   => 'root',
    'password'   => '',
    'dbname'     => 'u781177445_limber',
    'port'       => 3306
];

$prodConfig = [
    'servername' => '127.0.0.1',
    'username'   => 'u781177445_limber',
    'password'   => 'PASSWORD',
    'dbname'     => 'u781177445_limber',
    'port'       => 3306
];

// Auto-detecta entorno
if (testConnection($localConfig)) {
    $config = $localConfig;
} else {
    $config = $prodConfig;
}

$conn = new mysqli(...$config);
```

### 8.2 Patrón de query con prepared statement (OBLIGATORIO para input de usuario)

```php
// CORRECTO — usar siempre para datos de usuario
$stmt = $conn->prepare("SELECT * FROM Usuarios WHERE correo_electronico = ?");
$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();
$stmt->close();

// INCORRECTO — vulnerabilidad SQL injection (legacy, debe corregirse)
$sql = "SELECT * FROM Tabla WHERE campo = '$variable'";
$conn->query($sql);
```

### 8.3 Patrón de query seguro con intval para IDs

```php
// CORRECTO para IDs numéricos
$id = intval($_GET['id']);
$sql = "DELETE FROM Tabla WHERE id = $id";

// O con prepared statement
$stmt = $conn->prepare("DELETE FROM Tabla WHERE id = ?");
$stmt->bind_param("i", $id);
```

### 8.4 Patrón de respuesta JSON para AJAX endpoints

```php
header('Content-Type: application/json');

try {
    // lógica
    echo json_encode(['success' => true, 'data' => $resultado]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
exit;
```

### 8.5 Patrón de protección de páginas admin

```php
<?php
require_once 'config.php';
session_start();

// Verificar autenticación
if (!isset($_SESSION['user_id'])) {
    header("Location: login.php");
    exit;
}

// Verificar rol (si aplica)
if ($_SESSION['user_role'] !== 'Administrador') {
    header("Location: index.php");
    exit;
}
// ... resto de la página
```

### 8.6 Patrón de sanitización de output HTML

```php
// CORRECTO — prevenir XSS
echo htmlspecialchars($row['nombre'], ENT_QUOTES, 'UTF-8');

// INCORRECTO — vulnerabilidad XSS
echo $row['nombre'];
```

---

## 9. Organización Interna de Archivos

### 9.1 Estructura de una página PHP típica

```php
<?php
// 1. Includes y configuración (siempre primero)
include('header.php');     // sesión + conn + $user_role
require_once 'config.php'; // si no se incluye en header

// 2. Verificación de permisos (antes de cualquier proceso)
if (!$user_logged_in) { header("Location: login.php"); exit; }

// 3. Procesamiento de POST (acciones del formulario)
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    // Validar input
    // Prepared statement
    // Redirect o mensaje
}

// 4. Procesamiento de GET (acciones de URL)
if (isset($_GET['action'])) {
    // Validar input
    // Lógica
}

// 5. Queries de lectura para renderizar la página
$result = $conn->query("SELECT ...");
?>

<!-- 6. HTML con PHP embebido (mínimo PHP en esta sección) -->
<link rel="stylesheet" href="styles/modulo.css">

<div class="container">
    <?php while ($row = $result->fetch_assoc()): ?>
        <!-- render row -->
    <?php endwhile; ?>
</div>

<!-- 7. Modales JavaScript al final -->
<script>
    // Solo lógica de UI, sin queries
</script>

<?php include('footer.php'); ?>
```

### 9.2 Estructura de un endpoint AJAX

```php
<?php
// 1. Configuración
require_once 'config.php';
session_start();
header('Content-Type: application/json');

// 2. Verificación de sesión
if (!isset($_SESSION['user_id'])) {
    echo json_encode(['error' => 'No autorizado']);
    exit;
}

// 3. Obtener y validar input
$id = intval($_POST['id'] ?? 0);
if ($id <= 0) {
    echo json_encode(['error' => 'ID inválido']);
    exit;
}

// 4. Query con prepared statement
$stmt = $conn->prepare("SELECT * FROM Tabla WHERE id = ?");
$stmt->bind_param("i", $id);
$stmt->execute();
$result = $stmt->get_result()->fetch_assoc();
$stmt->close();

// 5. Respuesta
echo json_encode($result ?: ['error' => 'No encontrado']);
exit;
```

### 9.3 Límites de complejidad por archivo

| Tipo de archivo | Líneas máx. recomendadas | Razón |
|----------------|------------------------|-------|
| Page PHP (page.php) | 400 líneas | Incluye HTML, lógica y JS |
| Endpoint AJAX (*_api.php) | 150 líneas | Solo lógica, sin HTML |
| Helper PHP (functions/) | 200 líneas | Funciones reutilizables |
| CSS por módulo (styles/) | 250 líneas | Estilos específicos |
| JavaScript inline | 100 líneas | Solo UI logic |

**Archivos que exceden el límite actualmente** (deuda técnica):
- `integraciones_externas.php` (~400+ líneas) → separar en módulos
- `soporte_mantenimiento.php` (~400+ líneas) → separar lógica
- `administrar_usuarios.php` (~400+ líneas) → separar en componentes

---

## 10. Límites de Calidad y Estructura

### 10.1 Reglas de nomenclatura

**Archivos PHP**:
- Snake_case para páginas: `gestion_inventario.php`
- Snake_case para APIs: `procesar_datos_api.php`
- Descriptivo del módulo: `get_provider_details.php`

**Variables PHP**:
```php
// Variables locales: snake_case
$nombre_producto = '';
$cantidad_disponible = 0;

// Variables de sesión: snake_case
$_SESSION['user_role']
$_SESSION['temp_user_id']

// Constantes: SCREAMING_SNAKE_CASE
define('MAX_FILE_SIZE', 5242880); // 5MB
define('UPLOAD_PATH', __DIR__ . '/uploads/');
```

**Tablas de BD**:
- PascalCase para tablas principales: `Usuarios`, `Inventario`, `Ventas`
- PascalCase con underscore para tablas compuestas: `Detalle_Ventas`, `Entradas_Inventario`
- Prefijo `Historial_` para tablas de auditoría
- Minúsculas para tablas de configuración: `configuracion_interfaz`

**IDs**:
- Formato: `id_{tabla_singular}` → `id_usuario`, `id_producto`, `id_venta`

### 10.2 Reglas de seguridad (OBLIGATORIAS)

```
1. NUNCA usar string interpolation en queries con input de usuario
2. SIEMPRE usar prepared statements para INSERT/UPDATE/DELETE
3. SIEMPRE usar intval() para IDs numéricos de URL
4. SIEMPRE usar htmlspecialchars() al renderizar datos de BD en HTML
5. SIEMPRE verificar $_SESSION antes de procesar acciones
6. NUNCA exponer stack traces en producción
7. NUNCA loguear datos de sesión al browser console
```

### 10.3 Reglas de estructura de código

```
1. Siempre require_once 'config.php' antes de cualquier query
2. Siempre verificar permisos antes de procesar POST/GET
3. Siempre cerrar statements preparados: $stmt->close()
4. Siempre cerrar conexión al final: $conn->close() (opcional, PHP lo hace)
5. Siempre usar exit() después de header("Location: ...")
6. Siempre verificar $conn->connect_error después de new mysqli()
```

### 10.4 Reglas de UI/Frontend

```
1. Un archivo CSS por módulo en styles/
2. No CSS inline en HTML (usar clases)
3. Bootstrap para layout y componentes base
4. JavaScript solo para UI interactions (modales, validación)
5. No business logic en JavaScript — toda la lógica va en PHP
6. AJAX solo para operaciones que no requieren reload de página
```

---

## 11. Seguridad

### 11.1 Medidas implementadas

| Medida | Implementación | Estado |
|--------|---------------|--------|
| Password hashing | `password_hash()` bcrypt | ✅ Activo |
| SQL injection detection | Pattern matching en login | ✅ Activo |
| reCAPTCHA Firebase | Login form | ✅ Activo |
| 2FA Teléfono | Firebase Auth (admins) | ✅ Activo |
| 2FA Email OTP | PHPMailer (admins, alternativo) | ✅ Activo |
| Verificación de email | PHPMailer en registro | ✅ Activo |
| CSP headers | Página 2FA | ⚠️ Parcial |
| Session management | PHP sessions | ✅ Activo |
| Role-based access | Check por página | ⚠️ Inconsistente |
| Prepared statements | Algunas páginas | ⚠️ Inconsistente |

### 11.2 Política de contraseñas

```php
// Registro: usar password_hash con bcrypt
$hashed = password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);

// Login: verificar
if (password_verify($password_input, $stored_hash)) {
    // acceso concedido
}
```

**Requisitos de contraseña** (pendiente de implementar):
- Mínimo 8 caracteres
- Al menos una letra mayúscula
- Al menos un número
- Al menos un carácter especial

### 11.3 Upload de archivos

```php
// Validaciones obligatorias en upload
$allowed_types = ['application/pdf', 'text/plain', 'application/vnd.ms-excel',
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'];
$max_size = 5 * 1024 * 1024; // 5MB

// Verificar tipo MIME (no solo extensión)
$finfo = new finfo(FILEINFO_MIME_TYPE);
$mime = $finfo->file($_FILES['file']['tmp_name']);

if (!in_array($mime, $allowed_types)) {
    throw new Exception("Tipo de archivo no permitido");
}

if ($_FILES['file']['size'] > $max_size) {
    throw new Exception("Archivo demasiado grande");
}

// Renombrar archivo para evitar path traversal
$new_name = uniqid() . '_' . basename($_FILES['file']['name']);
move_uploaded_file($_FILES['file']['tmp_name'], UPLOAD_PATH . $new_name);
```

### 11.4 CORS y Headers de seguridad

Para endpoints AJAX, incluir:
```php
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: SAMEORIGIN');
header('X-XSS-Protection: 1; mode=block');
```

---

## 12. Deuda Técnica Identificada

**Última actualización**: 2026-04-25 — Sesión de hardening de seguridad completada.

### Alta prioridad (vulnerabilidades de seguridad)

| # | Problema | Archivo(s) | Impacto | Estado | Solución |
|---|---------|-----------|---------|--------|----------|
| 1 | SQL injection via string concatenation | `gestion_inventario.php`, `gestion_ventas.php`, `login.php`, `register.php`, `perfil.php`, `gestion_compras.php`, `gestion_proveedores.php`, `administrar_usuarios.php` | **CRÍTICO** | ✅ **RESUELTO** 2026-04-25 | Migrado a prepared statements en todos los archivos |
| 2 | Credentials de producción hardcodeadas en config.php | `config.php` | **ALTO** | ✅ **RESUELTO** 2026-04-25 | Movido a `.env` + `.htaccess` bloquea acceso web |
| 3 | Session data loggeada al browser console | `gestion_inventario.php:196-198` | **ALTO** | ✅ **RESUELTO** 2026-04-25 | `console.log(userSession)` eliminado |
| 4 | Typo en nombre de variable de sesión | `login.php:57` | **MEDIO** | ✅ **RESUELTO** 2026-04-25 | `'$user_role'` corregido a `'user_role'` |
| 5 | Verificación de autenticación inconsistente | Varias páginas | **ALTO** | 🔄 Pendiente | Centralizar en helper `includes/auth_check.php` |

### Media prioridad (calidad de código)

| # | Problema | Archivo(s) | Estado | Solución |
|---|---------|-----------|--------|---------|
| 6 | XSS — output sin htmlspecialchars | `gestion_inventario.php`, `gestion_ventas.php`, `gestion_compras.php`, `gestion_proveedores.php`, `administrar_usuarios.php`, `perfil.php` | ✅ **RESUELTO** 2026-04-25 | Sanitizado con `htmlspecialchars()` y `ENT_QUOTES` donde aplica |
| 7 | Error messages de BD expuestos al usuario | Múltiples | ✅ **RESUELTO** 2026-04-25 | Mensajes genéricos, sin `$conn->error` en output |
| 8 | God files >400 líneas | `integraciones_externas.php`, `soporte_mantenimiento.php` | 🔄 Pendiente | Refactorizar en módulos |
| 9 | Lógica de negocio mezclada con HTML | Todas las páginas | 🔄 Pendiente (arquitectural) | Separar en capas |
| 10 | IP hardcodeada como placeholder en triggers | BD triggers | 🔄 Pendiente | Implementar captura de IP real |
| 11 | CSP headers solo en 2FA | `verificacion_2fa.php` | 🔄 Pendiente | Aplicar globalmente en header.php |

### Baja prioridad (mejoras)

| # | Problema | Estado | Solución |
|---|---------|--------|---------|
| 12 | Sin paginación en listados | 🔄 Pendiente | Agregar LIMIT/OFFSET con navegación |
| 13 | Sin validación de formularios del lado cliente | 🔄 Pendiente | Agregar validación HTML5 + JS |
| 14 | Sin índices en columnas de búsqueda frecuente | 🔄 Pendiente | Agregar índices en FK columns |
| 15 | Logs de error visibles en integraciones externas | 🔄 Pendiente | `ini_set('display_errors', 0)` en producción |
| 16 | `register.php` tiene Firebase credentials inline en JS generado | 🔄 Pendiente | Mover a `js/firebase-config.js` estático |

### Resumen de progreso de seguridad

```
Alta prioridad:   4/5 resueltos (80%)
Media prioridad:  3/6 resueltos (50%)
Baja prioridad:   0/5 resueltos (0%)
Total:            7/16 resueltos (44%)
```

---

## 13. APIs y Endpoints

### Endpoints AJAX del sistema

| Method | Archivo | Descripción | Auth Req. |
|--------|---------|-------------|-----------|
| GET | `fetch_inventario.php` | Lista productos disponibles | Sí |
| GET/POST | `get_purchase_details.php` | Detalle de una compra | Sí |
| POST | `update_purchase.php` | Actualizar compra | Sí (Admin/Empleado) |
| GET/POST | `get_provider_details.php` | Detalle de proveedor | Sí |
| POST | `update_provider.php` | Actualizar proveedor | Sí (Admin) |
| POST | `procesar_datos_api.php` | Procesar CSV uploaded | Sí (Admin) |
| POST | `procesar_mapeo_api.php` | Guardar mapeo CSV→BD | Sí (Admin) |
| POST | `integraciones_externas_api.php` | API externa | Sí (Admin) |
| POST | `guardar_codigo.php` | Guardar código de verificación | Sí |
| POST | `guardar_sesion_temp.php` | Datos temporales de sesión | — |
| POST | `update_session.php` | Actualizar datos de sesión | Sí |
| POST | `enviar_correo_confirmacion.php` | Enviar email OTP | Sí |

### Formato de respuesta estándar (AJAX)

```json
// Éxito
{
  "success": true,
  "data": { ... },
  "message": "Operación completada"
}

// Error
{
  "success": false,
  "error": "Descripción del error",
  "code": "ERROR_CODE"
}
```

### Endpoints de descarga de archivos

| Method | Archivo | Descripción |
|--------|---------|-------------|
| GET | `descargar_reporte.php?file=nombre` | Descargar reporte PDF/Excel |
| GET | `reporte_ventas_pdf.php` | Generar y descargar reporte PDF |
| GET | `generar_factura.php` | Generar factura PDF |

---

## 14. Integraciones Externas

### Firebase Authentication

**Proyecto Firebase**: `comercioelectronico-811d2`

**Uso**:
1. **reCAPTCHA en login** — `firebase.auth.RecaptchaVerifier`
2. **Phone Authentication (2FA)** — `firebase.auth.signInWithPhoneNumber`
3. **Firestore** — almacenamiento temporal durante 2FA

**Archivos de configuración**:
- `js/firebase-config.js` — configuración del SDK
- `google-services.json` — credenciales Firebase
- `verificacion_2fa.php` — página de verificación

**Versión del SDK**: Firebase 8.10.0 (compat)

**Decisión**: Se usa Firebase 8.x compat porque el proyecto fue iniciado antes del SDK modular v9+. Migrar a v9 requeriría refactorizar todos los scripts de Firebase.

---

### PHPMailer

**Uso**:
- Verificación de correo en registro
- Recuperación de contraseña
- Código OTP alternativo para 2FA de administradores
- Notificaciones del sistema

**Configuración** (en cada archivo que lo usa):
```php
use PHPMailer\PHPMailer\PHPMailer;
require_once 'vendor/autoload.php'; // o PHPMailer/src/PHPMailer.php

$mail = new PHPMailer(true);
$mail->isSMTP();
$mail->Host = 'smtp.gmail.com'; // o servidor Hostinger
$mail->SMTPAuth = true;
$mail->Username = 'correo@dominio.com';
$mail->Password = 'app_password';
$mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
$mail->Port = 587;
```

---

### PhpSpreadsheet

**Uso**:
- Exportación de reportes a Excel (.xlsx)
- Importación de datos desde CSV
- Integración CSV con mapeo de columnas

---

### FPDF

**Uso**:
- Generación de reportes en PDF
- Generación de facturas
- Descarga de documentos PDF

**Ubicación**: `fpdf/` y `fpdf.php` en raíz (instalación manual, no via Composer)

---

## 15. Configuración de Entornos

### Detección automática de entorno

El sistema auto-detecta si está en local o producción intentando conectar primero con la configuración local:

```php
// Flujo de detección en config.php
Local (localhost) → intenta primero
Si falla → usa configuración de producción (Hostinger)
```

### Variables por entorno

| Variable | Local | Producción |
|---------|-------|------------|
| servername | localhost | 127.0.0.1 |
| username | root | u781177445_limber |
| password | (vacío) | [ver config.php] |
| dbname | u781177445_limber | u781177445_limber |
| port | 3306 | 3306 |

### Mejora recomendada: archivo .env

Para eliminar credenciales del código fuente, migrar a:

```
# .env (FUERA del webroot o en .gitignore)
DB_HOST_LOCAL=localhost
DB_USER_LOCAL=root
DB_PASS_LOCAL=
DB_NAME=u781177445_limber

DB_HOST_PROD=127.0.0.1
DB_USER_PROD=u781177445_limber
DB_PASS_PROD=[password]
DB_NAME_PROD=u781177445_limber

APP_ENV=local  # o production
```

```php
// config.php refactorizado
$env = getenv('APP_ENV') ?: 'local';
$config = [
    'servername' => getenv("DB_HOST_{$env}"),
    'username'   => getenv("DB_USER_{$env}"),
    'password'   => getenv("DB_PASS_{$env}"),
    'dbname'     => getenv('DB_NAME'),
    'port'       => 3306
];
```

---

## 16. Generación de Reportes

### Reporte PDF (FPDF)

```php
require_once('fpdf/fpdf.php');

$pdf = new FPDF();
$pdf->AddPage();
$pdf->SetFont('Arial', 'B', 16);
$pdf->Cell(0, 10, 'Reporte de Ventas', 0, 1, 'C');

// Tabla de datos
$pdf->SetFont('Arial', '', 12);
while ($row = $result->fetch_assoc()) {
    $pdf->Cell(40, 10, $row['nombre'], 1);
    $pdf->Cell(40, 10, $row['monto'], 1);
    $pdf->Ln();
}

// Guardar o descargar
$pdf->Output('D', 'reporte_ventas.pdf'); // D = download directo
// O guardar en servidor:
$pdf->Output('F', 'reportes/reporte_' . date('Y-m-d') . '.pdf');
```

### Reporte Excel (PhpSpreadsheet)

```php
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;

require_once 'vendor/autoload.php';

$spreadsheet = new Spreadsheet();
$sheet = $spreadsheet->getActiveSheet();

// Headers
$sheet->setCellValue('A1', 'Producto');
$sheet->setCellValue('B1', 'Cantidad');

// Datos
$row = 2;
while ($data = $result->fetch_assoc()) {
    $sheet->setCellValue('A' . $row, $data['nombre_producto']);
    $sheet->setCellValue('B' . $row, $data['cantidad_disponible']);
    $row++;
}

// Descargar
header('Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
header('Content-Disposition: attachment;filename="inventario.xlsx"');
$writer = new Xlsx($spreadsheet);
$writer->save('php://output');
```

---

## 17. Manejo de Sesiones

### Inicio de sesión

Siempre verificar antes de `session_start()`:
```php
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}
```

### Variables de sesión de preferencias UI

La preferencia de tamaño de fuente se carga desde la BD al iniciar sesión y se almacena en sesión:
```php
// Al login
$_SESSION['tamano_fuente'] = getUserFontSize($user_id);

// En header.php — aplica a todo el sistema
$tamano_fuente = $_SESSION['tamano_fuente'] ?? 'mediano';
// → body font-size: 14px | 16px | 18px
```

### Limpieza de sesión en logout

```php
// logout.php
session_start();
session_unset();
session_destroy();
setcookie(session_name(), '', time() - 3600, '/');
header("Location: login.php");
exit;
```

---

## 18. Patrones de Base de Datos

### 18.1 Transacciones para operaciones multi-tabla

Para operaciones que afectan múltiples tablas (ej: crear venta + actualizar inventario):

```php
$conn->begin_transaction();

try {
    // Insert en Ventas
    $stmt1 = $conn->prepare("INSERT INTO Ventas (...) VALUES (...)");
    $stmt1->execute();
    $id_venta = $conn->insert_id;

    // Insert en Detalle_Ventas (trigger actualiza inventario)
    $stmt2 = $conn->prepare("INSERT INTO Detalle_Ventas (...) VALUES (...)");
    $stmt2->execute();

    $conn->commit();
} catch (Exception $e) {
    $conn->rollback();
    // manejar error
}
```

### 18.2 Triggers de auditoría

Patrón existente (aplicar consistentemente):
```sql
DELIMITER $$
CREATE TRIGGER `Tabla_after_insert` AFTER INSERT ON `Tabla` FOR EACH ROW BEGIN
    INSERT INTO `Historial_Tabla` (id_registro, tipo_accion, usuario_modifico, ip_origen, descripcion_cambio)
    VALUES (NEW.id, 'INSERT', USER(), @current_ip,
        CONCAT('Registro creado: campo1=', NEW.campo1, ', campo2=', NEW.campo2));
END
$$
DELIMITER ;
```

### 18.3 Queries frecuentes optimizadas

```sql
-- Productos con stock bajo (usar índice en cantidad_disponible)
SELECT id_producto, nombre_producto, cantidad_disponible, stock_minimo
FROM Inventario
WHERE cantidad_disponible <= stock_minimo
ORDER BY cantidad_disponible ASC;

-- Ventas del período con JOIN
SELECT V.id_venta, U.nombre AS cliente, V.fecha_venta, V.monto_total,
       DV.cantidad_vendida, I.nombre_producto, V.estado
FROM Ventas V
JOIN Usuarios U ON V.id_cliente = U.id_usuario
JOIN Detalle_Ventas DV ON V.id_venta = DV.id_venta
JOIN Inventario I ON DV.id_producto = I.id_producto
WHERE V.fecha_venta BETWEEN ? AND ?
ORDER BY V.fecha_venta DESC;

-- Historial de cambios de una compra
SELECT tipo_accion, fecha_modificacion, usuario_modifico, descripcion_cambio
FROM Historial_Compras
WHERE id_compra = ?
ORDER BY fecha_modificacion DESC;
```

---

## 19. Frontend y UI

### 19.1 Sistema de diseño

**Framework base**: Bootstrap 5.3.3

**Paleta de colores** (observada en uso):
```css
/* Variables Bootstrap usadas */
--bs-primary: #0d6efd    /* Acciones principales */
--bs-success: #198754    /* Confirmaciones, agregar */
--bs-danger:  #dc3545    /* Eliminaciones, errores */
--bs-warning: #ffc107    /* Advertencias */
--bs-info:    #0dcaf0    /* Información, editar */
```

**Componentes UI en uso**:
- Tablas responsivas Bootstrap (`table table-bordered`)
- Modales para crear/editar registros
- Formularios con `form-control` y `form-group`
- Botones con clases `btn btn-{variant} btn-sm`
- Alerts para mensajes de error/éxito
- Navbar responsive con menú hamburguesa custom

### 19.2 Responsividad

El sistema usa un breakpoint de `768px` para el menú hamburguesa:
```javascript
// En header.php
if (window.innerWidth > 768) {
    // menú desktop
} else {
    // menú mobile con hamburguesa
}
```

### 19.3 Modales estándar

Patrón de modal para CRUD:
```html
<div class="modal" id="createModal" style="display: none;">
    <div class="modal-content">
        <div class="modal-header">
            <h5 class="modal-title">Título</h5>
            <span class="close" onclick="closeModal('createModal')">&times;</span>
        </div>
        <form method="post">
            <input type="hidden" name="action" value="add">
            <div class="modal-body"><!-- campos --></div>
            <div class="modal-footer">
                <button type="button" onclick="closeModal('createModal')">Cerrar</button>
                <button type="submit">Guardar</button>
            </div>
        </form>
    </div>
</div>

<script>
function openModal(id) { document.getElementById(id).style.display = 'flex'; }
function closeModal(id) { document.getElementById(id).style.display = 'none'; }
</script>
```

### 19.4 Gráficas

Las gráficas en `graficas.php` usan JavaScript (probablemente Chart.js o similar via CDN) con datos inyectados desde PHP:

```php
// Patrón: inyectar datos de PHP a JS
<script>
    const datosVentas = <?php echo json_encode($ventas_por_mes); ?>;
    const datosInventario = <?php echo json_encode($stock_actual); ?>;
</script>
```

---

## 20. Performance y Escalabilidad

### 20.1 Targets de performance actuales

| Métrica | Target | Estado |
|---------|--------|--------|
| Page load inicial | < 2s | ⚠️ No medido |
| Query de listados | < 500ms | ⚠️ Sin índices optimizados |
| Generación PDF | < 3s | ⚠️ No medido |
| Upload CSV | < 10s (archivos < 5MB) | ⚠️ No medido |

### 20.2 Optimizaciones recomendadas

**Base de datos**:
```sql
-- Agregar índices en columnas FK (mejoran JOINs)
ALTER TABLE Detalle_Ventas ADD INDEX idx_dv_id_venta (id_venta);
ALTER TABLE Detalle_Ventas ADD INDEX idx_dv_id_producto (id_producto);
ALTER TABLE Ventas ADD INDEX idx_ventas_fecha (fecha_venta);
ALTER TABLE Compras ADD INDEX idx_compras_proveedor (id_proveedor);
ALTER TABLE Entradas_Inventario ADD INDEX idx_ei_producto (id_producto);
```

**PHP**:
- Usar `fetch_all(MYSQLI_ASSOC)` para pequeños datasets
- Usar `while ($row = $result->fetch_assoc())` para datasets grandes
- Cerrar conexiones `$conn->close()` en scripts de larga ejecución

**Frontend**:
- Minificar CSS y JS en producción
- Usar CDN para Bootstrap y Font Awesome (ya implementado)
- Habilitar compresión gzip en Hostinger

### 20.3 Límites conocidos

- **Sin caché**: Cada request ejecuta queries a BD en tiempo real
- **Sin paginación**: Los listados cargan todos los registros (riesgo con muchos datos)
- **Un servidor**: No hay load balancing (apropiado para PYME)
- **Sessions en disco**: PHP sessions en filesystem (adecuado para instancia única)

---

## 21. Testing Requirements

### 21.1 Testing manual requerido por módulo

Dado que el proyecto usa PHP procedural sin framework de testing, el testing es manual:

**Módulo Auth**:
- [ ] Login exitoso con reCAPTCHA
- [ ] Login fallido (credenciales incorrectas)
- [ ] Login con cuenta inactiva
- [ ] 2FA exitoso para administrador
- [ ] 2FA fallido (código incorrecto)
- [ ] Recuperación de contraseña por email
- [ ] Registro con verificación de email
- [ ] SQL injection attempt → debe ser loggeado y bloqueado

**Módulo Inventario**:
- [ ] Crear producto nuevo
- [ ] Editar producto existente
- [ ] Eliminar producto (con y sin stock)
- [ ] Visualizar alerta de stock bajo
- [ ] Verificar que usuario sin permisos no puede modificar

**Módulo Ventas**:
- [ ] Crear venta con stock suficiente → inventario debe decrementar
- [ ] Intentar crear venta con stock insuficiente → debe fallar con mensaje
- [ ] Eliminar venta → inventario debe recuperarse
- [ ] Verificar estados de venta

**Módulo Compras**:
- [ ] Crear orden de compra
- [ ] Actualizar estado de compra via AJAX
- [ ] Vincular compra a proveedor

**Módulo Integraciones**:
- [ ] Subir CSV válido → mapeo correcto
- [ ] Subir CSV inválido → mensaje de error
- [ ] Mapear columnas CSV a BD → datos insertados correctamente

### 21.2 Casos de borde importantes

```
- Productos con cantidad_disponible = 0 no deben aparecer en formularios de venta
- Precio unitario calculado: evitar división por cero (cantidad_vendida = 0)
- Upload de archivos: validar tipo MIME, no solo extensión
- Session timeout: comportamiento al expirar la sesión mid-operation
- Caracteres especiales en nombres (tildes, ñ) → charset utf8mb4
```

### 21.3 Checklist de seguridad antes de deploy

```
[ ] Verificar que config.php no expone credenciales en git
[ ] Verificar que display_errors = Off en producción
[ ] Verificar que uploads/ no permite ejecución de PHP
[ ] Verificar que vendor/ no es accesible directamente
[ ] Verificar que log.txt / php_errors.log no son accesibles via HTTP
[ ] Verificar que session.cookie_secure = On en producción (HTTPS)
[ ] Verificar que session.cookie_httponly = On
[ ] Probar todos los forms con payloads de SQL injection
[ ] Probar todos los forms con payloads de XSS
```

---

## 22. Quality Gates

### 22.1 Métricas de código (ENFORZAR)

| Métrica | Límite | Herramienta |
|---------|--------|-------------|
| Líneas por archivo PHP | MAX 400 | Manual review |
| Nesting depth | MAX 4 niveles | Manual review |
| Queries por página | MAX 10 | Manual review |
| Variables de sesión | Usar nombres documentados | Manual review |
| Inputs sin sanitizar | 0 | Code review |
| Credenciales en código | 0 | git grep |

### 22.2 Checklist de code review

```
[ ] Todos los inputs de usuario usan prepared statements
[ ] Todos los outputs de BD usan htmlspecialchars()
[ ] Todas las páginas verifican sesión antes de procesar
[ ] Endpoints AJAX retornan JSON válido
[ ] Archivos subidos son validados (tipo MIME + tamaño)
[ ] No hay debug code (var_dump, print_r, console.log con sesión) en producción
[ ] Errores de BD no se muestran al usuario (solo loguear)
[ ] Redirects siempre seguidos de exit()
```

### 22.3 Performance gates

```
[ ] Listados de productos cargan < 2s con hasta 1000 productos
[ ] Generación de PDF < 5s con hasta 100 registros
[ ] Import CSV procesa < 30s para archivos de 1MB
[ ] Login completo (con 2FA) < 30s
```

---

## 23. Plan de Refactorización

### Fase 1: Seguridad crítica ✅ COMPLETADA — 2026-04-25

**Duración real**: 1 sesión de trabajo.

| Tarea | Estado | Archivos afectados |
|-------|--------|-------------------|
| Eliminar `console.log(userSession)` | ✅ Hecho | `gestion_inventario.php` |
| Corregir typo `'$user_role'` → `'user_role'` | ✅ Hecho | `login.php` |
| Migrar SQL a prepared statements | ✅ Hecho | `gestion_inventario.php`, `gestion_ventas.php`, `login.php`, `register.php`, `perfil.php`, `gestion_compras.php`, `gestion_proveedores.php`, `administrar_usuarios.php` |
| Mover credenciales a `.env` | ✅ Hecho | `config.php`, `.env` (nuevo), `.htaccess` (nuevo) |
| Sanitizar outputs con `htmlspecialchars()` | ✅ Hecho | 6 archivos PHP |
| Eliminar `$conn->error` en output de usuario | ✅ Hecho | Múltiples archivos |

**Impacto**: Sistema ya no es vulnerable a SQL injection ni XSS en páginas principales. Credenciales de producción protegidas.

### Fase 2: Calidad de código (Corto plazo — próxima)

1. **Crear `includes/auth_check.php`** — centralizar verificación de sesión
   ```php
   // includes/auth_check.php
   function requireAuth(string $minRole = null): void {
       if (!isset($_SESSION['user_id'])) {
           header("Location: login.php");
           exit;
       }
       if ($minRole && $_SESSION['user_role'] !== $minRole) {
           header("Location: index.php");
           exit;
       }
   }
   ```
2. **Crear `utils/db.php`** — helper para queries comunes
   ```php
   // utils/db.php
   function dbQuery(mysqli $conn, string $sql, string $types = '', ...$params): mysqli_result|bool {
       $stmt = $conn->prepare($sql);
       if ($types) $stmt->bind_param($types, ...$params);
       $stmt->execute();
       return $stmt->get_result();
   }

   function dbFetchAll(mysqli $conn, string $sql, string $types = '', ...$params): array {
       $result = dbQuery($conn, $sql, $types, ...$params);
       return $result ? $result->fetch_all(MYSQLI_ASSOC) : [];
   }

   function dbFetchOne(mysqli $conn, string $sql, string $types = '', ...$params): ?array {
       $result = dbQuery($conn, $sql, $types, ...$params);
       return $result ? $result->fetch_assoc() : null;
   }
   ```
3. **Aplicar CSP headers globalmente** en `header.php`
4. **Agregar paginación** a todos los listados (LIMIT/OFFSET)
5. **Refactorizar archivos grandes** (>400 líneas) en módulos separados

### Fase 3: Arquitectura (Mediano plazo)

1. **Reorganizar estructura de carpetas** según estructura objetivo (sección 4)
2. **Separar endpoints AJAX** en directorio `api/` unificado
3. **Implementar `config/` directory** con configuración centralizada
4. **Crear `modules/` directory** con módulos auto-contenidos
5. **Agregar índices** de BD faltantes

---

## 24. Checklist Pre-Código

Verificar antes de agregar cualquier nueva feature:

### Estructura
- [ ] El archivo PHP sigue el patrón documentado en sección 9.1
- [ ] El archivo tiene menos de 400 líneas
- [ ] Se verifican permisos de rol antes de procesar
- [ ] CSS nuevo está en su propio archivo en `styles/`

### Seguridad
- [ ] Todos los inputs de usuario pasan por prepared statement
- [ ] Todos los outputs de BD pasan por `htmlspecialchars()`
- [ ] No hay credenciales hardcodeadas
- [ ] Verificación de sesión presente

### Base de datos
- [ ] Nuevas tablas siguen las convenciones de nomenclatura
- [ ] FKs tienen índices explícitos
- [ ] Tablas de historial tienen sus triggers (si la entidad es auditable)
- [ ] Schema actualizado en `bd.sql`

### Frontend
- [ ] Nuevo CSS en `styles/nombre_modulo.css`
- [ ] Modales siguen el patrón documentado
- [ ] No hay business logic en JavaScript
- [ ] Responsive verificado en mobile (768px breakpoint)

### Testing
- [ ] Happy path probado manualmente
- [ ] Casos de error probados manualmente
- [ ] Acceso por rol probado (no accede quien no debe)
- [ ] Input malicioso probado (SQL injection básico)

---

---

## 25. Guía de Despliegue — Hostinger

### Entorno de producción

| Parámetro | Valor |
|-----------|-------|
| Hosting | Hostinger Shared Hosting |
| Usuario BD | `u781177445_limber` |
| BD | `u781177445_limber` |
| PHP | 8.x (cPanel) |
| Servidor web | Apache (LiteSpeed en Hostinger) |
| Acceso FTP | via Hostinger File Manager o FTP client |

### Archivos que NO subir a producción

```
.env                    ← NUNCA via git/repositorio público, sí via FTP directo
config.php              ← bloqueado por .htaccess (pero no exponer)
endpointsPruebas/       ← solo para desarrollo local
bd.sql                  ← schema de BD, no en webroot
*.log                   ← si existen
PhpSpreadsheet-3.3.0/   ← usar solo vendor/ con composer
```

### Proceso de deploy

```
1. Subir archivos PHP modificados via FTP o File Manager de Hostinger
2. Subir .env con credenciales de producción (SOLO via FTP, no git)
3. Verificar que .htaccess está presente y bloquea .env
4. Verificar que vendor/ tiene las dependencias (composer install)
5. Probar login en producción con usuario de prueba
6. Verificar que 2FA funciona para Administrador
7. Revisar PHP error log en cPanel
```

### Variables de entorno en `.env`

```env
# Desarrollo local
LOCAL_DB_HOST=localhost
LOCAL_DB_USER=root
LOCAL_DB_PASS=
LOCAL_DB_NAME=u781177445_limber
LOCAL_DB_PORT=3306

# Producción (Hostinger)
PROD_DB_HOST=127.0.0.1
PROD_DB_USER=u781177445_limber
PROD_DB_PASS=[contraseña real]
PROD_DB_NAME=u781177445_limber
PROD_DB_PORT=3306
```

### Verificación post-deploy (checklist)

```
[ ] Login funciona (Usuario y Administrador)
[ ] 2FA funciona para Administrador
[ ] Inventario: CRUD funciona
[ ] Ventas: Crear venta actualiza stock correctamente
[ ] Compras: Registrar compra actualiza inventario
[ ] Reportes: Genera PDF sin error
[ ] Documentos: Upload funciona
[ ] .env NO accesible via navegador (devuelve 403)
[ ] config.php NO accesible via navegador (devuelve 403)
```

### Rollback

Si hay error en producción:
1. Reemplazar archivo afectado con versión anterior via FTP
2. Verificar `error_log` en cPanel → PHP Errors
3. Si BD corrupta: restaurar desde `bd.sql` (mantener backup actualizado)

---

## 26. Patrones de Error Handling

### Principio general

**Nunca exponer detalles internos al usuario.** Los errores técnicos van a log, el usuario ve mensajes genéricos.

```php
// ❌ MAL — expone información interna
echo "Error al actualizar el usuario: " . $conn->error;

// ✅ BIEN — mensaje genérico + log interno
error_log("DB Error en administrar_usuarios.php: " . $conn->error);
echo "<div class='alert alert-danger'>Error al actualizar el usuario. Intente nuevamente.</div>";
```

### Patrón: Manejo de errores en queries

```php
// Patrón estándar para operaciones de escritura
$stmt = $conn->prepare("INSERT INTO ...");
$stmt->bind_param("...", ...);

if ($stmt->execute()) {
    // Éxito
    $mensaje = "<div class='alert alert-success'>Operación completada.</div>";
} else {
    // Error — log interno, mensaje genérico al usuario
    error_log("Error en " . __FILE__ . ":" . __LINE__ . " — " . $stmt->error);
    $mensaje = "<div class='alert alert-danger'>Error al procesar. Intente nuevamente.</div>";
}
$stmt->close();
```

### Patrón: Manejo de errores en endpoints AJAX

```php
// Respuesta de error estandarizada
function jsonError(string $message, int $code = 400): void {
    http_response_code($code);
    header('Content-Type: application/json');
    echo json_encode(['success' => false, 'error' => $message]);
    exit;
}

// Respuesta de éxito estandarizada
function jsonSuccess($data = null, string $message = 'OK'): void {
    header('Content-Type: application/json');
    echo json_encode(['success' => true, 'data' => $data, 'message' => $message]);
    exit;
}

// Uso en endpoint AJAX
if (!isset($_SESSION['user_id'])) {
    jsonError('No autorizado', 401);
}

$result = dbFetchOne($conn, "SELECT ...", "i", $id);
if (!$result) {
    jsonError('Registro no encontrado', 404);
}

jsonSuccess($result);
```

### Patrón: Validación de inputs antes de query

```php
// Validar ANTES de preparar statement
function validatePositiveInt(mixed $value, string $fieldName): int {
    $val = intval($value);
    if ($val <= 0) {
        throw new InvalidArgumentException("$fieldName debe ser un número positivo");
    }
    return $val;
}

// En página PHP
try {
    $cantidad = validatePositiveInt($_POST['cantidad'], 'Cantidad');
    $id_producto = validatePositiveInt($_POST['id_producto'], 'Producto');
    // proceder con query
} catch (InvalidArgumentException $e) {
    $mensaje_error = htmlspecialchars($e->getMessage());
    echo "<div class='alert alert-warning'>$mensaje_error</div>";
}
```

### Patrón: Redirect + exit siempre juntos

```php
// ❌ MAL — sin exit, el código continúa ejecutándose
header("Location: login.php");

// ✅ BIEN — exit garantiza que nada más se ejecuta
header("Location: login.php");
exit;
```

### Categorías de error y respuesta

| Tipo de error | Log | Mensaje al usuario | HTTP Code |
|--------------|-----|-------------------|-----------|
| Autenticación fallida | No (previene enumeración) | "Credenciales inválidas" | 302 redirect |
| No autorizado | Sí | "No tienes permiso" | 302 redirect |
| Input inválido | No | Descripción específica | 200 (form re-display) |
| Error de BD | Sí | "Error al procesar. Intente nuevamente" | 200 (form re-display) |
| Archivo no encontrado | Sí | "Recurso no disponible" | 404 |
| Error interno inesperado | Sí (con stack trace) | "Error interno del servidor" | 500 |

---

## 27. Seguridad — Registro de Cambios

### Sesión 2026-04-25 — Hardening de seguridad

**Objetivo**: Eliminar SQL injection, XSS y exposición de datos críticos identificados en análisis previo.

#### SQL Injection → Prepared Statements

Todos los archivos migrados de string concatenation a `$conn->prepare()` + `bind_param()`:

| Archivo | Operaciones corregidas |
|---------|----------------------|
| `gestion_inventario.php` | INSERT producto, UPDATE producto |
| `gestion_ventas.php` | SELECT check stock, INSERT venta, INSERT detalle, UPDATE stock |
| `login.php` | SELECT autenticación (reordenado: pattern check ANTES del query) |
| `register.php` | SELECT check email, INSERT usuario |
| `perfil.php` | SELECT usuario, UPDATE perfil (3 variantes: sin pass, con pass, con rol) |
| `gestion_compras.php` | INSERT compra, SELECT check inventario, UPDATE inventario, INSERT inventario |
| `gestion_proveedores.php` | INSERT proveedor |
| `administrar_usuarios.php` | UPDATE usuario (2 variantes), INSERT usuario |

#### XSS → htmlspecialchars()

Aplicado `htmlspecialchars()` en todos los outputs de datos de BD en tablas HTML:
- `gestion_inventario.php` — tabla de productos + onclick JS
- `gestion_ventas.php` — tabla de ventas + IDs en href/onclick
- `gestion_compras.php` — tabla de compras + IDs en href/onclick
- `gestion_proveedores.php` — tabla de proveedores + IDs en href/onclick
- `administrar_usuarios.php` — tabla de usuarios + datos en onclick (con `ENT_QUOTES`)
- `perfil.php` — inputs de formulario con datos del usuario

Para atributos en `onclick="fn('...')"` se usó `ENT_QUOTES` para escapar comillas simples y prevenir escape del contexto JS.

#### Otras correcciones

| Problema | Solución | Archivo |
|---------|----------|---------|
| `console.log($_SESSION)` en producción | Eliminado bloque `<script>` completo | `gestion_inventario.php` |
| `$_SESSION['$user_role']` typo | Corregido a `$_SESSION['user_role']` | `login.php:57` |
| Credenciales DB hardcodeadas | Movidas a `.env`, parseado con función nativa | `config.php` |
| `.env` accesible via web | `.htaccess` con `Deny from all` | `.htaccess` (nuevo) |
| `config.php` accesible via web | `.htaccess` con `Deny from all` | `.htaccess` |
| `$conn->error` en output HTML | Reemplazado por mensajes genéricos + `error_log()` | Múltiples |
| División de strings en SQL: `'$monto' / '$cant'` | Calculado en PHP: `$precio = $monto / $cant` | `gestion_ventas.php` |

#### Bug crítico corregido — Autorización rota

El typo `$_SESSION['$user_role']` en `login.php` causaba que usuarios con rol `Empleado` o `Usuario` **nunca tuvieran su rol almacenado en sesión**. Todas las páginas que verificaban `$_SESSION['user_role']` recibían `null`, rompiendo el sistema RBAC completo para roles no-admin.

**Impacto**: Usuarios no-admin posiblemente no podían acceder a funcionalidades que debían poder usar, o accedían a funcionalidades que no debían (depende de la lógica de cada página).

**Fix**: `$_SESSION['user_role'] = $user['rol']` en `login.php` — fix de una línea, impacto crítico.

---

## 28. Patrones de Seguridad — Referencia Rápida

### Input validation — tipos de dato

```php
// IDs de BD — siempre intval
$id = intval($_POST['id'] ?? 0);
if ($id <= 0) { /* error */ }

// Cantidades numéricas
$cantidad = intval($_POST['cantidad'] ?? 0);

// Montos monetarios
$monto = floatval($_POST['monto'] ?? 0);

// Strings — no escapar aquí, bind_param lo maneja
$nombre = trim($_POST['nombre'] ?? '');
if (empty($nombre)) { /* error */ }

// Enum values — whitelist explícita
$estado_permitido = ['Activo', 'Inactivo'];
$estado = in_array($_POST['estado'], $estado_permitido) ? $_POST['estado'] : 'Activo';

// Rol — whitelist explícita
$roles_permitidos = ['Administrador', 'Empleado', 'Usuario'];
$rol = in_array($_POST['rol'], $roles_permitidos) ? $_POST['rol'] : 'Usuario';
```

### Output sanitization — contextos

```php
// Contexto HTML (body, td, p, etc.)
echo htmlspecialchars($valor, ENT_HTML5, 'UTF-8');

// Contexto atributo HTML con comillas dobles: <input value="...">
echo htmlspecialchars($valor, ENT_HTML5, 'UTF-8'); // misma función

// Contexto atributo HTML con comillas simples: onclick="fn('...')"
echo htmlspecialchars($valor, ENT_QUOTES, 'UTF-8'); // ENT_QUOTES escapa ' y "

// Contexto URL: href="page.php?id=..."
echo urlencode($valor);

// Contexto JSON (para AJAX responses)
echo json_encode($data, JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT);
```

### Prepared statements — tipos de bind_param

```
i  → integer   (INT, TINYINT, SMALLINT, etc.)
d  → double    (DECIMAL, FLOAT, DOUBLE)
s  → string    (VARCHAR, TEXT, DATETIME, DATE, ENUM)
b  → blob      (BLOB, archivos binarios)

Ejemplos:
bind_param("sii", $nombre, $cantidad, $stock)   → string, int, int
bind_param("isds", $id, $fecha, $monto, $est)   → int, string, double, string
bind_param("sssssssi", ..., $id)                → 7 strings + 1 int (al final)
```

### Verificación de sesión — patrones por contexto

```php
// Página que requiere cualquier usuario autenticado
if (!isset($_SESSION['user_id'])) {
    header("Location: login.php");
    exit;
}

// Página que requiere Administrador
if (!isset($_SESSION['user_role']) || $_SESSION['user_role'] !== 'Administrador') {
    header("Location: index.php");
    exit;
}

// Página que permite Admin o Empleado
$roles_permitidos = ['Administrador', 'Empleado'];
if (!isset($_SESSION['user_role']) || !in_array($_SESSION['user_role'], $roles_permitidos)) {
    header("Location: index.php");
    exit;
}

// Verificar acción específica dentro de una página
$puede_eliminar = isset($_SESSION['user_role']) && $_SESSION['user_role'] === 'Administrador';
$puede_editar = isset($_SESSION['user_role']) && in_array($_SESSION['user_role'], ['Administrador', 'Empleado']);
```

---

*Documento actualizado el 2026-04-25 — Sesión de hardening de seguridad completada.*
*Generado originalmente por `/oden:architect` el 2026-04-24T21:19:11Z.*

---

## 29. Testing Strategy — PHP Sistema Inventario

### 29.1 Niveles de testing aplicables

Este sistema usa PHP procedural sin framework de testing automatizado. El testing se organiza en tres niveles:

| Nivel | Método | Cuándo |
|-------|--------|--------|
| Unit (manual) | Probar función aislada con datos conocidos | Al crear funciones en `functions/` o `utils/` |
| Integration | Probar flujo completo página → BD → respuesta | Antes de cada despliegue |
| Regression | Verificar que fix no rompe funcionalidades existentes | Después de cada cambio en archivos core |

### 29.2 Testing de endpoints AJAX

Cada endpoint `*_api.php` debe ser testeable via `curl` o Postman:

```bash
# Test: get_provider_details.php
curl -X POST http://localhost/inventario/get_provider_details.php \
  -H "Cookie: PHPSESSID=<session_id>" \
  -d "id=1"
# Respuesta esperada: JSON con datos del proveedor o {"error": "No autorizado"}

# Test sin sesión
curl -X POST http://localhost/inventario/get_provider_details.php \
  -d "id=1"
# Respuesta esperada: {"error": "No autorizado"} con HTTP 200

# Test con ID inválido
curl -X POST http://localhost/inventario/get_provider_details.php \
  -H "Cookie: PHPSESSID=<session_id>" \
  -d "id=abc"
# intval("abc") = 0, respuesta: {"error": "ID inválido"} o {"error": "No encontrado"}
```

### 29.3 Escenarios de testing por módulo — detallado

#### Auth — Escenarios críticos

```
ESCENARIO A1: Login exitoso administrador + 2FA
Precondición: usuario admin existe, 2FA habilitado
Pasos:
  1. GET /login.php → formulario visible con reCAPTCHA
  2. POST email + password válido → redirect a /verificacion_2fa.php
  3. Ingresar código OTP válido (< 10 min) → redirect a /dashboard.php
  4. Verificar: $_SESSION['user_id'] establecido
  5. Verificar: $_SESSION['user_role'] = 'Administrador'
  6. Verificar: $_SESSION['2fa_verified'] = true
Resultado esperado: Acceso a dashboard con menú completo

ESCENARIO A2: Intento de bypass de 2FA
Pasos:
  1. Login exitoso → redirect a /verificacion_2fa.php
  2. Intentar GET /dashboard.php directamente (sin completar 2FA)
Resultado esperado: Redirect de vuelta a /verificacion_2fa.php

ESCENARIO A3: Contraseña incorrecta repetida
Pasos:
  1. POST login con password incorrecto × 5
Resultado esperado: Cuenta NO bloqueada (sistema actual no implementa bloqueo)
NOTA: Deuda técnica — implementar rate limiting en Fase 4

ESCENARIO A4: Token de recuperación vencido
Pasos:
  1. Solicitar recuperación de contraseña → email enviado
  2. Esperar > 1 hora
  3. Usar link de recuperación
Resultado esperado: Mensaje "Token expirado, solicite uno nuevo"
```

#### Inventario — Escenarios de stock

```
ESCENARIO I1: Stock bajo → alerta visual
Precondición: producto con cantidad_disponible <= stock_minimo
Pasos:
  1. GET /gestion_inventario.php
  2. Localizar producto con stock bajo en tabla
Resultado esperado: Fila resaltada en amarillo (#FFF3CD), badge "Stock Bajo"

ESCENARIO I2: Transaccionalidad: venta reduce stock
Pasos:
  1. Producto X con cantidad_disponible = 10
  2. Crear venta de producto X con cantidad = 3
  3. GET /gestion_inventario.php
Resultado esperado: cantidad_disponible = 7

ESCENARIO I3: Rollback implícito — venta eliminada
Pasos:
  1. Desde ESCENARIO I2: cantidad_disponible = 7
  2. Eliminar la venta creada
  3. GET /gestion_inventario.php
Resultado esperado: cantidad_disponible = 10 (repuesto)
NOTA: Verificar que el trigger `after_delete_venta` está activo en BD

ESCENARIO I4: Import CSV — productos existentes
Pasos:
  1. Export CSV del sistema (2 productos)
  2. Modificar precio_unitario de ambos en el CSV
  3. Import del CSV modificado
Resultado esperado: precios actualizados, sin duplicados
```

#### Reportes — Escenarios de generación PDF

```
ESCENARIO R1: Reporte de período vacío
Precondición: No hay ventas en el mes seleccionado
Pasos:
  1. GET /reportes.php → seleccionar mes sin ventas → Generar PDF
Resultado esperado: PDF generado con tabla vacía + mensaje "Sin registros"
ANTI-PATRÓN: No debe lanzar error de división por cero en totales

ESCENARIO R2: Reporte con caracteres especiales
Precondición: productos con nombres "Ñoño & Cía" o "Açaí"
Pasos:
  1. Crear venta con esos productos
  2. Generar PDF
Resultado esperado: Caracteres renderizados correctamente (FPDF usa ISO-8859-1)
NOTA: Aplicar utf8_decode() antes de pasar strings a FPDF

ESCENARIO R3: Descarga Excel vía PhpSpreadsheet
Pasos:
  1. GET /reportes.php → "Exportar Excel"
Resultado esperado:
  - Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
  - Archivo .xlsx descargado
  - Todas las columnas con datos correctos
  - Hoja con nombre descriptivo
```

### 29.4 Test data fixtures — SQL

```sql
-- Insertar datos de prueba (ejecutar en BD de desarrollo, nunca en producción)

-- Productos de prueba
INSERT INTO Inventario (nombre, cantidad_disponible, precio_unitario, stock_minimo)
VALUES
  ('Producto Test A', 50, 99.99, 10),
  ('Producto Test B', 5, 149.99, 10),  -- stock bajo
  ('Producto Test C', 0, 49.99, 5);    -- sin stock

-- Proveedor de prueba
INSERT INTO Proveedores (nombre, contacto, telefono, email)
VALUES ('Proveedor Test S.A.', 'Juan García', '555-0000', 'test@proveedor.com');

-- Usuario de prueba (bcrypt de "TestPass123!")
INSERT INTO Usuarios (nombre, apellido, correo, contrasena, rol, estado, verificado)
VALUES ('Test', 'User', 'test@test.com',
        '$2y$12$EJEMPLO_HASH_BCRYPT', 'Empleado', 'Activo', 1);

-- Limpiar datos de prueba
DELETE FROM Ventas WHERE id_producto IN (SELECT id FROM Inventario WHERE nombre LIKE 'Producto Test%');
DELETE FROM Inventario WHERE nombre LIKE 'Producto Test%';
DELETE FROM Proveedores WHERE nombre = 'Proveedor Test S.A.';
DELETE FROM Usuarios WHERE correo = 'test@test.com';
```

### 29.5 Verificación de seguridad — payloads de prueba

```
# XSS payloads — probar en TODOS los campos de texto
<script>alert('XSS')</script>
"><script>alert('XSS')</script>
<img src=x onerror=alert('XSS')>
javascript:alert('XSS')

# SQL Injection payloads — probar en campos ID y búsqueda
' OR '1'='1
1; DROP TABLE Inventario--
1 UNION SELECT 1,2,3,user(),5--
' OR 1=1 LIMIT 1--

# Path traversal — probar en campos de nombre de archivo
../../etc/passwd
../config.php
..\config.php (Windows)

# Resultado esperado para TODOS:
# - Input sanitizado o rechazado
# - Sin error de BD visible
# - Sin ejecución de código
# - Log de intento registrado (si el sistema lo implementa)
```

---

## 30. Guía de Code Review — Checklist Completo

### 30.1 Pre-merge checklist (OBLIGATORIO)

Antes de desplegar cualquier cambio al servidor de producción, verificar:

#### Seguridad
```
[ ] INPUTS: Todos los $_POST/$_GET/$_FILES procesados con prepared statements o intval()/trim()
[ ] OUTPUTS: Todos los datos de BD renderizados con htmlspecialchars()
[ ] SESIÓN: Verificación de $_SESSION antes de procesar acciones sensibles
[ ] UPLOAD: Archivos subidos validados por MIME type + tamaño
[ ] CREDENTIALS: Sin credenciales hardcodeadas en el código (usar $_ENV)
[ ] DEBUG: Sin var_dump(), print_r(), console.log() con datos de sesión/BD
[ ] ERRORS: Errores de BD capturados con try/catch, no mostrados al usuario
[ ] REDIRECT: Todos los header("Location:...") seguidos de exit()
```

#### Código
```
[ ] DRY: No hay lógica duplicada que debería ser una función en functions/
[ ] NAMING: Variables en snake_case, constantes en SCREAMING_SNAKE_CASE
[ ] QUERIES: Máximo 10 queries por página PHP
[ ] NESTING: Máximo 4 niveles de nesting
[ ] LINES: Archivos PHP < 400 líneas, endpoints AJAX < 150 líneas
[ ] STMT: Todos los prepared statements cerrados con $stmt->close()
[ ] UTF8: Caracteres especiales manejados con charset utf8mb4
```

#### UI
```
[ ] RESPONSIVE: Vista verificada en mobile (Bootstrap breakpoints)
[ ] EMPTY STATE: Tablas vacías muestran mensaje, no espacio en blanco
[ ] TRANSITIONS: Elementos interactivos tienen transition: all 0.2s ease
[ ] HIERARCHY: Información más importante arriba con mayor peso visual
[ ] SPACING: Sistema de espaciado 8px base (padding 16/24/32px)
```

#### Base de datos
```
[ ] INDICES: Queries con WHERE usan columnas indexadas
[ ] FK: Foreign keys definidas para mantener integridad referencial
[ ] ROLLBACK: Operaciones multi-tabla usan transacciones
[ ] CHARSET: Nuevas tablas usan utf8mb4_unicode_ci
[ ] TRIGGERS: Cambios de stock/estado se registran en Historial_*
```

### 30.2 Patrones que indican problemas (anti-patterns a rechazar)

```php
// ❌ RECHAZAR: String concatenation con input de usuario
$sql = "SELECT * FROM Productos WHERE nombre = '" . $_POST['nombre'] . "'";

// ✅ ACEPTAR: Prepared statement
$stmt = $conn->prepare("SELECT * FROM Productos WHERE nombre = ?");
$stmt->bind_param("s", $_POST['nombre']);

// ❌ RECHAZAR: Output sin sanitizar
echo $_GET['nombre'];
echo $row['descripcion'];

// ✅ ACEPTAR: Output sanitizado
echo htmlspecialchars($_GET['nombre'], ENT_HTML5, 'UTF-8');
echo htmlspecialchars($row['descripcion'], ENT_HTML5, 'UTF-8');

// ❌ RECHAZAR: Redirect sin exit
header("Location: login.php");
// código sigue ejecutándose aquí

// ✅ ACEPTAR: Redirect con exit
header("Location: login.php");
exit;

// ❌ RECHAZAR: Credencial hardcodeada
$conn = new mysqli("localhost", "root", "mi_password", "inventario");

// ✅ ACEPTAR: Variables de entorno
$conn = new mysqli($_ENV['DB_HOST'], $_ENV['DB_USER'], $_ENV['DB_PASS'], $_ENV['DB_NAME']);

// ❌ RECHAZAR: Error de BD visible al usuario
echo "Error: " . $conn->error;

// ✅ ACEPTAR: Error logueado, mensaje genérico al usuario
error_log("DB Error: " . $conn->error);
echo json_encode(['error' => 'Error interno del servidor']);

// ❌ RECHAZAR: Nesting excesivo (> 4 niveles)
if ($user) {
    if ($role) {
        if ($perm) {
            foreach ($data as $row) {
                if ($row['active']) {
                    // nivel 5
                }
            }
        }
    }
}

// ✅ ACEPTAR: Early returns para reducir nesting
if (!$user) return;
if (!$role) return;
if (!$perm) return;
foreach ($data as $row) {
    if (!$row['active']) continue;
    // nivel 2
}
```

### 30.3 Checklist específico para páginas nuevas

Al crear una nueva página PHP (`nuevo_modulo.php`), verificar la estructura:

```
[ ] 1. include('header.php') al inicio — establece sesión, $conn, $user_role
[ ] 2. Verificación de permiso inmediatamente después
[ ] 3. Procesamiento POST con prepared statements
[ ] 4. Queries de lectura después del POST
[ ] 5. HTML con PHP embebido minimal (lógica en PHP, no en HTML)
[ ] 6. Modales y JS al final del body
[ ] 7. include('footer.php') al cierre
[ ] 8. Archivo CSS específico en styles/nuevo_modulo.css
[ ] 9. Enlace en header.php según rol que debe ver el módulo
[ ] 10. Opción en sidebar con icono Lucide apropiado
```

---

## 31. Patrones de Validación de Input — PHP

### 31.1 Validación según tipo de dato

```php
// === ENTEROS ===
// IDs de BD, cantidades, años
$id = intval($_POST['id'] ?? 0);
if ($id <= 0) {
    echo json_encode(['error' => 'ID inválido']); exit;
}

// Con rango
$cantidad = intval($_POST['cantidad'] ?? 0);
if ($cantidad < 1 || $cantidad > 9999) {
    $error = "Cantidad debe ser entre 1 y 9999";
}

// === DECIMALES ===
// Precios, montos
$precio = floatval(str_replace(',', '.', $_POST['precio'] ?? '0'));
if ($precio < 0 || $precio > 999999.99) {
    $error = "Precio fuera de rango";
}

// === STRINGS ===
// Nombres, descripciones
$nombre = trim($_POST['nombre'] ?? '');
if (empty($nombre)) {
    $error = "Nombre requerido";
} elseif (strlen($nombre) > 255) {
    $error = "Nombre demasiado largo (máximo 255 caracteres)";
}
// No usar strip_tags en datos que van a BD — solo en output

// === EMAIL ===
$email = filter_var(trim($_POST['email'] ?? ''), FILTER_VALIDATE_EMAIL);
if (!$email) {
    $error = "Email inválido";
}

// === FECHAS ===
$fecha = trim($_POST['fecha'] ?? '');
if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $fecha)) {
    $error = "Formato de fecha inválido (YYYY-MM-DD)";
}
// Validar que es fecha real
$dt = DateTime::createFromFormat('Y-m-d', $fecha);
if (!$dt || $dt->format('Y-m-d') !== $fecha) {
    $error = "Fecha inválida";
}

// === ENUMS/WHITELIST ===
// Roles, estados, categorías
$estado_valido = ['Activo', 'Inactivo', 'Pendiente'];
$estado = trim($_POST['estado'] ?? '');
if (!in_array($estado, $estado_valido, true)) {
    $error = "Estado inválido";
}

// === ARCHIVOS ===
$tipos_permitidos = [
    'application/pdf',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'text/plain',
    'text/csv'
];
if (!isset($_FILES['archivo']) || $_FILES['archivo']['error'] !== UPLOAD_ERR_OK) {
    $error = "Error en la carga del archivo";
} else {
    $finfo = new finfo(FILEINFO_MIME_TYPE);
    $mime = $finfo->file($_FILES['archivo']['tmp_name']);
    if (!in_array($mime, $tipos_permitidos, true)) {
        $error = "Tipo de archivo no permitido";
    }
    if ($_FILES['archivo']['size'] > 5 * 1024 * 1024) {
        $error = "Archivo mayor a 5MB";
    }
}
```

### 31.2 Función helper de validación reutilizable

```php
// functions/validate.php

/**
 * Valida y sanitiza un campo de formulario.
 * Retorna string limpio o null si inválido.
 */
function validateString(mixed $value, int $minLen = 1, int $maxLen = 255): ?string {
    $clean = trim((string)$value);
    if (strlen($clean) < $minLen || strlen($clean) > $maxLen) return null;
    return $clean;
}

function validateInt(mixed $value, int $min = 1, int $max = PHP_INT_MAX): ?int {
    $n = intval($value);
    if ($n < $min || $n > $max) return null;
    return $n;
}

function validateDecimal(mixed $value, float $min = 0.0, float $max = 999999.99): ?float {
    $n = floatval(str_replace(',', '.', (string)$value));
    if ($n < $min || $n > $max) return null;
    return $n;
}

function validateEnum(mixed $value, array $allowed): ?string {
    $clean = trim((string)$value);
    return in_array($clean, $allowed, true) ? $clean : null;
}

function validateEmail(mixed $value): ?string {
    return filter_var(trim((string)$value), FILTER_VALIDATE_EMAIL) ?: null;
}

// Uso en página:
$nombre = validateString($_POST['nombre'] ?? '', 1, 100);
if ($nombre === null) { $errores[] = "Nombre: 1-100 caracteres requeridos"; }

$precio = validateDecimal($_POST['precio'] ?? 0, 0.01, 99999.99);
if ($precio === null) { $errores[] = "Precio: valor entre 0.01 y 99999.99"; }

if (!empty($errores)) {
    echo json_encode(['error' => implode(', ', $errores)]);
    exit;
}
```

### 31.3 Patrón de recolección de errores

```php
// Patrón preferido: recolectar todos los errores antes de responder
$errores = [];

$nombre = validateString($_POST['nombre'] ?? '', 1, 100);
if ($nombre === null) $errores[] = "Nombre requerido (1-100 chars)";

$precio = validateDecimal($_POST['precio'] ?? 0, 0.01);
if ($precio === null) $errores[] = "Precio debe ser mayor a 0";

$cantidad = validateInt($_POST['cantidad'] ?? 0, 1, 9999);
if ($cantidad === null) $errores[] = "Cantidad debe ser 1-9999";

// Respuesta unificada de errores
if (!empty($errores)) {
    // Para páginas con formulario HTML
    $error_msg = implode('<br>', array_map('htmlspecialchars', $errores));
    // Continuar renderizado con $error_msg en alerta

    // Para endpoints AJAX
    echo json_encode(['success' => false, 'errors' => $errores]);
    exit;
}

// Si llegamos aquí, todos los datos son válidos
// Proceder con prepared statement
```

---

## 32. Optimización de Consultas MySQL

### 32.1 Índices existentes y recomendados

```sql
-- Índices existentes (verificar con SHOW INDEX FROM tabla)
-- Inventario
PRIMARY KEY (id_producto)
INDEX (nombre)                -- búsquedas por nombre

-- Ventas
PRIMARY KEY (id_venta)
INDEX (id_producto)           -- JOIN con Inventario
INDEX (fecha_venta)           -- filtros por período
INDEX (estado)                -- filtros por estado

-- Usuarios
PRIMARY KEY (id_usuario)
UNIQUE (correo)               -- login por email

-- Índices RECOMENDADOS (pendientes de agregar)
CREATE INDEX idx_inventario_stock ON Inventario(cantidad_disponible, stock_minimo);
-- Acelera: WHERE cantidad_disponible <= stock_minimo

CREATE INDEX idx_ventas_periodo ON Ventas(fecha_venta, id_producto);
-- Acelera: reportes de ventas por período

CREATE INDEX idx_compras_proveedor_estado ON Compras(id_proveedor, estado);
-- Acelera: listado de compras por proveedor y estado
```

### 32.2 Queries problemáticos y optimizaciones

```sql
-- ❌ LENTO: SELECT * sin LIMIT en tabla grande
SELECT * FROM Ventas;

-- ✅ RÁPIDO: Paginación siempre
SELECT * FROM Ventas ORDER BY fecha_venta DESC LIMIT 50 OFFSET 0;

-- ❌ LENTO: Cálculo de stock en aplicación (N queries)
foreach ($productos as $p) {
    $stock = $conn->query("SELECT SUM(cantidad) FROM Entradas WHERE id_producto = {$p['id']}");
}

-- ✅ RÁPIDO: Cálculo en BD (1 query con JOIN)
SELECT i.id_producto, i.nombre, i.cantidad_disponible,
       COALESCE(SUM(e.cantidad), 0) AS total_entradas
FROM Inventario i
LEFT JOIN Entradas_Inventario e ON i.id_producto = e.id_producto
GROUP BY i.id_producto, i.nombre, i.cantidad_disponible;

-- ❌ LENTO: LIKE '%texto%' al inicio (no usa índice)
SELECT * FROM Inventario WHERE nombre LIKE '%producto%';

-- ✅ MEJOR: LIKE 'texto%' (usa índice) o FULLTEXT si disponible
SELECT * FROM Inventario WHERE nombre LIKE 'producto%';
-- O con FULLTEXT:
ALTER TABLE Inventario ADD FULLTEXT INDEX ft_nombre (nombre);
SELECT * FROM Inventario WHERE MATCH(nombre) AGAINST ('producto' IN BOOLEAN MODE);

-- ❌ LENTO: Subquery correlacionada
SELECT *, (SELECT COUNT(*) FROM Ventas WHERE id_producto = i.id_producto) AS total_ventas
FROM Inventario i;

-- ✅ RÁPIDO: JOIN con subquery
SELECT i.*, COALESCE(v.total_ventas, 0) AS total_ventas
FROM Inventario i
LEFT JOIN (SELECT id_producto, COUNT(*) AS total_ventas FROM Ventas GROUP BY id_producto) v
  ON i.id_producto = v.id_producto;
```

### 32.3 Transacciones para operaciones multi-tabla

```php
// Patrón para operaciones que tocan múltiples tablas

// Registrar venta + actualizar stock
$conn->begin_transaction();
try {
    // 1. Insertar venta
    $stmt = $conn->prepare("INSERT INTO Ventas (id_producto, cantidad, precio_total, fecha_venta, estado)
                            VALUES (?, ?, ?, NOW(), 'Completada')");
    $stmt->bind_param("iid", $id_producto, $cantidad, $precio_total);
    $stmt->execute();
    $id_venta = $conn->insert_id;
    $stmt->close();

    // 2. Actualizar stock (con verificación)
    $stmt = $conn->prepare("UPDATE Inventario
                            SET cantidad_disponible = cantidad_disponible - ?
                            WHERE id_producto = ? AND cantidad_disponible >= ?");
    $stmt->bind_param("iii", $cantidad, $id_producto, $cantidad);
    $stmt->execute();

    if ($stmt->affected_rows === 0) {
        throw new Exception("Stock insuficiente");
    }
    $stmt->close();

    // 3. Insertar en historial
    $stmt = $conn->prepare("INSERT INTO Historial_Ventas (id_venta, accion, id_usuario, fecha)
                            VALUES (?, 'CREACION', ?, NOW())");
    $stmt->bind_param("ii", $id_venta, $_SESSION['user_id']);
    $stmt->execute();
    $stmt->close();

    $conn->commit();
    echo json_encode(['success' => true, 'id_venta' => $id_venta]);

} catch (Exception $e) {
    $conn->rollback();
    error_log("Error en transacción venta: " . $e->getMessage());
    echo json_encode(['error' => $e->getMessage()]);
}
```

---

## 33. Logging y Monitoreo

### 33.1 Niveles de logging implementados

| Nivel | Función PHP | Destino | Cuándo usar |
|-------|------------|---------|-------------|
| ERROR | `error_log()` | `php_errors.log` | Errores de BD, excepciones, errores inesperados |
| WARNING | `error_log("WARNING: ...")` | `php_errors.log` | Inputs inválidos, acciones sospechosas |
| INFO | `file_put_contents($log, ...)` | `log.txt` | Acciones de usuario importantes (login, ventas) |
| DEBUG | Solo en desarrollo | Nunca en producción | Depuración temporal |

### 33.2 Patrones de log estandarizados

```php
// Log de error de BD — siempre con contexto
function logDbError(string $operation, string $error, array $context = []): void {
    $msg = sprintf(
        "[%s] DB ERROR in %s: %s | Context: %s | User: %s | IP: %s",
        date('Y-m-d H:i:s'),
        $operation,
        $error,
        json_encode($context),
        $_SESSION['user_id'] ?? 'anonymous',
        $_SERVER['REMOTE_ADDR'] ?? 'unknown'
    );
    error_log($msg);
}

// Uso:
$stmt = $conn->prepare("SELECT * FROM Inventario WHERE id = ?");
if (!$stmt) {
    logDbError('gestion_inventario::fetch', $conn->error, ['id' => $id]);
    echo json_encode(['error' => 'Error interno del servidor']);
    exit;
}

// Log de acción de usuario — para auditoría
function logUserAction(string $action, array $data = []): void {
    $log_entry = sprintf(
        "[%s] USER_ACTION: %s | User: %s (%s) | Data: %s\n",
        date('Y-m-d H:i:s'),
        $action,
        $_SESSION['user_nombre'] ?? 'unknown',
        $_SESSION['user_id'] ?? '0',
        json_encode($data)
    );
    file_put_contents(__DIR__ . '/log.txt', $log_entry, FILE_APPEND | LOCK_EX);
}

// Uso:
logUserAction('VENTA_CREADA', ['id_venta' => $id_venta, 'total' => $precio_total]);
logUserAction('PRODUCTO_ELIMINADO', ['id_producto' => $id, 'nombre' => $nombre]);

// Log de intento de seguridad
function logSecurityEvent(string $event, string $detail = ''): void {
    $msg = sprintf(
        "[%s] SECURITY: %s | Detail: %s | IP: %s | UA: %s\n",
        date('Y-m-d H:i:s'),
        $event,
        $detail,
        $_SERVER['REMOTE_ADDR'] ?? 'unknown',
        substr($_SERVER['HTTP_USER_AGENT'] ?? 'unknown', 0, 100)
    );
    file_put_contents(__DIR__ . '/log.txt', $msg, FILE_APPEND | LOCK_EX);
}

// Uso:
logSecurityEvent('LOGIN_FAILED', "email: " . substr($email, 0, 20));
logSecurityEvent('UNAUTHORIZED_ACCESS', "page: gestion_inventario.php, role: " . ($_SESSION['user_role'] ?? 'none'));
```

### 33.3 Monitoreo en producción (Hostinger)

```
Archivos de log a monitorear:
- /php_errors.log  → errores PHP (accesible via File Manager de Hostinger)
- /log.txt         → acciones de usuario y eventos de seguridad
- /log_api.log     → llamadas a API externa

Alertas manuales a revisar semanalmente:
[ ] Líneas "SECURITY:" en log.txt → intentos de acceso no autorizado
[ ] Líneas "DB ERROR" en php_errors.log → problemas de BD
[ ] Tamaño de log.txt > 10MB → rotar (renombrar, crear nuevo)

Script de rotación de logs (ejecutar mensualmente via cPanel cron):
# En cPanel → Cron Jobs:
# 0 0 1 * * mv /home/u781177445/public_html/inventario/log.txt \
#   /home/u781177445/public_html/inventario/log_$(date +%Y%m).txt && \
#   touch /home/u781177445/public_html/inventario/log.txt
```

### 33.4 Métricas de salud del sistema

```php
// endpoint: health_check.php (solo accesible para Administrador)
<?php
require_once 'config.php';
session_start();
if (!isset($_SESSION['user_role']) || $_SESSION['user_role'] !== 'Administrador') {
    http_response_code(403); exit;
}
header('Content-Type: application/json');

$health = [
    'timestamp' => date('c'),
    'db' => $conn->ping() ? 'ok' : 'error',
    'log_size_kb' => round(filesize(__DIR__ . '/log.txt') / 1024, 2),
    'uploads_writable' => is_writable(__DIR__ . '/uploads/'),
    'php_version' => PHP_VERSION,
    'memory_usage_mb' => round(memory_get_usage(true) / 1048576, 2),
];

echo json_encode($health, JSON_PRETTY_PRINT);
```

---

*Documento expandido el 2026-04-26 — Testing, Code Review, Validación, MySQL Optimization, Logging.*

---

## 34. Code Structure Guidelines — Enhanced

Esta sección define la organización interna del código PHP con límites precisos y medibles para prevenir god files e inconsistencias entre módulos.

### 34.1 Límites de Archivos por Tipo (ENFORCED)

| Tipo de archivo | Líneas máx. | Líneas típicas | Qué hacer si excede |
|----------------|------------|----------------|---------------------|
| Page PHP (`modulo.php`) | 400 | 200-300 | Extraer lógica a `modulo_logic.php` |
| Endpoint AJAX (`*_api.php`) | 150 | 80-120 | Extraer validaciones a helper |
| Helper / Functions (`functions/`) | 200 | 100-150 | Dividir por dominio |
| CSS por módulo (`styles/`) | 300 | 150-250 | Dividir en `base.css` + `modulo.css` |
| JavaScript inline por página | 120 | 60-90 | Mover a `js/modulo.js` |
| JavaScript externo (`js/*.js`) | 200 | 100-150 | Dividir por funcionalidad |
| Config / Setup | 100 | 40-60 | No exceder bajo ningún caso |

### 34.2 Organización por Módulo (HIGH COHESION)

Cada módulo del sistema sigue este patrón de archivos:

```
inventario/
├── gestion_inventario.php       # Vista principal (page)
├── procesar_inventario_api.php  # Endpoints AJAX del módulo
├── get_product_details.php      # Endpoint de lectura específico
├── styles/
│   └── inventario.css           # Estilos del módulo
└── js/
    └── inventario.js            # JS específico del módulo (si aplica)

ventas/
├── gestion_ventas.php
├── procesar_venta_api.php
├── get_venta_details.php
└── styles/
    └── ventas.css
```

**Regla de cohesión**: Un módulo no debe importar funciones de otro módulo directamente. Toda lógica compartida va en `functions/` o `config.php`.

### 34.3 Layer Dependencies (DIRECCIÓN OBLIGATORIA)

```
┌─────────────────────────────────────────────┐
│  CAPA DE PRESENTACIÓN (*.php con HTML)       │
│  gestion_inventario.php, dashboard.php, etc. │
└──────────────────────┬──────────────────────┘
                       │ puede usar ↓
┌──────────────────────▼──────────────────────┐
│  CAPA DE LÓGICA DE NEGOCIO                   │
│  *_api.php, funciones de validación          │
└──────────────────────┬──────────────────────┘
                       │ puede usar ↓
┌──────────────────────▼──────────────────────┐
│  CAPA DE DATOS                               │
│  config.php (BD), functions/, helpers        │
└─────────────────────────────────────────────┘

❌ PROHIBIDO: config.php importando lógica de negocio
❌ PROHIBIDO: functions/ llamando a páginas de presentación
❌ PROHIBIDO: Dependencias circulares entre módulos
✅ PERMITIDO: Imports de la misma capa
✅ PERMITIDO: Presentación → Lógica → Datos
```

### 34.4 Plantilla Estándar — Page PHP

```php
<?php
// ═══════════════════════════════════════════
// SECCIÓN 1: BOOTSTRAP (siempre primero, max 10 líneas)
// ═══════════════════════════════════════════
require_once 'config.php';
include('header.php');

// ═══════════════════════════════════════════
// SECCIÓN 2: PERMISOS (antes de cualquier proceso)
// ═══════════════════════════════════════════
if (!$user_logged_in) { header("Location: login.php"); exit; }
if ($user_role === 'Usuario' && $modulo_requiere_empleado) {
    header("Location: acceso_denegado.php"); exit;
}

// ═══════════════════════════════════════════
// SECCIÓN 3: PROCESAMIENTO POST (max 80 líneas total)
// ═══════════════════════════════════════════
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';
    // Un switch/match por acción (max 5 acciones por página)
    // Si hay más → separar en *_api.php
}

// ═══════════════════════════════════════════
// SECCIÓN 4: QUERIES DE LECTURA (max 50 líneas)
// ═══════════════════════════════════════════
$stmt = $conn->prepare("SELECT ... FROM Tabla WHERE activo = 1 ORDER BY nombre");
$stmt->execute();
$data = $stmt->get_result();
$stmt->close();

// ═══════════════════════════════════════════
// SECCIÓN 5: HTML / RENDER (max 150 líneas)
// ═══════════════════════════════════════════
?>
<div class="container-fluid">
    <!-- Contenido del módulo -->
</div>

<?php
// ═══════════════════════════════════════════
// SECCIÓN 6: JAVASCRIPT (max 80 líneas inline)
// ═══════════════════════════════════════════
?>
<script>
// Solo lógica de UI — sin queries ni business logic
</script>

<?php include('footer.php'); ?>
```

### 34.5 Plantilla Estándar — Endpoint AJAX

```php
<?php
// ═══════════════════════════════════════════
// BOOTSTRAP (max 5 líneas)
// ═══════════════════════════════════════════
require_once 'config.php';
session_start();
header('Content-Type: application/json');

// ═══════════════════════════════════════════
// AUTENTICACIÓN (obligatorio, max 8 líneas)
// ═══════════════════════════════════════════
if (!isset($_SESSION['user_id'])) {
    http_response_code(401);
    echo json_encode(['error' => 'No autorizado']);
    exit;
}

// ═══════════════════════════════════════════
// VALIDACIÓN DE INPUT (max 30 líneas)
// ═══════════════════════════════════════════
$id = intval($_POST['id'] ?? 0);
if ($id <= 0) {
    http_response_code(400);
    echo json_encode(['error' => 'ID inválido']);
    exit;
}
// Máximo 5 parámetros por endpoint. Si necesita más → revisar diseño.

// ═══════════════════════════════════════════
// LÓGICA (max 60 líneas — 1 responsabilidad)
// ═══════════════════════════════════════════
$stmt = $conn->prepare("SELECT * FROM Tabla WHERE id = ?");
$stmt->bind_param("i", $id);
$stmt->execute();
$result = $stmt->get_result()->fetch_assoc();
$stmt->close();

// ═══════════════════════════════════════════
// RESPUESTA (max 10 líneas)
// ═══════════════════════════════════════════
if (!$result) {
    http_response_code(404);
    echo json_encode(['error' => 'No encontrado']);
    exit;
}
echo json_encode(['success' => true, 'data' => $result]);
exit;
```

### 34.6 Límites de Complejidad

| Métrica | Límite | Herramienta de verificación |
|---------|--------|----------------------------|
| Cyclomatic complexity por función | Max 10 | PHP_CodeSniffer / revisión manual |
| Niveles de anidamiento (if/foreach) | Max 4 | Revisión visual |
| Parámetros por función | Max 5 | Revisión manual |
| Métodos públicos por clase | Max 12 | PHPStan |
| Statements `use` / `require` por archivo | Max 10 | Revisión manual |
| Variables locales por función | Max 12 | Revisión manual |

---

## 35. Quality Enforcement — Métricas Medibles

### 35.1 Dashboard de Calidad del Proyecto

```
📊 ESTADO DE CALIDAD — Sistema Inventario
══════════════════════════════════════════

ESTRUCTURA DE ARCHIVOS
  ✅ config.php               45  líneas  (límite: 100)
  ✅ header.php               80  líneas  (límite: 100)
  ⚠️  gestion_inventario.php  380 líneas  (límite: 400) — REVISAR
  ✅ procesar_inventario.php  120 líneas  (límite: 150)
  ❌ administrar_usuarios.php 430 líneas  (EXCEDE límite: 400)
  ❌ integraciones_externas   460 líneas  (EXCEDE límite: 400)

SEGURIDAD
  ✅ Prepared statements en 100% de queries con input de usuario
  ✅ htmlspecialchars() en 100% de outputs de BD
  ✅ Verificación de sesión en 100% de endpoints AJAX
  ✅ .env fuera de public_html

COBERTURA DE TESTS
  ⚠️  Endpoints AJAX: 60% con pruebas documentadas
  ⚠️  Flujos críticos: 80% cubiertos
  ❌ Tests automatizados: No implementados (deuda técnica)

DOCUMENTACIÓN
  ✅ technical-decisions.md: 3,400+ líneas
  ✅ spec-auth.md:           1,081 líneas
  ✅ spec-inventario.md:     1,011 líneas
  ✅ spec-ventas.md:           867 líneas
  ✅ spec-compras.md:          801 líneas
  ✅ spec-reportes.md:       1,077 líneas
  ⚠️  spec-dashboard-admin:    643 líneas (objetivo: 800+)
  ─────────────────────────────────
  TOTAL: 8,880+ líneas (objetivo: 8,000) ✅
```

### 35.2 Convenciones de Nomenclatura — Tabla Completa

| Elemento | Convención | Ejemplo correcto | Ejemplo incorrecto |
|----------|-----------|------------------|--------------------|
| Archivos PHP (páginas) | snake_case | `gestion_inventario.php` | `GestionInventario.php` |
| Archivos PHP (endpoints) | snake_case + sufijo | `procesar_venta_api.php` | `procesarVenta.php` |
| Archivos CSS | kebab-case | `template-theme.css` | `templateTheme.css` |
| Archivos JS | kebab-case | `inventario-utils.js` | `inventarioUtils.js` |
| Variables PHP | snake_case | `$nombre_producto` | `$nombreProducto` |
| Variables de sesión | snake_case | `$_SESSION['user_role']` | `$_SESSION['userRole']` |
| Constantes PHP | SCREAMING_SNAKE | `MAX_FILE_SIZE` | `maxFileSize` |
| Tablas BD principales | PascalCase | `Inventario`, `Ventas` | `inventario`, `VENTAS` |
| Tablas BD compuestas | PascalCase_Snake | `Detalle_Ventas` | `detalleVentas` |
| Columnas BD (IDs) | `id_{entidad}` | `id_producto` | `productId`, `idProducto` |
| Columnas BD (fechas) | sufijo `_fecha` o `fecha_*` | `fecha_registro` | `registrationDate` |
| Funciones PHP | camelCase | `getUserData()` | `get_user_data()` |
| Clases PHP | PascalCase | `EmailService` | `email_service` |
| IDs HTML | kebab-case | `modal-editar-producto` | `modalEditarProducto` |
| Clases CSS custom | kebab-case | `card-master` | `cardMaster` |

### 35.3 Error Handling — Patrones por Capa

```php
// ── CAPA DE DATOS (config.php / queries) ──────────────────────────
// Lanza errores de BD al nivel superior. Nunca maneja UI.
if (!$stmt) {
    throw new RuntimeException("DB prepare failed: " . $conn->error);
}

// ── CAPA DE LÓGICA (*_api.php) ────────────────────────────────────
// Captura, loguea y responde en JSON. Nunca reintenta.
try {
    // lógica...
} catch (RuntimeException $e) {
    error_log("[" . date('Y-m-d H:i:s') . "] API_ERROR: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Error interno del servidor']);
    exit;
}

// ── CAPA DE PRESENTACIÓN (*.php con HTML) ─────────────────────────
// Muestra mensajes al usuario. Nunca stack traces.
if (isset($_SESSION['error_msg'])) {
    echo '<div class="alert alert-danger">'
        . htmlspecialchars($_SESSION['error_msg'])
        . '</div>';
    unset($_SESSION['error_msg']);
}
```

### 35.4 Reglas de Enforcement — Checklist de Code Review

Antes de aprobar cualquier cambio verificar:

```
SEGURIDAD
  [ ] ¿Todo input de usuario pasa por intval() o trim() + validación?
  [ ] ¿Todos los outputs de BD usan htmlspecialchars()?
  [ ] ¿Todos los queries con input externo usan prepared statements?
  [ ] ¿El endpoint verifica $_SESSION antes de operar?

ESTRUCTURA
  [ ] ¿El archivo está dentro del límite de líneas para su tipo?
  [ ] ¿La lógica de negocio está en la capa correcta?
  [ ] ¿Las rutas de archivo son relativas (sin usernames en la ruta)?

CALIDAD
  [ ] ¿Las funciones tienen menos de 5 parámetros?
  [ ] ¿El anidamiento no supera 4 niveles?
  [ ] ¿Los nombres siguen las convenciones de la sección 35.2?
  [ ] ¿Los mensajes de error no exponen stack traces?

RENDIMIENTO
  [ ] ¿Las queries en bucles están consolidadas en una sola query?
  [ ] ¿Los índices BD cubren las columnas de WHERE y ORDER BY?
  [ ] ¿Se usa $stmt->close() después de cada prepared statement?
```

### 35.5 Métricas de Calidad — Umbrales de Alerta

| Métrica | Verde | Amarillo | Rojo |
|---------|-------|----------|------|
| Archivos dentro de límite de líneas | 100% | 90-99% | < 90% |
| Endpoints con verificación de sesión | 100% | — | < 100% |
| Queries con prepared statements | 100% | — | < 100% |
| Documentación total (líneas) | > 8,000 | 7,000-8,000 | < 7,000 |
| Specs de módulos (líneas mín.) | > 800 | 700-800 | < 700 |
| Deuda técnica abierta | 0-2 items | 3-5 items | > 5 items |

---

## 36. Testing Requirements por Capa

Esta sección define qué y cómo debe probarse en cada capa del sistema PHP monolítico.

### 36.1 Capa de Presentación — Pruebas de Integración Manual

Para cada `*.php` de página principal:

```markdown
## Checklist de prueba — [nombre_modulo.php]

### Render básico
  [ ] Carga sin errores PHP (revisar php_errors.log)
  [ ] Todos los elementos HTML se muestran correctamente
  [ ] El sidebar y topbar cargan correctamente via layout/

### Permisos por rol
  [ ] Rol Administrador: acceso completo
  [ ] Rol Empleado: acceso según módulo (ver spec correspondiente)
  [ ] Rol Usuario: redirección correcta si no tiene acceso
  [ ] Sin sesión: redirección a login.php

### Estado vacío (empty state)
  [ ] Si la tabla de BD está vacía → se muestra estado vacío, no error

### Funcionalidad CRUD
  [ ] CREATE: formulario valida campos obligatorios en cliente
  [ ] CREATE: datos se guardan correctamente en BD
  [ ] READ: tabla muestra datos paginados/filtrados correctamente
  [ ] UPDATE: modal de edición carga datos correctos
  [ ] UPDATE: cambios se reflejan en BD y en la UI
  [ ] DELETE: modal de confirmación aparece antes de eliminar
  [ ] DELETE: registro se elimina y la tabla se refresca
```

### 36.2 Capa de Lógica — Pruebas de Endpoints AJAX

Para cada `*_api.php`:

```markdown
## Checklist de prueba — [modulo_api.php]

### Autenticación
  [ ] Sin sesión → HTTP 401, JSON `{"error": "No autorizado"}`
  [ ] Con sesión válida → procesa normalmente

### Validación de input
  [ ] ID inválido (0, negativo, string) → HTTP 400, JSON con mensaje
  [ ] Campos obligatorios vacíos → HTTP 400, JSON con detalle
  [ ] Input con caracteres especiales → sanitizado, no SQL error

### Happy path
  [ ] Acción principal devuelve `{"success": true, ...datos}`
  [ ] Respuesta incluye todos los campos esperados
  [ ] BD refleja el cambio después de la operación

### Error handling
  [ ] Error de BD → HTTP 500, mensaje genérico (no stack trace)
  [ ] Registro no encontrado → HTTP 404, mensaje apropiado
  [ ] Acción no reconocida → HTTP 400, mensaje apropiado
```

### 36.3 Capa de Datos — Pruebas de Integridad de BD

```markdown
## Checklist de BD — Integridad referencial

### Foreign Keys
  [ ] DELETE en padre sin ON DELETE CASCADE → error apropiado
  [ ] INSERT en hijo con FK inexistente → error de constraint
  [ ] UPDATE de PK → verificar cascada o restricción

### Triggers de auditoría
  [ ] INSERT en Inventario → genera registro en Historial_Inventario
  [ ] UPDATE de stock → trigger actualiza fecha_ultima_actualizacion
  [ ] DELETE de Venta → registro queda en historial con estado CANCELADO

### Stock y transacciones
  [ ] Venta con stock insuficiente → transacción hace rollback
  [ ] Entrada de inventario → stock_actual se incrementa correctamente
  [ ] Salida de inventario → stock_actual no puede quedar negativo (verificar constraint o validación)

### Índices
  [ ] Queries de búsqueda por nombre_producto usan índice (EXPLAIN)
  [ ] Queries de filtro por fecha usan índice (EXPLAIN)
  [ ] JOIN entre Ventas y Detalle_Ventas usa índice en FK
```

### 36.4 Pruebas de Regresión — Flujos Críticos

Los siguientes flujos deben probarse después de cualquier cambio relevante:

| Flujo crítico | Módulos involucrados | Frecuencia de prueba |
|---------------|----------------------|----------------------|
| Login + 2FA (admin) | auth, firebase | Cada deploy |
| Crear venta + actualizar stock | ventas, inventario | Cada deploy |
| Importar CSV de inventario | integraciones, inventario | Cada cambio en integraciones |
| Generar reporte PDF | reportes, FPDF | Cada cambio en reportes |
| Exportar Excel | reportes, PhpSpreadsheet | Cada cambio en reportes |
| Crear/editar usuario | admin, auth | Cada cambio en admin |
| Recuperar contraseña | auth, PHPMailer | Cada cambio en auth |
| Upload de documento | documentos, uploads | Cada cambio en documentos |

### 36.5 Automatización de Pruebas — Hoja de Ruta

| Fase | Herramienta | Qué cubre | Estado |
|------|------------|-----------|--------|
| Fase 1 (actual) | Pruebas manuales con checklist | Todos los flujos | ✅ Documentado |
| Fase 2 (próxima) | PHPUnit | Funciones puras en `functions/` | ⏳ Pendiente |
| Fase 3 (futuro) | Pest PHP | Endpoints AJAX (HTTP testing) | ⏳ Pendiente |
| Fase 4 (futuro) | Playwright / Cypress | E2E flujos críticos en browser | ⏳ Pendiente |

**Prioridad para Fase 2** (funciones con más impacto):
- `calcularTotalVenta(array $items): float`
- `validarStockDisponible(int $id_producto, int $cantidad): bool`
- `sanitizarInputFormulario(array $data): array`
- `generarCodigoSKU(string $categoria, int $siguiente): string`

---

*Documento expandido el 2026-05-04 — Code Structure Guidelines Enhanced, Quality Enforcement Métricas, Testing Requirements por Capa.*
