-- ============================================================
-- 07_Procedimientos_Almacenados.sql
-- Proyecto de Base de Datos para un E-commerce
-- 20 Procedimientos Almacenados
-- ============================================================

USE E_commerce;

DELIMITER $$

-- ============================================================
-- 1. sp_RealizarNuevaVenta
--    Procesa una nueva venta de forma transaccional.
--    Parámetros: id_cliente, lista de productos en JSON.
--    JSON ejemplo: '[{"id":1,"qty":2},{"id":3,"qty":1}]'
-- ============================================================
DROP PROCEDURE IF EXISTS sp_RealizarNuevaVenta$$
CREATE PROCEDURE sp_RealizarNuevaVenta(
    IN  p_id_cliente INT,
    IN  p_items      JSON,
    OUT p_id_venta   INT,
    OUT p_mensaje    VARCHAR(255)
)
BEGIN
    DECLARE v_id_prod    INT;
    DECLARE v_qty        INT;
    DECLARE v_precio     DECIMAL(12,2);
    DECLARE v_stock      INT;
    DECLARE v_i          INT DEFAULT 0;
    DECLARE v_total_items INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_id_venta = NULL;
        SET p_mensaje  = 'Error al procesar la venta. Transacción revertida.';
    END;

    SET v_total_items = JSON_LENGTH(p_items);

    START TRANSACTION;

    INSERT INTO ventas (id_cliente, estado, total)
    VALUES (p_id_cliente, 'Pendiente de Pago', 0);
    SET p_id_venta = LAST_INSERT_ID();

    WHILE v_i < v_total_items DO
        SET v_id_prod = JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[', v_i, '].id')));
        SET v_qty     = JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[', v_i, '].qty')));

        SELECT precio, stock INTO v_precio, v_stock
        FROM productos WHERE id_producto = v_id_prod FOR UPDATE;

        IF v_stock < v_qty THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Stock insuficiente para uno de los productos';
        END IF;

        INSERT INTO detalle_ventas (id_venta, id_producto, cantidad, precio_unitario_congelado)
        VALUES (p_id_venta, v_id_prod, v_qty, v_precio);

        SET v_i = v_i + 1;
    END WHILE;

    UPDATE ventas
    SET total = (
        SELECT SUM(cantidad * precio_unitario_congelado)
        FROM detalle_ventas WHERE id_venta = p_id_venta
    )
    WHERE id_venta = p_id_venta;

    COMMIT;
    SET p_mensaje = CONCAT('Venta #', p_id_venta, ' creada exitosamente.');
END$$

-- ============================================================
-- 2. sp_AgregarNuevoProducto
--    Inserta un nuevo producto validando datos básicos.
-- ============================================================
DROP PROCEDURE IF EXISTS sp_AgregarNuevoProducto$$
CREATE PROCEDURE sp_AgregarNuevoProducto(
  IN  p_nombre       VARCHAR(150),
  IN  p_descripcion  TEXT,
  IN  p_precio       DECIMAL(12,2),
  IN  p_costo        DECIMAL(12,2),
  IN  p_stock        INT,
  IN  p_id_categoria INT,
  IN  p_id_proveedor INT,
  OUT p_id_producto  INT,
  OUT p_mensaje      VARCHAR(255)
)
sp_AgregarNuevoProducto: BEGIN
  DECLARE v_sku VARCHAR(60);
  IF p_precio <= 0 THEN
    SET p_mensaje = 'El precio debe ser mayor que cero.';
    SET p_id_producto = NULL;
    LEAVE sp_AgregarNuevoProducto;
  END IF;
  SET v_sku = fn_GenerarSKU(
    p_nombre,
    p_id_categoria,
    FLOOR(RAND() * 9000 + 1000)
  );
  INSERT INTO productos (
   nombre,
   descripcion,
   precio,
   costo,
   stock,
   sku,
   id_categoria,
   id_proveedor
  )
  VALUES (
    p_nombre,
    p_descripcion,
    p_precio,
    p_costo,
    p_stock,
    v_sku,
    p_id_categoria,
    p_id_proveedor
  );
  SET p_id_producto = LAST_INSERT_ID();
  SET p_mensaje = CONCAT(
    'Producto creado con ID: ',
    p_id_producto,
    ' SKU: ',
    v_sku
  );
