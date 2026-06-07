USE E_commerce;

-- ============================================================
-- Eventos
-- ============================================================

-- Activar el planificador de eventos
SET GLOBAL event_scheduler = ON;

DELIMITER $$

-- ============================================================
-- 1. evt_generate_weekly_sales_report
--    Genera un reporte de ventas semanal (cada lunes a las 01:00).
-- ============================================================
DROP EVENT IF EXISTS evt_generate_weekly_sales_report$$
CREATE EVENT evt_generate_weekly_sales_report
ON SCHEDULE EVERY 1 WEEK
STARTS TIMESTAMP(CURDATE() - INTERVAL WEEKDAY(CURDATE()) DAY + INTERVAL 1 WEEK, '01:00:00')
DO BEGIN
    INSERT INTO reporte_ventas_semanales (semana_inicio, semana_fin, total_ventas, num_ordenes)
    SELECT
        DATE_SUB(CURDATE(), INTERVAL 7 DAY),
        CURDATE(),
        COALESCE(SUM(total), 0),
        COUNT(id_venta)
    FROM ventas
    WHERE fecha_venta >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
      AND estado != 'Cancelado';
END$$

-- ============================================================
-- 2. evt_cleanup_temp_tables_daily
--    Limpia filas obsoletas en tablas de trabajo temporales (diario 03:00).
-- ============================================================
DROP EVENT IF EXISTS evt_cleanup_temp_tables_daily$$
CREATE EVENT evt_cleanup_temp_tables_daily
ON SCHEDULE EVERY 1 DAY
STARTS (TIMESTAMP(CURDATE()) + INTERVAL 3 HOUR)
DO BEGIN
    -- Limpia alertas de stock resueltas con más de 30 días
    DELETE FROM alertas_stock
    WHERE resuelta = 1 AND fecha_alerta < DATE_SUB(NOW(), INTERVAL 30 DAY);
END$$

-- ============================================================
-- 3. evt_archive_old_logs_monthly
--    Archiva logs de más de 6 meses (1er día de cada mes 02:00).
-- ============================================================
DROP EVENT IF EXISTS evt_archive_old_logs_monthly$$
CREATE EVENT evt_archive_old_logs_monthly
ON SCHEDULE EVERY 1 MONTH
STARTS (DATE_FORMAT(NOW() + INTERVAL 1 MONTH, '%Y-%m-01 02:00:00'))
DO BEGIN
    DELETE FROM log_cambios_precio
    WHERE fecha_cambio < DATE_SUB(NOW(), INTERVAL 6 MONTH);

    DELETE FROM log_auditoria_clientes
    WHERE fecha < DATE_SUB(NOW(), INTERVAL 6 MONTH);

    DELETE FROM log_estado_pedidos
    WHERE fecha_cambio < DATE_SUB(NOW(), INTERVAL 6 MONTH);
END$$

-- ============================================================
-- 4. evt_deactivate_expired_promotions_hourly
--    Desactiva productos marcados para descontinuación (cada hora).
--    (Extiende lógica si se agrega tabla promociones)
-- ============================================================
DROP EVENT IF EXISTS evt_deactivate_expired_promotions_hourly$$
CREATE EVENT evt_deactivate_expired_promotions_hourly
ON SCHEDULE EVERY 1 HOUR
STARTS NOW()
DO BEGIN
    -- Placeholder: desactivar productos sin stock > 90 días
    UPDATE productos
    SET activo = 0
    WHERE stock = 0
      AND fecha_modificacion < DATE_SUB(NOW(), INTERVAL 90 DAY)
      AND activo = 1;
END$$

-- ============================================================
-- 5. evt_recalculate_customer_loyalty_tiers_nightly
--    Recalcula el nivel de lealtad de los clientes (noche, 02:30).
-- ============================================================
DROP EVENT IF EXISTS evt_recalculate_customer_loyalty_tiers_nightly$$
CREATE EVENT evt_recalculate_customer_loyalty_tiers_nightly
ON SCHEDULE EVERY 1 DAY
STARTS (TIMESTAMP(CURDATE()) + INTERVAL 2 HOUR + INTERVAL 30 MINUTE)
DO BEGIN
    UPDATE clientes c
    SET total_gastado = (
        SELECT COALESCE(SUM(v.total), 0)
        FROM ventas v
        WHERE v.id_cliente = c.id_cliente AND v.estado = 'Entregado'
    );
END$$

-- ============================================================
-- 6. evt_generate_reorder_list_daily
--    Crea una lista de productos que necesitan reabastecerse (diario 06:00).
-- ============================================================
DROP EVENT IF EXISTS evt_generate_reorder_list_daily$$
CREATE EVENT evt_generate_reorder_list_daily
ON SCHEDULE EVERY 1 DAY
STARTS (TIMESTAMP(CURDATE()) + INTERVAL 6 HOUR)
DO BEGIN
    -- Insertar alerta para cada producto con stock < 30
    INSERT INTO alertas_stock (id_producto, stock_actual)
    SELECT id_producto, stock
    FROM productos
    WHERE stock < 30 AND activo = 1
      AND id_producto NOT IN (
          SELECT id_producto FROM alertas_stock WHERE resuelta = 0
      );
