USE E_commerce;

-- ============================================================
-- Triggers
-- ============================================================
 
DELIMITER $$
 
-- ============================================================
-- 1. trg_audit_precio_producto_after_update
--    Guarda un log de cambios de precios de productos.
-- ============================================================
DROP TRIGGER IF EXISTS trg_audit_precio_producto_after_update$$
CREATE TRIGGER trg_audit_precio_producto_after_update
AFTER UPDATE ON productos
FOR EACH ROW
BEGIN
  IF OLD.precio <> NEW.precio THEN
    INSERT INTO log_cambios_precio (id_producto, precio_anterior, precio_nuevo)
    VALUES (NEW.id_producto, OLD.precio, NEW.precio);
  END IF;
END$$
 
-- ============================================================
-- 2. trg_check_stock_before_insert_venta
--    Verifica disponibilidad de stock antes de insertar un detalle de venta.
-- ============================================================
DROP TRIGGER IF EXISTS trg_check_stock_before_insert_venta$$
CREATE TRIGGER trg_check_stock_before_insert_venta
BEFORE INSERT ON Detalle_de_Ventas
FOR EACH ROW
BEGIN
  DECLARE v_stock INT;
  SELECT stock INTO v_stock FROM productos WHERE id_producto = NEW.id_producto;
  IF v_stock < NEW.cantidad THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Stock insuficiente para el producto solicitado';
  END IF;
END$$
 
-- ============================================================
-- 3. trg_update_stock_after_insert_venta
--    Decrementa el stock después de registrar un detalle de venta.
-- ============================================================
DROP TRIGGER IF EXISTS trg_update_stock_after_insert_venta$$
CREATE TRIGGER trg_update_stock_after_insert_venta
AFTER INSERT ON Detalle_de_Ventas
FOR EACH ROW
BEGIN
  UPDATE productos
  SET stock = stock - NEW.cantidad
  WHERE id_producto = NEW.id_producto;
END$$
 
-- ============================================================
-- 4. trg_prevent_delete_categoria_with_products
--    Impide eliminar una categoría si tiene productos activos.
-- ============================================================
DROP TRIGGER IF EXISTS trg_prevent_delete_categoria_with_products$$
CREATE TRIGGER trg_prevent_delete_categoria_with_products
BEFORE DELETE ON categorias
FOR EACH ROW
BEGIN
  DECLARE v_count INT;
  SELECT COUNT(*) INTO v_count FROM productos
  WHERE id_categoria = OLD.id_categoria AND activo = 1;
  IF v_count > 0 THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'No se puede eliminar la categoría: tiene productos activos asociados';
  END IF;
END$$
 
-- ============================================================
-- 5. trg_log_new_customer_after_insert
--    Registra en auditoría cada nuevo cliente creado.
-- ============================================================
DROP TRIGGER IF EXISTS trg_log_new_customer_after_insert$$
CREATE TRIGGER trg_log_new_customer_after_insert
AFTER INSERT ON clientes
FOR EACH ROW
BEGIN
  INSERT INTO log_auditoria_clientes (id_cliente, accion, detalle)
  VALUES (NEW.id_cliente, 'NUEVO_CLIENTE', CONCAT('Email: ', NEW.email));
END$$
 
-- ============================================================
-- 6. trg_update_total_gastado_cliente
--    Actualiza total_gastado del cliente después de cada venta confirmada.
-- ============================================================
DROP TRIGGER IF EXISTS trg_update_total_gastado_cliente$$
CREATE TRIGGER trg_update_total_gastado_cliente
AFTER UPDATE ON ventas
FOR EACH ROW
BEGIN
  IF NEW.estado = 'Entregado' AND OLD.estado <> 'Entregado' THEN
    UPDATE clientes
    SET total_gastado = (
      SELECT COALESCE(SUM(total), 0)
      FROM ventas
      WHERE id_cliente = NEW.id_cliente AND estado = 'Entregado'
    )
    WHERE id_cliente = NEW.id_cliente;
  END IF;
END$$
 
-- ============================================================
-- 7. trg_set_fecha_modificacion_producto
--    Actualiza fecha_modificacion de un producto al editarlo.
-- ============================================================
DROP TRIGGER IF EXISTS trg_set_fecha_modificacion_producto$$
CREATE TRIGGER trg_set_fecha_modificacion_producto
BEFORE UPDATE ON productos
FOR EACH ROW
BEGIN
  SET NEW.fecha_modificacion = NOW();