END sp_AgregarNuevoProducto

-- ============================================================
-- 3. sp_ActualizarDireccionCliente
--    Actualiza la dirección de envío de un cliente.
-- ============================================================
DROP PROCEDURE IF EXISTS sp_ActualizarDireccionCliente$$
CREATE PROCEDURE sp_ActualizarDireccionCliente(
    IN p_id_cliente     INT,
    IN p_nueva_direccion TEXT,
    IN p_ciudad         VARCHAR(100),
    IN p_region         VARCHAR(100)
)
BEGIN
    UPDATE clientes
    SET direccion_envio = p_nueva_direccion,
        ciudad          = p_ciudad,
        region          = p_region
    WHERE id_cliente = p_id_cliente;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cliente no encontrado';
    END IF;
END$$

-- ============================================================
-- 4. sp_ProcesarDevolucion
--    Gestiona devolución: restaura stock y cancela la venta.
-- ============================================================
DROP PROCEDURE IF EXISTS sp_ProcesarDevolucion$$
CREATE PROCEDURE sp_ProcesarDevolucion(
    IN  p_id_venta INT,
    IN  p_motivo   VARCHAR(255),
    OUT p_mensaje  VARCHAR(255)
)
BEGIN
    DECLARE v_estado VARCHAR(30);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error al procesar la devolución.';
    END;

    SELECT estado INTO v_estado FROM ventas WHERE id_venta = p_id_venta;

    IF v_estado = 'Cancelado' THEN
        SET p_mensaje = 'La venta ya está cancelada.';
        LEAVE sp_ProcesarDevolucion;
    END IF;

    START TRANSACTION;

    -- Restaurar stock
    UPDATE productos p
    JOIN detalle_ventas dv ON p.id_producto = dv.id_producto
    SET p.stock = p.stock + dv.cantidad
    WHERE dv.id_venta = p_id_venta;

    -- Cancelar la venta
    UPDATE ventas SET estado = 'Cancelado' WHERE id_venta = p_id_venta;

    -- Log de la devolución
    INSERT INTO log_auditoria_clientes (id_cliente, accion, detalle)
    SELECT id_cliente, 'DEVOLUCION', CONCAT('Venta #', p_id_venta, ' - Motivo: ', p_motivo)
    FROM ventas WHERE id_venta = p_id_venta;

    COMMIT;
    SET p_mensaje = CONCAT('Devolución de venta #', p_id_venta, ' procesada exitosamente.');
END$$

-- ============================================================
-- 5. sp_ObtenerHistorialComprasCliente
--    Devuelve el historial completo de compras de un cliente.
-- ============================================================
DROP PROCEDURE IF EXISTS sp_ObtenerHistorialComprasCliente$$
CREATE PROCEDURE sp_ObtenerHistorialComprasCliente(IN p_id_cliente INT)
BEGIN
    SELECT
        v.id_venta,
        v.fecha_venta,
        v.estado,
        v.total,
        p.nombre AS producto,
        dv.cantidad,
        dv.precio_unitario_congelado,
        (dv.cantidad * dv.precio_unitario_congelado) AS subtotal
    FROM ventas v
    JOIN detalle_ventas dv ON v.id_venta    = dv.id_venta
    JOIN productos p       ON dv.id_producto = p.id_producto
    WHERE v.id_cliente = p_id_cliente
    ORDER BY v.fecha_venta DESC;
END$$

-- ============================================================
-- 6. sp_AjustarNivelStock
--    Ajusta manualmente el stock de un producto y registra el motivo.
-- ============================================================
DROP PROCEDURE IF EXISTS sp_AjustarNivelStock$$
CREATE PROCEDURE sp_AjustarNivelStock(
    IN p_id_producto INT,
    IN p_nuevo_stock INT,
    IN p_motivo      VARCHAR(255)
)
BEGIN
    IF p_nuevo_stock < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El stock no puede ser negativo';
    END IF;

    UPDATE productos SET stock = p_nuevo_stock WHERE id_producto = p_id_producto;

    INSERT INTO log_auditoria_clientes (id_cliente, accion, detalle)
    VALUES (NULL, 'AJUSTE_STOCK',
            CONCAT('Producto #', p_id_producto, ' stock ajustado a ', p_nuevo_stock, '. Motivo: ', p_motivo));