END$$

-- ============================================================
-- 7. evt_rebuild_indexes_weekly
--    Reconstruye índices (análisis de tablas) semanalmente (domingo 04:00).
-- ============================================================
DROP EVENT IF EXISTS evt_rebuild_indexes_weekly$$
CREATE EVENT evt_rebuild_indexes_weekly
ON SCHEDULE EVERY 1 WEEK
STARTS (TIMESTAMP(CURDATE() + INTERVAL (7 - WEEKDAY(CURDATE())) DAY) + INTERVAL 4 HOUR)
DO BEGIN
    ANALYZE TABLE productos;
    ANALYZE TABLE ventas;
    ANALYZE TABLE detalle_ventas;
    ANALYZE TABLE clientes;
END$$

-- ============================================================
-- 8. evt_suspend_inactive_accounts_quarterly
--    Desactiva cuentas sin actividad en más de 1 año (trimestral).
-- ============================================================
DROP EVENT IF EXISTS evt_suspend_inactive_accounts_quarterly$$
CREATE EVENT evt_suspend_inactive_accounts_quarterly
ON SCHEDULE EVERY 3 MONTH
STARTS (DATE_FORMAT(NOW() + INTERVAL 3 MONTH, '%Y-%m-01 05:00:00'))
DO BEGIN
    UPDATE clientes
    SET total_gastado = total_gastado -- marcador; en producción agregar campo 'activo'
    WHERE fecha_ultimo_pedido < DATE_SUB(NOW(), INTERVAL 1 YEAR)
       OR (fecha_ultimo_pedido IS NULL AND fecha_registro < DATE_SUB(NOW(), INTERVAL 1 YEAR));
END$$

-- ============================================================
-- 9. evt_aggregate_daily_sales_data
--    Agrega ventas del día en la tabla de KPIs (diario 23:55).
-- ============================================================
DROP EVENT IF EXISTS evt_aggregate_daily_sales_data$$
CREATE EVENT evt_aggregate_daily_sales_data
ON SCHEDULE EVERY 1 DAY
STARTS (TIMESTAMP(CURDATE()) + INTERVAL 23 HOUR + INTERVAL 55 MINUTE)
DO BEGIN
    INSERT INTO kpis_mensuales (anio, mes, total_ventas, num_ordenes, nuevos_clientes)
    SELECT
        YEAR(CURDATE()),
        MONTH(CURDATE()),
        COALESCE(SUM(v.total), 0),
        COUNT(v.id_venta),
        (SELECT COUNT(*) FROM clientes WHERE MONTH(fecha_registro) = MONTH(CURDATE()) AND YEAR(fecha_registro) = YEAR(CURDATE()))
    FROM ventas v
    WHERE MONTH(v.fecha_venta) = MONTH(CURDATE())
      AND YEAR(v.fecha_venta)  = YEAR(CURDATE())
      AND v.estado != 'Cancelado'
    ON DUPLICATE KEY UPDATE
        total_ventas    = VALUES(total_ventas),
        num_ordenes     = VALUES(num_ordenes),
        nuevos_clientes = VALUES(nuevos_clientes),
        calculado_en    = NOW();
END$$

-- ============================================================
-- 10. evt_check_data_consistency_nightly
--     Busca ventas sin detalles y las registra (noche 03:30).
-- ============================================================
DROP EVENT IF EXISTS evt_check_data_consistency_nightly$$
CREATE EVENT evt_check_data_consistency_nightly
ON SCHEDULE EVERY 1 DAY
STARTS (TIMESTAMP(CURDATE()) + INTERVAL 3 HOUR + INTERVAL 30 MINUTE)
DO BEGIN
    INSERT INTO log_auditoria_clientes (id_cliente, accion, detalle)
    SELECT v.id_cliente, 'VENTA_SIN_DETALLE',
           CONCAT('id_venta=', v.id_venta, ' sin líneas de detalle')
    FROM ventas v
    LEFT JOIN detalle_ventas dv ON v.id_venta = dv.id_venta
    WHERE dv.id_detalle IS NULL AND v.estado NOT IN ('Cancelado');
END$$