END$$
 
-- ============================================================
-- 8. trg_prevent_negative_stock
--    Impide que el stock se actualice a un valor negativo.
-- ============================================================
DROP TRIGGER IF EXISTS trg_prevent_negative_stock$$
CREATE TRIGGER trg_prevent_negative_stock
BEFORE UPDATE ON productos
FOR EACH ROW
BEGIN
  IF NEW.stock < 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'El stock no puede ser negativo';
  END IF;
END$$
 
-- ============================================================
-- 9. trg_capitalize_nombre_cliente
--    Capitaliza nombre y apellido al insertar un cliente.
-- ============================================================
DROP TRIGGER IF EXISTS trg_capitalize_nombre_cliente$$
CREATE TRIGGER trg_capitalize_nombre_cliente
BEFORE INSERT ON clientes
FOR EACH ROW
BEGIN
  SET NEW.nombre   = CONCAT(UPPER(LEFT(NEW.nombre, 1)),   LOWER(SUBSTRING(NEW.nombre, 2)));
  SET NEW.apellido = CONCAT(UPPER(LEFT(NEW.apellido, 1)), LOWER(SUBSTRING(NEW.apellido, 2)));
END$$
 
-- ============================================================
-- 10. trg_recalculate_total_venta_on_detalle_change
--     Recalcula el total de la venta al modificar un detalle.
-- ============================================================
DROP TRIGGER IF EXISTS trg_recalculate_total_venta_on_detalle_change$$
CREATE TRIGGER trg_recalculate_total_venta_on_detalle_change
AFTER UPDATE ON Detalle_de_Ventas
FOR EACH ROW
BEGIN
  UPDATE ventas
  SET total = (
    SELECT COALESCE(SUM(cantidad * precio_unitario_congelado), 0)
    FROM Detalle_de_Ventas WHERE id_venta = NEW.id_venta
  )
  WHERE id_venta = NEW.id_venta;
END$$
 
-- ============================================================
-- 11. trg_log_order_status_change
--     Audita cada cambio de estado en un pedido.
-- ============================================================
DROP TRIGGER IF EXISTS trg_log_order_status_change$$
CREATE TRIGGER trg_log_order_status_change
AFTER UPDATE ON ventas
FOR EACH ROW
BEGIN
  IF OLD.estado <> NEW.estado THEN
    INSERT INTO log_estado_pedidos (id_venta, estado_anterior, estado_nuevo)
    VALUES (NEW.id_venta, OLD.estado, NEW.estado);
  END IF;
END$$
 
-- ============================================================
-- 12. trg_prevent_price_zero_or_less
--     Impide que el precio de un producto sea 0 o negativo.
-- ============================================================
DROP TRIGGER IF EXISTS trg_prevent_price_zero_or_less$$
CREATE TRIGGER trg_prevent_price_zero_or_less
BEFORE UPDATE ON productos
FOR EACH ROW
BEGIN
  IF NEW.precio <= 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'El precio del producto debe ser mayor que cero';
  END IF;
END$$
 
-- ============================================================
-- 13. trg_send_stock_alert_on_low_stock
--     Inserta alerta si el stock baja del umbral (30 unidades).
-- ============================================================
DROP TRIGGER IF EXISTS trg_send_stock_alert_on_low_stock$$
CREATE TRIGGER trg_send_stock_alert_on_low_stock
AFTER UPDATE ON productos
FOR EACH ROW
BEGIN
  IF NEW.stock < 30 AND OLD.stock >= 30 THEN
    INSERT INTO alertas_stock (id_producto, stock_actual)
    VALUES (NEW.id_producto, NEW.stock);
  END IF;
END$$
 
-- ============================================================
-- 14. trg_archive_deleted_venta
--     Archiva la venta antes de eliminarla permanentemente.
-- ============================================================
DROP TRIGGER IF EXISTS trg_archive_deleted_venta$$
CREATE TRIGGER trg_archive_deleted_venta
BEFORE DELETE ON ventas
FOR EACH ROW
BEGIN
  INSERT INTO archivo_ventas (id_venta, id_cliente, fecha_venta, estado, total)
  VALUES (OLD.id_venta, OLD.id_cliente, OLD.fecha_venta, OLD.estado, OLD.total);
END$$
 
