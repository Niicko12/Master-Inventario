-- ============================================================
-- Índices de rendimiento — Sistema de Gestión de Inventario
-- Generado: 2025-05-03
--
-- Uso: mysql -u usuario -p nombre_bd < migrations/add_indexes.sql
--
-- Todos los índices usan CREATE INDEX IF NOT EXISTS para que
-- la migración sea idempotente (se puede ejecutar más de una vez).
-- ============================================================

USE u781177445_limber;

-- ============================================================
-- Tabla: Inventario
-- Existentes: PK(id_producto), KEY(ubicacion_id), KEY(id_proveedor)
-- Añadidos:   nombre_producto (búsqueda/LIKE),
--             fecha_ultima_actualizacion (ORDER BY en reportes)
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_inventario_nombre_producto
    ON Inventario (nombre_producto);

CREATE INDEX IF NOT EXISTS idx_inventario_fecha_actualizacion
    ON Inventario (fecha_ultima_actualizacion);

-- ============================================================
-- Tabla: Ventas
-- Existentes: PK(id_venta), KEY(id_cliente)
-- Añadidos:   fecha_venta  (ORDER BY, rangos de fecha),
--             estado       (filtrado por estado de venta)
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_ventas_fecha_venta
    ON Ventas (fecha_venta);

CREATE INDEX IF NOT EXISTS idx_ventas_estado
    ON Ventas (estado);

-- ============================================================
-- Tabla: Compras
-- Existentes: PK(id_compra), KEY(id_proveedor)
-- Añadidos:   nombre_producto (búsqueda de compras por producto),
--             fecha_compra    (ORDER BY, filtrado por fecha),
--             estado          (filtrado por estado de compra)
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_compras_nombre_producto
    ON Compras (nombre_producto);

CREATE INDEX IF NOT EXISTS idx_compras_fecha_compra
    ON Compras (fecha_compra);

CREATE INDEX IF NOT EXISTS idx_compras_estado
    ON Compras (estado);

-- ============================================================
-- Tabla: Proveedores
-- Existentes: PK(id_proveedor)
-- Añadidos:   nombre_proveedor (búsqueda/autocomplete),
--             email            (lookup de duplicados y login)
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_proveedores_nombre
    ON Proveedores (nombre_proveedor);

CREATE INDEX IF NOT EXISTS idx_proveedores_email
    ON Proveedores (email);

-- ============================================================
-- Tabla: Usuarios
-- Existentes: PK(id_usuario), UNIQUE(correo_electronico)
-- Añadidos:   estado  (filtrado de usuarios Activos/Inactivos),
--             rol     (filtrado por rol en administrar_usuarios),
--             nombre  (búsqueda por nombre de usuario)
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_usuarios_estado
    ON Usuarios (estado);

CREATE INDEX IF NOT EXISTS idx_usuarios_rol
    ON Usuarios (rol);

CREATE INDEX IF NOT EXISTS idx_usuarios_nombre
    ON Usuarios (nombre);

-- ============================================================
-- Tabla: Documentos
-- Existentes: PK(id_documento)
-- Añadidos:   fecha_subida   (ORDER BY en listados),
--             tipo_documento (filtrado por tipo)
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_documentos_fecha_subida
    ON Documentos (fecha_subida);

CREATE INDEX IF NOT EXISTS idx_documentos_tipo
    ON Documentos (tipo_documento);

-- ============================================================
-- Tabla: Detalle_Ventas
-- Existentes: PK(id_detalle), KEY(id_producto), KEY(id_venta)
-- FK ya tienen índice, no se requieren índices adicionales.
-- ============================================================

-- ============================================================
-- Tabla: Detalle_Compras
-- Existentes: PK(id_detalle), KEY(id_compra), KEY(id_producto)
-- FK ya tienen índice, no se requieren índices adicionales.
-- ============================================================
