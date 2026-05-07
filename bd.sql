DROP DATABASE IF EXISTS u781177445_limber;
CREATE DATABASE IF NOT EXISTS u781177445_limber;
USE u781177445_limber;


CREATE TABLE `Compras` (
  `id_compra` int(11) NOT NULL,
  `id_proveedor` int(11) DEFAULT NULL,
  `nombre_producto` varchar(100) NOT NULL,
  `cantidad_comprada` int(11) NOT NULL,
  `fecha_compra` datetime DEFAULT NULL,
  `monto_total` decimal(10,2) DEFAULT NULL,
  `estado` varchar(50) DEFAULT 'En Curso'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `Compras`
--

INSERT INTO `Compras` (`id_compra`, `id_proveedor`, `nombre_producto`, `cantidad_comprada`, `fecha_compra`, `monto_total`, `estado`) VALUES
(19, 824, 'vinil', 5, '2024-11-29 04:45:23', 0.17, 'En Curso'),
(20, 826, 'Gaseosas', 200, '2025-02-06 12:15:29', 150000.00, 'En Curso');

--
-- Disparadores `Compras`
--
DELIMITER $$
CREATE TRIGGER `Compras_after_delete` AFTER DELETE ON `Compras` FOR EACH ROW BEGIN
    DECLARE ip_origen VARCHAR(45);
    SET ip_origen = 'IP_DEL_USUARIO';

    INSERT INTO `Historial_Compras` (`id_compra`, `tipo_accion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`)
    VALUES (OLD.id_compra, 'DELETE', USER(), ip_origen,
        CONCAT('Compra eliminada: ID Proveedor=', OLD.id_proveedor, ', Fecha Compra=', OLD.fecha_compra, ', Monto Total=', OLD.monto_total));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `Compras_after_insert` AFTER INSERT ON `Compras` FOR EACH ROW BEGIN
    DECLARE ip_origen VARCHAR(45);
    SET ip_origen = 'IP_DEL_USUARIO';

    INSERT INTO `Historial_Compras` (`id_compra`, `tipo_accion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`)
    VALUES (NEW.id_compra, 'INSERT', USER(), ip_origen,
        CONCAT('Nueva compra registrada: ID Proveedor=', NEW.id_proveedor, ', Fecha Compra=', NEW.fecha_compra, ', Monto Total=', NEW.monto_total));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `Compras_after_update` AFTER UPDATE ON `Compras` FOR EACH ROW BEGIN
    DECLARE ip_origen VARCHAR(45);
    DECLARE descripcion TEXT;
    SET ip_origen = 'IP_DEL_USUARIO';

    SET descripcion = '';

    IF OLD.id_proveedor <> NEW.id_proveedor THEN
        SET descripcion = CONCAT(descripcion, 'ID Proveedor cambió de ', OLD.id_proveedor, ' a ', NEW.id_proveedor, '. ');
    END IF;

    IF OLD.fecha_compra <> NEW.fecha_compra THEN
        SET descripcion = CONCAT(descripcion, 'Fecha Compra cambió de ', OLD.fecha_compra, ' a ', NEW.fecha_compra, '. ');
    END IF;

    IF OLD.monto_total <> NEW.monto_total THEN
        SET descripcion = CONCAT(descripcion, 'Monto Total cambió de ', OLD.monto_total, ' a ', NEW.monto_total, '. ');
    END IF;

    INSERT INTO `Historial_Compras` (`id_compra`, `tipo_accion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`)
    VALUES (NEW.id_compra, 'UPDATE', USER(), ip_origen, descripcion);
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `configuracion_interfaz`
--

CREATE TABLE `configuracion_interfaz` (
  `id_configuracion` int(11) NOT NULL,
  `id_usuario` int(11) DEFAULT NULL,
  `tema_color` varchar(50) DEFAULT NULL,
  `tamano_fuente` varchar(10) DEFAULT NULL,
  `modo_oscuro` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `configuracion_interfaz`
--

INSERT INTO `configuracion_interfaz` (`id_configuracion`, `id_usuario`, `tema_color`, `tamano_fuente`, `modo_oscuro`) VALUES
(3, 5, NULL, 'grande', 0),
(4, 12, NULL, 'grande', 0),
(5, 3, NULL, 'grande', 0),
(6, 17, NULL, 'pequeño', 0),
(7, 1, NULL, 'pequeño', 0);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Detalle_Compras`
--

CREATE TABLE `Detalle_Compras` (
  `id_detalle` int(11) NOT NULL,
  `id_compra` int(11) DEFAULT NULL,
  `id_producto` int(11) DEFAULT NULL,
  `cantidad_comprada` int(11) DEFAULT NULL,
  `precio_unitario` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Disparadores `Detalle_Compras`
--
DELIMITER $$
CREATE TRIGGER `Detalle_Compras_after_delete` AFTER DELETE ON `Detalle_Compras` FOR EACH ROW BEGIN
    DECLARE ip_origen VARCHAR(45);
    SET ip_origen = 'IP_DEL_USUARIO';

    INSERT INTO `Historial_Detalle_Compras` (`id_detalle`, `tipo_accion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`)
    VALUES (OLD.id_detalle, 'DELETE', USER(), ip_origen,
        CONCAT('Detalle de compra eliminado: ID Compra=', OLD.id_compra, ', ID Producto=', OLD.id_producto, 
               ', Cantidad Comprada=', OLD.cantidad_comprada, ', Precio Unitario=', OLD.precio_unitario));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `Detalle_Compras_after_insert` AFTER INSERT ON `Detalle_Compras` FOR EACH ROW BEGIN
    DECLARE ip_origen VARCHAR(45);
    SET ip_origen = 'IP_DEL_USUARIO';

    INSERT INTO `Historial_Detalle_Compras` (`id_detalle`, `tipo_accion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`)
    VALUES (NEW.id_detalle, 'INSERT', USER(), ip_origen,
        CONCAT('Nuevo detalle de compra registrado: ID Compra=', NEW.id_compra, ', ID Producto=', NEW.id_producto, 
               ', Cantidad Comprada=', NEW.cantidad_comprada, ', Precio Unitario=', NEW.precio_unitario));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `Detalle_Compras_after_update` AFTER UPDATE ON `Detalle_Compras` FOR EACH ROW BEGIN
    DECLARE ip_origen VARCHAR(45);
    DECLARE descripcion TEXT;
    SET ip_origen = 'IP_DEL_USUARIO';

    SET descripcion = '';

    IF OLD.id_compra <> NEW.id_compra THEN
        SET descripcion = CONCAT(descripcion, 'ID Compra cambió de ', OLD.id_compra, ' a ', NEW.id_compra, '. ');
    END IF;

    IF OLD.id_producto <> NEW.id_producto THEN
        SET descripcion = CONCAT(descripcion, 'ID Producto cambió de ', OLD.id_producto, ' a ', NEW.id_producto, '. ');
    END IF;

    IF OLD.cantidad_comprada <> NEW.cantidad_comprada THEN
        SET descripcion = CONCAT(descripcion, 'Cantidad Comprada cambió de ', OLD.cantidad_comprada, ' a ', NEW.cantidad_comprada, '. ');
    END IF;

    IF OLD.precio_unitario <> NEW.precio_unitario THEN
        SET descripcion = CONCAT(descripcion, 'Precio Unitario cambió de ', OLD.precio_unitario, ' a ', NEW.precio_unitario, '. ');
    END IF;

    INSERT INTO `Historial_Detalle_Compras` (`id_detalle`, `tipo_accion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`)
    VALUES (NEW.id_detalle, 'UPDATE', USER(), ip_origen, descripcion);
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Detalle_Ventas`
--

CREATE TABLE `Detalle_Ventas` (
  `id_detalle` int(11) NOT NULL,
  `id_venta` int(11) DEFAULT NULL,
  `id_producto` int(11) DEFAULT NULL,
  `cantidad_vendida` int(11) DEFAULT NULL,
  `precio_unitario` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `Detalle_Ventas`
--

INSERT INTO `Detalle_Ventas` (`id_detalle`, `id_venta`, `id_producto`, `cantidad_vendida`, `precio_unitario`) VALUES
(11, 27, 4, 1, 15.00),
(12, 28, 4, 1, 15.00),
(18, 34, 13, 10, 2.00),
(19, 35, 4, 2, 1.00),
(20, 36, 4, 3, 0.33);

--
-- Disparadores `Detalle_Ventas`
--
DELIMITER $$
CREATE TRIGGER `Detalle_Ventas_after_delete` AFTER DELETE ON `Detalle_Ventas` FOR EACH ROW BEGIN
    DECLARE ip_origen VARCHAR(45);
    SET ip_origen = 'IP_DEL_USUARIO';

    INSERT INTO `Historial_Detalle_Ventas` (`id_detalle`, `tipo_accion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`)
    VALUES (OLD.id_detalle, 'DELETE', USER(), ip_origen,
        CONCAT('Detalle de venta eliminado: ID Venta=', OLD.id_venta, ', ID Producto=', OLD.id_producto, 
               ', Cantidad Vendida=', OLD.cantidad_vendida, ', Precio Unitario=', OLD.precio_unitario));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `Detalle_Ventas_after_insert` AFTER INSERT ON `Detalle_Ventas` FOR EACH ROW BEGIN
    DECLARE ip_origen VARCHAR(45);
    SET ip_origen = 'IP_DEL_USUARIO';

    INSERT INTO `Historial_Detalle_Ventas` (`id_detalle`, `tipo_accion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`)
    VALUES (NEW.id_detalle, 'INSERT', USER(), ip_origen,
        CONCAT('Nuevo detalle de venta registrado: ID Venta=', NEW.id_venta, ', ID Producto=', NEW.id_producto, 
               ', Cantidad Vendida=', NEW.cantidad_vendida, ', Precio Unitario=', NEW.precio_unitario));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `Detalle_Ventas_after_update` AFTER UPDATE ON `Detalle_Ventas` FOR EACH ROW BEGIN
    DECLARE ip_origen VARCHAR(45);
    DECLARE descripcion TEXT;
    SET ip_origen = 'IP_DEL_USUARIO';

    SET descripcion = '';

    IF OLD.id_venta <> NEW.id_venta THEN
        SET descripcion = CONCAT(descripcion, 'ID Venta cambió de ', OLD.id_venta, ' a ', NEW.id_venta, '. ');
    END IF;

    IF OLD.id_producto <> NEW.id_producto THEN
        SET descripcion = CONCAT(descripcion, 'ID Producto cambió de ', OLD.id_producto, ' a ', NEW.id_producto, '. ');
    END IF;

    IF OLD.cantidad_vendida <> NEW.cantidad_vendida THEN
        SET descripcion = CONCAT(descripcion, 'Cantidad Vendida cambió de ', OLD.cantidad_vendida, ' a ', NEW.cantidad_vendida, '. ');
    END IF;

    IF OLD.precio_unitario <> NEW.precio_unitario THEN
        SET descripcion = CONCAT(descripcion, 'Precio Unitario cambió de ', OLD.precio_unitario, ' a ', NEW.precio_unitario, '. ');
    END IF;

    INSERT INTO `Historial_Detalle_Ventas` (`id_detalle`, `tipo_accion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`)
    VALUES (NEW.id_detalle, 'UPDATE', USER(), ip_origen, descripcion);
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `before_insert_venta` BEFORE INSERT ON `Detalle_Ventas` FOR EACH ROW BEGIN
    DECLARE stock_disponible INT;

    
    SELECT cantidad_disponible INTO stock_disponible
    FROM Inventario
    WHERE id_producto = NEW.id_producto;

    IF stock_disponible IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El producto especificado no existe en el inventario.';
    ELSEIF stock_disponible < NEW.cantidad_vendida THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Stock insuficiente en inventario para completar la venta.';
    ELSE
        
        UPDATE Inventario
        SET cantidad_disponible = cantidad_disponible - NEW.cantidad_vendida
        WHERE id_producto = NEW.id_producto;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Documentos`
--

CREATE TABLE `Documentos` (
  `id_documento` int(11) NOT NULL,
  `tipo_documento` varchar(50) NOT NULL,
  `descripcion` text NOT NULL,
  `fecha_creacion` date NOT NULL,
  `version` varchar(20) NOT NULL,
  `usuario_subio` varchar(50) NOT NULL,
  `nombre_archivo` varchar(255) NOT NULL,
  `ruta_archivo` varchar(255) NOT NULL,
  `fecha_subida` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `Documentos`
--

INSERT INTO `Documentos` (`id_documento`, `tipo_documento`, `descripcion`, `fecha_creacion`, `version`, `usuario_subio`, `nombre_archivo`, `ruta_archivo`, `fecha_subida`) VALUES
(1, 'Lista de Viniles', 'Viniles', '2024-11-11', '1', '5', 'bd.txt', 'uploads/bd.txt', '2024-11-11 11:05:12'),
(2, 'Lista de Tintas', 'Tintas', '2024-11-11', '3', '5', 'bd.txt', 'uploads/bd.txt', '2024-11-11 11:07:36'),
(3, 'Informe del mes de Marzo', 'documento', '2024-11-11', '2', '5', 'informe_venta.txt', 'uploads/informe_venta.txt', '2024-11-11 11:08:33'),
(4, 'Informe de compras ', 'Compras', '2024-11-11', '2', '5', 'informe_venta.txt', 'uploads/informe_venta.txt', '2024-11-11 11:45:45'),
(5, 'Informe', 'informe de gerencia', '2024-11-11', '1.1', '12', 'informe_venta.txt', 'uploads/informe_venta.txt', '2024-11-11 13:58:41'),
(6, 'Pruebas', 'Prueba Subir Documento', '2025-02-06', '1', '1', '05_PT1_ES1822022193_MagañaLopezLimberNicanor_PropuestaDeProyecto (1).xlsx', 'uploads/05_PT1_ES1822022193_MagañaLopezLimberNicanor_PropuestaDeProyecto (1).xlsx', '2025-02-06 19:29:31');

--
-- Disparadores `Documentos`
--
DELIMITER $$
CREATE TRIGGER `after_Documentos_delete` AFTER DELETE ON `Documentos` FOR EACH ROW BEGIN
    INSERT INTO Historial_Documentos (id_documento, tipo_accion, usuario_modifico, ip_origen, descripcion_cambio)
    VALUES (OLD.id_documento, 'DELETE', @current_user, @current_ip, CONCAT('Documento eliminado: ', OLD.descripcion));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `after_Documentos_insert` AFTER INSERT ON `Documentos` FOR EACH ROW BEGIN
    INSERT INTO Historial_Documentos (id_documento, tipo_accion, usuario_modifico, ip_origen, descripcion_cambio)
    VALUES (NEW.id_documento, 'INSERT', @current_user, @current_ip, CONCAT('Documento creado: ', NEW.descripcion));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `after_Documentos_update` AFTER UPDATE ON `Documentos` FOR EACH ROW BEGIN
    INSERT INTO Historial_Documentos (id_documento, tipo_accion, usuario_modifico, ip_origen, descripcion_cambio)
    VALUES (NEW.id_documento, 'UPDATE', @current_user, @current_ip, CONCAT('Documento actualizado: ', NEW.descripcion));
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Documentos_Registros`
--

CREATE TABLE `Documentos_Registros` (
  `id` int(11) NOT NULL,
  `id_documento` int(11) NOT NULL,
  `tabla` varchar(50) NOT NULL,
  `registro_id` int(11) NOT NULL,
  `fecha_adjuncion` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `Documentos_Registros`
--

INSERT INTO `Documentos_Registros` (`id`, `id_documento`, `tabla`, `registro_id`, `fecha_adjuncion`) VALUES
(1, 3, 'Ventas', 1010, '2024-11-11 11:45:01'),
(2, 4, 'Inventario', 1010, '2024-11-11 11:58:45');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Entradas_Inventario`
--

CREATE TABLE `Entradas_Inventario` (
  `id_entrada` int(11) NOT NULL,
  `id_producto` int(11) DEFAULT NULL,
  `cantidad_entrada` int(11) DEFAULT NULL,
  `fecha_entrada` datetime DEFAULT NULL,
  `usuario_registro` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Disparadores `Entradas_Inventario`
--
DELIMITER $$
CREATE TRIGGER `Entradas_Inventario_after_delete` AFTER DELETE ON `Entradas_Inventario` FOR EACH ROW BEGIN
    DECLARE ip_origen VARCHAR(45);
    SET ip_origen = 'IP_DEL_USUARIO';

    INSERT INTO `Historial_Entradas_Inventario` (`id_entrada`, `tipo_accion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`)
    VALUES (OLD.id_entrada, 'DELETE', USER(), ip_origen,
        CONCAT('Entrada de inventario eliminada: ID Producto=', OLD.id_producto, ', Cantidad=', OLD.cantidad_entrada, ', Fecha=', OLD.fecha_entrada));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `Entradas_Inventario_after_insert` AFTER INSERT ON `Entradas_Inventario` FOR EACH ROW BEGIN
    DECLARE ip_origen VARCHAR(45);
    SET ip_origen = 'IP_DEL_USUARIO';

    INSERT INTO `Historial_Entradas_Inventario` (`id_entrada`, `tipo_accion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`)
    VALUES (NEW.id_entrada, 'INSERT', USER(), ip_origen,
        CONCAT('Nueva entrada de inventario: ID Producto=', NEW.id_producto, ', Cantidad=', NEW.cantidad_entrada, ', Fecha=', NEW.fecha_entrada));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `Entradas_Inventario_after_update` AFTER UPDATE ON `Entradas_Inventario` FOR EACH ROW BEGIN
    DECLARE ip_origen VARCHAR(45);
    DECLARE descripcion TEXT;
    SET ip_origen = 'IP_DEL_USUARIO';

    SET descripcion = '';

    IF OLD.id_producto <> NEW.id_producto THEN
        SET descripcion = CONCAT(descripcion, 'ID Producto cambió de ', OLD.id_producto, ' a ', NEW.id_producto, '. ');
    END IF;

    IF OLD.cantidad_entrada <> NEW.cantidad_entrada THEN
        SET descripcion = CONCAT(descripcion, 'Cantidad cambió de ', OLD.cantidad_entrada, ' a ', NEW.cantidad_entrada, '. ');
    END IF;

    IF OLD.fecha_entrada <> NEW.fecha_entrada THEN
        SET descripcion = CONCAT(descripcion, 'Fecha Entrada cambió de ', OLD.fecha_entrada, ' a ', NEW.fecha_entrada, '. ');
    END IF;

    INSERT INTO `Historial_Entradas_Inventario` (`id_entrada`, `tipo_accion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`)
    VALUES (NEW.id_entrada, 'UPDATE', USER(), ip_origen, descripcion);
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Historial_Compras`
--

CREATE TABLE `Historial_Compras` (
  `id_historial` int(11) NOT NULL,
  `id_compra` int(11) NOT NULL,
  `tipo_accion` enum('INSERT','UPDATE','DELETE') NOT NULL,
  `fecha_modificacion` datetime DEFAULT current_timestamp(),
  `usuario_modifico` varchar(100) DEFAULT NULL,
  `ip_origen` varchar(45) DEFAULT NULL,
  `descripcion_cambio` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `Historial_Compras`
--

INSERT INTO `Historial_Compras` (`id_historial`, `id_compra`, `tipo_accion`, `fecha_modificacion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`) VALUES
(1, 2, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nueva compra registrada: ID Proveedor=1, Fecha Compra=2024-01-02 10:00:00, Monto Total=1200.00'),
(2, 3, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nueva compra registrada: ID Proveedor=2, Fecha Compra=2024-01-03 11:15:00, Monto Total=1500.75'),
(3, 4, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nueva compra registrada: ID Proveedor=3, Fecha Compra=2024-01-04 09:30:00, Monto Total=800.50'),
(4, 5, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nueva compra registrada: ID Proveedor=4, Fecha Compra=2024-01-05 14:20:00, Monto Total=950.40'),
(5, 6, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nueva compra registrada: ID Proveedor=5, Fecha Compra=2024-01-06 08:45:00, Monto Total=700.25'),
(6, 7, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nueva compra registrada: ID Proveedor=1, Fecha Compra=2024-01-07 13:10:00, Monto Total=1025.00'),
(7, 8, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nueva compra registrada: ID Proveedor=2, Fecha Compra=2024-01-08 16:05:00, Monto Total=1150.60'),
(8, 9, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nueva compra registrada: ID Proveedor=3, Fecha Compra=2024-01-09 12:25:00, Monto Total=1300.80'),
(9, 10, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nueva compra registrada: ID Proveedor=4, Fecha Compra=2024-01-10 11:00:00, Monto Total=1450.50'),
(10, 11, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nueva compra registrada: ID Proveedor=5, Fecha Compra=2024-01-11 15:45:00, Monto Total=1100.20'),
(11, 1, 'DELETE', '2024-11-11 08:28:41', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Compra eliminada: ID Proveedor=1, Fecha Compra=2024-11-11 04:49:26, Monto Total=1000.00'),
(12, 2, 'DELETE', '2024-11-11 08:28:41', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Compra eliminada: ID Proveedor=1, Fecha Compra=2024-01-02 10:00:00, Monto Total=1200.00'),
(13, 3, 'DELETE', '2024-11-11 08:28:41', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Compra eliminada: ID Proveedor=2, Fecha Compra=2024-01-03 11:15:00, Monto Total=1500.75'),
(14, 4, 'DELETE', '2024-11-11 08:28:41', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Compra eliminada: ID Proveedor=3, Fecha Compra=2024-01-04 09:30:00, Monto Total=800.50'),
(15, 5, 'DELETE', '2024-11-11 08:28:41', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Compra eliminada: ID Proveedor=4, Fecha Compra=2024-01-05 14:20:00, Monto Total=950.40'),
(16, 6, 'DELETE', '2024-11-11 08:28:41', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Compra eliminada: ID Proveedor=5, Fecha Compra=2024-01-06 08:45:00, Monto Total=700.25'),
(17, 7, 'DELETE', '2024-11-11 08:28:41', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Compra eliminada: ID Proveedor=1, Fecha Compra=2024-01-07 13:10:00, Monto Total=1025.00'),
(18, 8, 'DELETE', '2024-11-11 08:28:41', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Compra eliminada: ID Proveedor=2, Fecha Compra=2024-01-08 16:05:00, Monto Total=1150.60'),
(19, 9, 'DELETE', '2024-11-11 08:28:41', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Compra eliminada: ID Proveedor=3, Fecha Compra=2024-01-09 12:25:00, Monto Total=1300.80'),
(20, 10, 'DELETE', '2024-11-11 08:28:41', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Compra eliminada: ID Proveedor=4, Fecha Compra=2024-01-10 11:00:00, Monto Total=1450.50'),
(21, 11, 'DELETE', '2024-11-11 08:28:41', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Compra eliminada: ID Proveedor=5, Fecha Compra=2024-01-11 15:45:00, Monto Total=1100.20'),
(22, 12, 'INSERT', '2024-11-11 08:41:40', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nueva compra registrada: ID Proveedor=6, Fecha Compra=2024-11-11 08:41:40, Monto Total=150.00'),
(23, 12, 'UPDATE', '2024-11-11 08:48:33', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(24, 13, 'INSERT', '2024-11-11 08:48:47', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nueva compra registrada: ID Proveedor=6, Fecha Compra=2024-11-11 08:48:47, Monto Total=1500.00'),
(25, 14, 'INSERT', '2024-11-11 08:49:55', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nueva compra registrada: ID Proveedor=6, Fecha Compra=2024-11-11 08:49:55, Monto Total=1200.00'),
(26, 15, 'INSERT', '2024-11-11 08:50:33', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nueva compra registrada: ID Proveedor=7, Fecha Compra=2024-11-11 08:50:33, Monto Total=1517.00'),
(27, 15, 'UPDATE', '2024-11-11 09:54:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(28, 15, 'UPDATE', '2024-11-11 10:00:16', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Monto Total cambió de 1517.00 a 16000.00. '),
(29, 15, 'UPDATE', '2024-11-11 10:08:15', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(30, 15, 'DELETE', '2024-11-11 10:08:15', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Compra eliminada: ID Proveedor=7, Fecha Compra=2024-11-11 08:50:33, Monto Total=16000.00'),
(31, 14, 'UPDATE', '2024-11-11 10:08:24', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(32, 14, 'DELETE', '2024-11-11 10:08:24', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Compra eliminada: ID Proveedor=6, Fecha Compra=2024-11-11 08:49:55, Monto Total=1200.00'),
(33, 16, 'INSERT', '2024-11-11 13:49:46', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nueva compra registrada: ID Proveedor=8, Fecha Compra=2024-11-11 13:49:46, Monto Total=800.00'),
(34, 17, 'INSERT', '2024-11-11 13:51:19', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nueva compra registrada: ID Proveedor=7, Fecha Compra=2024-11-11 13:51:19, Monto Total=650.00'),
(35, 12, 'DELETE', '2024-11-11 15:19:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Compra eliminada: ID Proveedor=6, Fecha Compra=2024-11-11 08:41:40, Monto Total=150.00'),
(36, 13, 'UPDATE', '2024-11-11 20:19:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(37, 13, 'UPDATE', '2024-11-11 20:19:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(38, 13, 'DELETE', '2024-11-11 21:31:48', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Compra eliminada: ID Proveedor=6, Fecha Compra=2024-11-11 08:48:47, Monto Total=1500.00'),
(39, 18, 'INSERT', '2024-11-12 03:20:35', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nueva compra registrada: ID Proveedor=9, Fecha Compra=2024-11-12 03:20:35, Monto Total=3000.00'),
(40, 16, 'DELETE', '2024-11-15 08:31:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Compra eliminada: ID Proveedor=8, Fecha Compra=2024-11-11 13:49:46, Monto Total=800.00'),
(41, 17, 'DELETE', '2024-11-15 08:31:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Compra eliminada: ID Proveedor=7, Fecha Compra=2024-11-11 13:51:19, Monto Total=650.00'),
(42, 18, 'DELETE', '2024-11-15 08:31:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Compra eliminada: ID Proveedor=9, Fecha Compra=2024-11-12 03:20:35, Monto Total=3000.00'),
(43, 19, 'INSERT', '2024-11-29 04:45:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nueva compra registrada: ID Proveedor=824, Fecha Compra=2024-11-29 04:45:23, Monto Total=0.17'),
(44, 20, 'INSERT', '2025-02-06 12:15:29', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nueva compra registrada: ID Proveedor=826, Fecha Compra=2025-02-06 12:15:29, Monto Total=150000.00');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Historial_Detalle_Compras`
--

CREATE TABLE `Historial_Detalle_Compras` (
  `id_historial` int(11) NOT NULL,
  `id_detalle` int(11) NOT NULL,
  `tipo_accion` enum('INSERT','UPDATE','DELETE') NOT NULL,
  `fecha_modificacion` datetime DEFAULT current_timestamp(),
  `usuario_modifico` varchar(100) DEFAULT NULL,
  `ip_origen` varchar(45) DEFAULT NULL,
  `descripcion_cambio` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `Historial_Detalle_Compras`
--

INSERT INTO `Historial_Detalle_Compras` (`id_historial`, `id_detalle`, `tipo_accion`, `fecha_modificacion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`) VALUES
(1, 1, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de compra registrado: ID Compra=2, ID Producto=2, Cantidad Comprada=10, Precio Unitario=50.00'),
(2, 2, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de compra registrado: ID Compra=3, ID Producto=3, Cantidad Comprada=20, Precio Unitario=45.00'),
(3, 3, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de compra registrado: ID Compra=4, ID Producto=2, Cantidad Comprada=15, Precio Unitario=53.25'),
(4, 4, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de compra registrado: ID Compra=5, ID Producto=3, Cantidad Comprada=18, Precio Unitario=40.50'),
(5, 5, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de compra registrado: ID Compra=6, ID Producto=2, Cantidad Comprada=12, Precio Unitario=47.75'),
(6, 6, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de compra registrado: ID Compra=7, ID Producto=2, Cantidad Comprada=14, Precio Unitario=55.00'),
(7, 7, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de compra registrado: ID Compra=8, ID Producto=3, Cantidad Comprada=25, Precio Unitario=44.60'),
(8, 8, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de compra registrado: ID Compra=9, ID Producto=3, Cantidad Comprada=30, Precio Unitario=48.90'),
(9, 9, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de compra registrado: ID Compra=10, ID Producto=2, Cantidad Comprada=17, Precio Unitario=51.75'),
(10, 10, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de compra registrado: ID Compra=11, ID Producto=3, Cantidad Comprada=22, Precio Unitario=49.80'),
(11, 1, 'DELETE', '2024-11-11 08:28:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Detalle de compra eliminado: ID Compra=2, ID Producto=2, Cantidad Comprada=10, Precio Unitario=50.00'),
(12, 2, 'DELETE', '2024-11-11 08:28:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Detalle de compra eliminado: ID Compra=3, ID Producto=3, Cantidad Comprada=20, Precio Unitario=45.00'),
(13, 3, 'DELETE', '2024-11-11 08:28:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Detalle de compra eliminado: ID Compra=4, ID Producto=2, Cantidad Comprada=15, Precio Unitario=53.25'),
(14, 4, 'DELETE', '2024-11-11 08:28:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Detalle de compra eliminado: ID Compra=5, ID Producto=3, Cantidad Comprada=18, Precio Unitario=40.50'),
(15, 5, 'DELETE', '2024-11-11 08:28:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Detalle de compra eliminado: ID Compra=6, ID Producto=2, Cantidad Comprada=12, Precio Unitario=47.75'),
(16, 6, 'DELETE', '2024-11-11 08:28:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Detalle de compra eliminado: ID Compra=7, ID Producto=2, Cantidad Comprada=14, Precio Unitario=55.00'),
(17, 7, 'DELETE', '2024-11-11 08:28:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Detalle de compra eliminado: ID Compra=8, ID Producto=3, Cantidad Comprada=25, Precio Unitario=44.60'),
(18, 8, 'DELETE', '2024-11-11 08:28:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Detalle de compra eliminado: ID Compra=9, ID Producto=3, Cantidad Comprada=30, Precio Unitario=48.90'),
(19, 9, 'DELETE', '2024-11-11 08:28:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Detalle de compra eliminado: ID Compra=10, ID Producto=2, Cantidad Comprada=17, Precio Unitario=51.75'),
(20, 10, 'DELETE', '2024-11-11 08:28:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Detalle de compra eliminado: ID Compra=11, ID Producto=3, Cantidad Comprada=22, Precio Unitario=49.80');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Historial_Detalle_Ventas`
--

CREATE TABLE `Historial_Detalle_Ventas` (
  `id_historial` int(11) NOT NULL,
  `id_detalle` int(11) NOT NULL,
  `tipo_accion` enum('INSERT','UPDATE','DELETE') NOT NULL,
  `fecha_modificacion` datetime DEFAULT current_timestamp(),
  `usuario_modifico` varchar(100) DEFAULT NULL,
  `ip_origen` varchar(45) DEFAULT NULL,
  `descripcion_cambio` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `Historial_Detalle_Ventas`
--

INSERT INTO `Historial_Detalle_Ventas` (`id_historial`, `id_detalle`, `tipo_accion`, `fecha_modificacion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`) VALUES
(1, 1, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de venta registrado: ID Venta=7, ID Producto=2, Cantidad Vendida=5, Precio Unitario=60.00'),
(2, 2, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de venta registrado: ID Venta=8, ID Producto=3, Cantidad Vendida=8, Precio Unitario=55.50'),
(3, 3, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de venta registrado: ID Venta=9, ID Producto=2, Cantidad Vendida=6, Precio Unitario=63.25'),
(4, 4, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de venta registrado: ID Venta=10, ID Producto=3, Cantidad Vendida=9, Precio Unitario=58.75'),
(5, 5, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de venta registrado: ID Venta=11, ID Producto=2, Cantidad Vendida=4, Precio Unitario=59.75'),
(6, 6, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de venta registrado: ID Venta=12, ID Producto=3, Cantidad Vendida=7, Precio Unitario=60.00'),
(7, 7, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de venta registrado: ID Venta=13, ID Producto=2, Cantidad Vendida=5, Precio Unitario=65.50'),
(8, 8, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de venta registrado: ID Venta=14, ID Producto=3, Cantidad Vendida=10, Precio Unitario=64.75'),
(9, 9, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de venta registrado: ID Venta=15, ID Producto=2, Cantidad Vendida=6, Precio Unitario=62.50'),
(10, 10, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de venta registrado: ID Venta=16, ID Producto=3, Cantidad Vendida=8, Precio Unitario=57.75'),
(11, 1, 'INSERT', '2024-11-11 08:54:18', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de venta registrado: ID Venta=17, ID Producto=4, Cantidad Vendida=5, Precio Unitario=20.00'),
(12, 2, 'INSERT', '2024-11-11 08:56:40', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de venta registrado: ID Venta=18, ID Producto=4, Cantidad Vendida=5, Precio Unitario=20.00'),
(13, 3, 'INSERT', '2024-11-11 09:08:48', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de venta registrado: ID Venta=19, ID Producto=5, Cantidad Vendida=5, Precio Unitario=20.00'),
(14, 3, 'UPDATE', '2024-11-11 09:08:52', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad Vendida cambió de 5 a 8. '),
(15, 3, 'UPDATE', '2024-11-11 09:09:43', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad Vendida cambió de 8 a 5. '),
(16, 3, 'UPDATE', '2024-11-11 09:13:40', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad Vendida cambió de 5 a 8. '),
(17, 3, 'DELETE', '2024-11-11 09:13:46', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Detalle de venta eliminado: ID Venta=19, ID Producto=5, Cantidad Vendida=8, Precio Unitario=20.00'),
(18, 4, 'INSERT', '2024-11-11 13:02:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de venta registrado: ID Venta=20, ID Producto=7, Cantidad Vendida=55, Precio Unitario=909.09'),
(19, 5, 'INSERT', '2024-11-11 13:02:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de venta registrado: ID Venta=21, ID Producto=5, Cantidad Vendida=5, Precio Unitario=2000.00'),
(20, 6, 'INSERT', '2024-11-11 13:02:59', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de venta registrado: ID Venta=22, ID Producto=4, Cantidad Vendida=1, Precio Unitario=15.00'),
(21, 7, 'INSERT', '2024-11-11 13:06:30', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de venta registrado: ID Venta=23, ID Producto=4, Cantidad Vendida=1, Precio Unitario=15.00'),
(22, 8, 'INSERT', '2024-11-11 13:06:33', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de venta registrado: ID Venta=24, ID Producto=4, Cantidad Vendida=1, Precio Unitario=15.00'),
(23, 9, 'INSERT', '2024-11-11 13:06:34', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de venta registrado: ID Venta=25, ID Producto=4, Cantidad Vendida=1, Precio Unitario=15.00'),
(24, 10, 'INSERT', '2024-11-11 13:06:34', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de venta registrado: ID Venta=26, ID Producto=4, Cantidad Vendida=1, Precio Unitario=15.00'),
(25, 11, 'INSERT', '2024-11-11 13:06:47', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de venta registrado: ID Venta=27, ID Producto=4, Cantidad Vendida=1, Precio Unitario=15.00'),
(26, 12, 'INSERT', '2024-11-11 13:06:48', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de venta registrado: ID Venta=28, ID Producto=4, Cantidad Vendida=1, Precio Unitario=15.00'),
(27, 13, 'INSERT', '2024-11-11 13:06:48', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de venta registrado: ID Venta=29, ID Producto=4, Cantidad Vendida=1, Precio Unitario=15.00'),
(28, 14, 'INSERT', '2024-11-11 13:06:49', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de venta registrado: ID Venta=30, ID Producto=4, Cantidad Vendida=1, Precio Unitario=15.00'),
(29, 15, 'INSERT', '2024-11-11 13:06:49', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de venta registrado: ID Venta=31, ID Producto=4, Cantidad Vendida=1, Precio Unitario=15.00'),
(30, 16, 'INSERT', '2024-11-11 13:54:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de venta registrado: ID Venta=32, ID Producto=9, Cantidad Vendida=43, Precio Unitario=6.67'),
(31, 4, 'DELETE', '2024-11-11 13:54:34', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Detalle de venta eliminado: ID Venta=20, ID Producto=7, Cantidad Vendida=55, Precio Unitario=909.09'),
(32, 5, 'DELETE', '2024-11-11 13:54:40', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Detalle de venta eliminado: ID Venta=21, ID Producto=5, Cantidad Vendida=5, Precio Unitario=2000.00'),
(33, 16, 'DELETE', '2024-11-11 15:41:14', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Detalle de venta eliminado: ID Venta=32, ID Producto=9, Cantidad Vendida=43, Precio Unitario=6.67'),
(34, 15, 'DELETE', '2024-11-11 15:41:21', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Detalle de venta eliminado: ID Venta=31, ID Producto=4, Cantidad Vendida=1, Precio Unitario=15.00'),
(35, 14, 'DELETE', '2024-11-11 15:41:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Detalle de venta eliminado: ID Venta=30, ID Producto=4, Cantidad Vendida=1, Precio Unitario=15.00'),
(36, 17, 'INSERT', '2024-11-11 15:58:33', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de venta registrado: ID Venta=33, ID Producto=4, Cantidad Vendida=1, Precio Unitario=20.00'),
(37, 17, 'DELETE', '2024-11-11 16:03:11', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Detalle de venta eliminado: ID Venta=33, ID Producto=4, Cantidad Vendida=1, Precio Unitario=20.00'),
(38, 6, 'DELETE', '2024-11-11 21:31:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Detalle de venta eliminado: ID Venta=22, ID Producto=4, Cantidad Vendida=1, Precio Unitario=15.00'),
(39, 13, 'DELETE', '2024-11-11 21:31:34', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Detalle de venta eliminado: ID Venta=29, ID Producto=4, Cantidad Vendida=1, Precio Unitario=15.00'),
(40, 7, 'DELETE', '2024-11-11 21:37:21', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Detalle de venta eliminado: ID Venta=23, ID Producto=4, Cantidad Vendida=1, Precio Unitario=15.00'),
(41, 8, 'DELETE', '2024-11-11 21:37:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Detalle de venta eliminado: ID Venta=24, ID Producto=4, Cantidad Vendida=1, Precio Unitario=15.00'),
(42, 9, 'DELETE', '2024-11-11 21:37:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Detalle de venta eliminado: ID Venta=25, ID Producto=4, Cantidad Vendida=1, Precio Unitario=15.00'),
(43, 10, 'DELETE', '2024-11-11 21:37:43', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Detalle de venta eliminado: ID Venta=26, ID Producto=4, Cantidad Vendida=1, Precio Unitario=15.00'),
(44, 18, 'INSERT', '2025-01-30 23:05:08', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de venta registrado: ID Venta=34, ID Producto=13, Cantidad Vendida=10, Precio Unitario=2.00'),
(45, 19, 'INSERT', '2025-01-30 23:06:37', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de venta registrado: ID Venta=35, ID Producto=4, Cantidad Vendida=2, Precio Unitario=1.00'),
(46, 20, 'INSERT', '2025-01-30 23:12:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de venta registrado: ID Venta=36, ID Producto=4, Cantidad Vendida=3, Precio Unitario=0.33'),
(47, 21, 'INSERT', '2025-01-30 23:13:11', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de venta registrado: ID Venta=37, ID Producto=8, Cantidad Vendida=90, Precio Unitario=0.01'),
(48, 22, 'INSERT', '2025-01-30 23:16:22', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo detalle de venta registrado: ID Venta=38, ID Producto=9, Cantidad Vendida=20, Precio Unitario=-0.05'),
(49, 22, 'DELETE', '2025-01-30 23:25:49', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Detalle de venta eliminado: ID Venta=38, ID Producto=9, Cantidad Vendida=20, Precio Unitario=-0.05'),
(50, 21, 'DELETE', '2025-01-30 23:26:17', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Detalle de venta eliminado: ID Venta=37, ID Producto=8, Cantidad Vendida=90, Precio Unitario=0.01');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Historial_Documentos`
--

CREATE TABLE `Historial_Documentos` (
  `id_historial` int(11) NOT NULL,
  `id_documento` int(11) NOT NULL,
  `tipo_accion` enum('INSERT','UPDATE','DELETE') NOT NULL,
  `fecha_modificacion` timestamp NULL DEFAULT current_timestamp(),
  `usuario_modifico` varchar(50) NOT NULL,
  `ip_origen` varchar(45) NOT NULL,
  `descripcion_cambio` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `Historial_Documentos`
--

INSERT INTO `Historial_Documentos` (`id_historial`, `id_documento`, `tipo_accion`, `fecha_modificacion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`) VALUES
(1, 1, 'INSERT', '2024-11-11 11:05:12', '5', '2800:484:4b72:df50::3605', 'Documento creado: sdfg'),
(2, 2, 'INSERT', '2024-11-11 11:07:36', '5', '2800:484:4b72:df50::3605', 'Documento creado: dfsgdsg'),
(3, 3, 'INSERT', '2024-11-11 11:08:33', '5', '2800:484:4b72:df50::3605', 'Documento creado: dsfgsdf'),
(4, 4, 'INSERT', '2024-11-11 11:45:45', '5', '2800:484:4b72:df50::3605', 'Documento creado: dfsgdfs'),
(5, 4, 'UPDATE', '2024-11-11 11:47:32', '5', '2800:484:4b72:df50::3605', 'Documento actualizado: dfsgdfs'),
(6, 4, 'UPDATE', '2024-11-11 11:58:59', '5', '2800:484:4b72:df50::3605', 'Documento actualizado: TESTER'),
(7, 3, 'UPDATE', '2024-11-11 13:57:43', '12', '2800:484:4b72:df50::3605', 'Documento actualizado: documento'),
(8, 5, 'INSERT', '2024-11-11 13:58:41', '12', '2800:484:4b72:df50::3605', 'Documento creado: informe de gerencia'),
(10, 6, 'INSERT', '2025-02-06 19:29:31', '1', '2800:484:4b72:df50::30ef', 'Documento creado: Prueba Subir Documento'),
(21, 1, 'UPDATE', '2025-04-07 00:41:40', '17', '45.171.157.122', 'Documento actualizado: sdfg'),
(22, 2, 'UPDATE', '2025-04-07 00:42:13', '17', '45.171.157.122', 'Documento actualizado: Tintas'),
(23, 2, 'UPDATE', '2025-04-07 00:42:28', '17', '45.171.157.122', 'Documento actualizado: Tintas'),
(24, 3, 'UPDATE', '2025-04-07 00:42:50', '17', '45.171.157.122', 'Documento actualizado: documento'),
(25, 1, 'UPDATE', '2025-04-07 00:43:05', '17', '45.171.157.122', 'Documento actualizado: Viniles'),
(26, 4, 'UPDATE', '2025-04-07 00:43:42', '17', '45.171.157.122', 'Documento actualizado: Compras'),
(27, 3, 'UPDATE', '2025-04-07 00:43:55', '17', '45.171.157.122', 'Documento actualizado: documento'),
(28, 5, 'UPDATE', '2025-04-07 00:44:05', '17', '45.171.157.122', 'Documento actualizado: informe de gerencia');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Historial_Entradas_Inventario`
--

CREATE TABLE `Historial_Entradas_Inventario` (
  `id_historial` int(11) NOT NULL,
  `id_entrada` int(11) NOT NULL,
  `tipo_accion` enum('INSERT','UPDATE','DELETE') NOT NULL,
  `fecha_modificacion` datetime DEFAULT current_timestamp(),
  `usuario_modifico` varchar(100) DEFAULT NULL,
  `ip_origen` varchar(45) DEFAULT NULL,
  `descripcion_cambio` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `Historial_Entradas_Inventario`
--

INSERT INTO `Historial_Entradas_Inventario` (`id_historial`, `id_entrada`, `tipo_accion`, `fecha_modificacion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`) VALUES
(1, 1, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nueva entrada de inventario: ID Producto=2, Cantidad=20, Fecha=2024-01-02 08:30:00'),
(2, 2, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nueva entrada de inventario: ID Producto=3, Cantidad=25, Fecha=2024-01-03 09:15:00'),
(3, 3, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nueva entrada de inventario: ID Producto=2, Cantidad=15, Fecha=2024-01-04 11:00:00'),
(4, 4, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nueva entrada de inventario: ID Producto=3, Cantidad=30, Fecha=2024-01-05 10:45:00'),
(5, 5, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nueva entrada de inventario: ID Producto=2, Cantidad=18, Fecha=2024-01-06 13:30:00'),
(6, 6, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nueva entrada de inventario: ID Producto=3, Cantidad=20, Fecha=2024-01-07 12:20:00'),
(7, 7, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nueva entrada de inventario: ID Producto=2, Cantidad=22, Fecha=2024-01-08 14:15:00'),
(8, 8, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nueva entrada de inventario: ID Producto=3, Cantidad=27, Fecha=2024-01-09 15:00:00'),
(9, 9, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nueva entrada de inventario: ID Producto=2, Cantidad=19, Fecha=2024-01-10 09:40:00'),
(10, 10, 'INSERT', '2024-11-11 08:01:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nueva entrada de inventario: ID Producto=3, Cantidad=23, Fecha=2024-01-11 11:30:00'),
(11, 1, 'DELETE', '2024-11-11 08:27:56', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Entrada de inventario eliminada: ID Producto=2, Cantidad=20, Fecha=2024-01-02 08:30:00'),
(12, 2, 'DELETE', '2024-11-11 08:27:56', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Entrada de inventario eliminada: ID Producto=3, Cantidad=25, Fecha=2024-01-03 09:15:00'),
(13, 3, 'DELETE', '2024-11-11 08:27:56', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Entrada de inventario eliminada: ID Producto=2, Cantidad=15, Fecha=2024-01-04 11:00:00'),
(14, 4, 'DELETE', '2024-11-11 08:27:56', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Entrada de inventario eliminada: ID Producto=3, Cantidad=30, Fecha=2024-01-05 10:45:00'),
(15, 5, 'DELETE', '2024-11-11 08:27:56', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Entrada de inventario eliminada: ID Producto=2, Cantidad=18, Fecha=2024-01-06 13:30:00'),
(16, 6, 'DELETE', '2024-11-11 08:27:56', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Entrada de inventario eliminada: ID Producto=3, Cantidad=20, Fecha=2024-01-07 12:20:00'),
(17, 7, 'DELETE', '2024-11-11 08:27:56', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Entrada de inventario eliminada: ID Producto=2, Cantidad=22, Fecha=2024-01-08 14:15:00'),
(18, 8, 'DELETE', '2024-11-11 08:27:56', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Entrada de inventario eliminada: ID Producto=3, Cantidad=27, Fecha=2024-01-09 15:00:00'),
(19, 9, 'DELETE', '2024-11-11 08:27:56', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Entrada de inventario eliminada: ID Producto=2, Cantidad=19, Fecha=2024-01-10 09:40:00'),
(20, 10, 'DELETE', '2024-11-11 08:27:56', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Entrada de inventario eliminada: ID Producto=3, Cantidad=23, Fecha=2024-01-11 11:30:00');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Historial_Inventario`
--

CREATE TABLE `Historial_Inventario` (
  `id_historial` int(11) NOT NULL,
  `id_producto` int(11) NOT NULL,
  `tipo_accion` enum('INSERT','UPDATE','DELETE') NOT NULL,
  `fecha_modificacion` datetime DEFAULT current_timestamp(),
  `usuario_modifico` varchar(100) DEFAULT NULL,
  `ip_origen` varchar(45) DEFAULT NULL,
  `descripcion_cambio` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `Historial_Inventario`
--

INSERT INTO `Historial_Inventario` (`id_historial`, `id_producto`, `tipo_accion`, `fecha_modificacion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`) VALUES
(1, 2, 'DELETE', '2024-11-11 08:29:18', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Producto eliminado: Nombre=test, Cantidad=10, Stock mínimo=100'),
(2, 3, 'DELETE', '2024-11-11 08:29:18', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Producto eliminado: Nombre=tester, Cantidad=10, Stock mínimo=100'),
(3, 4, 'INSERT', '2024-11-11 08:48:47', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo producto en inventario: Nombre=Pan, Cantidad=20, Stock mínimo=10'),
(4, 5, 'INSERT', '2024-11-11 08:49:55', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo producto en inventario: Nombre=Tomate, Cantidad=20, Stock mínimo=10'),
(5, 5, 'UPDATE', '2024-11-11 08:50:33', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 20 a 50. '),
(6, 4, 'UPDATE', '2024-11-11 08:54:18', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 20 a 15. '),
(7, 4, 'UPDATE', '2024-11-11 08:54:18', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 15 a 10. '),
(8, 4, 'UPDATE', '2024-11-11 08:56:40', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 10 a 5. '),
(9, 4, 'UPDATE', '2024-11-11 08:56:40', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 5 a 0. '),
(10, 5, 'UPDATE', '2024-11-11 09:08:48', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 50 a 45. '),
(11, 5, 'UPDATE', '2024-11-11 09:08:48', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 45 a 40. '),
(12, 5, 'UPDATE', '2024-11-11 09:08:52', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 40 a 37. '),
(13, 5, 'UPDATE', '2024-11-11 09:09:43', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 37 a 40. '),
(14, 5, 'UPDATE', '2024-11-11 09:13:40', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 40 a 37. '),
(15, 5, 'UPDATE', '2024-11-11 09:13:46', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 37 a 45. '),
(16, 7, 'INSERT', '2024-11-11 09:18:11', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo producto en inventario: Nombre=arepa, Cantidad=150, Stock mínimo=40'),
(17, 7, 'UPDATE', '2024-11-11 09:18:17', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 150 a 155. '),
(18, 4, 'UPDATE', '2024-11-11 12:50:40', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 0 a 20. Stock mínimo cambió de 10 a 5. '),
(19, 7, 'UPDATE', '2024-11-11 13:02:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 155 a 100. '),
(20, 7, 'UPDATE', '2024-11-11 13:02:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 100 a 45. '),
(21, 5, 'UPDATE', '2024-11-11 13:02:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 45 a 40. '),
(22, 5, 'UPDATE', '2024-11-11 13:02:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 40 a 35. '),
(23, 4, 'UPDATE', '2024-11-11 13:02:59', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 20 a 19. '),
(24, 4, 'UPDATE', '2024-11-11 13:02:59', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 19 a 18. '),
(25, 4, 'UPDATE', '2024-11-11 13:06:30', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 18 a 17. '),
(26, 4, 'UPDATE', '2024-11-11 13:06:30', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 17 a 16. '),
(27, 4, 'UPDATE', '2024-11-11 13:06:33', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 16 a 15. '),
(28, 4, 'UPDATE', '2024-11-11 13:06:33', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 15 a 14. '),
(29, 4, 'UPDATE', '2024-11-11 13:06:34', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 14 a 13. '),
(30, 4, 'UPDATE', '2024-11-11 13:06:34', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 13 a 12. '),
(31, 4, 'UPDATE', '2024-11-11 13:06:34', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 12 a 11. '),
(32, 4, 'UPDATE', '2024-11-11 13:06:34', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 11 a 10. '),
(33, 4, 'UPDATE', '2024-11-11 13:06:47', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 10 a 9. '),
(34, 4, 'UPDATE', '2024-11-11 13:06:47', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 9 a 8. '),
(35, 4, 'UPDATE', '2024-11-11 13:06:48', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 8 a 7. '),
(36, 4, 'UPDATE', '2024-11-11 13:06:48', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 7 a 6. '),
(37, 4, 'UPDATE', '2024-11-11 13:06:48', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 6 a 5. '),
(38, 4, 'UPDATE', '2024-11-11 13:06:48', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 5 a 4. '),
(39, 4, 'UPDATE', '2024-11-11 13:06:49', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 4 a 3. '),
(40, 4, 'UPDATE', '2024-11-11 13:06:49', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 3 a 2. '),
(41, 4, 'UPDATE', '2024-11-11 13:06:49', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 2 a 1. '),
(42, 4, 'UPDATE', '2024-11-11 13:06:49', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 1 a 0. '),
(43, 8, 'INSERT', '2024-11-11 13:49:46', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo producto en inventario: Nombre=vinil, Cantidad=30, Stock mínimo=10'),
(44, 8, 'UPDATE', '2024-11-11 13:51:19', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 30 a 55. '),
(45, 9, 'INSERT', '2024-11-11 13:53:18', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo producto en inventario: Nombre=textiles, Cantidad=100, Stock mínimo=10'),
(46, 9, 'UPDATE', '2024-11-11 13:53:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nombre cambió de textiles a textiles test. '),
(47, 9, 'UPDATE', '2024-11-11 13:53:32', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nombre cambió de textiles test a textiles. '),
(48, 9, 'UPDATE', '2024-11-11 13:54:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 100 a 57. '),
(49, 9, 'UPDATE', '2024-11-11 13:54:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 57 a 14. '),
(50, 7, 'UPDATE', '2024-11-11 13:54:34', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 45 a 100. '),
(51, 5, 'UPDATE', '2024-11-11 13:54:40', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 35 a 40. '),
(52, 7, 'DELETE', '2024-11-11 15:19:24', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Producto eliminado: Nombre=arepa, Cantidad=100, Stock mínimo=40'),
(53, 5, 'DELETE', '2024-11-11 15:19:29', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Producto eliminado: Nombre=Tomate, Cantidad=40, Stock mínimo=10'),
(54, 9, 'UPDATE', '2024-11-11 15:41:14', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 14 a 57. '),
(55, 4, 'UPDATE', '2024-11-11 15:41:21', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 0 a 1. '),
(56, 4, 'UPDATE', '2024-11-11 15:41:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 1 a 2. '),
(57, 10, 'INSERT', '2024-11-11 15:57:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo producto en inventario: Nombre=Ventana, Cantidad=4, Stock mínimo=2'),
(58, 4, 'UPDATE', '2024-11-11 15:58:33', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 2 a 1. '),
(59, 4, 'UPDATE', '2024-11-11 15:58:33', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 1 a 0. '),
(60, 4, 'UPDATE', '2024-11-11 16:03:11', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 0 a 1. '),
(61, 4, 'UPDATE', '2024-11-11 21:31:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 1 a 2. '),
(62, 4, 'UPDATE', '2024-11-11 21:31:34', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 2 a 3. '),
(63, 4, 'UPDATE', '2024-11-11 21:34:40', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nombre cambió de Pan a VinilAC. '),
(64, 4, 'UPDATE', '2024-11-11 21:37:21', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 3 a 4. '),
(65, 4, 'UPDATE', '2024-11-11 21:37:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 4 a 5. '),
(66, 4, 'UPDATE', '2024-11-11 21:37:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 5 a 6. '),
(67, 4, 'UPDATE', '2024-11-11 21:37:43', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 6 a 7. '),
(68, 8, 'UPDATE', '2024-11-12 03:20:35', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 55 a 85. '),
(69, 11, 'INSERT', '2024-11-29 04:43:41', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo producto en inventario: Nombre=vinil2, Cantidad=3, Stock mínimo=2'),
(70, 8, 'UPDATE', '2024-11-29 04:45:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 85 a 90. '),
(71, 12, 'INSERT', '2025-01-27 23:44:29', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo producto en inventario: Nombre=Tinta Roja, Cantidad=500, Stock mínimo=200'),
(72, 13, 'INSERT', '2025-01-30 22:16:30', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo producto en inventario: Nombre=Libretas Paper Mate, Cantidad=20, Stock mínimo=-52'),
(73, 14, 'INSERT', '2025-01-30 22:30:50', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo producto en inventario: Nombre=Tazas Hernandez, Cantidad=-25, Stock mínimo=50'),
(74, 13, 'UPDATE', '2025-01-30 23:05:08', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 20 a 10. '),
(75, 13, 'UPDATE', '2025-01-30 23:05:08', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 10 a 0. '),
(76, 4, 'UPDATE', '2025-01-30 23:06:37', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 7 a 5. '),
(77, 4, 'UPDATE', '2025-01-30 23:06:37', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 5 a 3. '),
(78, 4, 'UPDATE', '2025-01-30 23:12:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 3 a 0. '),
(79, 4, 'UPDATE', '2025-01-30 23:12:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 0 a -3. '),
(80, 8, 'UPDATE', '2025-01-30 23:13:11', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 90 a 0. '),
(81, 8, 'UPDATE', '2025-01-30 23:13:11', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 0 a -90. '),
(82, 9, 'UPDATE', '2025-01-30 23:16:22', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 57 a 37. '),
(83, 9, 'UPDATE', '2025-01-30 23:16:22', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 37 a 17. '),
(84, 9, 'UPDATE', '2025-01-30 23:25:49', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de 17 a 37. '),
(85, 8, 'UPDATE', '2025-01-30 23:26:17', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Cantidad disponible cambió de -90 a 0. '),
(86, 15, 'INSERT', '2025-02-06 12:15:29', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo producto en inventario: Nombre=Gaseosas, Cantidad=200, Stock mínimo=10'),
(87, 15, 'DELETE', '2025-04-07 00:39:55', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Producto eliminado: Nombre=Gaseosas, Cantidad=200, Stock mínimo=10');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Historial_Proveedores`
--

CREATE TABLE `Historial_Proveedores` (
  `id_historial` int(11) NOT NULL,
  `id_proveedor` int(11) NOT NULL,
  `tipo_accion` enum('INSERT','UPDATE','DELETE') NOT NULL,
  `fecha_modificacion` datetime DEFAULT current_timestamp(),
  `usuario_modifico` varchar(100) DEFAULT NULL,
  `ip_origen` varchar(45) DEFAULT NULL,
  `descripcion_cambio` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `Historial_Proveedores`
--

INSERT INTO `Historial_Proveedores` (`id_historial`, `id_proveedor`, `tipo_accion`, `fecha_modificacion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`) VALUES
(1, 1, 'DELETE', '2024-11-11 08:29:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor A, Teléfono=1234567890, Email=contactoA@proveedores.com, Dirección=Calle 1 #123'),
(2, 2, 'DELETE', '2024-11-11 08:29:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor B, Teléfono=0987654321, Email=contactoB@proveedores.com, Dirección=Calle 2 #456'),
(3, 3, 'DELETE', '2024-11-11 08:29:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor C, Teléfono=1122334455, Email=contactoC@proveedores.com, Dirección=Calle 3 #789'),
(4, 4, 'DELETE', '2024-11-11 08:29:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor D, Teléfono=5566778899, Email=contactoD@proveedores.com, Dirección=Calle 4 #101'),
(5, 5, 'DELETE', '2024-11-11 08:29:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor E, Teléfono=6677889900, Email=contactoE@proveedores.com, Dirección=Calle 5 #102'),
(6, 6, 'INSERT', '2024-11-11 08:34:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=test, Teléfono=1010, Email=test@gmail.com, Dirección=test'),
(7, 7, 'INSERT', '2024-11-11 08:50:16', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=pepe, Teléfono=12025158, Email=asdfsa@gmail.com, Dirección=dfsfgads'),
(8, 8, 'INSERT', '2024-11-11 13:48:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=juanito, Teléfono=2121212, Email=juanito@gmail.com, Dirección=dir dir'),
(9, 6, 'UPDATE', '2024-11-11 15:48:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Teléfono cambió de 1010 a 101010. '),
(10, 9, 'INSERT', '2024-11-11 21:33:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Viniles AC, Teléfono=9142234566, Email=jafsjsdfjsd|@gmail.com, Dirección=sdfsdfsdfsf'),
(11, 1, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(12, 2, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(13, 3, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(14, 4, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(15, 5, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(16, 10, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(17, 11, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(18, 12, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(19, 13, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13'),
(20, 14, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(21, 15, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(22, 16, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16'),
(23, 17, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(24, 18, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(25, 19, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(26, 20, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(27, 21, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(28, 22, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(29, 23, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(30, 24, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(31, 25, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(32, 26, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26'),
(33, 27, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27'),
(34, 28, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(35, 29, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(36, 30, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(37, 31, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(38, 32, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(39, 33, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(40, 34, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(41, 35, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(42, 36, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(43, 37, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(44, 38, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(45, 39, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39'),
(46, 40, 'INSERT', '2024-11-15 07:54:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(47, 41, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(48, 42, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(49, 43, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(50, 44, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(51, 45, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(52, 46, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 6, Teléfono=3106666, Email=contacto6, Dirección=Ciudad 6'),
(53, 47, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 7, Teléfono=3107777, Email=contacto7, Dirección=Ciudad 7'),
(54, 48, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 8, Teléfono=3108888, Email=contacto8, Dirección=Ciudad 8'),
(55, 49, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 9, Teléfono=3109999, Email=contacto9, Dirección=Ciudad 9'),
(56, 50, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(57, 51, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(58, 52, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(59, 53, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13'),
(60, 54, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(61, 55, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(62, 56, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16'),
(63, 57, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(64, 58, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(65, 59, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(66, 60, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(67, 61, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(68, 62, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(69, 63, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(70, 64, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(71, 65, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(72, 66, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26'),
(73, 67, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27'),
(74, 68, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(75, 69, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(76, 70, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(77, 71, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(78, 72, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(79, 73, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(80, 74, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(81, 75, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(82, 76, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(83, 77, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(84, 78, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(85, 79, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39'),
(86, 80, 'INSERT', '2024-11-15 07:54:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(87, 81, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(88, 82, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(89, 83, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(90, 84, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(91, 85, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(92, 86, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 6, Teléfono=3106666, Email=contacto6, Dirección=Ciudad 6'),
(93, 87, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 7, Teléfono=3107777, Email=contacto7, Dirección=Ciudad 7'),
(94, 88, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 8, Teléfono=3108888, Email=contacto8, Dirección=Ciudad 8'),
(95, 89, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 9, Teléfono=3109999, Email=contacto9, Dirección=Ciudad 9'),
(96, 90, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(97, 91, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(98, 92, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(99, 93, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13'),
(100, 94, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(101, 95, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(102, 96, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16'),
(103, 97, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(104, 98, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(105, 99, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(106, 100, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(107, 101, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(108, 102, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(109, 103, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(110, 104, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(111, 105, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(112, 106, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26'),
(113, 107, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27'),
(114, 108, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(115, 109, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(116, 110, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(117, 111, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(118, 112, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(119, 113, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(120, 114, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(121, 115, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(122, 116, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(123, 117, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(124, 118, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(125, 119, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39'),
(126, 120, 'INSERT', '2024-11-15 07:55:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(127, 121, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(128, 122, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(129, 123, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(130, 124, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(131, 125, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(132, 126, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 6, Teléfono=3106666, Email=contacto6, Dirección=Ciudad 6'),
(133, 127, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 7, Teléfono=3107777, Email=contacto7, Dirección=Ciudad 7'),
(134, 128, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 8, Teléfono=3108888, Email=contacto8, Dirección=Ciudad 8'),
(135, 129, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 9, Teléfono=3109999, Email=contacto9, Dirección=Ciudad 9'),
(136, 130, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(137, 131, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(138, 132, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(139, 133, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13'),
(140, 134, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(141, 135, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(142, 136, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16'),
(143, 137, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(144, 138, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(145, 139, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(146, 140, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(147, 141, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(148, 142, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(149, 143, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(150, 144, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(151, 145, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(152, 146, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26'),
(153, 147, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27'),
(154, 148, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(155, 149, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(156, 150, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(157, 151, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(158, 152, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(159, 153, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(160, 154, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(161, 155, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(162, 156, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(163, 157, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(164, 158, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(165, 159, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39'),
(166, 160, 'INSERT', '2024-11-15 07:55:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(167, 161, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=RON1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(168, 162, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(169, 163, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(170, 164, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(171, 165, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(172, 166, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 6, Teléfono=3106666, Email=contacto6, Dirección=Ciudad 6'),
(173, 167, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 7, Teléfono=3107777, Email=contacto7, Dirección=Ciudad 7'),
(174, 168, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 8, Teléfono=3108888, Email=contacto8, Dirección=Ciudad 8'),
(175, 169, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 9, Teléfono=3109999, Email=contacto9, Dirección=Ciudad 9'),
(176, 170, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(177, 171, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(178, 172, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(179, 173, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13'),
(180, 174, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(181, 175, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(182, 176, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16'),
(183, 177, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(184, 178, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(185, 179, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(186, 180, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(187, 181, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(188, 182, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(189, 183, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(190, 184, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(191, 185, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(192, 186, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26'),
(193, 187, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27'),
(194, 188, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(195, 189, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(196, 190, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(197, 191, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(198, 192, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(199, 193, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(200, 194, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(201, 195, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(202, 196, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(203, 197, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(204, 198, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(205, 199, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39'),
(206, 200, 'INSERT', '2024-11-15 07:55:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(207, 1, 'DELETE', '2024-11-15 07:55:54', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(208, 201, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=RON1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(209, 202, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(210, 203, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(211, 204, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(212, 205, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(213, 206, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 6, Teléfono=3106666, Email=contacto6, Dirección=Ciudad 6'),
(214, 207, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 7, Teléfono=3107777, Email=contacto7, Dirección=Ciudad 7'),
(215, 208, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 8, Teléfono=3108888, Email=contacto8, Dirección=Ciudad 8'),
(216, 209, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 9, Teléfono=3109999, Email=contacto9, Dirección=Ciudad 9'),
(217, 210, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(218, 211, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(219, 212, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(220, 213, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13'),
(221, 214, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(222, 215, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(223, 216, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16'),
(224, 217, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(225, 218, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(226, 219, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(227, 220, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(228, 221, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(229, 222, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(230, 223, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(231, 224, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(232, 225, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(233, 226, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26'),
(234, 227, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27'),
(235, 228, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(236, 229, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(237, 230, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(238, 231, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(239, 232, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(240, 233, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(241, 234, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(242, 235, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(243, 236, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(244, 237, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(245, 238, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(246, 239, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39'),
(247, 240, 'INSERT', '2024-11-15 07:56:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(248, 1, 'INSERT', '2024-11-15 07:56:20', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=RON1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(249, 241, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=RON1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(250, 242, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(251, 243, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(252, 244, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(253, 245, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(254, 246, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 6, Teléfono=3106666, Email=contacto6, Dirección=Ciudad 6'),
(255, 247, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 7, Teléfono=3107777, Email=contacto7, Dirección=Ciudad 7'),
(256, 248, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 8, Teléfono=3108888, Email=contacto8, Dirección=Ciudad 8'),
(257, 249, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 9, Teléfono=3109999, Email=contacto9, Dirección=Ciudad 9'),
(258, 250, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(259, 251, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(260, 252, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(261, 253, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13');
INSERT INTO `Historial_Proveedores` (`id_historial`, `id_proveedor`, `tipo_accion`, `fecha_modificacion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`) VALUES
(262, 254, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(263, 255, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(264, 256, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16'),
(265, 257, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(266, 258, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(267, 259, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(268, 260, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(269, 261, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(270, 262, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(271, 263, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(272, 264, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(273, 265, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(274, 266, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26'),
(275, 267, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27'),
(276, 268, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(277, 269, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(278, 270, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(279, 271, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(280, 272, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(281, 273, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(282, 274, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(283, 275, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(284, 276, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(285, 277, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(286, 278, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(287, 279, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39'),
(288, 280, 'INSERT', '2024-11-15 07:57:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(289, 281, 'INSERT', '2024-11-15 07:58:24', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(290, 282, 'INSERT', '2024-11-15 07:58:24', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(291, 283, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=RDSGDFSG1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(292, 284, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(293, 285, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(294, 286, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(295, 287, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(296, 288, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 6, Teléfono=3106666, Email=contacto6, Dirección=Ciudad 6'),
(297, 289, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 7, Teléfono=3107777, Email=contacto7, Dirección=Ciudad 7'),
(298, 290, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 8, Teléfono=3108888, Email=contacto8, Dirección=Ciudad 8'),
(299, 291, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 9, Teléfono=3109999, Email=contacto9, Dirección=Ciudad 9'),
(300, 292, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(301, 293, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(302, 294, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(303, 295, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13'),
(304, 296, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(305, 297, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(306, 298, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16'),
(307, 299, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(308, 300, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(309, 301, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(310, 302, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(311, 303, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(312, 304, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(313, 305, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(314, 306, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(315, 307, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(316, 308, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26'),
(317, 309, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27'),
(318, 310, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(319, 311, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(320, 312, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(321, 313, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(322, 314, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(323, 315, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(324, 316, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(325, 317, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(326, 318, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(327, 319, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(328, 320, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(329, 321, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39'),
(330, 322, 'INSERT', '2024-11-15 07:59:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(331, 323, 'INSERT', '2024-11-15 08:07:46', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(332, 324, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=RDSGDFSG1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(333, 325, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(334, 326, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(335, 327, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(336, 328, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(337, 329, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 6, Teléfono=3106666, Email=contacto6, Dirección=Ciudad 6'),
(338, 330, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 7, Teléfono=3107777, Email=contacto7, Dirección=Ciudad 7'),
(339, 331, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 8, Teléfono=3108888, Email=contacto8, Dirección=Ciudad 8'),
(340, 332, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 9, Teléfono=3109999, Email=contacto9, Dirección=Ciudad 9'),
(341, 333, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(342, 334, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(343, 335, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(344, 336, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13'),
(345, 337, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(346, 338, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(347, 339, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16'),
(348, 340, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(349, 341, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(350, 342, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(351, 343, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(352, 344, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(353, 345, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(354, 346, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(355, 347, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(356, 348, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(357, 349, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26'),
(358, 350, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27'),
(359, 351, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(360, 352, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(361, 353, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(362, 354, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(363, 355, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(364, 356, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(365, 357, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(366, 358, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(367, 359, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(368, 360, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(369, 361, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(370, 362, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39'),
(371, 363, 'INSERT', '2024-11-15 08:08:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(372, 364, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=RDSGDFSG1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(373, 365, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(374, 366, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(375, 367, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(376, 368, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(377, 369, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 6, Teléfono=3106666, Email=contacto6, Dirección=Ciudad 6'),
(378, 370, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 7, Teléfono=3107777, Email=contacto7, Dirección=Ciudad 7'),
(379, 371, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 8, Teléfono=3108888, Email=contacto8, Dirección=Ciudad 8'),
(380, 372, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 9, Teléfono=3109999, Email=contacto9, Dirección=Ciudad 9'),
(381, 373, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(382, 374, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(383, 375, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(384, 376, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13'),
(385, 377, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(386, 378, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(387, 379, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16'),
(388, 380, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(389, 381, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(390, 382, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(391, 383, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(392, 384, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(393, 385, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(394, 386, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(395, 387, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(396, 388, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(397, 389, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26'),
(398, 390, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27'),
(399, 391, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(400, 392, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(401, 393, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(402, 394, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(403, 395, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(404, 396, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(405, 397, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(406, 398, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(407, 399, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(408, 400, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(409, 401, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(410, 402, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39'),
(411, 403, 'INSERT', '2024-11-15 08:19:23', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(412, 404, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=RDSGDFSG1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(413, 405, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(414, 406, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(415, 407, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(416, 408, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(417, 409, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 6, Teléfono=3106666, Email=contacto6, Dirección=Ciudad 6'),
(418, 410, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 7, Teléfono=3107777, Email=contacto7, Dirección=Ciudad 7'),
(419, 411, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 8, Teléfono=3108888, Email=contacto8, Dirección=Ciudad 8'),
(420, 412, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 9, Teléfono=3109999, Email=contacto9, Dirección=Ciudad 9'),
(421, 413, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(422, 414, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(423, 415, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(424, 416, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13'),
(425, 417, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(426, 418, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(427, 419, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16'),
(428, 420, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(429, 421, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(430, 422, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(431, 423, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(432, 424, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(433, 425, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(434, 426, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(435, 427, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(436, 428, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(437, 429, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26'),
(438, 430, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27'),
(439, 431, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(440, 432, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(441, 433, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(442, 434, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(443, 435, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(444, 436, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(445, 437, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(446, 438, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(447, 439, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(448, 440, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(449, 441, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(450, 442, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39'),
(451, 443, 'INSERT', '2024-11-15 08:21:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(452, 444, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=RDSGDFSG1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(453, 445, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(454, 446, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(455, 447, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(456, 448, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(457, 449, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 6, Teléfono=3106666, Email=contacto6, Dirección=Ciudad 6'),
(458, 450, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 7, Teléfono=3107777, Email=contacto7, Dirección=Ciudad 7'),
(459, 451, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 8, Teléfono=3108888, Email=contacto8, Dirección=Ciudad 8'),
(460, 452, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 9, Teléfono=3109999, Email=contacto9, Dirección=Ciudad 9'),
(461, 453, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(462, 454, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(463, 455, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(464, 456, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13'),
(465, 457, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(466, 458, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(467, 459, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16'),
(468, 460, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(469, 461, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(470, 462, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(471, 463, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(472, 464, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(473, 465, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(474, 466, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(475, 467, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(476, 468, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(477, 469, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26'),
(478, 470, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27'),
(479, 471, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(480, 472, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(481, 473, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(482, 474, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(483, 475, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(484, 476, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(485, 477, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(486, 478, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(487, 479, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(488, 480, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(489, 481, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(490, 482, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39'),
(491, 483, 'INSERT', '2024-11-15 08:21:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(492, 11, 'DELETE', '2024-11-15 08:22:03', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(493, 5, 'DELETE', '2024-11-15 08:22:08', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(494, 3, 'DELETE', '2024-11-15 08:22:11', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(495, 2, 'DELETE', '2024-11-15 08:22:12', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(496, 484, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=RDSGDFSG1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(497, 485, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(498, 486, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(499, 487, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(500, 488, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(501, 489, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 6, Teléfono=3106666, Email=contacto6, Dirección=Ciudad 6'),
(502, 490, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 7, Teléfono=3107777, Email=contacto7, Dirección=Ciudad 7'),
(503, 491, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 8, Teléfono=3108888, Email=contacto8, Dirección=Ciudad 8'),
(504, 492, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 9, Teléfono=3109999, Email=contacto9, Dirección=Ciudad 9'),
(505, 493, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(506, 494, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(507, 495, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(508, 496, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13'),
(509, 497, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(510, 498, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(511, 499, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16'),
(512, 500, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(513, 501, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(514, 502, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(515, 503, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(516, 504, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(517, 505, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(518, 506, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(519, 507, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(520, 508, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(521, 509, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26'),
(522, 510, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27');
INSERT INTO `Historial_Proveedores` (`id_historial`, `id_proveedor`, `tipo_accion`, `fecha_modificacion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`) VALUES
(523, 511, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(524, 512, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(525, 513, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(526, 514, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(527, 515, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(528, 516, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(529, 517, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(530, 518, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(531, 519, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(532, 520, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(533, 521, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(534, 522, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39'),
(535, 523, 'INSERT', '2024-11-15 08:22:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(536, 524, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(537, 525, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(538, 526, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(539, 527, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(540, 528, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(541, 529, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(542, 530, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(543, 531, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(544, 532, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(545, 533, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(546, 534, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(547, 535, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(548, 536, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(549, 537, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(550, 538, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(551, 539, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(552, 540, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(553, 541, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(554, 542, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(555, 543, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(556, 544, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(557, 545, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(558, 546, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(559, 547, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(560, 548, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(561, 549, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(562, 550, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(563, 551, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(564, 552, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(565, 553, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(566, 554, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(567, 555, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(568, 556, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(569, 557, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(570, 558, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(571, 559, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(572, 560, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(573, 561, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(574, 562, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(575, 563, 'INSERT', '2024-11-15 08:24:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(579, 1, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=RON1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(580, 4, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(581, 6, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=test, Teléfono=101010, Email=test@gmail.com, Dirección=test'),
(582, 7, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=pepe, Teléfono=12025158, Email=asdfsa@gmail.com, Dirección=dfsfgads'),
(583, 8, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=juanito, Teléfono=2121212, Email=juanito@gmail.com, Dirección=dir dir'),
(584, 9, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Viniles AC, Teléfono=9142234566, Email=jafsjsdfjsd|@gmail.com, Dirección=sdfsdfsdfsf'),
(585, 10, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(586, 12, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(587, 13, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13'),
(588, 14, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(589, 15, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(590, 16, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16'),
(591, 17, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(592, 18, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(593, 19, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(594, 20, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(595, 21, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(596, 22, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(597, 23, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(598, 24, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(599, 25, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(600, 26, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26'),
(601, 27, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27'),
(602, 28, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(603, 29, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(604, 30, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(605, 31, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(606, 32, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(607, 33, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(608, 34, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(609, 35, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(610, 36, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(611, 37, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(612, 38, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(613, 39, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39'),
(614, 40, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(615, 41, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(616, 42, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(617, 43, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(618, 44, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(619, 45, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(620, 46, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 6, Teléfono=3106666, Email=contacto6, Dirección=Ciudad 6'),
(621, 47, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 7, Teléfono=3107777, Email=contacto7, Dirección=Ciudad 7'),
(622, 48, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 8, Teléfono=3108888, Email=contacto8, Dirección=Ciudad 8'),
(623, 49, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 9, Teléfono=3109999, Email=contacto9, Dirección=Ciudad 9'),
(624, 50, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(625, 51, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(626, 52, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(627, 53, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13'),
(628, 54, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(629, 55, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(630, 56, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16'),
(631, 57, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(632, 58, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(633, 59, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(634, 60, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(635, 61, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(636, 62, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(637, 63, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(638, 64, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(639, 65, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(640, 66, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26'),
(641, 67, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27'),
(642, 68, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(643, 69, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(644, 70, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(645, 71, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(646, 72, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(647, 73, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(648, 74, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(649, 75, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(650, 76, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(651, 77, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(652, 78, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(653, 79, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39'),
(654, 80, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(655, 81, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(656, 82, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(657, 83, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(658, 84, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(659, 85, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(660, 86, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 6, Teléfono=3106666, Email=contacto6, Dirección=Ciudad 6'),
(661, 87, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 7, Teléfono=3107777, Email=contacto7, Dirección=Ciudad 7'),
(662, 88, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 8, Teléfono=3108888, Email=contacto8, Dirección=Ciudad 8'),
(663, 89, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 9, Teléfono=3109999, Email=contacto9, Dirección=Ciudad 9'),
(664, 90, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(665, 91, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(666, 92, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(667, 93, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13'),
(668, 94, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(669, 95, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(670, 96, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16'),
(671, 97, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(672, 98, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(673, 99, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(674, 100, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(675, 101, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(676, 102, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(677, 103, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(678, 104, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(679, 105, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(680, 106, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26'),
(681, 107, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27'),
(682, 108, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(683, 109, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(684, 110, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(685, 111, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(686, 112, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(687, 113, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(688, 114, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(689, 115, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(690, 116, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(691, 117, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(692, 118, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(693, 119, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39'),
(694, 120, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(695, 121, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(696, 122, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(697, 123, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(698, 124, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(699, 125, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(700, 126, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 6, Teléfono=3106666, Email=contacto6, Dirección=Ciudad 6'),
(701, 127, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 7, Teléfono=3107777, Email=contacto7, Dirección=Ciudad 7'),
(702, 128, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 8, Teléfono=3108888, Email=contacto8, Dirección=Ciudad 8'),
(703, 129, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 9, Teléfono=3109999, Email=contacto9, Dirección=Ciudad 9'),
(704, 130, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(705, 131, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(706, 132, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(707, 133, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13'),
(708, 134, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(709, 135, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(710, 136, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16'),
(711, 137, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(712, 138, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(713, 139, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(714, 140, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(715, 141, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(716, 142, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(717, 143, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(718, 144, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(719, 145, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(720, 146, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26'),
(721, 147, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27'),
(722, 148, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(723, 149, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(724, 150, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(725, 151, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(726, 152, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(727, 153, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(728, 154, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(729, 155, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(730, 156, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(731, 157, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(732, 158, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(733, 159, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39'),
(734, 160, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(735, 161, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=RON1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(736, 162, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(737, 163, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(738, 164, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(739, 165, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(740, 166, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 6, Teléfono=3106666, Email=contacto6, Dirección=Ciudad 6'),
(741, 167, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 7, Teléfono=3107777, Email=contacto7, Dirección=Ciudad 7'),
(742, 168, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 8, Teléfono=3108888, Email=contacto8, Dirección=Ciudad 8'),
(743, 169, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 9, Teléfono=3109999, Email=contacto9, Dirección=Ciudad 9'),
(744, 170, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(745, 171, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(746, 172, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(747, 173, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13'),
(748, 174, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(749, 175, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(750, 176, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16'),
(751, 177, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(752, 178, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(753, 179, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(754, 180, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(755, 181, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(756, 182, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(757, 183, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(758, 184, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(759, 185, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(760, 186, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26'),
(761, 187, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27'),
(762, 188, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(763, 189, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(764, 190, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(765, 191, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(766, 192, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(767, 193, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(768, 194, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(769, 195, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(770, 196, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(771, 197, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(772, 198, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(773, 199, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39'),
(774, 200, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(775, 201, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=RON1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(776, 202, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(777, 203, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(778, 204, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(779, 205, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(780, 206, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 6, Teléfono=3106666, Email=contacto6, Dirección=Ciudad 6'),
(781, 207, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 7, Teléfono=3107777, Email=contacto7, Dirección=Ciudad 7'),
(782, 208, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 8, Teléfono=3108888, Email=contacto8, Dirección=Ciudad 8'),
(783, 209, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 9, Teléfono=3109999, Email=contacto9, Dirección=Ciudad 9'),
(784, 210, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(785, 211, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(786, 212, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(787, 213, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13'),
(788, 214, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(789, 215, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(790, 216, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16'),
(791, 217, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(792, 218, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(793, 219, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(794, 220, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(795, 221, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(796, 222, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(797, 223, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(798, 224, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(799, 225, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(800, 226, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26');
INSERT INTO `Historial_Proveedores` (`id_historial`, `id_proveedor`, `tipo_accion`, `fecha_modificacion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`) VALUES
(801, 227, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27'),
(802, 228, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(803, 229, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(804, 230, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(805, 231, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(806, 232, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(807, 233, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(808, 234, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(809, 235, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(810, 236, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(811, 237, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(812, 238, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(813, 239, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39'),
(814, 240, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(815, 241, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=RON1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(816, 242, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(817, 243, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(818, 244, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(819, 245, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(820, 246, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 6, Teléfono=3106666, Email=contacto6, Dirección=Ciudad 6'),
(821, 247, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 7, Teléfono=3107777, Email=contacto7, Dirección=Ciudad 7'),
(822, 248, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 8, Teléfono=3108888, Email=contacto8, Dirección=Ciudad 8'),
(823, 249, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 9, Teléfono=3109999, Email=contacto9, Dirección=Ciudad 9'),
(824, 250, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(825, 251, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(826, 252, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(827, 253, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13'),
(828, 254, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(829, 255, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(830, 256, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16'),
(831, 257, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(832, 258, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(833, 259, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(834, 260, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(835, 261, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(836, 262, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(837, 263, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(838, 264, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(839, 265, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(840, 266, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26'),
(841, 267, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27'),
(842, 268, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(843, 269, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(844, 270, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(845, 271, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(846, 272, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(847, 273, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(848, 274, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(849, 275, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(850, 276, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(851, 277, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(852, 278, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(853, 279, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39'),
(854, 280, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(855, 281, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(856, 282, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(857, 283, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=RDSGDFSG1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(858, 284, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(859, 285, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(860, 286, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(861, 287, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(862, 288, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 6, Teléfono=3106666, Email=contacto6, Dirección=Ciudad 6'),
(863, 289, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 7, Teléfono=3107777, Email=contacto7, Dirección=Ciudad 7'),
(864, 290, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 8, Teléfono=3108888, Email=contacto8, Dirección=Ciudad 8'),
(865, 291, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 9, Teléfono=3109999, Email=contacto9, Dirección=Ciudad 9'),
(866, 292, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(867, 293, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(868, 294, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(869, 295, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13'),
(870, 296, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(871, 297, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(872, 298, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16'),
(873, 299, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(874, 300, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(875, 301, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(876, 302, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(877, 303, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(878, 304, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(879, 305, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(880, 306, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(881, 307, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(882, 308, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26'),
(883, 309, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27'),
(884, 310, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(885, 311, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(886, 312, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(887, 313, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(888, 314, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(889, 315, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(890, 316, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(891, 317, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(892, 318, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(893, 319, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(894, 320, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(895, 321, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39'),
(896, 322, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(897, 323, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(898, 324, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=RDSGDFSG1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(899, 325, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(900, 326, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(901, 327, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(902, 328, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(903, 329, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 6, Teléfono=3106666, Email=contacto6, Dirección=Ciudad 6'),
(904, 330, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 7, Teléfono=3107777, Email=contacto7, Dirección=Ciudad 7'),
(905, 331, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 8, Teléfono=3108888, Email=contacto8, Dirección=Ciudad 8'),
(906, 332, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 9, Teléfono=3109999, Email=contacto9, Dirección=Ciudad 9'),
(907, 333, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(908, 334, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(909, 335, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(910, 336, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13'),
(911, 337, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(912, 338, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(913, 339, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16'),
(914, 340, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(915, 341, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(916, 342, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(917, 343, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(918, 344, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(919, 345, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(920, 346, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(921, 347, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(922, 348, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(923, 349, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26'),
(924, 350, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27'),
(925, 351, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(926, 352, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(927, 353, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(928, 354, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(929, 355, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(930, 356, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(931, 357, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(932, 358, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(933, 359, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(934, 360, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(935, 361, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(936, 362, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39'),
(937, 363, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(938, 364, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=RDSGDFSG1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(939, 365, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(940, 366, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(941, 367, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(942, 368, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(943, 369, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 6, Teléfono=3106666, Email=contacto6, Dirección=Ciudad 6'),
(944, 370, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 7, Teléfono=3107777, Email=contacto7, Dirección=Ciudad 7'),
(945, 371, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 8, Teléfono=3108888, Email=contacto8, Dirección=Ciudad 8'),
(946, 372, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 9, Teléfono=3109999, Email=contacto9, Dirección=Ciudad 9'),
(947, 373, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(948, 374, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(949, 375, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(950, 376, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13'),
(951, 377, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(952, 378, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(953, 379, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16'),
(954, 380, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(955, 381, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(956, 382, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(957, 383, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(958, 384, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(959, 385, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(960, 386, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(961, 387, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(962, 388, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(963, 389, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26'),
(964, 390, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27'),
(965, 391, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(966, 392, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(967, 393, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(968, 394, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(969, 395, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(970, 396, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(971, 397, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(972, 398, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(973, 399, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(974, 400, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(975, 401, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(976, 402, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39'),
(977, 403, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(978, 404, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=RDSGDFSG1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(979, 405, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(980, 406, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(981, 407, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(982, 408, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(983, 409, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 6, Teléfono=3106666, Email=contacto6, Dirección=Ciudad 6'),
(984, 410, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 7, Teléfono=3107777, Email=contacto7, Dirección=Ciudad 7'),
(985, 411, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 8, Teléfono=3108888, Email=contacto8, Dirección=Ciudad 8'),
(986, 412, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 9, Teléfono=3109999, Email=contacto9, Dirección=Ciudad 9'),
(987, 413, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(988, 414, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(989, 415, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(990, 416, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13'),
(991, 417, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(992, 418, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(993, 419, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16'),
(994, 420, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(995, 421, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(996, 422, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(997, 423, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(998, 424, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(999, 425, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(1000, 426, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(1001, 427, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(1002, 428, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(1003, 429, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26'),
(1004, 430, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27'),
(1005, 431, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(1006, 432, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(1007, 433, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(1008, 434, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(1009, 435, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(1010, 436, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(1011, 437, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(1012, 438, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(1013, 439, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(1014, 440, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(1015, 441, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(1016, 442, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39'),
(1017, 443, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(1018, 444, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=RDSGDFSG1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(1019, 445, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(1020, 446, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(1021, 447, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(1022, 448, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(1023, 449, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 6, Teléfono=3106666, Email=contacto6, Dirección=Ciudad 6'),
(1024, 450, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 7, Teléfono=3107777, Email=contacto7, Dirección=Ciudad 7'),
(1025, 451, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 8, Teléfono=3108888, Email=contacto8, Dirección=Ciudad 8'),
(1026, 452, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 9, Teléfono=3109999, Email=contacto9, Dirección=Ciudad 9'),
(1027, 453, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(1028, 454, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(1029, 455, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(1030, 456, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13'),
(1031, 457, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(1032, 458, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(1033, 459, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16'),
(1034, 460, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(1035, 461, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(1036, 462, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(1037, 463, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(1038, 464, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(1039, 465, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(1040, 466, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(1041, 467, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(1042, 468, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(1043, 469, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26'),
(1044, 470, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27'),
(1045, 471, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(1046, 472, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(1047, 473, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(1048, 474, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(1049, 475, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(1050, 476, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(1051, 477, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(1052, 478, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(1053, 479, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(1054, 480, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(1055, 481, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(1056, 482, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39');
INSERT INTO `Historial_Proveedores` (`id_historial`, `id_proveedor`, `tipo_accion`, `fecha_modificacion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`) VALUES
(1057, 483, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(1058, 484, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=RDSGDFSG1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(1059, 485, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(1060, 486, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(1061, 487, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(1062, 488, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(1063, 489, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 6, Teléfono=3106666, Email=contacto6, Dirección=Ciudad 6'),
(1064, 490, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 7, Teléfono=3107777, Email=contacto7, Dirección=Ciudad 7'),
(1065, 491, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 8, Teléfono=3108888, Email=contacto8, Dirección=Ciudad 8'),
(1066, 492, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 9, Teléfono=3109999, Email=contacto9, Dirección=Ciudad 9'),
(1067, 493, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(1068, 494, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(1069, 495, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(1070, 496, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13'),
(1071, 497, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(1072, 498, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(1073, 499, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16'),
(1074, 500, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(1075, 501, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(1076, 502, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(1077, 503, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(1078, 504, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(1079, 505, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(1080, 506, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(1081, 507, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(1082, 508, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(1083, 509, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26'),
(1084, 510, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27'),
(1085, 511, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(1086, 512, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(1087, 513, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(1088, 514, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(1089, 515, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(1090, 516, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(1091, 517, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(1092, 518, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(1093, 519, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(1094, 520, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(1095, 521, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(1096, 522, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39'),
(1097, 523, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(1098, 524, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1099, 525, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1100, 526, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1101, 527, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1102, 528, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1103, 529, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1104, 530, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1105, 531, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1106, 532, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1107, 533, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1108, 534, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1109, 535, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1110, 536, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1111, 537, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1112, 538, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1113, 539, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1114, 540, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1115, 541, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1116, 542, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1117, 543, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1118, 544, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1119, 545, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1120, 546, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1121, 547, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1122, 548, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1123, 549, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1124, 550, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1125, 551, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1126, 552, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1127, 553, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1128, 554, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1129, 555, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1130, 556, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1131, 557, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1132, 558, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1133, 559, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1134, 560, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1135, 561, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1136, 562, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1137, 563, 'DELETE', '2024-11-15 08:33:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1138, 564, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=RDSGDFSG1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(1139, 565, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(1140, 566, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(1141, 567, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(1142, 568, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(1143, 569, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 6, Teléfono=3106666, Email=contacto6, Dirección=Ciudad 6'),
(1144, 570, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 7, Teléfono=3107777, Email=contacto7, Dirección=Ciudad 7'),
(1145, 571, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 8, Teléfono=3108888, Email=contacto8, Dirección=Ciudad 8'),
(1146, 572, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 9, Teléfono=3109999, Email=contacto9, Dirección=Ciudad 9'),
(1147, 573, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(1148, 574, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(1149, 575, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(1150, 576, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13'),
(1151, 577, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(1152, 578, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(1153, 579, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16'),
(1154, 580, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(1155, 581, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(1156, 582, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(1157, 583, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(1158, 584, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(1159, 585, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(1160, 586, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(1161, 587, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(1162, 588, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(1163, 589, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26'),
(1164, 590, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27'),
(1165, 591, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(1166, 592, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(1167, 593, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(1168, 594, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(1169, 595, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(1170, 596, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(1171, 597, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(1172, 598, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(1173, 599, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(1174, 600, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(1175, 601, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(1176, 602, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39'),
(1177, 603, 'INSERT', '2024-11-15 08:34:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(1178, 604, 'INSERT', '2024-11-15 08:36:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1179, 200, 'INSERT', '2024-11-15 08:36:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1180, 200, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1181, 564, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=RDSGDFSG1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(1182, 565, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(1183, 566, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(1184, 567, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(1185, 568, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(1186, 569, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 6, Teléfono=3106666, Email=contacto6, Dirección=Ciudad 6'),
(1187, 570, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 7, Teléfono=3107777, Email=contacto7, Dirección=Ciudad 7'),
(1188, 571, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 8, Teléfono=3108888, Email=contacto8, Dirección=Ciudad 8'),
(1189, 572, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 9, Teléfono=3109999, Email=contacto9, Dirección=Ciudad 9'),
(1190, 573, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(1191, 574, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(1192, 575, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(1193, 576, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13'),
(1194, 577, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(1195, 578, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(1196, 579, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16'),
(1197, 580, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(1198, 581, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(1199, 582, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(1200, 583, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(1201, 584, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(1202, 585, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(1203, 586, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(1204, 587, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(1205, 588, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(1206, 589, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26'),
(1207, 590, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27'),
(1208, 591, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(1209, 592, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(1210, 593, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(1211, 594, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(1212, 595, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(1213, 596, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(1214, 597, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(1215, 598, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(1216, 599, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(1217, 600, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(1218, 601, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(1219, 602, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39'),
(1220, 603, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(1221, 604, 'DELETE', '2024-11-15 08:38:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1222, 605, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1223, 606, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1224, 607, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1225, 608, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1226, 609, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1227, 610, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1228, 611, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1229, 612, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1230, 613, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1231, 614, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1232, 615, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1233, 616, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1234, 617, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1235, 618, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1236, 619, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1237, 620, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1238, 621, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1239, 622, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1240, 623, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1241, 624, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1242, 625, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1243, 626, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1244, 627, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1245, 628, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1246, 629, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1247, 630, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1248, 631, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1249, 632, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1250, 633, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1251, 634, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1252, 635, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1253, 636, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1254, 637, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1255, 638, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1256, 639, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1257, 640, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1258, 641, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1259, 642, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1260, 643, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1261, 644, 'INSERT', '2024-11-15 08:41:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1262, 605, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1263, 606, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1264, 607, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1265, 608, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1266, 609, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1267, 610, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1268, 611, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1269, 612, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1270, 613, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1271, 614, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1272, 615, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1273, 616, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1274, 617, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1275, 618, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1276, 619, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1277, 620, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1278, 621, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1279, 622, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1280, 623, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1281, 624, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1282, 625, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1283, 626, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1284, 627, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1285, 628, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1286, 629, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1287, 630, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1288, 631, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1289, 632, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1290, 633, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1291, 634, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1292, 635, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1293, 636, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1294, 637, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1295, 638, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1296, 639, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1297, 640, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1298, 641, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1299, 642, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1300, 643, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1301, 644, 'DELETE', '2024-11-15 09:17:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1302, 645, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1303, 646, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1304, 647, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1305, 648, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1306, 649, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1307, 650, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1308, 651, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1309, 652, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1310, 653, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1311, 654, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1312, 655, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1313, 656, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1314, 657, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1315, 658, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1316, 659, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1317, 660, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1318, 661, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1319, 662, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1320, 663, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1321, 664, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1322, 665, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1323, 666, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1324, 667, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1325, 668, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1326, 669, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1327, 670, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1328, 671, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1329, 672, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1330, 673, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1331, 674, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1332, 675, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1333, 676, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1334, 677, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1335, 678, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1336, 679, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1337, 680, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1338, 681, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1339, 682, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1340, 683, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1341, 684, 'INSERT', '2024-11-15 09:24:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1342, 685, 'INSERT', '2024-11-15 09:55:46', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=RDSGDFSG1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(1343, 686, 'INSERT', '2024-11-15 09:55:46', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(1344, 687, 'INSERT', '2024-11-15 09:55:46', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(1345, 688, 'INSERT', '2024-11-15 09:55:46', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(1346, 689, 'INSERT', '2024-11-15 09:55:46', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(1347, 690, 'INSERT', '2024-11-15 09:55:46', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 6, Teléfono=3106666, Email=contacto6, Dirección=Ciudad 6'),
(1348, 691, 'INSERT', '2024-11-15 09:55:46', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 7, Teléfono=3107777, Email=contacto7, Dirección=Ciudad 7'),
(1349, 692, 'INSERT', '2024-11-15 09:55:46', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 8, Teléfono=3108888, Email=contacto8, Dirección=Ciudad 8'),
(1350, 693, 'INSERT', '2024-11-15 09:55:46', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 9, Teléfono=3109999, Email=contacto9, Dirección=Ciudad 9'),
(1351, 694, 'INSERT', '2024-11-15 09:55:46', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(1352, 695, 'INSERT', '2024-11-15 09:55:46', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(1353, 696, 'INSERT', '2024-11-15 09:55:46', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(1354, 697, 'INSERT', '2024-11-15 09:55:46', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13'),
(1355, 698, 'INSERT', '2024-11-15 09:55:46', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(1356, 699, 'INSERT', '2024-11-15 09:55:46', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(1357, 700, 'INSERT', '2024-11-15 09:55:46', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16'),
(1358, 701, 'INSERT', '2024-11-15 09:55:46', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(1359, 702, 'INSERT', '2024-11-15 09:55:46', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(1360, 703, 'INSERT', '2024-11-15 09:55:46', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(1361, 704, 'INSERT', '2024-11-15 09:55:46', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(1362, 705, 'INSERT', '2024-11-15 09:55:46', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(1363, 706, 'INSERT', '2024-11-15 09:55:46', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(1364, 707, 'INSERT', '2024-11-15 09:55:46', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(1365, 708, 'INSERT', '2024-11-15 09:55:46', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(1366, 709, 'INSERT', '2024-11-15 09:55:46', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(1367, 710, 'INSERT', '2024-11-15 09:55:46', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26'),
(1368, 711, 'INSERT', '2024-11-15 09:55:46', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27'),
(1369, 712, 'INSERT', '2024-11-15 09:55:47', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(1370, 713, 'INSERT', '2024-11-15 09:55:47', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(1371, 714, 'INSERT', '2024-11-15 09:55:47', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(1372, 715, 'INSERT', '2024-11-15 09:55:47', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(1373, 716, 'INSERT', '2024-11-15 09:55:47', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(1374, 717, 'INSERT', '2024-11-15 09:55:47', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(1375, 718, 'INSERT', '2024-11-15 09:55:47', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(1376, 719, 'INSERT', '2024-11-15 09:55:47', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(1377, 720, 'INSERT', '2024-11-15 09:55:47', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(1378, 721, 'INSERT', '2024-11-15 09:55:47', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(1379, 722, 'INSERT', '2024-11-15 09:55:47', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(1380, 723, 'INSERT', '2024-11-15 09:55:47', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39'),
(1381, 724, 'INSERT', '2024-11-15 09:55:47', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(1382, 725, 'INSERT', '2024-11-15 09:59:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40@gmail.com, Dirección=Ciudad 40'),
(1383, 645, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1384, 646, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1385, 647, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1386, 648, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1387, 649, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1388, 650, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1389, 651, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1390, 652, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1391, 653, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1392, 654, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1393, 655, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1394, 656, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1395, 657, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1396, 658, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1397, 659, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1398, 660, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1399, 661, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1400, 662, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1401, 663, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1402, 664, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1403, 665, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL);
INSERT INTO `Historial_Proveedores` (`id_historial`, `id_proveedor`, `tipo_accion`, `fecha_modificacion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`) VALUES
(1404, 666, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1405, 667, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1406, 668, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1407, 669, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1408, 670, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1409, 671, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1410, 672, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1411, 673, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1412, 674, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1413, 675, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1414, 676, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1415, 677, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1416, 678, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1417, 679, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1418, 680, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1419, 681, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1420, 682, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1421, 683, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1422, 684, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1423, 685, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=RDSGDFSG1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(1424, 686, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(1425, 687, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(1426, 688, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(1427, 689, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(1428, 690, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 6, Teléfono=3106666, Email=contacto6, Dirección=Ciudad 6'),
(1429, 691, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 7, Teléfono=3107777, Email=contacto7, Dirección=Ciudad 7'),
(1430, 692, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 8, Teléfono=3108888, Email=contacto8, Dirección=Ciudad 8'),
(1431, 693, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 9, Teléfono=3109999, Email=contacto9, Dirección=Ciudad 9'),
(1432, 694, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(1433, 695, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(1434, 696, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(1435, 697, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13'),
(1436, 698, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(1437, 699, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(1438, 700, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16'),
(1439, 701, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(1440, 702, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(1441, 703, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(1442, 704, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(1443, 705, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(1444, 706, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(1445, 707, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(1446, 708, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(1447, 709, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(1448, 710, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26'),
(1449, 711, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27'),
(1450, 712, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(1451, 713, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(1452, 714, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(1453, 715, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(1454, 716, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(1455, 717, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(1456, 718, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(1457, 719, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(1458, 720, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(1459, 721, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(1460, 722, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(1461, 723, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39'),
(1462, 724, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(1463, 725, 'DELETE', '2024-11-15 09:59:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40@gmail.com, Dirección=Ciudad 40'),
(1464, 726, 'INSERT', '2024-11-15 09:59:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40@gmail.com, Dirección=Ciudad 40'),
(1465, 727, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(1466, 728, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(1467, 729, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(1468, 730, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(1469, 731, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(1470, 732, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 6, Teléfono=3106666, Email=contacto6, Dirección=Ciudad 6'),
(1471, 733, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 7, Teléfono=3107777, Email=contacto7, Dirección=Ciudad 7'),
(1472, 734, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 8, Teléfono=3108888, Email=contacto8, Dirección=Ciudad 8'),
(1473, 735, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 9, Teléfono=3109999, Email=contacto9, Dirección=Ciudad 9'),
(1474, 736, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(1475, 737, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(1476, 738, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(1477, 739, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13'),
(1478, 740, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(1479, 741, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(1480, 742, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16'),
(1481, 743, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(1482, 744, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(1483, 745, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(1484, 746, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(1485, 747, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(1486, 748, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(1487, 749, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(1488, 750, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(1489, 751, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(1490, 752, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26'),
(1491, 753, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27'),
(1492, 754, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(1493, 755, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(1494, 756, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(1495, 757, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(1496, 758, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(1497, 759, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(1498, 760, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(1499, 761, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(1500, 762, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(1501, 763, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(1502, 764, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(1503, 765, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39'),
(1504, 766, 'INSERT', '2024-11-15 10:02:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(1505, 726, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40@gmail.com, Dirección=Ciudad 40'),
(1506, 727, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 1, Teléfono=3101111, Email=contacto1, Dirección=Ciudad 1'),
(1507, 728, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(1508, 729, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(1509, 730, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(1510, 731, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(1511, 732, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 6, Teléfono=3106666, Email=contacto6, Dirección=Ciudad 6'),
(1512, 733, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 7, Teléfono=3107777, Email=contacto7, Dirección=Ciudad 7'),
(1513, 734, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 8, Teléfono=3108888, Email=contacto8, Dirección=Ciudad 8'),
(1514, 735, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 9, Teléfono=3109999, Email=contacto9, Dirección=Ciudad 9'),
(1515, 736, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(1516, 737, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(1517, 738, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(1518, 739, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13'),
(1519, 740, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(1520, 741, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(1521, 742, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16'),
(1522, 743, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(1523, 744, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(1524, 745, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(1525, 746, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(1526, 747, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(1527, 748, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(1528, 749, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(1529, 750, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(1530, 751, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(1531, 752, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26'),
(1532, 753, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27'),
(1533, 754, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(1534, 755, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(1535, 756, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(1536, 757, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(1537, 758, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(1538, 759, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(1539, 760, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(1540, 761, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(1541, 762, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(1542, 763, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(1543, 764, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(1544, 765, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39'),
(1545, 766, 'DELETE', '2024-11-15 10:03:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(1546, 767, 'INSERT', '2024-11-15 10:04:30', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40@gmail.com, Dirección=Ciudad 40'),
(1547, 1, 'INSERT', '2024-11-15 14:07:50', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor A, Teléfono=3101111111, Email=proveedor_a@example.com, Dirección=Calle 1, Ciudad A'),
(1548, 2, 'INSERT', '2024-11-15 14:07:50', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor B, Teléfono=3102222222, Email=proveedor_b@example.com, Dirección=Calle 2, Ciudad B'),
(1549, 3, 'INSERT', '2024-11-15 14:07:50', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor C, Teléfono=3103333333, Email=proveedor_c@example.com, Dirección=Calle 3, Ciudad C'),
(1550, 4, 'INSERT', '2024-11-15 14:07:50', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor D, Teléfono=3104444444, Email=proveedor_d@example.com, Dirección=Calle 4, Ciudad D'),
(1551, 5, 'INSERT', '2024-11-15 14:07:50', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor E, Teléfono=3105555555, Email=proveedor_e@example.com, Dirección=Calle 5, Ciudad E'),
(1552, 6, 'INSERT', '2024-11-15 14:07:50', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor F, Teléfono=3106666666, Email=proveedor_f@example.com, Dirección=Calle 6, Ciudad F'),
(1553, 7, 'INSERT', '2024-11-15 14:07:50', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor G, Teléfono=3107777777, Email=proveedor_g@example.com, Dirección=Calle 7, Ciudad G'),
(1554, 8, 'INSERT', '2024-11-15 14:07:50', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor H, Teléfono=3108888888, Email=proveedor_h@example.com, Dirección=Calle 8, Ciudad H'),
(1555, 9, 'INSERT', '2024-11-15 14:07:50', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor I, Teléfono=3109999999, Email=proveedor_i@example.com, Dirección=Calle 9, Ciudad I'),
(1556, 10, 'INSERT', '2024-11-15 14:07:50', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor J, Teléfono=3101010101, Email=proveedor_j@example.com, Dirección=Calle 10, Ciudad J'),
(1557, 11, 'INSERT', '2024-11-15 14:07:50', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor K, Teléfono=3101111122, Email=proveedor_k@example.com, Dirección=Calle 11, Ciudad K'),
(1558, 12, 'INSERT', '2024-11-15 14:07:50', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor L, Teléfono=3102222233, Email=proveedor_l@example.com, Dirección=Calle 12, Ciudad L'),
(1559, 13, 'INSERT', '2024-11-15 14:07:50', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor M, Teléfono=3103333344, Email=proveedor_m@example.com, Dirección=Calle 13, Ciudad M'),
(1560, 14, 'INSERT', '2024-11-15 14:07:50', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor N, Teléfono=3104444455, Email=proveedor_n@example.com, Dirección=Calle 14, Ciudad N'),
(1561, 15, 'INSERT', '2024-11-15 14:07:50', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor O, Teléfono=3105555566, Email=proveedor_o@example.com, Dirección=Calle 15, Ciudad O'),
(1562, 16, 'INSERT', '2024-11-15 14:07:50', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor P, Teléfono=3106666677, Email=proveedor_p@example.com, Dirección=Calle 16, Ciudad P'),
(1563, 17, 'INSERT', '2024-11-15 14:07:50', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor Q, Teléfono=3107777788, Email=proveedor_q@example.com, Dirección=Calle 17, Ciudad Q'),
(1564, 18, 'INSERT', '2024-11-15 14:07:50', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor R, Teléfono=3108888899, Email=proveedor_r@example.com, Dirección=Calle 18, Ciudad R'),
(1565, 19, 'INSERT', '2024-11-15 14:07:50', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor S, Teléfono=3109999900, Email=proveedor_s@example.com, Dirección=Calle 19, Ciudad S'),
(1566, 20, 'INSERT', '2024-11-15 14:07:50', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor T, Teléfono=3101010203, Email=proveedor_t@example.com, Dirección=Calle 20, Ciudad T'),
(1567, 1, 'DELETE', '2024-11-15 14:10:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor A, Teléfono=3101111111, Email=proveedor_a@example.com, Dirección=Calle 1, Ciudad A'),
(1568, 2, 'DELETE', '2024-11-15 14:10:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor B, Teléfono=3102222222, Email=proveedor_b@example.com, Dirección=Calle 2, Ciudad B'),
(1569, 3, 'DELETE', '2024-11-15 14:10:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor C, Teléfono=3103333333, Email=proveedor_c@example.com, Dirección=Calle 3, Ciudad C'),
(1570, 4, 'DELETE', '2024-11-15 14:10:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor D, Teléfono=3104444444, Email=proveedor_d@example.com, Dirección=Calle 4, Ciudad D'),
(1571, 5, 'DELETE', '2024-11-15 14:10:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor E, Teléfono=3105555555, Email=proveedor_e@example.com, Dirección=Calle 5, Ciudad E'),
(1572, 6, 'DELETE', '2024-11-15 14:10:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor F, Teléfono=3106666666, Email=proveedor_f@example.com, Dirección=Calle 6, Ciudad F'),
(1573, 7, 'DELETE', '2024-11-15 14:10:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor G, Teléfono=3107777777, Email=proveedor_g@example.com, Dirección=Calle 7, Ciudad G'),
(1574, 8, 'DELETE', '2024-11-15 14:10:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor H, Teléfono=3108888888, Email=proveedor_h@example.com, Dirección=Calle 8, Ciudad H'),
(1575, 9, 'DELETE', '2024-11-15 14:10:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor I, Teléfono=3109999999, Email=proveedor_i@example.com, Dirección=Calle 9, Ciudad I'),
(1576, 10, 'DELETE', '2024-11-15 14:10:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor J, Teléfono=3101010101, Email=proveedor_j@example.com, Dirección=Calle 10, Ciudad J'),
(1577, 11, 'DELETE', '2024-11-15 14:10:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor K, Teléfono=3101111122, Email=proveedor_k@example.com, Dirección=Calle 11, Ciudad K'),
(1578, 12, 'DELETE', '2024-11-15 14:10:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor L, Teléfono=3102222233, Email=proveedor_l@example.com, Dirección=Calle 12, Ciudad L'),
(1579, 13, 'DELETE', '2024-11-15 14:10:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor M, Teléfono=3103333344, Email=proveedor_m@example.com, Dirección=Calle 13, Ciudad M'),
(1580, 14, 'DELETE', '2024-11-15 14:10:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor N, Teléfono=3104444455, Email=proveedor_n@example.com, Dirección=Calle 14, Ciudad N'),
(1581, 15, 'DELETE', '2024-11-15 14:10:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor O, Teléfono=3105555566, Email=proveedor_o@example.com, Dirección=Calle 15, Ciudad O'),
(1582, 16, 'DELETE', '2024-11-15 14:10:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor P, Teléfono=3106666677, Email=proveedor_p@example.com, Dirección=Calle 16, Ciudad P'),
(1583, 17, 'DELETE', '2024-11-15 14:10:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor Q, Teléfono=3107777788, Email=proveedor_q@example.com, Dirección=Calle 17, Ciudad Q'),
(1584, 18, 'DELETE', '2024-11-15 14:10:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor R, Teléfono=3108888899, Email=proveedor_r@example.com, Dirección=Calle 18, Ciudad R'),
(1585, 19, 'DELETE', '2024-11-15 14:10:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor S, Teléfono=3109999900, Email=proveedor_s@example.com, Dirección=Calle 19, Ciudad S'),
(1586, 20, 'DELETE', '2024-11-15 14:10:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor T, Teléfono=3101010203, Email=proveedor_t@example.com, Dirección=Calle 20, Ciudad T'),
(1587, 767, 'DELETE', '2024-11-15 14:10:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40@gmail.com, Dirección=Ciudad 40'),
(1588, 1, 'INSERT', '2024-11-15 14:10:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor A, Teléfono=3101111111, Email=proveedor_a@example.com, Dirección=Calle 1, Ciudad A'),
(1589, 2, 'INSERT', '2024-11-15 14:10:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor B, Teléfono=3102222222, Email=proveedor_b@example.com, Dirección=Calle 2, Ciudad B'),
(1590, 3, 'INSERT', '2024-11-15 14:10:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor C, Teléfono=3103333333, Email=proveedor_c@example.com, Dirección=Calle 3, Ciudad C'),
(1591, 4, 'INSERT', '2024-11-15 14:10:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor D, Teléfono=3104444444, Email=proveedor_d@example.com, Dirección=Calle 4, Ciudad D'),
(1592, 5, 'INSERT', '2024-11-15 14:10:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor E, Teléfono=3105555555, Email=proveedor_e@example.com, Dirección=Calle 5, Ciudad E'),
(1593, 6, 'INSERT', '2024-11-15 14:10:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor F, Teléfono=3106666666, Email=proveedor_f@example.com, Dirección=Calle 6, Ciudad F'),
(1594, 7, 'INSERT', '2024-11-15 14:10:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor G, Teléfono=3107777777, Email=proveedor_g@example.com, Dirección=Calle 7, Ciudad G'),
(1595, 8, 'INSERT', '2024-11-15 14:10:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor H, Teléfono=3108888888, Email=proveedor_h@example.com, Dirección=Calle 8, Ciudad H'),
(1596, 9, 'INSERT', '2024-11-15 14:10:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor I, Teléfono=3109999999, Email=proveedor_i@example.com, Dirección=Calle 9, Ciudad I'),
(1597, 10, 'INSERT', '2024-11-15 14:10:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor J, Teléfono=3101010101, Email=proveedor_j@example.com, Dirección=Calle 10, Ciudad J'),
(1598, 11, 'INSERT', '2024-11-15 14:10:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor K, Teléfono=3101111122, Email=proveedor_k@example.com, Dirección=Calle 11, Ciudad K'),
(1599, 12, 'INSERT', '2024-11-15 14:10:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor L, Teléfono=3102222233, Email=proveedor_l@example.com, Dirección=Calle 12, Ciudad L'),
(1600, 13, 'INSERT', '2024-11-15 14:10:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor M, Teléfono=3103333344, Email=proveedor_m@example.com, Dirección=Calle 13, Ciudad M'),
(1601, 14, 'INSERT', '2024-11-15 14:10:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor N, Teléfono=3104444455, Email=proveedor_n@example.com, Dirección=Calle 14, Ciudad N'),
(1602, 15, 'INSERT', '2024-11-15 14:10:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor O, Teléfono=3105555566, Email=proveedor_o@example.com, Dirección=Calle 15, Ciudad O'),
(1603, 16, 'INSERT', '2024-11-15 14:10:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor P, Teléfono=3106666677, Email=proveedor_p@example.com, Dirección=Calle 16, Ciudad P'),
(1604, 17, 'INSERT', '2024-11-15 14:10:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor Q, Teléfono=3107777788, Email=proveedor_q@example.com, Dirección=Calle 17, Ciudad Q'),
(1605, 18, 'INSERT', '2024-11-15 14:10:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor R, Teléfono=3108888899, Email=proveedor_r@example.com, Dirección=Calle 18, Ciudad R'),
(1606, 19, 'INSERT', '2024-11-15 14:10:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor S, Teléfono=3109999900, Email=proveedor_s@example.com, Dirección=Calle 19, Ciudad S'),
(1607, 20, 'INSERT', '2024-11-15 14:10:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor T, Teléfono=3101010203, Email=proveedor_t@example.com, Dirección=Calle 20, Ciudad T'),
(1608, 1, 'DELETE', '2024-11-15 14:10:54', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor A, Teléfono=3101111111, Email=proveedor_a@example.com, Dirección=Calle 1, Ciudad A'),
(1609, 2, 'DELETE', '2024-11-15 14:10:54', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor B, Teléfono=3102222222, Email=proveedor_b@example.com, Dirección=Calle 2, Ciudad B'),
(1610, 3, 'DELETE', '2024-11-15 14:10:54', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor C, Teléfono=3103333333, Email=proveedor_c@example.com, Dirección=Calle 3, Ciudad C'),
(1611, 4, 'DELETE', '2024-11-15 14:10:54', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor D, Teléfono=3104444444, Email=proveedor_d@example.com, Dirección=Calle 4, Ciudad D'),
(1612, 5, 'DELETE', '2024-11-15 14:10:54', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor E, Teléfono=3105555555, Email=proveedor_e@example.com, Dirección=Calle 5, Ciudad E'),
(1613, 6, 'DELETE', '2024-11-15 14:10:54', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor F, Teléfono=3106666666, Email=proveedor_f@example.com, Dirección=Calle 6, Ciudad F'),
(1614, 7, 'DELETE', '2024-11-15 14:10:54', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor G, Teléfono=3107777777, Email=proveedor_g@example.com, Dirección=Calle 7, Ciudad G'),
(1615, 8, 'DELETE', '2024-11-15 14:10:54', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor H, Teléfono=3108888888, Email=proveedor_h@example.com, Dirección=Calle 8, Ciudad H'),
(1616, 9, 'DELETE', '2024-11-15 14:10:54', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor I, Teléfono=3109999999, Email=proveedor_i@example.com, Dirección=Calle 9, Ciudad I'),
(1617, 10, 'DELETE', '2024-11-15 14:10:54', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor J, Teléfono=3101010101, Email=proveedor_j@example.com, Dirección=Calle 10, Ciudad J'),
(1618, 11, 'DELETE', '2024-11-15 14:10:54', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor K, Teléfono=3101111122, Email=proveedor_k@example.com, Dirección=Calle 11, Ciudad K'),
(1619, 12, 'DELETE', '2024-11-15 14:10:54', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor L, Teléfono=3102222233, Email=proveedor_l@example.com, Dirección=Calle 12, Ciudad L'),
(1620, 13, 'DELETE', '2024-11-15 14:10:54', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor M, Teléfono=3103333344, Email=proveedor_m@example.com, Dirección=Calle 13, Ciudad M'),
(1621, 14, 'DELETE', '2024-11-15 14:10:54', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor N, Teléfono=3104444455, Email=proveedor_n@example.com, Dirección=Calle 14, Ciudad N'),
(1622, 15, 'DELETE', '2024-11-15 14:10:54', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor O, Teléfono=3105555566, Email=proveedor_o@example.com, Dirección=Calle 15, Ciudad O'),
(1623, 16, 'DELETE', '2024-11-15 14:10:54', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor P, Teléfono=3106666677, Email=proveedor_p@example.com, Dirección=Calle 16, Ciudad P'),
(1624, 17, 'DELETE', '2024-11-15 14:10:54', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor Q, Teléfono=3107777788, Email=proveedor_q@example.com, Dirección=Calle 17, Ciudad Q'),
(1625, 18, 'DELETE', '2024-11-15 14:10:54', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor R, Teléfono=3108888899, Email=proveedor_r@example.com, Dirección=Calle 18, Ciudad R'),
(1626, 19, 'DELETE', '2024-11-15 14:10:54', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor S, Teléfono=3109999900, Email=proveedor_s@example.com, Dirección=Calle 19, Ciudad S'),
(1627, 20, 'DELETE', '2024-11-15 14:10:54', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor T, Teléfono=3101010203, Email=proveedor_t@example.com, Dirección=Calle 20, Ciudad T'),
(1628, 768, 'INSERT', '2024-11-16 16:00:41', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1629, 769, 'INSERT', '2024-11-16 16:00:41', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1630, 770, 'INSERT', '2024-11-16 16:00:41', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1631, 771, 'INSERT', '2024-11-16 16:00:41', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1632, 772, 'INSERT', '2024-11-16 16:00:41', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1633, 773, 'INSERT', '2024-11-16 16:11:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1634, 774, 'INSERT', '2024-11-16 16:11:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1635, 775, 'INSERT', '2024-11-16 16:11:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1636, 776, 'INSERT', '2024-11-16 16:11:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1637, 777, 'INSERT', '2024-11-16 16:11:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1638, 778, 'INSERT', '2024-11-16 16:14:56', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1639, 779, 'INSERT', '2024-11-16 16:14:56', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1640, 780, 'INSERT', '2024-11-16 16:14:56', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1641, 781, 'INSERT', '2024-11-16 16:14:56', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1642, 782, 'INSERT', '2024-11-16 16:14:56', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1643, 768, 'DELETE', '2024-11-16 16:31:21', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1644, 769, 'DELETE', '2024-11-16 16:31:21', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1645, 770, 'DELETE', '2024-11-16 16:31:21', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1646, 771, 'DELETE', '2024-11-16 16:31:21', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1647, 772, 'DELETE', '2024-11-16 16:31:21', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1648, 773, 'DELETE', '2024-11-16 16:31:21', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1649, 774, 'DELETE', '2024-11-16 16:31:21', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1650, 775, 'DELETE', '2024-11-16 16:31:21', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1651, 776, 'DELETE', '2024-11-16 16:31:21', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1652, 777, 'DELETE', '2024-11-16 16:31:21', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1653, 778, 'DELETE', '2024-11-16 16:31:21', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1654, 779, 'DELETE', '2024-11-16 16:31:21', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1655, 780, 'DELETE', '2024-11-16 16:31:21', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1656, 781, 'DELETE', '2024-11-16 16:31:21', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1657, 782, 'DELETE', '2024-11-16 16:31:21', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(1658, 783, 'INSERT', '2024-11-16 16:31:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40@gmail.com, Dirección=Ciudad 40'),
(1659, 784, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 1, Teléfono=3101111, Email=contacto1@gmail.com, Dirección=Ciudad 1'),
(1660, 785, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(1661, 786, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(1662, 787, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(1663, 788, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(1664, 789, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 6, Teléfono=3106666, Email=contacto6, Dirección=Ciudad 6'),
(1665, 790, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 7, Teléfono=3107777, Email=contacto7, Dirección=Ciudad 7'),
(1666, 791, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 8, Teléfono=3108888, Email=contacto8, Dirección=Ciudad 8'),
(1667, 792, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 9, Teléfono=3109999, Email=contacto9, Dirección=Ciudad 9'),
(1668, 793, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(1669, 794, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(1670, 795, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(1671, 796, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13'),
(1672, 797, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(1673, 798, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(1674, 799, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16');
INSERT INTO `Historial_Proveedores` (`id_historial`, `id_proveedor`, `tipo_accion`, `fecha_modificacion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`) VALUES
(1675, 800, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(1676, 801, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(1677, 802, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(1678, 803, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(1679, 804, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(1680, 805, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(1681, 806, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(1682, 807, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(1683, 808, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(1684, 809, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26'),
(1685, 810, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27'),
(1686, 811, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(1687, 812, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(1688, 813, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(1689, 814, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(1690, 815, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(1691, 816, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(1692, 817, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(1693, 818, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(1694, 819, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(1695, 820, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(1696, 821, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(1697, 822, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39'),
(1698, 823, 'INSERT', '2024-11-16 16:32:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(1699, 783, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40@gmail.com, Dirección=Ciudad 40'),
(1700, 784, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 1, Teléfono=3101111, Email=contacto1@gmail.com, Dirección=Ciudad 1'),
(1701, 785, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2, Dirección=Ciudad 2'),
(1702, 786, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3, Dirección=Ciudad 3'),
(1703, 787, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4, Dirección=Ciudad 4'),
(1704, 788, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5, Dirección=Ciudad 5'),
(1705, 789, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 6, Teléfono=3106666, Email=contacto6, Dirección=Ciudad 6'),
(1706, 790, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 7, Teléfono=3107777, Email=contacto7, Dirección=Ciudad 7'),
(1707, 791, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 8, Teléfono=3108888, Email=contacto8, Dirección=Ciudad 8'),
(1708, 792, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 9, Teléfono=3109999, Email=contacto9, Dirección=Ciudad 9'),
(1709, 793, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 10, Teléfono=31010101010, Email=contacto10, Dirección=Ciudad 10'),
(1710, 794, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 11, Teléfono=31011111111, Email=contacto11, Dirección=Ciudad 11'),
(1711, 795, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 12, Teléfono=31012121212, Email=contacto12, Dirección=Ciudad 12'),
(1712, 796, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 13, Teléfono=31013131313, Email=contacto13, Dirección=Ciudad 13'),
(1713, 797, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 14, Teléfono=31014141414, Email=contacto14, Dirección=Ciudad 14'),
(1714, 798, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 15, Teléfono=31015151515, Email=contacto15, Dirección=Ciudad 15'),
(1715, 799, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 16, Teléfono=31016161616, Email=contacto16, Dirección=Ciudad 16'),
(1716, 800, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 17, Teléfono=31017171717, Email=contacto17, Dirección=Ciudad 17'),
(1717, 801, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 18, Teléfono=31018181818, Email=contacto18, Dirección=Ciudad 18'),
(1718, 802, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 19, Teléfono=31019191919, Email=contacto19, Dirección=Ciudad 19'),
(1719, 803, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 20, Teléfono=31020202020, Email=contacto20, Dirección=Ciudad 20'),
(1720, 804, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 21, Teléfono=31021212121, Email=contacto21, Dirección=Ciudad 21'),
(1721, 805, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 22, Teléfono=31022222222, Email=contacto22, Dirección=Ciudad 22'),
(1722, 806, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 23, Teléfono=31023232323, Email=contacto23, Dirección=Ciudad 23'),
(1723, 807, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 24, Teléfono=31024242424, Email=contacto24, Dirección=Ciudad 24'),
(1724, 808, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 25, Teléfono=31025252525, Email=contacto25, Dirección=Ciudad 25'),
(1725, 809, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 26, Teléfono=31026262626, Email=contacto26, Dirección=Ciudad 26'),
(1726, 810, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 27, Teléfono=31027272727, Email=contacto27, Dirección=Ciudad 27'),
(1727, 811, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 28, Teléfono=31028282828, Email=contacto28, Dirección=Ciudad 28'),
(1728, 812, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 29, Teléfono=31029292929, Email=contacto29, Dirección=Ciudad 29'),
(1729, 813, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 30, Teléfono=31030303030, Email=contacto30, Dirección=Ciudad 30'),
(1730, 814, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 31, Teléfono=31031313131, Email=contacto31, Dirección=Ciudad 31'),
(1731, 815, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 32, Teléfono=31032323232, Email=contacto32, Dirección=Ciudad 32'),
(1732, 816, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 33, Teléfono=31033333333, Email=contacto33, Dirección=Ciudad 33'),
(1733, 817, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 34, Teléfono=31034343434, Email=contacto34, Dirección=Ciudad 34'),
(1734, 818, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 35, Teléfono=31035353535, Email=contacto35, Dirección=Ciudad 35'),
(1735, 819, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 36, Teléfono=31036363636, Email=contacto36, Dirección=Ciudad 36'),
(1736, 820, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 37, Teléfono=31037373737, Email=contacto37, Dirección=Ciudad 37'),
(1737, 821, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 38, Teléfono=31038383838, Email=contacto38, Dirección=Ciudad 38'),
(1738, 822, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 39, Teléfono=31039393939, Email=contacto39, Dirección=Ciudad 39'),
(1739, 823, 'DELETE', '2024-11-16 16:34:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor 40, Teléfono=31040404040, Email=contacto40, Dirección=Ciudad 40'),
(1740, 1, 'INSERT', '2024-11-16 16:34:06', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor A, Teléfono=3101111111, Email=proveedor_a@example.com, Dirección=Calle 1, Ciudad A'),
(1741, 2, 'INSERT', '2024-11-16 16:34:06', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor B, Teléfono=3102222222, Email=proveedor_b@example.com, Dirección=Calle 2, Ciudad B'),
(1742, 3, 'INSERT', '2024-11-16 16:34:06', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor C, Teléfono=3103333333, Email=proveedor_c@example.com, Dirección=Calle 3, Ciudad C'),
(1743, 4, 'INSERT', '2024-11-16 16:34:06', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor D, Teléfono=3104444444, Email=proveedor_d@example.com, Dirección=Calle 4, Ciudad D'),
(1744, 5, 'INSERT', '2024-11-16 16:34:06', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor E, Teléfono=3105555555, Email=proveedor_e@example.com, Dirección=Calle 5, Ciudad E'),
(1745, 6, 'INSERT', '2024-11-16 16:34:06', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor F, Teléfono=3106666666, Email=proveedor_f@example.com, Dirección=Calle 6, Ciudad F'),
(1746, 7, 'INSERT', '2024-11-16 16:34:06', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor G, Teléfono=3107777777, Email=proveedor_g@example.com, Dirección=Calle 7, Ciudad G'),
(1747, 8, 'INSERT', '2024-11-16 16:34:06', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor H, Teléfono=3108888888, Email=proveedor_h@example.com, Dirección=Calle 8, Ciudad H'),
(1748, 9, 'INSERT', '2024-11-16 16:34:06', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor I, Teléfono=3109999999, Email=proveedor_i@example.com, Dirección=Calle 9, Ciudad I'),
(1749, 10, 'INSERT', '2024-11-16 16:34:06', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor J, Teléfono=3101010101, Email=proveedor_j@example.com, Dirección=Calle 10, Ciudad J'),
(1750, 11, 'INSERT', '2024-11-16 16:34:06', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor K, Teléfono=3101111122, Email=proveedor_k@example.com, Dirección=Calle 11, Ciudad K'),
(1751, 12, 'INSERT', '2024-11-16 16:34:06', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor L, Teléfono=3102222233, Email=proveedor_l@example.com, Dirección=Calle 12, Ciudad L'),
(1752, 13, 'INSERT', '2024-11-16 16:34:06', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor M, Teléfono=3103333344, Email=proveedor_m@example.com, Dirección=Calle 13, Ciudad M'),
(1753, 14, 'INSERT', '2024-11-16 16:34:06', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor N, Teléfono=3104444455, Email=proveedor_n@example.com, Dirección=Calle 14, Ciudad N'),
(1754, 15, 'INSERT', '2024-11-16 16:34:06', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor O, Teléfono=3105555566, Email=proveedor_o@example.com, Dirección=Calle 15, Ciudad O'),
(1755, 16, 'INSERT', '2024-11-16 16:34:06', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor P, Teléfono=3106666677, Email=proveedor_p@example.com, Dirección=Calle 16, Ciudad P'),
(1756, 17, 'INSERT', '2024-11-16 16:34:06', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor Q, Teléfono=3107777788, Email=proveedor_q@example.com, Dirección=Calle 17, Ciudad Q'),
(1757, 18, 'INSERT', '2024-11-16 16:34:06', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor R, Teléfono=3108888899, Email=proveedor_r@example.com, Dirección=Calle 18, Ciudad R'),
(1758, 19, 'INSERT', '2024-11-16 16:34:06', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor S, Teléfono=3109999900, Email=proveedor_s@example.com, Dirección=Calle 19, Ciudad S'),
(1759, 20, 'INSERT', '2024-11-16 16:34:06', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor T, Teléfono=3101010203, Email=proveedor_t@example.com, Dirección=Calle 20, Ciudad T'),
(1760, 1, 'DELETE', '2024-11-16 20:34:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor A, Teléfono=3101111111, Email=proveedor_a@example.com, Dirección=Calle 1, Ciudad A'),
(1761, 2, 'DELETE', '2024-11-16 20:34:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor B, Teléfono=3102222222, Email=proveedor_b@example.com, Dirección=Calle 2, Ciudad B'),
(1762, 3, 'DELETE', '2024-11-16 20:34:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor C, Teléfono=3103333333, Email=proveedor_c@example.com, Dirección=Calle 3, Ciudad C'),
(1763, 4, 'DELETE', '2024-11-16 20:34:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor D, Teléfono=3104444444, Email=proveedor_d@example.com, Dirección=Calle 4, Ciudad D'),
(1764, 5, 'DELETE', '2024-11-16 20:34:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor E, Teléfono=3105555555, Email=proveedor_e@example.com, Dirección=Calle 5, Ciudad E'),
(1765, 6, 'DELETE', '2024-11-16 20:34:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor F, Teléfono=3106666666, Email=proveedor_f@example.com, Dirección=Calle 6, Ciudad F'),
(1766, 7, 'DELETE', '2024-11-16 20:34:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor G, Teléfono=3107777777, Email=proveedor_g@example.com, Dirección=Calle 7, Ciudad G'),
(1767, 8, 'DELETE', '2024-11-16 20:34:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor H, Teléfono=3108888888, Email=proveedor_h@example.com, Dirección=Calle 8, Ciudad H'),
(1768, 9, 'DELETE', '2024-11-16 20:34:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor I, Teléfono=3109999999, Email=proveedor_i@example.com, Dirección=Calle 9, Ciudad I'),
(1769, 10, 'DELETE', '2024-11-16 20:34:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor J, Teléfono=3101010101, Email=proveedor_j@example.com, Dirección=Calle 10, Ciudad J'),
(1770, 11, 'DELETE', '2024-11-16 20:34:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor K, Teléfono=3101111122, Email=proveedor_k@example.com, Dirección=Calle 11, Ciudad K'),
(1771, 12, 'DELETE', '2024-11-16 20:34:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor L, Teléfono=3102222233, Email=proveedor_l@example.com, Dirección=Calle 12, Ciudad L'),
(1772, 13, 'DELETE', '2024-11-16 20:34:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor M, Teléfono=3103333344, Email=proveedor_m@example.com, Dirección=Calle 13, Ciudad M'),
(1773, 14, 'DELETE', '2024-11-16 20:34:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor N, Teléfono=3104444455, Email=proveedor_n@example.com, Dirección=Calle 14, Ciudad N'),
(1774, 15, 'DELETE', '2024-11-16 20:34:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor O, Teléfono=3105555566, Email=proveedor_o@example.com, Dirección=Calle 15, Ciudad O'),
(1775, 16, 'DELETE', '2024-11-16 20:34:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor P, Teléfono=3106666677, Email=proveedor_p@example.com, Dirección=Calle 16, Ciudad P'),
(1776, 17, 'DELETE', '2024-11-16 20:34:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor Q, Teléfono=3107777788, Email=proveedor_q@example.com, Dirección=Calle 17, Ciudad Q'),
(1777, 18, 'DELETE', '2024-11-16 20:34:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor R, Teléfono=3108888899, Email=proveedor_r@example.com, Dirección=Calle 18, Ciudad R'),
(1778, 19, 'DELETE', '2024-11-16 20:34:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor S, Teléfono=3109999900, Email=proveedor_s@example.com, Dirección=Calle 19, Ciudad S'),
(1779, 20, 'DELETE', '2024-11-16 20:34:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Proveedor eliminado: Nombre=Proveedor T, Teléfono=3101010203, Email=proveedor_t@example.com, Dirección=Calle 20, Ciudad T'),
(1780, 824, 'INSERT', '2024-11-16 21:07:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 1, Teléfono=3101111, Email=contacto1@gmail.com, Dirección=Ciudad 1'),
(1781, 825, 'INSERT', '2024-11-16 21:07:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 2, Teléfono=3102222, Email=contacto2@gmail.com, Dirección=Ciudad 2'),
(1782, 826, 'INSERT', '2024-11-16 21:07:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 3, Teléfono=3103333, Email=contacto3@gmail.com, Dirección=Ciudad 3'),
(1783, 827, 'INSERT', '2024-11-16 21:07:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 4, Teléfono=3104444, Email=contacto4@gmail.com, Dirección=Ciudad 4'),
(1784, 828, 'INSERT', '2024-11-16 21:07:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo proveedor: Nombre=Proveedor 5, Teléfono=3105555, Email=contacto5@gmail.com, Dirección=Ciudad 5');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Historial_Reportes`
--

CREATE TABLE `Historial_Reportes` (
  `id_historial` int(11) NOT NULL,
  `id_reporte` int(11) NOT NULL,
  `tipo_accion` enum('INSERT','UPDATE','DELETE') NOT NULL,
  `fecha_modificacion` datetime DEFAULT current_timestamp(),
  `usuario_modifico` varchar(100) DEFAULT NULL,
  `ip_origen` varchar(45) DEFAULT NULL,
  `descripcion_cambio` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `Historial_Reportes`
--

INSERT INTO `Historial_Reportes` (`id_historial`, `id_reporte`, `tipo_accion`, `fecha_modificacion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`) VALUES
(1, 7, 'INSERT', '2024-11-11 14:03:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(2, 8, 'INSERT', '2024-11-11 14:07:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo reporte: Tipo=Ventas, Formato=csv, Nombre=reporte_ventas_1, Ruta=reportes/reporte_ventas_1_2024-11-12_08-25-10.csv'),
(3, 23, 'INSERT', '2024-11-11 14:08:16', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo reporte: Tipo=Ventas, Formato=csv, Nombre=reporte_ventas_1, Ruta=reportes/reporte_ventas_1_2024-11-12_08-25-10.csv'),
(4, 9, 'INSERT', '2024-11-11 14:08:16', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo reporte: Tipo=Inventario, Formato=csv, Nombre=reporte_inventario_1, Ruta=reportes/reporte_inventario_1_2024-11-12_09-15-45.csv'),
(5, 10, 'INSERT', '2024-11-11 14:08:16', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo reporte: Tipo=Compras, Formato=csv, Nombre=reporte_compras_2, Ruta=reportes/reporte_compras_2_2024-11-13_10-10-15.csv'),
(6, 11, 'INSERT', '2024-11-11 14:08:16', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo reporte: Tipo=Ventas, Formato=csv, Nombre=reporte_ventas_2, Ruta=reportes/reporte_ventas_2_2024-11-14_11-20-30.csv'),
(7, 12, 'INSERT', '2024-11-11 14:08:16', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo reporte: Tipo=Inventario, Formato=csv, Nombre=reporte_inventario_2, Ruta=reportes/reporte_inventario_2_2024-11-14_12-30-00.csv'),
(8, 13, 'INSERT', '2024-11-11 14:08:16', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo reporte: Tipo=Compras, Formato=csv, Nombre=reporte_compras_3, Ruta=reportes/reporte_compras_3_2024-11-15_13-40-22.csv'),
(9, 14, 'INSERT', '2024-11-11 14:08:16', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo reporte: Tipo=Ventas, Formato=csv, Nombre=reporte_ventas_3, Ruta=reportes/reporte_ventas_3_2024-11-16_14-50-45.csv'),
(10, 15, 'INSERT', '2024-11-11 14:08:16', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo reporte: Tipo=Inventario, Formato=csv, Nombre=reporte_inventario_3, Ruta=reportes/reporte_inventario_3_2024-11-17_15-05-30.csv'),
(11, 16, 'INSERT', '2024-11-11 14:08:16', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo reporte: Tipo=Compras, Formato=csv, Nombre=reporte_compras_4, Ruta=reportes/reporte_compras_4_2024-11-18_16-15-45.csv'),
(12, 17, 'INSERT', '2024-11-11 14:08:16', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo reporte: Tipo=Ventas, Formato=csv, Nombre=reporte_ventas_4, Ruta=reportes/reporte_ventas_4_2024-11-19_17-25-10.csv'),
(13, 18, 'INSERT', '2024-11-11 14:08:16', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo reporte: Tipo=Inventario, Formato=csv, Nombre=reporte_inventario_4, Ruta=reportes/reporte_inventario_4_2024-11-20_18-35-25.csv'),
(14, 19, 'INSERT', '2024-11-11 14:08:16', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo reporte: Tipo=Compras, Formato=csv, Nombre=reporte_compras_5, Ruta=reportes/reporte_compras_5_2024-11-21_19-45-40.csv'),
(15, 20, 'INSERT', '2024-11-11 14:08:16', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo reporte: Tipo=Ventas, Formato=csv, Nombre=reporte_ventas_5, Ruta=reportes/reporte_ventas_5_2024-11-22_20-55-55.csv'),
(16, 21, 'INSERT', '2024-11-11 14:08:16', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo reporte: Tipo=Inventario, Formato=csv, Nombre=reporte_inventario_5, Ruta=reportes/reporte_inventario_5_2024-11-23_21-05-10.csv'),
(17, 22, 'INSERT', '2024-11-11 14:08:16', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo reporte: Tipo=Compras, Formato=csv, Nombre=reporte_compras_6, Ruta=reportes/reporte_compras_6_2024-11-24_22-15-25.csv'),
(18, 24, 'INSERT', '2024-11-11 15:10:21', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(19, 25, 'INSERT', '2024-11-11 15:11:17', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(20, 26, 'INSERT', '2024-11-11 15:13:11', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(21, 27, 'INSERT', '2024-11-11 15:13:21', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(22, 28, 'INSERT', '2024-11-11 15:15:17', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(23, 8, 'DELETE', '2024-11-11 15:20:16', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Reporte eliminado: Tipo=Ventas, Formato=csv, Nombre=reporte_ventas_1, Ruta=reportes/reporte_ventas_1_2024-11-12_08-25-10.csv'),
(24, 9, 'DELETE', '2024-11-11 15:20:18', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Reporte eliminado: Tipo=Inventario, Formato=csv, Nombre=reporte_inventario_1, Ruta=reportes/reporte_inventario_1_2024-11-12_09-15-45.csv'),
(25, 10, 'DELETE', '2024-11-11 15:20:21', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Reporte eliminado: Tipo=Compras, Formato=csv, Nombre=reporte_compras_2, Ruta=reportes/reporte_compras_2_2024-11-13_10-10-15.csv'),
(26, 11, 'DELETE', '2024-11-11 15:20:24', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Reporte eliminado: Tipo=Ventas, Formato=csv, Nombre=reporte_ventas_2, Ruta=reportes/reporte_ventas_2_2024-11-14_11-20-30.csv'),
(27, 12, 'DELETE', '2024-11-11 15:20:26', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Reporte eliminado: Tipo=Inventario, Formato=csv, Nombre=reporte_inventario_2, Ruta=reportes/reporte_inventario_2_2024-11-14_12-30-00.csv'),
(28, 13, 'DELETE', '2024-11-11 15:20:28', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Reporte eliminado: Tipo=Compras, Formato=csv, Nombre=reporte_compras_3, Ruta=reportes/reporte_compras_3_2024-11-15_13-40-22.csv'),
(29, 14, 'DELETE', '2024-11-11 15:20:30', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Reporte eliminado: Tipo=Ventas, Formato=csv, Nombre=reporte_ventas_3, Ruta=reportes/reporte_ventas_3_2024-11-16_14-50-45.csv'),
(30, 15, 'DELETE', '2024-11-11 15:20:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Reporte eliminado: Tipo=Inventario, Formato=csv, Nombre=reporte_inventario_3, Ruta=reportes/reporte_inventario_3_2024-11-17_15-05-30.csv'),
(31, 16, 'DELETE', '2024-11-11 15:20:35', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Reporte eliminado: Tipo=Compras, Formato=csv, Nombre=reporte_compras_4, Ruta=reportes/reporte_compras_4_2024-11-18_16-15-45.csv'),
(32, 17, 'DELETE', '2024-11-11 15:20:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Reporte eliminado: Tipo=Ventas, Formato=csv, Nombre=reporte_ventas_4, Ruta=reportes/reporte_ventas_4_2024-11-19_17-25-10.csv'),
(33, 18, 'DELETE', '2024-11-11 15:20:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Reporte eliminado: Tipo=Inventario, Formato=csv, Nombre=reporte_inventario_4, Ruta=reportes/reporte_inventario_4_2024-11-20_18-35-25.csv'),
(34, 19, 'DELETE', '2024-11-11 15:20:40', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Reporte eliminado: Tipo=Compras, Formato=csv, Nombre=reporte_compras_5, Ruta=reportes/reporte_compras_5_2024-11-21_19-45-40.csv'),
(35, 20, 'DELETE', '2024-11-11 15:20:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Reporte eliminado: Tipo=Ventas, Formato=csv, Nombre=reporte_ventas_5, Ruta=reportes/reporte_ventas_5_2024-11-22_20-55-55.csv'),
(36, 21, 'DELETE', '2024-11-11 15:20:43', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Reporte eliminado: Tipo=Inventario, Formato=csv, Nombre=reporte_inventario_5, Ruta=reportes/reporte_inventario_5_2024-11-23_21-05-10.csv'),
(37, 22, 'DELETE', '2024-11-11 15:20:46', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Reporte eliminado: Tipo=Compras, Formato=csv, Nombre=reporte_compras_6, Ruta=reportes/reporte_compras_6_2024-11-24_22-15-25.csv'),
(38, 23, 'DELETE', '2024-11-11 15:20:48', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Reporte eliminado: Tipo=Ventas, Formato=csv, Nombre=reporte_ventas_1, Ruta=reportes/reporte_ventas_1_2024-11-12_08-25-10.csv'),
(39, 29, 'INSERT', '2025-04-01 23:01:37', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Historial_Salidas_Inventario`
--

CREATE TABLE `Historial_Salidas_Inventario` (
  `id_historial` int(11) NOT NULL,
  `id_salida` int(11) NOT NULL,
  `id_producto` int(11) NOT NULL,
  `cantidad_salida` int(11) NOT NULL,
  `fecha_salida` datetime NOT NULL,
  `usuario_registro` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Historial_Usuarios`
--

CREATE TABLE `Historial_Usuarios` (
  `id_historial` int(11) NOT NULL,
  `id_usuario` int(11) NOT NULL,
  `tipo_accion` enum('INSERT','UPDATE','DELETE') NOT NULL,
  `fecha_modificacion` datetime DEFAULT current_timestamp(),
  `usuario_modifico` varchar(100) DEFAULT NULL,
  `ip_origen` varchar(45) DEFAULT NULL,
  `descripcion_cambio` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `Historial_Usuarios`
--

INSERT INTO `Historial_Usuarios` (`id_historial`, `id_usuario`, `tipo_accion`, `fecha_modificacion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`) VALUES
(1, 2, 'UPDATE', '2024-11-11 11:09:28', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(2, 11, 'INSERT', '2024-11-11 12:25:08', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(3, 11, 'UPDATE', '2024-11-11 12:27:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(4, 11, 'UPDATE', '2024-11-11 12:33:45', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Rol cambió de Usuario a Empleado. '),
(5, 11, 'UPDATE', '2024-11-11 12:50:03', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Rol cambió de Empleado a Usuario. '),
(6, 11, 'UPDATE', '2024-11-11 12:50:24', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Rol cambió de Usuario a Empleado. '),
(7, 1, 'UPDATE', '2024-11-11 12:58:20', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(8, 12, 'INSERT', '2024-11-11 13:41:11', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(9, 12, 'UPDATE', '2024-11-11 13:41:56', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(10, 12, 'UPDATE', '2024-11-11 13:42:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(11, 12, 'UPDATE', '2024-11-11 13:43:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Rol cambió de Usuario a Administrador. '),
(12, 12, 'UPDATE', '2024-11-11 13:44:33', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(13, 12, 'UPDATE', '2024-11-11 13:44:59', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(14, 12, 'UPDATE', '2024-11-11 13:46:33', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(15, 2, 'UPDATE', '2024-11-11 14:00:16', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Rol cambió de Usuario a Administrador. '),
(16, 13, 'INSERT', '2024-11-11 14:00:53', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo registro: Nombre=test, Correo=testertester@gmail.com, Rol=Usuario, Estado=Inactivo'),
(17, 5, 'UPDATE', '2024-11-11 14:01:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Estado cambió de Activo a Inactivo. '),
(18, 5, 'UPDATE', '2024-11-11 14:02:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Estado cambió de Inactivo a Activo. '),
(19, 1, 'UPDATE', '2024-11-11 15:10:52', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(20, 14, 'INSERT', '2024-11-11 15:13:01', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(21, 14, 'UPDATE', '2024-11-11 15:13:55', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Rol cambió de Usuario a Administrador. '),
(22, 14, 'UPDATE', '2024-11-11 15:15:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(23, 14, 'UPDATE', '2024-11-11 15:19:14', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(24, 3, 'UPDATE', '2024-11-11 15:25:40', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Rol cambió de Usuario a Administrador. '),
(25, 3, 'UPDATE', '2024-11-11 15:50:35', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(26, 1, 'UPDATE', '2024-11-11 15:57:41', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(27, 6, 'DELETE', '2024-11-11 16:08:50', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(28, 7, 'DELETE', '2024-11-11 16:08:54', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(29, 14, 'UPDATE', '2024-11-11 16:39:53', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(30, 14, 'UPDATE', '2024-11-11 16:46:29', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(31, 15, 'INSERT', '2024-11-11 16:47:56', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(32, 14, 'DELETE', '2024-11-11 16:48:34', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Registro eliminado: Nombre=Limber Magaña, Correo=limbernicko@gmail.com, Rol=Administrador, Estado=Activo'),
(33, 15, 'UPDATE', '2024-11-11 16:48:51', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Rol cambió de Usuario a Administrador. '),
(34, 15, 'UPDATE', '2024-11-11 16:49:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(35, 13, 'DELETE', '2024-11-11 16:52:36', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Registro eliminado: Nombre=test, Correo=testertester@gmail.com, Rol=Usuario, Estado=Inactivo'),
(36, 10, 'DELETE', '2024-11-11 16:52:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(37, 16, 'INSERT', '2024-11-11 16:53:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(38, 16, 'UPDATE', '2024-11-11 16:54:52', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(39, 16, 'UPDATE', '2024-11-11 16:55:17', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Rol cambió de Usuario a Administrador. '),
(40, 16, 'UPDATE', '2024-11-11 16:55:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(41, 15, 'DELETE', '2024-11-11 19:37:04', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Registro eliminado: Nombre=Limber Magaña, Correo=limbernicko8@gmail.com, Rol=Administrador, Estado=Activo'),
(42, 16, 'DELETE', '2024-11-11 19:37:07', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Registro eliminado: Nombre=limber, Correo=limbernicko9@gmail.com, Rol=Administrador, Estado=Activo'),
(43, 17, 'INSERT', '2024-11-11 20:12:54', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(44, 17, 'UPDATE', '2024-11-11 20:13:37', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Rol cambió de Usuario a Administrador. '),
(45, 18, 'INSERT', '2024-11-11 20:25:43', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(46, 18, 'DELETE', '2024-11-11 20:26:08', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(47, 19, 'INSERT', '2024-11-11 20:26:38', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(48, 20, 'INSERT', '2024-11-11 20:29:09', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(49, 20, 'UPDATE', '2024-11-11 20:30:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Rol cambió de Usuario a Empleado. '),
(50, 5, 'UPDATE', '2024-11-13 15:15:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(51, 5, 'UPDATE', '2024-11-13 15:16:17', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(52, 21, 'INSERT', '2024-11-13 15:17:05', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(53, 5, 'UPDATE', '2024-11-15 06:52:43', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(54, 5, 'UPDATE', '2024-11-15 07:43:49', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Rol cambió de Administrador a Usuario. '),
(55, 22, 'INSERT', '2024-11-15 15:59:22', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(56, 23, 'INSERT', '2024-11-21 19:57:33', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(57, 3, 'DELETE', '2025-01-28 20:02:56', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(58, 24, 'INSERT', '2025-01-28 20:03:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(59, 24, 'UPDATE', '2025-01-28 20:05:32', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(60, 24, 'UPDATE', '2025-01-28 20:06:17', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(61, 24, 'UPDATE', '2025-01-28 20:08:47', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Rol cambió de Usuario a Administrador. '),
(62, 19, 'UPDATE', '2025-01-28 20:46:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Rol cambió de Usuario a Administrador. '),
(63, 19, 'UPDATE', '2025-01-28 20:47:35', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(64, 19, 'UPDATE', '2025-01-28 20:51:50', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(65, 25, 'INSERT', '2025-01-29 05:11:39', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo registro: Nombre=12345, Correo=dulceitamar@hotmail.com, Rol=Usuario, Estado=Activo'),
(66, 25, 'DELETE', '2025-01-29 05:24:11', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Registro eliminado: Nombre=12345, Correo=dulceitamar@hotmail.com, Rol=Usuario, Estado=Activo'),
(67, 26, 'INSERT', '2025-01-29 05:26:05', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Nuevo registro: Nombre=Dulce Vigueras, Correo=dulceitamar@hotmail.com, Rol=Usuario, Estado=Activo'),
(68, 27, 'INSERT', '2025-01-29 23:52:11', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(69, 19, 'UPDATE', '2025-01-30 01:16:44', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Rol cambió de Administrador a Empleado. '),
(70, 19, 'UPDATE', '2025-01-30 01:18:21', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(71, 19, 'UPDATE', '2025-01-30 01:20:24', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Rol cambió de Empleado a . '),
(72, 19, 'UPDATE', '2025-01-30 01:20:42', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(73, 2, 'DELETE', '2025-01-30 03:48:37', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Registro eliminado: Nombre=limber, Correo=limbermagana85@gmail.com, Rol=Administrador, Estado=Activo'),
(74, 24, 'UPDATE', '2025-01-30 19:35:52', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(75, 24, 'UPDATE', '2025-01-30 21:42:50', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(76, 26, 'DELETE', '2025-01-30 21:47:17', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Registro eliminado: Nombre=Dulce Vigueras, Correo=dulceitamar@hotmail.com, Rol=Usuario, Estado=Activo'),
(77, 27, 'UPDATE', '2025-01-30 23:46:25', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(78, 27, 'UPDATE', '2025-01-30 23:58:16', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(79, 11, 'DELETE', '2025-02-06 03:26:35', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Registro eliminado: Nombre=Juan Pablo, Correo=jpcaicedo@gmail.com, Rol=Empleado, Estado=Activo'),
(80, 33, 'INSERT', '2025-02-06 03:27:10', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(81, 34, 'INSERT', '2025-02-06 03:27:40', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(82, 1, 'UPDATE', '2025-02-06 03:28:20', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(83, 1, 'UPDATE', '2025-02-06 03:28:50', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(84, 4, 'UPDATE', '2025-02-06 03:52:02', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(85, 1, 'UPDATE', '2025-02-06 03:52:37', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(86, 4, 'UPDATE', '2025-02-06 03:52:41', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(87, 1, 'UPDATE', '2025-02-06 03:54:28', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', ''),
(88, 35, 'INSERT', '2025-02-16 22:21:31', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', NULL),
(89, 35, 'UPDATE', '2025-02-18 15:39:35', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Rol cambió de Usuario a Administrador. '),
(90, 1, 'DELETE', '2025-04-07 00:44:57', 'u781177445_limber@127.0.0.1', 'IP_DEL_USUARIO', 'Registro eliminado: Nombre=test, Correo=admin@admi, Rol=Administrador, Estado=Activo');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Historial_Ventas`
--

CREATE TABLE `Historial_Ventas` (
  `id_historial` int(11) NOT NULL,
  `id_venta` int(11) NOT NULL,
  `id_producto` int(11) NOT NULL,
  `cantidad_vendida` int(11) NOT NULL,
  `fecha_venta` datetime NOT NULL,
  `monto_total` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `incidentes_soporte`
--

CREATE TABLE `incidentes_soporte` (
  `id_incidente` int(11) NOT NULL,
  `descripcion_incidente` text DEFAULT NULL,
  `fecha_reporte` datetime DEFAULT NULL,
  `prioridad` enum('Alta','Media','Baja') DEFAULT NULL,
  `estado_incidente` enum('Abierto','En Proceso','Cerrado') DEFAULT NULL,
  `usuario_reporta` int(11) DEFAULT NULL,
  `usuario_responsable` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `incidentes_soporte`
--

INSERT INTO `incidentes_soporte` (`id_incidente`, `descripcion_incidente`, `fecha_reporte`, `prioridad`, `estado_incidente`, `usuario_reporta`, `usuario_responsable`) VALUES
(1, 'Arreglar todo el codigo ', '2024-11-11 13:17:50', 'Alta', 'En Proceso', 11, NULL),
(3, 'Error al cargar el inventario', '2024-02-03 11:45:00', 'Media', 'Abierto', 4, 2),
(4, 'Problema con el acceso a la aplicación', '2024-02-04 14:20:00', 'Baja', 'Cerrado', 5, 3),
(5, 'Incidente de autenticación de usuario', '2024-02-05 16:50:00', 'Alta', 'En Proceso', 2, 3),
(11, 'Prueba 3', '2024-11-11 13:24:21', 'Alta', 'En Proceso', 11, NULL),
(12, 'tarea test', '2024-11-11 13:55:04', 'Media', 'En Proceso', 12, NULL),
(13, 'Incidente de prueba', '2025-02-06 21:34:40', 'Alta', 'En Proceso', 1, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `IntentosInyeccionSQL`
--

CREATE TABLE `IntentosInyeccionSQL` (
  `id` int(11) NOT NULL,
  `intento` text NOT NULL,
  `ip` varchar(45) NOT NULL,
  `fecha` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `IntentosInyeccionSQL`
--

INSERT INTO `IntentosInyeccionSQL` (`id`, `intento`, `ip`, `fecha`) VALUES
(1, '\'; DROP TABLE Usuarios;--', '2800:484:4b72:df50::3605', '2024-11-11 10:28:41'),
(2, 'SELECT * FROM IntentosInyeccionSQL;', '2800:484:4b72:df50::6d03', '2024-11-11 12:26:13'),
(3, '\'; DROP TABLE Usuarios;--', '2800:484:4b72:df50::3605', '2024-11-11 14:23:48');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Inventario`
--

CREATE TABLE `Inventario` (
  `id_producto` int(11) NOT NULL,
  `nombre_producto` varchar(100) DEFAULT NULL,
  `cantidad_disponible` int(11) DEFAULT NULL,
  `stock_minimo` int(11) DEFAULT NULL,
  `fecha_ultima_actualizacion` datetime DEFAULT NULL,
  `ubicacion_id` int(11) DEFAULT NULL,
  `id_proveedor` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `Inventario`
--

INSERT INTO `Inventario` (`id_producto`, `nombre_producto`, `cantidad_disponible`, `stock_minimo`, `fecha_ultima_actualizacion`, `ubicacion_id`, `id_proveedor`) VALUES
(4, 'VinilAC', -3, 5, '2024-11-11 21:34:40', NULL, NULL),
(8, 'vinil', 0, 10, '2024-11-29 04:45:23', NULL, NULL),
(9, 'textiles', 37, 10, '2024-11-11 13:53:32', NULL, NULL),
(10, 'Ventana', 4, 2, '2024-11-11 15:57:02', NULL, NULL),
(11, 'vinil2', 3, 2, '2024-11-29 04:43:41', NULL, NULL),
(12, 'Tinta Roja', 500, 200, '2025-01-27 23:44:29', NULL, NULL),
(13, 'Libretas Paper Mate', 0, -52, '2025-01-30 22:16:30', NULL, NULL),
(14, 'Tazas Hernandez', -25, 50, '2025-01-30 22:30:50', NULL, NULL);

--
-- Disparadores `Inventario`
--
DELIMITER $$
CREATE TRIGGER `Inventario_after_delete` AFTER DELETE ON `Inventario` FOR EACH ROW BEGIN
    DECLARE ip_origen VARCHAR(45);
    SET ip_origen = 'IP_DEL_USUARIO';

    INSERT INTO `Historial_Inventario` (`id_producto`, `tipo_accion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`)
    VALUES (OLD.id_producto, 'DELETE', USER(), ip_origen,
        CONCAT('Producto eliminado: Nombre=', OLD.nombre_producto, ', Cantidad=', OLD.cantidad_disponible, ', Stock mínimo=', OLD.stock_minimo));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `Inventario_after_insert` AFTER INSERT ON `Inventario` FOR EACH ROW BEGIN
    DECLARE ip_origen VARCHAR(45);
    SET ip_origen = 'IP_DEL_USUARIO';

    INSERT INTO `Historial_Inventario` (`id_producto`, `tipo_accion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`)
    VALUES (NEW.id_producto, 'INSERT', USER(), ip_origen,
        CONCAT('Nuevo producto en inventario: Nombre=', NEW.nombre_producto, ', Cantidad=', NEW.cantidad_disponible, ', Stock mínimo=', NEW.stock_minimo));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `Inventario_after_update` AFTER UPDATE ON `Inventario` FOR EACH ROW BEGIN
    DECLARE ip_origen VARCHAR(45);
    DECLARE descripcion TEXT;
    SET ip_origen = 'IP_DEL_USUARIO';
    SET descripcion = '';

    IF OLD.nombre_producto <> NEW.nombre_producto THEN
        SET descripcion = CONCAT(descripcion, 'Nombre cambió de ', OLD.nombre_producto, ' a ', NEW.nombre_producto, '. ');
    END IF;

    IF OLD.cantidad_disponible <> NEW.cantidad_disponible THEN
        SET descripcion = CONCAT(descripcion, 'Cantidad disponible cambió de ', OLD.cantidad_disponible, ' a ', NEW.cantidad_disponible, '. ');
    END IF;

    IF OLD.stock_minimo <> NEW.stock_minimo THEN
        SET descripcion = CONCAT(descripcion, 'Stock mínimo cambió de ', OLD.stock_minimo, ' a ', NEW.stock_minimo, '. ');
    END IF;

    INSERT INTO `Historial_Inventario` (`id_producto`, `tipo_accion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`)
    VALUES (NEW.id_producto, 'UPDATE', USER(), ip_origen, descripcion);
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Proveedores`
--

CREATE TABLE `Proveedores` (
  `id_proveedor` int(11) NOT NULL,
  `nombre_proveedor` varchar(100) DEFAULT NULL,
  `telefono` varchar(15) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `direccion` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `Proveedores`
--

INSERT INTO `Proveedores` (`id_proveedor`, `nombre_proveedor`, `telefono`, `email`, `direccion`) VALUES
(824, 'Proveedor 1', '3101111', 'contacto1@gmail.com', 'Ciudad 1'),
(825, 'Proveedor 2', '3102222', 'contacto2@gmail.com', 'Ciudad 2'),
(826, 'Proveedor 3', '3103333', 'contacto3@gmail.com', 'Ciudad 3'),
(827, 'Proveedor 4', '3104444', 'contacto4@gmail.com', 'Ciudad 4'),
(828, 'Proveedor 5', '3105555', 'contacto5@gmail.com', 'Ciudad 5');

--
-- Disparadores `Proveedores`
--
DELIMITER $$
CREATE TRIGGER `Proveedores_after_delete` AFTER DELETE ON `Proveedores` FOR EACH ROW BEGIN
    DECLARE ip_origen VARCHAR(45);
    SET ip_origen = 'IP_DEL_USUARIO';

    INSERT INTO `Historial_Proveedores` (`id_proveedor`, `tipo_accion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`)
    VALUES (OLD.id_proveedor, 'DELETE', USER(), ip_origen,
        CONCAT('Proveedor eliminado: Nombre=', OLD.nombre_proveedor, ', Teléfono=', OLD.telefono, ', Email=', OLD.email, ', Dirección=', OLD.direccion));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `Proveedores_after_insert` AFTER INSERT ON `Proveedores` FOR EACH ROW BEGIN
    DECLARE ip_origen VARCHAR(45);
    SET ip_origen = 'IP_DEL_USUARIO';

    INSERT INTO `Historial_Proveedores` (`id_proveedor`, `tipo_accion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`)
    VALUES (NEW.id_proveedor, 'INSERT', USER(), ip_origen,
        CONCAT('Nuevo proveedor: Nombre=', NEW.nombre_proveedor, ', Teléfono=', NEW.telefono, ', Email=', NEW.email, ', Dirección=', NEW.direccion));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `Proveedores_after_update` AFTER UPDATE ON `Proveedores` FOR EACH ROW BEGIN
    DECLARE ip_origen VARCHAR(45);
    DECLARE descripcion TEXT;
    SET ip_origen = 'IP_DEL_USUARIO';
    SET descripcion = '';

    IF OLD.nombre_proveedor <> NEW.nombre_proveedor THEN
        SET descripcion = CONCAT(descripcion, 'Nombre cambió de ', OLD.nombre_proveedor, ' a ', NEW.nombre_proveedor, '. ');
    END IF;

    IF OLD.telefono <> NEW.telefono THEN
        SET descripcion = CONCAT(descripcion, 'Teléfono cambió de ', OLD.telefono, ' a ', NEW.telefono, '. ');
    END IF;

    IF OLD.email <> NEW.email THEN
        SET descripcion = CONCAT(descripcion, 'Email cambió de ', OLD.email, ' a ', NEW.email, '. ');
    END IF;

    IF OLD.direccion <> NEW.direccion THEN
        SET descripcion = CONCAT(descripcion, 'Dirección cambió de ', OLD.direccion, ' a ', NEW.direccion, '. ');
    END IF;

    INSERT INTO `Historial_Proveedores` (`id_proveedor`, `tipo_accion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`)
    VALUES (NEW.id_proveedor, 'UPDATE', USER(), ip_origen, descripcion);
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Reportes`
--

CREATE TABLE `Reportes` (
  `id_reporte` int(11) NOT NULL,
  `tipo_reporte` varchar(255) NOT NULL,
  `fecha_generacion` datetime DEFAULT current_timestamp(),
  `formato_reporte` varchar(50) DEFAULT NULL,
  `usuario_genero` int(11) DEFAULT NULL,
  `nombre` varchar(255) DEFAULT NULL,
  `tipo` varchar(50) DEFAULT NULL,
  `ruta_archivo` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `Reportes`
--

INSERT INTO `Reportes` (`id_reporte`, `tipo_reporte`, `fecha_generacion`, `formato_reporte`, `usuario_genero`, `nombre`, `tipo`, `ruta_archivo`) VALUES
(2, '', '2024-11-11 06:25:06', NULL, NULL, 'Compras', 'CSV', 'reportes/reporte_Compras_2024-11-11_06-25-06.csv'),
(3, '', '2024-11-11 06:27:28', NULL, NULL, 'test', 'csv', 'reportes/test_2024-11-11_06-27-28.csv'),
(4, '', '2024-11-11 06:29:03', NULL, NULL, 'asfdsf', 'csv', 'reportes/asfdsf_2024-11-11_06-29-03.csv'),
(5, '', '2024-11-11 06:29:44', NULL, NULL, 'asfdsf', 'csv', 'reportes/asfdsf_2024-11-11_06-29-44.csv'),
(7, '', '2024-11-11 14:03:36', NULL, NULL, 'test_compras', 'csv', 'reportes/test_compras_2024-11-11_14-03-36.csv'),
(24, '', '2024-11-11 15:10:21', NULL, NULL, 'fgdsgs', 'pdf', 'reportes/fgdsgs_2024-11-11_15-10-21.pdf'),
(25, '', '2024-11-11 15:11:17', NULL, NULL, 'fgdsgs', 'pdf', 'reportes/fgdsgs_2024-11-11_15-11-17.pdf'),
(26, '', '2024-11-11 15:13:11', NULL, NULL, 'etasdf', 'pdf', 'reportes/etasdf_2024-11-11_15-13-11.pdf'),
(27, '', '2024-11-11 15:13:21', NULL, NULL, 'gsfdgsd', 'pdf', 'reportes/gsfdgsd_2024-11-11_15-13-21.pdf'),
(28, '', '2024-11-11 15:15:17', NULL, NULL, 'gsfdgsd', 'pdf', 'reportes/gsfdgsd_2024-11-11_15-15-17.pdf'),
(29, '', '2025-04-01 23:01:37', NULL, NULL, '1', 'pdf', 'reportes/1_2025-04-01_23-01-37.pdf');

--
-- Disparadores `Reportes`
--
DELIMITER $$
CREATE TRIGGER `Reportes_after_delete` AFTER DELETE ON `Reportes` FOR EACH ROW BEGIN
    DECLARE ip_origen VARCHAR(45);
    SET ip_origen = 'IP_DEL_USUARIO';

    INSERT INTO `Historial_Reportes` (`id_reporte`, `tipo_accion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`)
    VALUES (OLD.id_reporte, 'DELETE', USER(), ip_origen,
        CONCAT('Reporte eliminado: Tipo=', OLD.tipo_reporte, ', Formato=', OLD.formato_reporte, ', Nombre=', OLD.nombre, ', Ruta=', OLD.ruta_archivo));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `Reportes_after_insert` AFTER INSERT ON `Reportes` FOR EACH ROW BEGIN
    DECLARE ip_origen VARCHAR(45);
    SET ip_origen = 'IP_DEL_USUARIO';

    INSERT INTO `Historial_Reportes` (`id_reporte`, `tipo_accion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`)
    VALUES (NEW.id_reporte, 'INSERT', USER(), ip_origen,
        CONCAT('Nuevo reporte: Tipo=', NEW.tipo_reporte, ', Formato=', NEW.formato_reporte, ', Nombre=', NEW.nombre, ', Ruta=', NEW.ruta_archivo));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `Reportes_after_update` AFTER UPDATE ON `Reportes` FOR EACH ROW BEGIN
    DECLARE ip_origen VARCHAR(45);
    DECLARE descripcion TEXT;
    SET ip_origen = 'IP_DEL_USUARIO';
    SET descripcion = '';

    IF OLD.tipo_reporte <> NEW.tipo_reporte THEN
        SET descripcion = CONCAT(descripcion, 'Tipo de reporte cambió de ', OLD.tipo_reporte, ' a ', NEW.tipo_reporte, '. ');
    END IF;

   
    IF OLD.formato_reporte <> NEW.formato_reporte THEN
        SET descripcion = CONCAT(descripcion, 'Formato de reporte cambió de ', OLD.formato_reporte, ' a ', NEW.formato_reporte, '. ');
    END IF;

    IF OLD.nombre <> NEW.nombre THEN
        SET descripcion = CONCAT(descripcion, 'Nombre del reporte cambió de ', OLD.nombre, ' a ', NEW.nombre, '. ');
    END IF;

    IF OLD.ruta_archivo <> NEW.ruta_archivo THEN
        SET descripcion = CONCAT(descripcion, 'Ruta del archivo cambió de ', OLD.ruta_archivo, ' a ', NEW.ruta_archivo, '. ');
    END IF;

    INSERT INTO `Historial_Reportes` (`id_reporte`, `tipo_accion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`)
    VALUES (NEW.id_reporte, 'UPDATE', USER(), ip_origen, descripcion);
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Salidas_Inventario`
--

CREATE TABLE `Salidas_Inventario` (
  `id_salida` int(11) NOT NULL,
  `id_producto` int(11) DEFAULT NULL,
  `cantidad_salida` int(11) DEFAULT NULL,
  `fecha_salida` datetime DEFAULT NULL,
  `usuario_registro` int(11) DEFAULT NULL,
  `tipo_accion` varchar(50) DEFAULT 'salida'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tareas_mantenimiento`
--

CREATE TABLE `tareas_mantenimiento` (
  `id_tarea` int(11) NOT NULL,
  `descripcion_tarea` text DEFAULT NULL,
  `fecha_programada` datetime DEFAULT NULL,
  `estado_tarea` enum('Programada','Completada','Fallida') DEFAULT NULL,
  `usuario_responsable` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tareas_mantenimiento`
--

INSERT INTO `tareas_mantenimiento` (`id_tarea`, `descripcion_tarea`, `fecha_programada`, `estado_tarea`, `usuario_responsable`) VALUES
(2, 'Actualización de seguridad del sistema', '2024-02-07 09:30:00', 'Completada', 2),
(3, 'Limpieza de datos obsoletos del sistema', '2024-02-08 10:00:00', 'Fallida', 3),
(4, 'Optimización de consultas SQL en inventario', '2024-02-09 13:00:00', 'Completada', 2),
(5, 'Revisión de acceso a roles y permisos', '2024-02-10 15:30:00', 'Programada', 1),
(8, 'Revision de acceso roles', '2024-11-14 08:05:00', 'Programada', 4),
(9, 'Revision de acceso roles', '2024-11-14 08:05:00', 'Programada', 4),
(10, 'Actualizacion de Seguridad :v', '2024-11-21 06:09:00', 'Programada', 1),
(11, 'Comprar Garros', '2024-11-21 06:10:00', 'Programada', 4),
(14, 'Test', '2024-11-13 10:13:00', 'Programada', 1),
(17, 'Comprar Pc ', '2024-11-22 12:17:00', 'Programada', 2),
(0, 'Prueba Tarea Mantenimiento', '2025-02-20 17:15:00', 'Programada', 24);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Ubicaciones`
--

CREATE TABLE `Ubicaciones` (
  `id_ubicacion` int(11) NOT NULL,
  `nombre_ubicacion` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `Ubicaciones`
--

INSERT INTO `Ubicaciones` (`id_ubicacion`, `nombre_ubicacion`) VALUES
(1, 'Almacén Principal'),
(2, 'Depósito Secundario'),
(3, 'Estante Superior'),
(4, 'Estante Inferior');

--
-- Disparadores `Ubicaciones`
--
DELIMITER $$
CREATE TRIGGER `Ubicaciones_after_delete` AFTER DELETE ON `Ubicaciones` FOR EACH ROW BEGIN
    DECLARE ip_origen VARCHAR(45);
    SET ip_origen = 'IP_DEL_USUARIO';

    INSERT INTO `Historial_Ubicaciones` (`id_ubicacion`, `tipo_accion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`)
    VALUES (OLD.id_ubicacion, 'DELETE', USER(), ip_origen,
        CONCAT('Ubicación eliminada: Nombre=', OLD.nombre_ubicacion));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `Ubicaciones_after_update` AFTER UPDATE ON `Ubicaciones` FOR EACH ROW BEGIN
    DECLARE ip_origen VARCHAR(45);
    DECLARE descripcion TEXT;
    SET ip_origen = 'IP_DEL_USUARIO';
    SET descripcion = '';

    IF OLD.nombre_ubicacion <> NEW.nombre_ubicacion THEN
        SET descripcion = CONCAT(descripcion, 'Nombre de ubicación cambiado de ', OLD.nombre_ubicacion, ' a ', NEW.nombre_ubicacion, '. ');
    END IF;

    INSERT INTO `Historial_Ubicaciones` (`id_ubicacion`, `tipo_accion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`)
    VALUES (NEW.id_ubicacion, 'UPDATE', USER(), ip_origen, descripcion);
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Usuarios`
--

CREATE TABLE `Usuarios` (
  `id_usuario` int(11) NOT NULL,
  `nombre` varchar(100) DEFAULT NULL,
  `correo_electronico` varchar(100) DEFAULT NULL,
  `contrasena` varchar(255) DEFAULT NULL,
  `rol` enum('Administrador','Usuario','Empleado') DEFAULT NULL,
  `estado` enum('Activo','Inactivo') DEFAULT NULL,
  `telefono` varchar(20) DEFAULT NULL,
  `fecha_creacion` datetime DEFAULT NULL,
  `direccion` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `Usuarios`
--

INSERT INTO `Usuarios` (`id_usuario`, `nombre`, `correo_electronico`, `contrasena`, `rol`, `estado`, `telefono`, `fecha_creacion`, `direccion`) VALUES
(4, NULL, 'admin@gmail.com', '$2y$10$MaIMq70iNROw6O3QbgsgEO9aq4jbxg2io86HjV.iNQuPg.ZHMuJHK', 'Administrador', 'Activo', '+573024794842', NULL, NULL),
(5, 'test', 'ronalddemiancipagauta@gmail.com', '$2y$10$kTFsC9wIqyx9TAZNmCS3s.kvWIx6aceTOXBH8RCOyZOWzOomzbFIq', 'Usuario', 'Activo', '+573138498633', NULL, NULL),
(8, 'Carlos Martínez', NULL, NULL, 'Usuario', NULL, NULL, NULL, NULL),
(9, 'Ana García', NULL, NULL, 'Usuario', NULL, NULL, NULL, NULL),
(12, 'ronald', 'ronaldcipagauta@gmail.com', '$2y$10$ilEo9iiPVE9u6jOHXnsZUuA3hymMzsQC7Gjd7fYuRCO6Usze7fWLa', 'Administrador', 'Activo', '+529931088811', NULL, NULL),
(17, NULL, 'limbernicko7@gmail.com', '$2y$10$yqByjdGTYGBOGVMeENOK6uiSjI5om.C.y/nWmf2NyQCn.fz1CZivO', 'Administrador', 'Activo', '+529931088811', NULL, NULL),
(19, 'Limber Magaña', 'limbernicko8@gmail.com', '$2y$10$307pSfyfqdsfzF3BLGRoj.ZSTPut8OXog8H6tWq84lF998S/r.3/u', '', 'Activo', '+529931088811', NULL, 'SANTOS'),
(20, NULL, 'limbernicko9@gmail.com', '$2y$10$thp/Ckwa.ySA7wCAOj7A2esytZs0INMQ5p5WRCpZAbTOF1phkr8IC', 'Empleado', 'Activo', NULL, NULL, NULL),
(21, NULL, 'tester@gmail.com', '$2y$10$XS3K86MYlALR5jyy67RUxOR7kP8/D29lTa6fvaTcmYdzFbyVBReOq', 'Usuario', 'Activo', NULL, NULL, NULL),
(22, NULL, 'wg_kg@hotmail.com', '$2y$10$T7ZqM0klXE1280sRZN3pWOv8fM9qL5x9GNZ0OpxciDP8QLFRztwQ.', 'Usuario', 'Activo', NULL, NULL, NULL),
(23, NULL, 'juanpcaicedop702@gmail.com', '$2y$10$oJGiqE1U/n9CzARw2gbIi.oPdcC4/L8ViWAxfW6MxjqA9Xf0zrJcu', 'Usuario', 'Activo', NULL, NULL, NULL),
(24, 'Dulce Itamar ', 'dulceitamar22@gmail.com', '$2y$10$ck0R5I4QBeZufhy39nI0ceTibKd8uLpAMXYVlnk7Wiv2JLRlKj5R6', 'Administrador', 'Activo', '5581374505', NULL, 'Av. Huitzilihuitl 53 Col. Santa Isabel Tola. Delegación Gustavo A. Madero'),
(27, 'Antonio Mendoza', 'cliente123@email.com', '$2y$10$Aos3qmX4ke9OP7Y8VtI5ROwA23HfcAxhkclCezzEFZjYZIxZ3.u.m', 'Usuario', 'Activo', 'aaaaa', NULL, 'SANTOS'),
(33, NULL, 'jpcaicedo@gmail.com', '$2y$10$k/NEa4e3pwj6JH820HB82e31txxpt/POHP3UvP0yili1xJ8YLq/vu', 'Usuario', 'Activo', NULL, NULL, NULL),
(34, NULL, 'ronitalc9@hotmail.com', '$2y$10$Eg5.AZzgLGeyIB0h5QETOuZ0xuCZFDxlPI1s4V.iNQuPg.ZHMuJHK', 'Usuario', 'Activo', NULL, NULL, NULL),
(35, NULL, 'cardenaspaladinessebastian7@gmail.com', '$2y$10$bqr0vu2N4Fro8VXlsyjBWOq5ZL.aLo52t3Vibcza/gHYte6PVlO5G', 'Administrador', 'Activo', '+573015208350', NULL, NULL);

--
-- Disparadores `Usuarios`
--
DELIMITER $$
CREATE TRIGGER `Usuarios_after_delete` AFTER DELETE ON `Usuarios` FOR EACH ROW BEGIN
    DECLARE ip_origen VARCHAR(45);
    SET ip_origen = 'IP_DEL_USUARIO';

    INSERT INTO `Historial_Usuarios` (`id_usuario`, `tipo_accion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`)
    VALUES (OLD.id_usuario, 'DELETE', USER(), ip_origen,
        CONCAT('Registro eliminado: Nombre=', OLD.nombre, ', Correo=', OLD.correo_electronico, ', Rol=', OLD.rol, ', Estado=', OLD.estado));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `Usuarios_after_insert` AFTER INSERT ON `Usuarios` FOR EACH ROW BEGIN
    DECLARE ip_origen VARCHAR(45);
    SET ip_origen = 'IP_DEL_USUARIO';

    INSERT INTO `Historial_Usuarios` (`id_usuario`, `tipo_accion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`)
    VALUES (NEW.id_usuario, 'INSERT', USER(), ip_origen,
        CONCAT('Nuevo registro: Nombre=', NEW.nombre, ', Correo=', NEW.correo_electronico, ', Rol=', NEW.rol, ', Estado=', NEW.estado));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `Usuarios_after_update` AFTER UPDATE ON `Usuarios` FOR EACH ROW BEGIN
    DECLARE ip_origen VARCHAR(45);
    DECLARE descripcion TEXT;
    SET ip_origen = 'IP_DEL_USUARIO';

    SET descripcion = '';

    IF OLD.nombre <> NEW.nombre THEN
        SET descripcion = CONCAT(descripcion, 'Nombre cambió de ', OLD.nombre, ' a ', NEW.nombre, '. ');
    END IF;

    IF OLD.correo_electronico <> NEW.correo_electronico THEN
        SET descripcion = CONCAT(descripcion, 'Correo cambió de ', OLD.correo_electronico, ' a ', NEW.correo_electronico, '. ');
    END IF;

    IF OLD.rol <> NEW.rol THEN
        SET descripcion = CONCAT(descripcion, 'Rol cambió de ', OLD.rol, ' a ', NEW.rol, '. ');
    END IF;

    IF OLD.estado <> NEW.estado THEN
        SET descripcion = CONCAT(descripcion, 'Estado cambió de ', OLD.estado, ' a ', NEW.estado, '. ');
    END IF;

    INSERT INTO `Historial_Usuarios` (`id_usuario`, `tipo_accion`, `usuario_modifico`, `ip_origen`, `descripcion_cambio`)
    VALUES (NEW.id_usuario, 'UPDATE', USER(), ip_origen, descripcion);
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Ventas`
--

CREATE TABLE `Ventas` (
  `id_venta` int(11) NOT NULL,
  `id_cliente` int(11) DEFAULT NULL,
  `fecha_venta` datetime DEFAULT NULL,
  `monto_total` decimal(10,2) DEFAULT NULL,
  `tipo_accion` varchar(50) DEFAULT 'venta',
  `estado` enum('Petición Realizada','Producto Pagado','En Envío','Entregado','Devuelto','En Curso') DEFAULT 'En Curso'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `Ventas`
--

INSERT INTO `Ventas` (`id_venta`, `id_cliente`, `fecha_venta`, `monto_total`, `tipo_accion`, `estado`) VALUES
(27, 9, '2024-11-11 13:06:47', 15.00, 'venta', 'Petición Realizada'),
(28, 9, '2024-11-11 13:06:48', 15.00, 'venta', 'Petición Realizada'),
(34, 5, '2025-01-30 23:05:08', 20.00, 'venta', 'Petición Realizada'),
(35, 21, '2025-01-30 23:06:37', 2.00, 'venta', 'Petición Realizada'),
(36, 5, '2025-01-30 23:12:45', 1.00, 'venta', 'Petición Realizada');

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `Compras`
--
ALTER TABLE `Compras`
  ADD PRIMARY KEY (`id_compra`),
  ADD KEY `fk_compras_proveedor` (`id_proveedor`);

--
-- Indices de la tabla `configuracion_interfaz`
--
ALTER TABLE `configuracion_interfaz`
  ADD PRIMARY KEY (`id_configuracion`),
  ADD KEY `id_usuario` (`id_usuario`);

--
-- Indices de la tabla `Detalle_Compras`
--
ALTER TABLE `Detalle_Compras`
  ADD PRIMARY KEY (`id_detalle`),
  ADD KEY `id_compra` (`id_compra`),
  ADD KEY `fk_detalle_compras_inventario` (`id_producto`);

--
-- Indices de la tabla `Detalle_Ventas`
--
ALTER TABLE `Detalle_Ventas`
  ADD PRIMARY KEY (`id_detalle`),
  ADD KEY `fk_detalle_ventas_inventario` (`id_producto`),
  ADD KEY `Detalle_Ventas_ibfk_1` (`id_venta`);

--
-- Indices de la tabla `Documentos`
--
ALTER TABLE `Documentos`
  ADD PRIMARY KEY (`id_documento`);

--
-- Indices de la tabla `Documentos_Registros`
--
ALTER TABLE `Documentos_Registros`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_documento` (`id_documento`);

--
-- Indices de la tabla `Entradas_Inventario`
--
ALTER TABLE `Entradas_Inventario`
  ADD PRIMARY KEY (`id_entrada`),
  ADD KEY `id_producto` (`id_producto`),
  ADD KEY `usuario_registro` (`usuario_registro`);

--
-- Indices de la tabla `Historial_Compras`
--
ALTER TABLE `Historial_Compras`
  ADD PRIMARY KEY (`id_historial`);

--
-- Indices de la tabla `Historial_Detalle_Compras`
--
ALTER TABLE `Historial_Detalle_Compras`
  ADD PRIMARY KEY (`id_historial`);

--
-- Indices de la tabla `Historial_Detalle_Ventas`
--
ALTER TABLE `Historial_Detalle_Ventas`
  ADD PRIMARY KEY (`id_historial`);

--
-- Indices de la tabla `Historial_Documentos`
--
ALTER TABLE `Historial_Documentos`
  ADD PRIMARY KEY (`id_historial`),
  ADD KEY `id_documento` (`id_documento`);

--
-- Indices de la tabla `Historial_Entradas_Inventario`
--
ALTER TABLE `Historial_Entradas_Inventario`
  ADD PRIMARY KEY (`id_historial`);

--
-- Indices de la tabla `Historial_Inventario`
--
ALTER TABLE `Historial_Inventario`
  ADD PRIMARY KEY (`id_historial`);

--
-- Indices de la tabla `Historial_Proveedores`
--
ALTER TABLE `Historial_Proveedores`
  ADD PRIMARY KEY (`id_historial`);

--
-- Indices de la tabla `Historial_Reportes`
--
ALTER TABLE `Historial_Reportes`
  ADD PRIMARY KEY (`id_historial`);

--
-- Indices de la tabla `Historial_Salidas_Inventario`
--
ALTER TABLE `Historial_Salidas_Inventario`
  ADD PRIMARY KEY (`id_historial`),
  ADD KEY `id_salida` (`id_salida`),
  ADD KEY `id_producto` (`id_producto`);

--
-- Indices de la tabla `Historial_Usuarios`
--
ALTER TABLE `Historial_Usuarios`
  ADD PRIMARY KEY (`id_historial`);

--
-- Indices de la tabla `Historial_Ventas`
--
ALTER TABLE `Historial_Ventas`
  ADD PRIMARY KEY (`id_historial`),
  ADD KEY `id_venta` (`id_venta`),
  ADD KEY `id_producto` (`id_producto`);

--
-- Indices de la tabla `incidentes_soporte`
--
ALTER TABLE `incidentes_soporte`
  ADD PRIMARY KEY (`id_incidente`);

--
-- Indices de la tabla `IntentosInyeccionSQL`
--
ALTER TABLE `IntentosInyeccionSQL`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `Inventario`
--
ALTER TABLE `Inventario`
  ADD PRIMARY KEY (`id_producto`),
  ADD KEY `fk_ubicacion` (`ubicacion_id`),
  ADD KEY `fk_inventario_proveedor` (`id_proveedor`);

--
-- Indices de la tabla `Proveedores`
--
ALTER TABLE `Proveedores`
  ADD PRIMARY KEY (`id_proveedor`);

--
-- Indices de la tabla `Reportes`
--
ALTER TABLE `Reportes`
  ADD PRIMARY KEY (`id_reporte`),
  ADD KEY `Reportes_ibfk_1` (`usuario_genero`);

--
-- Indices de la tabla `Salidas_Inventario`
--
ALTER TABLE `Salidas_Inventario`
  ADD PRIMARY KEY (`id_salida`),
  ADD KEY `usuario_registro` (`usuario_registro`),
  ADD KEY `fk_salidas_inventario_producto` (`id_producto`);

--
-- Indices de la tabla `Ubicaciones`
--
ALTER TABLE `Ubicaciones`
  ADD PRIMARY KEY (`id_ubicacion`);

--
-- Indices de la tabla `Usuarios`
--
ALTER TABLE `Usuarios`
  ADD PRIMARY KEY (`id_usuario`),
  ADD UNIQUE KEY `correo_electronico` (`correo_electronico`);

--
-- Indices de la tabla `Ventas`
--
ALTER TABLE `Ventas`
  ADD PRIMARY KEY (`id_venta`),
  ADD KEY `Ventas_ibfk_1` (`id_cliente`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `Compras`
--
ALTER TABLE `Compras`
  MODIFY `id_compra` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT de la tabla `configuracion_interfaz`
--
ALTER TABLE `configuracion_interfaz`
  MODIFY `id_configuracion` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT de la tabla `Detalle_Compras`
--
ALTER TABLE `Detalle_Compras`
  MODIFY `id_detalle` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT de la tabla `Detalle_Ventas`
--
ALTER TABLE `Detalle_Ventas`
  MODIFY `id_detalle` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT de la tabla `Documentos`
--
ALTER TABLE `Documentos`
  MODIFY `id_documento` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `Documentos_Registros`
--
ALTER TABLE `Documentos_Registros`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `Entradas_Inventario`
--
ALTER TABLE `Entradas_Inventario`
  MODIFY `id_entrada` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT de la tabla `Historial_Compras`
--
ALTER TABLE `Historial_Compras`
  MODIFY `id_historial` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=45;

--
-- AUTO_INCREMENT de la tabla `Historial_Detalle_Compras`
--
ALTER TABLE `Historial_Detalle_Compras`
  MODIFY `id_historial` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT de la tabla `Historial_Detalle_Ventas`
--
ALTER TABLE `Historial_Detalle_Ventas`
  MODIFY `id_historial` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=51;

--
-- AUTO_INCREMENT de la tabla `Historial_Documentos`
--
ALTER TABLE `Historial_Documentos`
  MODIFY `id_historial` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=30;

--
-- AUTO_INCREMENT de la tabla `Historial_Entradas_Inventario`
--
ALTER TABLE `Historial_Entradas_Inventario`
  MODIFY `id_historial` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT de la tabla `Historial_Inventario`
--
ALTER TABLE `Historial_Inventario`
  MODIFY `id_historial` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=88;

--
-- AUTO_INCREMENT de la tabla `Historial_Proveedores`
--
ALTER TABLE `Historial_Proveedores`
  MODIFY `id_historial` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1785;

--
-- AUTO_INCREMENT de la tabla `Historial_Reportes`
--
ALTER TABLE `Historial_Reportes`
  MODIFY `id_historial` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=40;

--
-- AUTO_INCREMENT de la tabla `Historial_Salidas_Inventario`
--
ALTER TABLE `Historial_Salidas_Inventario`
  MODIFY `id_historial` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `Historial_Usuarios`
--
ALTER TABLE `Historial_Usuarios`
  MODIFY `id_historial` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=91;

--
-- AUTO_INCREMENT de la tabla `Historial_Ventas`
--
ALTER TABLE `Historial_Ventas`
  MODIFY `id_historial` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `incidentes_soporte`
--
ALTER TABLE `incidentes_soporte`
  MODIFY `id_incidente` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT de la tabla `IntentosInyeccionSQL`
--
ALTER TABLE `IntentosInyeccionSQL`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `Inventario`
--
ALTER TABLE `Inventario`
  MODIFY `id_producto` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT de la tabla `Proveedores`
--
ALTER TABLE `Proveedores`
  MODIFY `id_proveedor` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=829;

--
-- AUTO_INCREMENT de la tabla `Reportes`
--
ALTER TABLE `Reportes`
  MODIFY `id_reporte` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=30;

--
-- AUTO_INCREMENT de la tabla `Salidas_Inventario`
--
ALTER TABLE `Salidas_Inventario`
  MODIFY `id_salida` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT de la tabla `Ubicaciones`
--
ALTER TABLE `Ubicaciones`
  MODIFY `id_ubicacion` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `Usuarios`
--
ALTER TABLE `Usuarios`
  MODIFY `id_usuario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=36;

--
-- AUTO_INCREMENT de la tabla `Ventas`
--
ALTER TABLE `Ventas`
  MODIFY `id_venta` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=39;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `Compras`
--
ALTER TABLE `Compras`
  ADD CONSTRAINT `Compras_ibfk_1` FOREIGN KEY (`id_proveedor`) REFERENCES `Proveedores` (`id_proveedor`),
  ADD CONSTRAINT `fk_compras_proveedor` FOREIGN KEY (`id_proveedor`) REFERENCES `Proveedores` (`id_proveedor`) ON DELETE SET NULL;

--
-- Filtros para la tabla `Detalle_Compras`
--
ALTER TABLE `Detalle_Compras`
  ADD CONSTRAINT `Detalle_Compras_ibfk_1` FOREIGN KEY (`id_compra`) REFERENCES `Compras` (`id_compra`),
  ADD CONSTRAINT `Detalle_Compras_ibfk_2` FOREIGN KEY (`id_producto`) REFERENCES `Inventario` (`id_producto`),
  ADD CONSTRAINT `fk_detalle_compras_inventario` FOREIGN KEY (`id_producto`) REFERENCES `Inventario` (`id_producto`) ON DELETE CASCADE;

--
-- Filtros para la tabla `Detalle_Ventas`
--
ALTER TABLE `Detalle_Ventas`
  ADD CONSTRAINT `Detalle_Ventas_ibfk_1` FOREIGN KEY (`id_venta`) REFERENCES `Ventas` (`id_venta`) ON DELETE CASCADE,
  ADD CONSTRAINT `Detalle_Ventas_ibfk_2` FOREIGN KEY (`id_producto`) REFERENCES `Inventario` (`id_producto`),
  ADD CONSTRAINT `fk_detalle_ventas_inventario` FOREIGN KEY (`id_producto`) REFERENCES `Inventario` (`id_producto`) ON DELETE CASCADE;

--
-- Filtros para la tabla `Documentos_Registros`
--
ALTER TABLE `Documentos_Registros`
  ADD CONSTRAINT `Documentos_Registros_ibfk_1` FOREIGN KEY (`id_documento`) REFERENCES `Documentos` (`id_documento`) ON DELETE CASCADE;

--
-- Filtros para la tabla `Entradas_Inventario`
--
ALTER TABLE `Entradas_Inventario`
  ADD CONSTRAINT `Entradas_Inventario_ibfk_1` FOREIGN KEY (`id_producto`) REFERENCES `Inventario` (`id_producto`),
  ADD CONSTRAINT `Entradas_Inventario_ibfk_2` FOREIGN KEY (`usuario_registro`) REFERENCES `Usuarios` (`id_usuario`);

--
-- Filtros para la tabla `Historial_Documentos`
--
ALTER TABLE `Historial_Documentos`
  ADD CONSTRAINT `Historial_Documentos_ibfk_1` FOREIGN KEY (`id_documento`) REFERENCES `Documentos` (`id_documento`) ON DELETE CASCADE;

--
-- Filtros para la tabla `Historial_Salidas_Inventario`
--
ALTER TABLE `Historial_Salidas_Inventario`
  ADD CONSTRAINT `Historial_Salidas_Inventario_ibfk_1` FOREIGN KEY (`id_salida`) REFERENCES `Salidas_Inventario` (`id_salida`) ON DELETE CASCADE,
  ADD CONSTRAINT `Historial_Salidas_Inventario_ibfk_2` FOREIGN KEY (`id_producto`) REFERENCES `Inventario` (`id_producto`) ON DELETE CASCADE;

--
-- Filtros para la tabla `Historial_Ventas`
--
ALTER TABLE `Historial_Ventas`
  ADD CONSTRAINT `Historial_Ventas_ibfk_1` FOREIGN KEY (`id_venta`) REFERENCES `Ventas` (`id_venta`) ON DELETE CASCADE,
  ADD CONSTRAINT `Historial_Ventas_ibfk_2` FOREIGN KEY (`id_producto`) REFERENCES `Inventario` (`id_producto`) ON DELETE CASCADE;

--
-- Filtros para la tabla `Inventario`
--
ALTER TABLE `Inventario`
  ADD CONSTRAINT `fk_inventario_proveedor` FOREIGN KEY (`id_proveedor`) REFERENCES `Proveedores` (`id_proveedor`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_ubicacion` FOREIGN KEY (`ubicacion_id`) REFERENCES `Ubicaciones` (`id_ubicacion`);

--
-- Filtros para la tabla `Reportes`
--
ALTER TABLE `Reportes`
  ADD CONSTRAINT `Reportes_ibfk_1` FOREIGN KEY (`usuario_genero`) REFERENCES `Usuarios` (`id_usuario`) ON DELETE CASCADE;

--
-- Filtros para la tabla `Salidas_Inventario`
--
ALTER TABLE `Salidas_Inventario`
  ADD CONSTRAINT `Salidas_Inventario_ibfk_1` FOREIGN KEY (`id_producto`) REFERENCES `Inventario` (`id_producto`),
  ADD CONSTRAINT `Salidas_Inventario_ibfk_2` FOREIGN KEY (`usuario_registro`) REFERENCES `Usuarios` (`id_usuario`),
  ADD CONSTRAINT `fk_salidas_inventario_producto` FOREIGN KEY (`id_producto`) REFERENCES `Inventario` (`id_producto`) ON DELETE CASCADE;

--
-- Filtros para la tabla `Ventas`
--
ALTER TABLE `Ventas`
  ADD CONSTRAINT `Ventas_ibfk_1` FOREIGN KEY (`id_cliente`) REFERENCES `Usuarios` (`id_usuario`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_ventas_usuario` FOREIGN KEY (`id_cliente`) REFERENCES `Usuarios` (`id_usuario`) ON DELETE SET NULL;
COMMIT;

-- =====================================================
-- Rate Limiting: LoginAttempts table
-- Added: 2026-04-26 — Brute force protection
-- =====================================================

CREATE TABLE IF NOT EXISTS `LoginAttempts` (
  `id`           INT(11) NOT NULL AUTO_INCREMENT,
  `email`        VARCHAR(100) NOT NULL,
  `ip`           VARCHAR(45) NOT NULL,
  `success`      TINYINT(1) NOT NULL DEFAULT 0,
  `attempted_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_email_time` (`email`, `attempted_at`),
  INDEX `idx_ip_time` (`ip`, `attempted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