-- ============================================================
-- 11. evt_send_birthday_greetings_daily
--     Lista clientes que cumplen años hoy para enviarles cupón (diario 08:00).
-- ============================================================
DROP EVENT IF EXISTS evt_send_birthday_greetings_daily$$
CREATE EVENT evt_send_birthday_greetings_daily
ON SCHEDULE EVERY 1 DAY
STARTS (TIMESTAMP(CURDATE()) + INTERVAL 8 HOUR)
DO BEGIN
    INSERT INTO log_auditoria_clientes (id_cliente, accion, detalle)
    SELECT id_cliente, 'CUMPLEANOS_HOY',
           CONCAT('Feliz cumpleaños - generar cupón para ', email)
    FROM clientes
    WHERE MONTH(fecha_nacimiento) = MONTH(CURDATE())
      AND DAY(fecha_nacimiento)   = DAY(CURDATE());
END$$

-- ============================================================
-- 12. evt_update_product_rankings_hourly
--     Actualiza la tabla ranking_productos cada hora.
-- ============================================================
DROP EVENT IF EXISTS evt_update_product_rankings_hourly$$
CREATE EVENT evt_update_product_rankings_hourly
ON SCHEDULE EVERY 1 HOUR
STARTS NOW()
DO BEGIN
    REPLACE INTO ranking_productos (id_producto, nombre, total_vendido, ingresos, actualizado_en)
    SELECT
        p.id_producto,
        p.nombre,
        COALESCE(SUM(dv.cantidad), 0),
        COALESCE(SUM(dv.cantidad * dv.precio_unitario_congelado), 0),
        NOW()
    FROM productos p
    LEFT JOIN detalle_ventas dv ON p.id_producto = dv.id_producto
    LEFT JOIN ventas v          ON dv.id_venta   = v.id_venta AND v.estado != 'Cancelado'
    GROUP BY p.id_producto, p.nombre;
END$$

-- ============================================================
-- 13. evt_backup_critical_tables_daily
--     Simula un backup lógico: copia datos clave a tablas _bk (noche 01:00).
-- ============================================================
DROP EVENT IF EXISTS evt_backup_critical_tables_daily$$
CREATE EVENT evt_backup_critical_tables_daily
ON SCHEDULE EVERY 1 DAY
STARTS (TIMESTAMP(CURDATE()) + INTERVAL 1 HOUR)
DO BEGIN
    -- En producción, esto se reemplaza por mysqldump desde el SO.
    -- Aquí se crea/actualiza una tabla de respaldo simple.
    CREATE TABLE IF NOT EXISTS ventas_bk LIKE ventas;
    REPLACE INTO ventas_bk SELECT * FROM ventas;
END$$

-- ============================================================
-- 14. evt_clear_abandoned_carts_daily
--     Elimina carritos abandonados hace más de 72 horas (diario 04:00).
-- ============================================================
DROP EVENT IF EXISTS evt_clear_abandoned_carts_daily$$
CREATE EVENT evt_clear_abandoned_carts_daily
ON SCHEDULE EVERY 1 DAY
STARTS (TIMESTAMP(CURDATE()) + INTERVAL 4 HOUR)
DO BEGIN
    DELETE FROM carritos_abandonados
    WHERE fecha_agrego < DATE_SUB(NOW(), INTERVAL 72 HOUR);
END$$

-- ============================================================
-- 15. evt_calculate_monthly_kpis
--     Calcula los KPIs del mes y los guarda (1er día de c/mes 00:30).
-- ============================================================
DROP EVENT IF EXISTS evt_calculate_monthly_kpis$$
CREATE EVENT evt_calculate_monthly_kpis
ON SCHEDULE EVERY 1 MONTH
STARTS (DATE_FORMAT(NOW() + INTERVAL 1 MONTH, '%Y-%m-01 00:30:00'))
DO BEGIN
    INSERT INTO kpis_mensuales (anio, mes, total_ventas, num_ordenes, nuevos_clientes)
    SELECT
        YEAR(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)),
        MONTH(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)),
        COALESCE(SUM(total), 0),
        COUNT(id_venta),
        (SELECT COUNT(*) FROM clientes
         WHERE YEAR(fecha_registro)  = YEAR(DATE_SUB(CURDATE(), INTERVAL 1 MONTH))
           AND MONTH(fecha_registro) = MONTH(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)))
    FROM ventas
    WHERE YEAR(fecha_venta)  = YEAR(DATE_SUB(CURDATE(), INTERVAL 1 MONTH))
      AND MONTH(fecha_venta) = MONTH(DATE_SUB(CURDATE(), INTERVAL 1 MONTH))
      AND estado != 'Cancelado'
    ON DUPLICATE KEY UPDATE
        total_ventas    = VALUES(total_ventas),
        num_ordenes     = VALUES(num_ordenes),
        nuevos_clientes = VALUES(nuevos_clientes);
END$$

