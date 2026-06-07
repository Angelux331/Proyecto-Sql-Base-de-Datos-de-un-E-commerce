USE E_commerce;

-- ==================================
-- Funciones Definidas por el Usuario
-- ==================================

DELIMITER $$

-- =========================================================================
-- 1. fn_CalcularTotalVenta (Calcula el monto total de una venta específica)
-- =========================================================================
DROP FUNCTION IF EXISTS fn_CalcularTotalVenta$$
CREATE FUNCTION fn_CalcularTotalVenta(p_id_venta INT)
RETURNS DECIMAL(14,2)
DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(14,2);
    SELECT COALESCE(SUM(cantidad * precio_unitario_congelado), 0)
    INTO v_total
    FROM Detalle_de_Ventas
    WHERE id_venta = p_id_venta;
    RETURN v_total;
END$$
 
-- ==========================================================================================
-- 2. fn_VerificarDisponibilidadStock (Retorna TRUE si hay suficiente stock para un producto)
-- ==========================================================================================
DROP FUNCTION IF EXISTS fn_VerificarDisponibilidadStock$$
CREATE FUNCTION fn_VerificarDisponibilidadStock(p_id_producto INT, p_cantidad INT)
RETURNS TINYINT(1)
DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_stock INT;
    SELECT stock INTO v_stock FROM productos WHERE id_producto = p_id_producto;
    RETURN (v_stock >= p_cantidad);
END$$
 
-- ===============================================================================
-- 3. fn_ObtenerPrecioProducto (Devuelve el precio actual de venta de un producto)
-- ===============================================================================
DROP FUNCTION IF EXISTS fn_ObtenerPrecioProducto$$
CREATE FUNCTION fn_ObtenerPrecioProducto(p_id_producto INT)
RETURNS DECIMAL(12,2)
DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_precio DECIMAL(12,2);
    SELECT precio INTO v_precio FROM productos WHERE id_producto = p_id_producto;
    RETURN v_precio;
END$$
 
-- ==========================================================================================
-- 4. fn_CalcularEdadCliente (Calcula la edad del cliente a partir de su fecha de nacimiento)
-- ==========================================================================================
DROP FUNCTION IF EXISTS fn_CalcularEdadCliente$$
CREATE FUNCTION fn_CalcularEdadCliente(p_id_cliente INT)
RETURNS INT
DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_fnac DATE;
    SELECT fecha_nacimiento INTO v_fnac FROM clientes WHERE id_cliente = p_id_cliente;
    IF v_fnac IS NULL THEN RETURN NULL; END IF;
    RETURN TIMESTAMPDIFF(YEAR, v_fnac, CURDATE());
END$$
 
-- =======================================================================================
-- 5. fn_FormatearNombreCompleto (Retorna nombre y apellido en formato "Apellido, Nombre")
-- =======================================================================================
DROP FUNCTION IF EXISTS fn_FormatearNombre$$
CREATE FUNCTION fn_FormatearNombre(p_id_cliente INT)
RETURNS VARCHAR(200)
DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_nombre   VARCHAR(80);
    DECLARE v_apellido VARCHAR(80);
    SELECT nombre, apellido INTO v_nombre, v_apellido
    FROM clientes WHERE id_cliente = p_id_cliente;
    RETURN CONCAT(UPPER(v_apellido), ', ', INITCAP_LIKE(v_nombre));
END$$
 
-- ==========================================================================================
-- 6. fn_EsClienteNuevo (TRUE si el cliente realizó su primera compra en los últimos 30 días)
-- ==========================================================================================
DROP FUNCTION IF EXISTS fn_EsClienteNuevo$$
CREATE FUNCTION fn_EsClienteNuevo(p_id_cliente INT)
RETURNS TINYINT(1)
DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_primera DATE;
    SELECT MIN(DATE(fecha_venta)) INTO v_primera
    FROM ventas WHERE id_cliente = p_id_cliente AND estado != 'Cancelado';
    RETURN (v_primera >= DATE_SUB(CURDATE(), INTERVAL 30 DAY));
END$$
 