END$$

-- ============================================================
-- 7. sp_EliminarClienteDeFormaSegura
--    Anonimiza los datos del cliente manteniendo la integridad referencial.
-- ============================================================
DROP PROCEDURE IF EXISTS sp_EliminarClienteDeFormaSegura$$
CREATE PROCEDURE sp_EliminarClienteDeFormaSegura(IN p_id_cliente INT)
BEGIN
    UPDATE clientes
    SET nombre          = CONCAT('ANONIMO_', id_cliente),
        apellido        = 'ELIMINADO',
        email           = CONCAT('deleted_', id_cliente, '@noreply.com'),
        contrasena      = SHA2(UUID(), 256),
        direccion_envio = NULL,
        ciudad          = NULL,
        region          = NULL,
        fecha_nacimiento = NULL
    WHERE id_cliente = p_id_cliente;
END$$

-- ============================================================
-- 8. sp_AplicarDescuentoPorCategoria
--    Aplica un descuento porcentual a todos los productos de una categoría.
-- ============================================================
DROP PROCEDURE IF EXISTS sp_AplicarDescuentoPorCategoria$$
CREATE PROCEDURE sp_AplicarDescuentoPorCategoria(
    IN p_id_categoria   INT,
    IN p_descuento_pct  DECIMAL(5,2)
)
BEGIN
    IF p_descuento_pct <= 0 OR p_descuento_pct >= 100 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El descuento debe estar entre 0 y 100%';
    END IF;

    UPDATE productos
    SET precio = ROUND(precio * (1 - p_descuento_pct / 100), 2)
    WHERE id_categoria = p_id_categoria AND activo = 1;

    SELECT ROW_COUNT() AS productos_actualizados;
END$$

-- ============================================================
-- 9. sp_GenerarReporteMensualVentas
--    Reporte completo de ventas para un mes y año dados.
-- ============================================================
DROP PROCEDURE IF EXISTS sp_GenerarReporteMensualVentas$$
CREATE PROCEDURE sp_GenerarReporteMensualVentas(IN p_anio INT, IN p_mes INT)
BEGIN
    -- Resumen general
    SELECT
        COUNT(id_venta)     AS total_ordenes,
        SUM(total)          AS ingresos_totales,
        AVG(total)          AS ticket_promedio,
        MAX(total)          AS venta_mas_alta,
        MIN(total)          AS venta_mas_baja
    FROM ventas
    WHERE YEAR(fecha_venta) = p_anio
      AND MONTH(fecha_venta) = p_mes
      AND estado != 'Cancelado';

    -- Top 5 productos del mes
    SELECT p.nombre, SUM(dv.cantidad) AS unidades, SUM(dv.cantidad * dv.precio_unitario_congelado) AS ingresos
    FROM detalle_ventas dv
    JOIN productos p ON dv.id_producto = p.id_producto
    JOIN ventas v    ON dv.id_venta    = v.id_venta
    WHERE YEAR(v.fecha_venta) = p_anio AND MONTH(v.fecha_venta) = p_mes AND v.estado != 'Cancelado'
    GROUP BY p.nombre ORDER BY ingresos DESC LIMIT 5;
END$$

-- ============================================================
-- 10. sp_CambiarEstadoPedido
--     Cambia el estado de un pedido y registra en el log.
-- ============================================================
DROP PROCEDURE IF EXISTS sp_CambiarEstadoPedido$$
CREATE PROCEDURE sp_CambiarEstadoPedido(
    IN  p_id_venta    INT,
    IN  p_nuevo_estado VARCHAR(30),
    OUT p_mensaje      VARCHAR(255)
)
BEGIN
    DECLARE v_estado_actual VARCHAR(30);

    SELECT estado INTO v_estado_actual FROM ventas WHERE id_venta = p_id_venta;

    IF v_estado_actual IS NULL THEN
        SET p_mensaje = 'Venta no encontrada.';
        LEAVE sp_CambiarEstadoPedido;
    END IF;

    IF v_estado_actual = 'Cancelado' OR v_estado_actual = 'Entregado' THEN
        SET p_mensaje = CONCAT('No se puede cambiar el estado desde: ', v_estado_actual);
        LEAVE sp_CambiarEstadoPedido;
    END IF;

    UPDATE ventas SET estado = p_nuevo_estado WHERE id_venta = p_id_venta;
    SET p_mensaje = CONCAT('Estado cambiado de "', v_estado_actual, '" a "', p_nuevo_estado, '"');