-- ============================================================
-- 15. trg_validate_email_format_on_customer
--     Valida el formato del email antes de insertar o actualizar.
-- ============================================================
DROP TRIGGER IF EXISTS trg_validate_email_format_on_customer$$
CREATE TRIGGER trg_validate_email_format_on_customer
BEFORE INSERT ON clientes
FOR EACH ROW
BEGIN
  IF NEW.email NOT REGEXP '^[A-Za-z0-9._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}$' THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'El formato del correo electrónico no es válido';
  END IF;
END$$
 
-- ============================================================
-- 16. trg_update_last_order_date_customer
--     Actualiza la fecha del último pedido en clientes.
-- ============================================================
DROP TRIGGER IF EXISTS trg_update_last_order_date_customer$$
CREATE TRIGGER trg_update_last_order_date_customer
AFTER INSERT ON ventas
FOR EACH ROW
BEGIN
  UPDATE clientes
  SET fecha_ultimo_pedido = NEW.fecha_venta
  WHERE id_cliente = NEW.id_cliente
    AND (fecha_ultimo_pedido IS NULL OR NEW.fecha_venta > fecha_ultimo_pedido);
END$$
 
-- ============================================================
-- 17. trg_prevent_self_referral
--     Impide que un cliente se referencie a sí mismo
--     (útil si se agrega un campo id_referidor).
--     Aquí lo aplicamos en log_auditoria_clientes como ejemplo.
-- ============================================================
DROP TRIGGER IF EXISTS trg_prevent_self_referral$$
CREATE TRIGGER trg_prevent_self_referral
BEFORE INSERT ON log_auditoria_clientes
FOR EACH ROW
BEGIN
  -- Placeholder: en un sistema de referidos real, verificar
  -- que NEW.id_referidor <> NEW.id_cliente
  IF NEW.accion = 'AUTO_REFERRAL' THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Un cliente no puede referenciarse a sí mismo';
  END IF;
END$$
 
-- ============================================================
-- 18. trg_log_permission_changes
--     Audita cambios en la tabla de permisos (log_permisos).
-- ============================================================
DROP TRIGGER IF EXISTS trg_log_permission_changes$$
CREATE TRIGGER trg_log_permission_changes
AFTER INSERT ON log_permisos
FOR EACH ROW
BEGIN
  -- El registro ya se inserta; aquí se podría escalar la alerta
  -- En producción: enviar notificación a tabla de alertas
  INSERT INTO log_auditoria_clientes (id_cliente, accion, detalle)
  VALUES (NULL, 'CAMBIO_PERMISO', CONCAT('Usuario: ', NEW.usuario, ' - ', NEW.accion));
END$$
 
-- ============================================================
-- 19. trg_assign_default_category_on_null
--     Asigna categoría "General" si se inserta un producto sin categoría.
-- ============================================================
DROP TRIGGER IF EXISTS trg_assign_default_category_on_null$$
CREATE TRIGGER trg_assign_default_category_on_null
BEFORE INSERT ON productos
FOR EACH ROW
BEGIN
    DECLARE v_categoria INT;

    IF NEW.id_categoria IS NULL THEN
        SELECT id_categoria
        INTO v_categoria
        FROM categorias
        WHERE nombre = 'General'
        LIMIT 1;

        SET NEW.id_categoria = v_categoria;
    END IF;
END$$
 
-- ============================================================
-- 20. trg_update_producto_count_in_categoria
--     Mantiene el contador de productos en cada categoría.
-- ============================================================
DROP TRIGGER IF EXISTS trg_update_producto_count_in_categoria_insert$$
CREATE TRIGGER trg_update_producto_count_in_categoria_insert
AFTER INSERT ON productos
FOR EACH ROW
BEGIN
  IF NEW.id_categoria IS NOT NULL THEN
    UPDATE categorias
    SET total_productos = total_productos + 1
    WHERE id_categoria = NEW.id_categoria;
  END IF;
END$$
 
DROP TRIGGER IF EXISTS trg_update_producto_count_in_categoria_delete$$
CREATE TRIGGER trg_update_producto_count_in_categoria_delete
AFTER DELETE ON productos
FOR EACH ROW
BEGIN
  IF OLD.id_categoria IS NOT NULL THEN
    UPDATE categorias
    SET total_productos = GREATEST(total_productos - 1, 0)
    WHERE id_categoria = OLD.id_categoria;
  END IF;
END$$
 
DELIMITER ;

-- apartir de aca le deje la documentacion a la ia