-- ========================================================================================
-- 7. fn_CalcularCostoEnvio (Costo de envío simulado: 1% del total de la venta (mín. 8000))
-- ========================================================================================
DROP FUNCTION IF EXISTS fn_CalcularCostoEnvio$$
CREATE FUNCTION fn_CalcularCostoEnvio(p_id_venta INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(14,2);
    DECLARE v_costo DECIMAL(10,2);
    SET v_total = fn_CalcularTotalVenta(p_id_venta);
    SET v_costo = ROUND(v_total * 0.01, 2);
    RETURN IF(v_costo < 8000, 8000, v_costo);
END$$
 
-- ==========================================================================
-- 8. fn_AplicarDescuento (Aplica un porcentaje de descuento a un monto dado)
-- ==========================================================================
DROP FUNCTION IF EXISTS fn_AplicarDescuento$$
CREATE FUNCTION fn_AplicarDescuento(p_monto DECIMAL(14,2), p_descuento_pct DECIMAL(5,2))
RETURNS DECIMAL(14,2)
DETERMINISTIC NO SQL
BEGIN
    IF p_descuento_pct < 0 OR p_descuento_pct > 100 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Porcentaje de descuento inválido';
    END IF;
    RETURN ROUND(p_monto * (1 - p_descuento_pct / 100), 2);
END$$
 
-- ========================================================================
-- 9. fn_ObtenerUltimaFechaCompra (Fecha de la última compra de un cliente)
-- ========================================================================
DROP FUNCTION IF EXISTS fn_ObtenerUltimaFechaCompra$$
CREATE FUNCTION fn_ObtenerUltimaFechaCompra(p_id_cliente INT)
RETURNS DATETIME
DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_fecha DATETIME;
    SELECT MAX(fecha_venta) INTO v_fecha
    FROM ventas WHERE id_cliente = p_id_cliente AND estado != 'Cancelado';
    RETURN v_fecha;
END$$
 
-- =============================================================================
-- 10. fn_ValidarFormatoEmail (TRUE si la cadena tiene formato válido de correo)
-- =============================================================================
DROP FUNCTION IF EXISTS fn_ValidarFormatoEmail$$
CREATE FUNCTION fn_ValidarFormatoEmail(p_email VARCHAR(150))
RETURNS TINYINT(1)
DETERMINISTIC NO SQL
BEGIN
    RETURN (p_email REGEXP '^[A-Za-z0-9._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}$');
END$$
 
-- =====================================================================================
-- 11. fn_ObtenerNombreCategoria (Nombre de la categoría a partir del ID de un producto)
-- =====================================================================================
DROP FUNCTION IF EXISTS fn_ObtenerNombreCategoria$$
CREATE FUNCTION fn_ObtenerNombreCategoria(p_id_producto INT)
RETURNS VARCHAR(100)
DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_nombre VARCHAR(100);
    SELECT c.nombre INTO v_nombre
    FROM productos p JOIN categorias c ON p.id_categoria = c.id_categoria
    WHERE p.id_producto = p_id_producto;
    RETURN COALESCE(v_nombre, 'Sin categoría');
END$$
 
-- =======================================================================================
-- 12. fn_ContarVentasCliente (Total de compras realizadas por un cliente (no canceladas))
-- =======================================================================================
DROP FUNCTION IF EXISTS fn_ContarVentasCliente$$
CREATE FUNCTION fn_ContarVentasCliente(p_id_cliente INT)
RETURNS INT
DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_total INT;
    SELECT COUNT(*) INTO v_total
    FROM ventas WHERE id_cliente = p_id_cliente AND estado != 'Cancelado';
    RETURN v_total;
END$$
 
-- ==============================================================================================
-- 13. fn_CalcularDiasDesdeUltimaCompra (Días transcurridos desde la última compra de un cliente)
-- ==============================================================================================
DROP FUNCTION IF EXISTS fn_CalcularDiasDesdeUltimaCompra$$
CREATE FUNCTION fn_CalcularDiasDesdeUltimaCompra(p_id_cliente INT)
RETURNS INT
DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_ultima DATETIME;
    SET v_ultima = fn_ObtenerUltimaFechaCompra(p_id_cliente);
    IF v_ultima IS NULL THEN RETURN NULL; END IF;
    RETURN DATEDIFF(CURDATE(), DATE(v_ultima));
END$$
 
-- ==========================================================================
-- 14. fn_DeterminarEstadoLealtad (Asigna nivel de lealtad según gasto total)
-- ==========================================================================
DROP FUNCTION IF EXISTS fn_DeterminarEstadoLealtad$$
CREATE FUNCTION fn_DeterminarEstadoLealtad(p_id_cliente INT)
RETURNS VARCHAR(20)
DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_gastado DECIMAL(14,2);
    SELECT total_gastado INTO v_gastado FROM clientes WHERE id_cliente = p_id_cliente;
    RETURN CASE
        WHEN v_gastado >= 5000000 THEN 'Oro'
        WHEN v_gastado >= 2000000 THEN 'Plata'
        ELSE                           'Bronce'
    END;
END$$
 
-- ==========================================================================
-- 15. fn_GenerarSKU (Genera un SKU único: primeras 4 letras del nombre + id)
-- ==========================================================================
DROP FUNCTION IF EXISTS fn_GenerarSKU$$
CREATE FUNCTION fn_GenerarSKU(p_nombre VARCHAR(150), p_id_categoria INT, p_seq INT)
RETURNS VARCHAR(60)
DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_cat VARCHAR(4);
    DECLARE v_prod VARCHAR(4);
    SELECT UPPER(LEFT(REPLACE(nombre,' ',''), 4)) INTO v_cat
    FROM categorias WHERE id_categoria = p_id_categoria;
    SET v_prod = UPPER(LEFT(REPLACE(p_nombre,' ',''), 4));
    RETURN CONCAT(v_cat, '-', v_prod, '-', LPAD(p_seq, 4, '0'));
END$$
 
-- ==============================================================================
-- 16. fn_CalcularIVA (Calcula el IVA (19% Colombia) sobre el total de una venta)
-- ==============================================================================
DROP FUNCTION IF EXISTS fn_CalcularIVA$$
CREATE FUNCTION fn_CalcularIVA(p_id_venta INT)
RETURNS DECIMAL(14,2)
DETERMINISTIC READS SQL DATA
BEGIN
    RETURN ROUND(fn_CalcularTotalVenta(p_id_venta) * 0.19, 2);
END$$
 
-- ====================================================================================================
-- 17. fn_ObtenerStockTotalPorCategoria (Suma el stock de todos los productos activos de una categoría)
-- ====================================================================================================
DROP FUNCTION IF EXISTS fn_ObtenerStockTotalPorCategoria$$
CREATE FUNCTION fn_ObtenerStockTotalPorCategoria(p_id_categoria INT)
RETURNS INT
DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_total INT;
    SELECT COALESCE(SUM(stock), 0) INTO v_total
    FROM productos
    WHERE id_categoria = p_id_categoria AND activo = 1;
    RETURN v_total;
END$$
 
-- ===========================================================================================================
-- 18. fn_EstimarFechaEntrega (Fecha estimada de entrega: +3 días hábiles para Bogotá, +5 para otras ciudades)
-- ===========================================================================================================
DROP FUNCTION IF EXISTS fn_EstimarFechaEntrega$$
CREATE FUNCTION fn_EstimarFechaEntrega(p_id_venta INT)
RETURNS DATE
DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_ciudad VARCHAR(100);
    DECLARE v_dias   INT DEFAULT 5;
    SELECT c.ciudad INTO v_ciudad
    FROM ventas v JOIN clientes c ON v.id_cliente = c.id_cliente
    WHERE v.id_venta = p_id_venta;
    IF v_ciudad = 'Bogotá' THEN SET v_dias = 3; END IF;
    RETURN DATE_ADD(CURDATE(), INTERVAL v_dias DAY);
END$$
 
-- ===========================================================================
-- 19. fn_ConvertirMoneda (Convierte un monto COP a otra moneda con tasa fija)
-- ===========================================================================
DROP FUNCTION IF EXISTS fn_ConvertirMoneda$$
CREATE FUNCTION fn_ConvertirMoneda(p_monto DECIMAL(14,2), p_moneda_destino VARCHAR(3))
RETURNS DECIMAL(14,4)
DETERMINISTIC NO SQL
BEGIN
    DECLARE v_tasa DECIMAL(14,6);
    SET v_tasa = CASE p_moneda_destino
        WHEN 'USD' THEN 0.000245
        WHEN 'EUR' THEN 0.000226
        WHEN 'GBP' THEN 0.000194
        ELSE 1
    END;
    RETURN ROUND(p_monto * v_tasa, 4);
END$$
 
-- =============================================================================================================================================
-- 20. fn_ValidarComplejidadContrasena (Verifica que la contraseña tenga al menos 8 caracteres, una mayúscula, un número y un carácter especial)
-- =============================================================================================================================================
DROP FUNCTION IF EXISTS fn_ValidarComplejidadContrasena$$
CREATE FUNCTION fn_ValidarComplejidadContrasena(p_contrasena VARCHAR(255))
RETURNS TINYINT(1)
DETERMINISTIC NO SQL
BEGIN
    IF LENGTH(p_contrasena) < 8                              THEN RETURN 0; END IF;
    IF p_contrasena NOT REGEXP '[A-Z]'                       THEN RETURN 0; END IF;
    IF p_contrasena NOT REGEXP '[0-9]'                       THEN RETURN 0; END IF;
    IF p_contrasena NOT REGEXP '[^A-Za-z0-9]'               THEN RETURN 0; END IF;
    RETURN 1;
END$$
 
DELIMITER ;