-- ============================================================
-- 16. evt_refresh_materialized_views_nightly
--     Actualiza las tablas de resumen usadas como vistas materializadas.
-- ============================================================
DROP EVENT IF EXISTS evt_refresh_materialized_views_nightly$$
CREATE EVENT evt_refresh_materialized_views_nightly
ON SCHEDULE EVERY 1 DAY
STARTS (TIMESTAMP(CURDATE()) + INTERVAL 2 HOUR)
DO BEGIN
    REPLACE INTO ranking_productos (id_producto, nombre, total_vendido, ingresos, actualizado_en)
    SELECT p.id_producto, p.nombre,
           COALESCE(SUM(dv.cantidad), 0),
           COALESCE(SUM(dv.cantidad * dv.precio_unitario_congelado), 0),
           NOW()
    FROM productos p
    LEFT JOIN detalle_ventas dv ON p.id_producto = dv.id_producto
    LEFT JOIN ventas v          ON dv.id_venta   = v.id_venta AND v.estado != 'Cancelado'
    GROUP BY p.id_producto, p.nombre;
END$$

-- ============================================================
-- 17. evt_log_database_size_weekly
--     Registra el tamaño de la BD en la tabla de auditoría (semanal).
-- ============================================================
DROP EVENT IF EXISTS evt_log_database_size_weekly$$
CREATE EVENT evt_log_database_size_weekly
ON SCHEDULE EVERY 1 WEEK
STARTS (TIMESTAMP(CURDATE()) + INTERVAL 5 HOUR)
DO BEGIN
    INSERT INTO log_auditoria_clientes (id_cliente, accion, detalle)
    SELECT NULL, 'DB_SIZE_MONITOR',
           CONCAT('Tamaño BD E_commerce: ',
                  ROUND(SUM(data_length + index_length) / 1024 / 1024, 2), ' MB')
    FROM information_schema.TABLES
    WHERE table_schema = 'E_commerce';
END$$

-- ============================================================
-- 18. evt_detect_fraudulent_activity_hourly
--     Detecta clientes con más de 5 pedidos en la última hora.
-- ============================================================
DROP EVENT IF EXISTS evt_detect_fraudulent_activity_hourly$$
CREATE EVENT evt_detect_fraudulent_activity_hourly
ON SCHEDULE EVERY 1 HOUR
STARTS NOW()
DO BEGIN
    INSERT INTO log_auditoria_clientes (id_cliente, accion, detalle)
    SELECT id_cliente, 'POSIBLE_FRAUDE',
           CONCAT(COUNT(*), ' pedidos en la última hora')
    FROM ventas
    WHERE fecha_venta >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
    GROUP BY id_cliente
    HAVING COUNT(*) > 5;
END$$

-- ============================================================
-- 19. evt_generate_supplier_performance_report_monthly
--     Crea reporte mensual de rendimiento de proveedores.
-- ============================================================
DROP EVENT IF EXISTS evt_generate_supplier_performance_report_monthly$$
CREATE EVENT evt_generate_supplier_performance_report_monthly
ON SCHEDULE EVERY 1 MONTH
STARTS (DATE_FORMAT(NOW() + INTERVAL 1 MONTH, '%Y-%m-02 07:00:00'))
DO BEGIN
    INSERT INTO log_auditoria_clientes (id_cliente, accion, detalle)
    SELECT NULL, 'REPORTE_PROVEEDOR',
           CONCAT(pr.nombre, ' - Ventas: ',
                  COALESCE(SUM(dv.cantidad * dv.precio_unitario_congelado), 0))
    FROM proveedores pr
    LEFT JOIN productos p ON pr.id_proveedor = p.id_proveedor
    LEFT JOIN detalle_ventas dv ON p.id_producto = dv.id_producto
    LEFT JOIN ventas v ON dv.id_venta = v.id_venta
          AND MONTH(v.fecha_venta) = MONTH(DATE_SUB(CURDATE(), INTERVAL 1 MONTH))
          AND v.estado != 'Cancelado'
    GROUP BY pr.id_proveedor, pr.nombre;
END$$

-- ============================================================
-- 20. evt_purge_soft_deleted_records_weekly
--     Elimina permanentemente registros marcados para borrado > 30 días.
-- ============================================================
DROP EVENT IF EXISTS evt_purge_soft_deleted_records_weekly$$
CREATE EVENT evt_purge_soft_deleted_records_weekly
ON SCHEDULE EVERY 1 WEEK
STARTS (TIMESTAMP(CURDATE()) + INTERVAL 3 HOUR)
DO BEGIN
    -- Elimina ventas archivadas con más de 30 días en el archivo
    DELETE FROM archivo_ventas
    WHERE fecha_archivo < DATE_SUB(NOW(), INTERVAL 30 DAY);

    -- Elimina alertas de stock resueltas con más de 30 días
    DELETE FROM alertas_stock
    WHERE resuelta = 1 AND fecha_alerta < DATE_SUB(NOW(), INTERVAL 30 DAY);
END$$

DELIMITER ;