END$$

-- ============================================================
-- 11. sp_RegistrarNuevoCliente
--     Registra un nuevo cliente validando email único.
-- ============================================================
DROP PROCEDURE IF EXISTS sp_RegistrarNuevoCliente$$
CREATE PROCEDURE sp_RegistrarNuevoCliente(
    IN  p_nombre       VARCHAR(80),
    IN  p_apellido     VARCHAR(80),
    IN  p_email        VARCHAR(150),
    IN  p_contrasena   VARCHAR(255),
    IN  p_direccion    TEXT,
    OUT p_id_cliente   INT,
    OUT p_mensaje      VARCHAR(255)
)
BEGIN
    DECLARE v_existe INT;

    SELECT COUNT(*) INTO v_existe FROM clientes WHERE email = p_email;

    IF v_existe > 0 THEN
        SET p_id_cliente = NULL;
        SET p_mensaje = 'El correo electrónico ya está registrado.';
        LEAVE sp_RegistrarNuevoCliente;
    END IF;

    IF fn_ValidarFormatoEmail(p_email) = 0 THEN
        SET p_id_cliente = NULL;
        SET p_mensaje = 'Formato de correo inválido.';
        LEAVE sp_RegistrarNuevoCliente;
    END IF;

    INSERT INTO clientes (nombre, apellido, email, contrasena, direccion_envio)
    VALUES (p_nombre, p_apellido, p_email, SHA2(p_contrasena, 256), p_direccion);

    SET p_id_cliente = LAST_INSERT_ID();
    SET p_mensaje = CONCAT('Cliente registrado con ID: ', p_id_cliente);
END$$

-- ============================================================
-- 12. sp_ObtenerDetallesProductoCompleto
--     Información completa de un producto con proveedor y categoría.
-- ============================================================
DROP PROCEDURE IF EXISTS sp_ObtenerDetallesProductoCompleto$$
CREATE PROCEDURE sp_ObtenerDetallesProductoCompleto(IN p_id_producto INT)
BEGIN
    SELECT
        p.*,
        c.nombre  AS categoria_nombre,
        c.descripcion AS categoria_descripcion,
        pr.nombre AS proveedor_nombre,
        pr.email_contacto,
        pr.telefono_contacto
    FROM productos p
    LEFT JOIN categorias  c  ON p.id_categoria  = c.id_categoria
    LEFT JOIN proveedores pr ON p.id_proveedor  = pr.id_proveedor
    WHERE p.id_producto = p_id_producto;
END$$

-- ============================================================
-- 13. sp_FusionarCuentasCliente
--     Fusiona dos cuentas duplicadas: mantiene p_id_principal,
--     migra ventas de p_id_secundario y elimina la secundaria.
-- ============================================================
DROP PROCEDURE IF EXISTS sp_FusionarCuentasCliente$$
CREATE PROCEDURE sp_FusionarCuentasCliente(
    IN  p_id_principal  INT,
    IN  p_id_secundario INT,
    OUT p_mensaje       VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error al fusionar cuentas.';
    END;

    IF p_id_principal = p_id_secundario THEN
        SET p_mensaje = 'Los IDs deben ser distintos.';
        LEAVE sp_FusionarCuentasCliente;
    END IF;

    START TRANSACTION;
    UPDATE ventas SET id_cliente = p_id_principal WHERE id_cliente = p_id_secundario;
    CALL sp_EliminarClienteDeFormaSegura(p_id_secundario);
    COMMIT;

    SET p_mensaje = CONCAT('Cuenta ', p_id_secundario, ' fusionada en ', p_id_principal, '.');
END$$

-- ============================================================
-- 14. sp_AsignarProductoAProveedor
--     Asigna o cambia el proveedor de un producto.
-- ============================================================
DROP PROCEDURE IF EXISTS sp_AsignarProductoAProveedor$$
CREATE PROCEDURE sp_AsignarProductoAProveedor(
    IN p_id_producto  INT,
    IN p_id_proveedor INT
)
BEGIN
    UPDATE productos
    SET id_proveedor = p_id_proveedor
    WHERE id_producto = p_id_producto;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Producto o proveedor no encontrado';
    END IF;
END$$

-- ============================================================
-- 15. sp_BuscarProductos
--     Búsqueda avanzada de productos con múltiples filtros.
-- ============================================================
DROP PROCEDURE IF EXISTS sp_BuscarProductos$$
CREATE PROCEDURE sp_BuscarProductos(
    IN p_nombre       VARCHAR(150),
    IN p_id_categoria INT,
    IN p_precio_min   DECIMAL(12,2),
    IN p_precio_max   DECIMAL(12,2),
    IN p_solo_activos TINYINT(1)
)
BEGIN
    SELECT p.id_producto, p.nombre, p.precio, p.stock, p.sku,
           c.nombre AS categoria, pr.nombre AS proveedor
    FROM productos p
    LEFT JOIN categorias  c  ON p.id_categoria = c.id_categoria
    LEFT JOIN proveedores pr ON p.id_proveedor = pr.id_proveedor
    WHERE (p_nombre IS NULL OR p.nombre LIKE CONCAT('%', p_nombre, '%'))
      AND (p_id_categoria IS NULL OR p.id_categoria = p_id_categoria)
      AND (p_precio_min IS NULL OR p.precio >= p_precio_min)
      AND (p_precio_max IS NULL OR p.precio <= p_precio_max)
      AND (p_solo_activos IS NULL OR p.activo = p_solo_activos)
    ORDER BY p.nombre;
END$$

-- ============================================================
-- 16. sp_ObtenerDashboardAdmin
--     KPIs para el panel de administración.
-- ============================================================
DROP PROCEDURE IF EXISTS sp_ObtenerDashboardAdmin$$
CREATE PROCEDURE sp_ObtenerDashboardAdmin()
BEGIN
    SELECT
        (SELECT COUNT(*) FROM ventas WHERE DATE(fecha_venta) = CURDATE()) AS ventas_hoy,
        (SELECT COALESCE(SUM(total),0) FROM ventas WHERE DATE(fecha_venta) = CURDATE() AND estado != 'Cancelado') AS ingresos_hoy,
        (SELECT COUNT(*) FROM clientes WHERE DATE(fecha_registro) = CURDATE()) AS nuevos_clientes_hoy,
        (SELECT COUNT(*) FROM productos WHERE stock < 30 AND activo = 1) AS productos_bajo_stock,
        (SELECT COUNT(*) FROM ventas WHERE estado = 'Pendiente de Pago') AS ordenes_pendientes,
        (SELECT COALESCE(SUM(total),0) FROM ventas WHERE MONTH(fecha_venta) = MONTH(CURDATE()) AND YEAR(fecha_venta) = YEAR(CURDATE()) AND estado != 'Cancelado') AS ingresos_mes_actual;
END$$

-- ============================================================
-- 17. sp_ProcesarPago
--     Simula el procesamiento de un pago y actualiza el estado.
-- ============================================================
DROP PROCEDURE IF EXISTS sp_ProcesarPago$$
CREATE PROCEDURE sp_ProcesarPago(
    IN  p_id_venta    INT,
    IN  p_metodo_pago VARCHAR(50),
    OUT p_aprobado    TINYINT(1),
    OUT p_mensaje     VARCHAR(255)
)
BEGIN
    DECLARE v_total  DECIMAL(14,2);
    DECLARE v_estado VARCHAR(30);

    SELECT total, estado INTO v_total, v_estado FROM ventas WHERE id_venta = p_id_venta;

    IF v_estado != 'Pendiente de Pago' THEN
        SET p_aprobado = 0;
        SET p_mensaje  = CONCAT('Venta en estado "', v_estado, '" no puede procesarse.');
        LEAVE sp_ProcesarPago;
    END IF;

    -- Simulación de aprobación (90% de éxito)
    IF RAND() < 0.9 THEN
        UPDATE ventas SET estado = 'Procesando' WHERE id_venta = p_id_venta;
        SET p_aprobado = 1;
        SET p_mensaje  = CONCAT('Pago aprobado via ', p_metodo_pago, '. Total: $', FORMAT(v_total, 0));
    ELSE
        SET p_aprobado = 0;
        SET p_mensaje  = 'Pago rechazado. Intente nuevamente.';
    END IF;
END$$

-- ============================================================
-- 18. sp_AnadirResenaProducto
--     Permite a un cliente añadir una reseña a un producto comprado.
-- ============================================================
DROP PROCEDURE IF EXISTS sp_AnadirResenaProducto$$
CREATE PROCEDURE sp_AnadirResenaProducto(
    IN  p_id_cliente   INT,
    IN  p_id_producto  INT,
    IN  p_calificacion TINYINT,
    IN  p_comentario   TEXT,
    OUT p_mensaje      VARCHAR(255)
)
BEGIN
    DECLARE v_ha_comprado INT;

    -- Verificar que el cliente haya comprado el producto
    SELECT COUNT(*) INTO v_ha_comprado
    FROM ventas v
    JOIN detalle_ventas dv ON v.id_venta = dv.id_venta
    WHERE v.id_cliente = p_id_cliente AND dv.id_producto = p_id_producto
      AND v.estado = 'Entregado';

    IF v_ha_comprado = 0 THEN
        SET p_mensaje = 'Solo puedes reseñar productos que hayas comprado y recibido.';
        LEAVE sp_AnadirResenaProducto;
    END IF;

    IF p_calificacion NOT BETWEEN 1 AND 5 THEN
        SET p_mensaje = 'La calificación debe estar entre 1 y 5.';
        LEAVE sp_AnadirResenaProducto;
    END IF;

    INSERT INTO resenas_productos (id_producto, id_cliente, calificacion, comentario)
    VALUES (p_id_producto, p_id_cliente, p_calificacion, p_comentario);

    SET p_mensaje = 'Reseña registrada exitosamente.';
END$$

-- ============================================================
-- 19. sp_ObtenerProductosRelacionados
--     Productos frecuentemente comprados junto al dado
-- ============================================================
DROP PROCEDURE IF EXISTS sp_ObtenerProductosRelacionados$$
CREATE PROCEDURE sp_ObtenerProductosRelacionados(IN p_id_producto INT)
BEGIN
    SELECT
        p.id_producto,
        p.nombre,
        p.precio,
        COUNT(*) AS veces_comprado_junto
    FROM detalle_ventas dv1
    JOIN detalle_ventas dv2 ON dv1.id_venta = dv2.id_venta
                           AND dv2.id_producto != p_id_producto
    JOIN productos p ON dv2.id_producto = p.id_producto
    WHERE dv1.id_producto = p_id_producto
      AND p.activo = 1
    GROUP BY p.id_producto, p.nombre, p.precio
    ORDER BY veces_comprado_junto DESC
    LIMIT 5;
END$$

-- ============================================================
-- 20. sp_MoverProductosEntreCategorias
--     Mueve uno o más productos de una categoría a otra.
-- ============================================================
DROP PROCEDURE IF EXISTS sp_MoverProductosEntreCategorias$$
CREATE PROCEDURE sp_MoverProductosEntreCategorias(
    IN  p_id_categoria_origen  INT,
    IN  p_id_categoria_destino INT,
    IN  p_ids_productos        JSON,
    OUT p_mensaje              VARCHAR(255)
)
BEGIN
    DECLARE v_count INT;
    DECLARE v_i     INT DEFAULT 0;
    DECLARE v_id    INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error al mover productos.';
    END;

    SET v_count = JSON_LENGTH(p_ids_productos);

    START TRANSACTION;
    WHILE v_i < v_count DO
        SET v_id = JSON_UNQUOTE(JSON_EXTRACT(p_ids_productos, CONCAT('$[', v_i, ']')));
        UPDATE productos
        SET id_categoria = p_id_categoria_destino
        WHERE id_producto = v_id AND id_categoria = p_id_categoria_origen;
        SET v_i = v_i + 1;
    END WHILE;
    COMMIT;

    SET p_mensaje = CONCAT(v_count, ' producto(s) movidos a categoría #', p_id_categoria_destino, '.');
END$$

DELIMITER ;