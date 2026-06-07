USE E_commerce;

-- ===================
-- Consultas Avanzadas
-- ===================

-- ================================
-- 1. Top 10 Productos Más Vendidos
-- ================================

SELECT
    p.id_producto,
    p.nombre,
    SUM(dv.cantidad) AS unidades_vendidas,
    SUM(dv.cantidad * dv.precio_unitario_congelado) AS ingresos_totales
FROM Detalle_de_Ventas dv
JOIN productos p ON dv.id_producto = p.id_producto
JOIN ventas    v ON dv.id_venta    = v.id_venta
WHERE v.estado != 'Cancelado'
GROUP BY p.id_producto, p.nombre
ORDER BY ingresos_totales DESC
LIMIT 10;

-- =============================
-- 2. Productos con Bajas Ventas
-- =============================
WITH ventas_producto AS (
    SELECT
        p.id_producto,
        p.nombre,
        COALESCE(SUM(dv.cantidad), 0) AS unidades_vendidas
    FROM productos p
    LEFT JOIN Detalle_de_Ventas dv ON p.id_producto = dv.id_producto
    LEFT JOIN ventas v          ON dv.id_venta   = v.id_venta AND v.estado != 'Cancelado'
    WHERE p.activo = 1
    GROUP BY p.id_producto, p.nombre
),
percentil AS (
    SELECT PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY unidades_vendidas) AS umbral
    FROM ventas_producto
)
SELECT vp.id_producto, vp.nombre, vp.unidades_vendidas
FROM ventas_producto vp, percentil
WHERE vp.unidades_vendidas <= percentil.umbral
ORDER BY vp.unidades_vendidas ASC;
 
-- =================================================
-- 3. Clientes VIP (Top 5 por gasto total histórico)
-- =================================================
SELECT
    c.id_cliente,
    CONCAT(c.nombre, ' ', c.apellido) AS cliente,
    c.email,
    COUNT(DISTINCT v.id_venta)         AS total_ordenes,
    SUM(v.total)                       AS ltv_total
FROM clientes c
JOIN ventas v ON c.id_cliente = v.id_cliente
WHERE v.estado != 'Cancelado'
GROUP BY c.id_cliente, c.nombre, c.apellido, c.email
ORDER BY ltv_total DESC
LIMIT 5;
 
-- ========================================================================
-- 4. Análisis de Ventas Mensuales (Ventas totales agrupadas por mes y año)
-- ========================================================================
SELECT
    YEAR(v.fecha_venta)  AS anio,
    MONTH(v.fecha_venta) AS mes,
    MONTHNAME(v.fecha_venta) AS nombre_mes,
    COUNT(v.id_venta)    AS num_ordenes,
    SUM(v.total)         AS total_ventas
FROM ventas v
WHERE v.estado != 'Cancelado'
GROUP BY anio, mes, nombre_mes
ORDER BY anio, mes;
 
-- ========================================
-- 5. Crecimiento de Clientes por Trimestre
-- ========================================
SELECT
    YEAR(fecha_registro)    AS anio,
    QUARTER(fecha_registro) AS trimestre,
    COUNT(id_cliente)       AS nuevos_clientes
FROM clientes
GROUP BY anio, trimestre
ORDER BY anio, trimestre;
 
-- =========================================================================
-- 6. Tasa de Compra Repetida (Porcentaje de clientes con más de una compra)
-- =========================================================================
SELECT
    COUNT(DISTINCT CASE WHEN total_ordenes > 1 THEN id_cliente END) AS clientes_repetidos,
    COUNT(DISTINCT id_cliente)                                        AS total_clientes,
    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN total_ordenes > 1 THEN id_cliente END)
              / COUNT(DISTINCT id_cliente), 2
    ) AS tasa_repeticion_pct
FROM (
    SELECT id_cliente, COUNT(id_venta) AS total_ordenes
    FROM ventas
    WHERE estado != 'Cancelado'
    GROUP BY id_cliente
) AS resumen;
 
-- ============================================
-- 7. Productos Comprados Juntos Frecuentemente
-- ============================================
SELECT
    p1.nombre AS producto_1,
    p2.nombre AS producto_2,
    COUNT(*)  AS veces_juntos
FROM Detalle_de_Ventas dv1
JOIN Detalle_de_Ventas dv2 ON dv1.id_venta = dv2.id_venta AND dv1.id_producto < dv2.id_producto
JOIN productos p1 ON dv1.id_producto = p1.id_producto
JOIN productos p2 ON dv2.id_producto = p2.id_producto
GROUP BY p1.nombre, p2.nombre
ORDER BY veces_juntos DESC
LIMIT 20;
 
-- =======================================================================================
-- 8. Rotación de Inventario por Categoría (Unidades vendidas / stock promedio disponible)
-- =======================================================================================
SELECT
    c.nombre AS categoria,
    SUM(dv.cantidad)         AS unidades_vendidas,
    SUM(p.stock)             AS stock_actual,
    ROUND(
        SUM(dv.cantidad) / NULLIF(SUM(p.stock), 0), 2
    ) AS tasa_rotacion
FROM categorias c
JOIN productos p        ON c.id_categoria = p.id_categoria
LEFT JOIN Detalle_de_Ventas dv ON p.id_producto = dv.id_producto
LEFT JOIN ventas v          ON dv.id_venta  = v.id_venta AND v.estado != 'Cancelado'
GROUP BY c.id_categoria, c.nombre
ORDER BY tasa_rotacion DESC;
 
-- ===============================================================
-- 9. Productos que Necesitan Reabastecimiento (stock menos de 30)
-- ===============================================================
SELECT
    p.id_producto,
    p.nombre,
    p.sku,
    p.stock,
    pr.nombre AS proveedor
FROM productos p
LEFT JOIN proveedores pr ON p.id_proveedor = pr.id_proveedor
WHERE p.stock < 30 AND p.activo = 1
ORDER BY p.stock ASC;
 
-- ==============================================================================================================================================
-- 10. Análisis de Carrito Abandonado (Simulado) (Clientes con productos en carrito hace más de 72 horas sin haber completado una venta reciente)
-- ==============================================================================================================================================
SELECT
    c.id_cliente,
    CONCAT(c.nombre, ' ', c.apellido) AS cliente,
    c.email,
    COUNT(ca.id_carrito)              AS productos_abandonados,
    MIN(ca.fecha_agrego)              AS desde_cuando
FROM carritos_abandonados ca
JOIN clientes c ON ca.id_cliente = c.id_cliente
WHERE ca.fecha_agrego < DATE_SUB(NOW(), INTERVAL 72 HOUR)
  AND NOT EXISTS (
      SELECT 1 FROM ventas v
      WHERE v.id_cliente = ca.id_cliente
        AND v.fecha_venta > DATE_SUB(NOW(), INTERVAL 72 HOUR)
        AND v.estado NOT IN ('Cancelado')
  )
GROUP BY c.id_cliente, c.nombre, c.apellido, c.email
ORDER BY desde_cuando ASC;
 
-- =====================================================================================
-- 11. Rendimiento de Proveedores (Proveedores según volumen de ventas de sus productos)
-- =====================================================================================
SELECT
    pr.id_proveedor,
    pr.nombre AS proveedor,
    COUNT(DISTINCT p.id_producto)                          AS num_productos,
    SUM(dv.cantidad)                                       AS unidades_vendidas,
    SUM(dv.cantidad * dv.precio_unitario_congelado)        AS ingresos_generados
FROM proveedores pr
JOIN productos p       ON pr.id_proveedor = p.id_proveedor
LEFT JOIN Detalle_de_Ventas dv ON p.id_producto = dv.id_producto
LEFT JOIN ventas v          ON dv.id_venta  = v.id_venta AND v.estado != 'Cancelado'
GROUP BY pr.id_proveedor, pr.nombre
ORDER BY ingresos_generados DESC;
 
-- ==============================================
-- 12. Análisis Geográfico de Ventas (por ciudad)
-- ==============================================
SELECT
    c.ciudad,
    c.region,
    COUNT(DISTINCT v.id_venta) AS num_ordenes,
    SUM(v.total)               AS total_ventas
FROM ventas v
JOIN clientes c ON v.id_cliente = c.id_cliente
WHERE v.estado != 'Cancelado'
GROUP BY c.ciudad, c.region
ORDER BY total_ventas DESC;
 
-- ===========================
-- 13. Ventas por Hora del Día
-- ===========================
SELECT
    HOUR(fecha_venta) AS hora_dia,
    COUNT(id_venta)   AS num_ordenes,
    SUM(total)        AS ingresos
FROM ventas
WHERE estado != 'Cancelado'
GROUP BY hora_dia
ORDER BY num_ordenes DESC;
 
-- ==============================================================================================================================================================
-- 14. Impacto de Promociones (Comparativa de ventas de un producto antes, durante y después de un período determinado) (Ajusta las fechas según tu campaña real)
-- ==============================================================================================================================================================
SELECT
    p.nombre AS producto,
    SUM(CASE WHEN v.fecha_venta < '2024-03-01'                               THEN dv.cantidad * dv.precio_unitario_congelado ELSE 0 END) AS ventas_antes,
    SUM(CASE WHEN v.fecha_venta BETWEEN '2024-03-01' AND '2024-04-30'        THEN dv.cantidad * dv.precio_unitario_congelado ELSE 0 END) AS ventas_durante,
    SUM(CASE WHEN v.fecha_venta > '2024-04-30'                               THEN dv.cantidad * dv.precio_unitario_congelado ELSE 0 END) AS ventas_despues
FROM Detalle_de_Ventas dv
JOIN productos p ON dv.id_producto = p.id_producto
JOIN ventas    v ON dv.id_venta    = v.id_venta
WHERE v.estado != 'Cancelado'
GROUP BY p.nombre
ORDER BY ventas_durante DESC;
 
-- ================================================================================
-- 15. Análisis de Cohort (Retención de clientes mes a mes desde su primera compra)
-- ================================================================================
WITH primera_compra AS (
    SELECT id_cliente, DATE_FORMAT(MIN(fecha_venta), '%Y-%m') AS cohort
    FROM ventas
    WHERE estado != 'Cancelado'
    GROUP BY id_cliente
),
actividad AS (
    SELECT
        v.id_cliente,
        DATE_FORMAT(v.fecha_venta, '%Y-%m') AS mes_actividad
    FROM ventas v
    WHERE v.estado != 'Cancelado'
    GROUP BY v.id_cliente, mes_actividad
)
SELECT
    pc.cohort,
    a.mes_actividad,
    COUNT(DISTINCT a.id_cliente) AS clientes_activos
FROM primera_compra pc
JOIN actividad a ON pc.id_cliente = a.id_cliente
WHERE a.mes_actividad >= pc.cohort
GROUP BY pc.cohort, a.mes_actividad
ORDER BY pc.cohort, a.mes_actividad;
 
-- ====================================
-- 16. Margen de Beneficio por Producto
-- ====================================
SELECT
    p.id_producto,
    p.nombre,
    p.precio,
    p.costo,
    ROUND(p.precio - p.costo, 2)                  AS margen_bruto,
    ROUND((p.precio - p.costo) / p.precio * 100, 2) AS margen_pct
FROM productos p
WHERE p.activo = 1
ORDER BY margen_pct DESC;
 
-- =============================================
-- 17. Tiempo Promedio Entre Compras por Cliente
-- =============================================
WITH ventas_ordenadas AS (
    SELECT
        id_cliente,
        fecha_venta,
        LAG(fecha_venta) OVER (PARTITION BY id_cliente ORDER BY fecha_venta) AS compra_anterior
    FROM ventas
    WHERE estado != 'Cancelado'
)
SELECT
    id_cliente,
    ROUND(AVG(DATEDIFF(fecha_venta, compra_anterior)), 1) AS dias_entre_compras
FROM ventas_ordenadas
WHERE compra_anterior IS NOT NULL
GROUP BY id_cliente
ORDER BY dias_entre_compras ASC;
 
-- ===================================================================================================
-- 18. Productos Más Vistos vs. Más Comprados (Asume una tabla visitas_productos simulado con ranking)
-- ===================================================================================================
SELECT
    p.id_producto,
    p.nombre,
    COALESCE(SUM(dv.cantidad), 0) AS unidades_compradas,
    RANK() OVER (ORDER BY COALESCE(SUM(dv.cantidad), 0) DESC) AS ranking_compras
FROM productos p
LEFT JOIN Detalle_de_Ventas dv ON p.id_producto = dv.id_producto
LEFT JOIN ventas v          ON dv.id_venta  = v.id_venta AND v.estado != 'Cancelado'
GROUP BY p.id_producto, p.nombre
ORDER BY unidades_compradas DESC;
 
-- ====================================================================================================================================================
-- 19. Segmentación RFM de Clientes (Recencia (días desde última compra), Frecuencia, Monetario) (esta seccion fue con ayuda de ia, no la entendi bien)
-- ====================================================================================================================================================
WITH rfm_raw AS (
    SELECT
        c.id_cliente,
        CONCAT(c.nombre, ' ', c.apellido)        AS cliente,
        DATEDIFF(CURDATE(), MAX(v.fecha_venta))  AS recencia,
        COUNT(v.id_venta)                         AS frecuencia,
        SUM(v.total)                              AS monetario
    FROM clientes c
    JOIN ventas v ON c.id_cliente = v.id_cliente
    WHERE v.estado != 'Cancelado'
    GROUP BY c.id_cliente, c.nombre, c.apellido
),
rfm_scores AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recencia ASC)   AS r_score,
        NTILE(5) OVER (ORDER BY frecuencia DESC) AS f_score,
        NTILE(5) OVER (ORDER BY monetario DESC)  AS m_score
    FROM rfm_raw
)
SELECT
    id_cliente, cliente, recencia, frecuencia, monetario,
    r_score, f_score, m_score,
    (r_score + f_score + m_score) AS rfm_total,
    CASE
        WHEN (r_score + f_score + m_score) >= 13 THEN 'Campeón'
        WHEN (r_score + f_score + m_score) >= 10 THEN 'Cliente Fiel'
        WHEN (r_score + f_score + m_score) >= 7  THEN 'Potencial'
        ELSE 'En Riesgo'
    END AS segmento
FROM rfm_scores
ORDER BY rfm_total DESC;
 
-- ===============================================================================================================
-- 20. Predicción de Demanda Simple (Proyección próximo mes) (Promedio móvil de los últimos 3 meses por categoría)
-- ===============================================================================================================
WITH ventas_mensuales_cat AS (
    SELECT
        c.id_categoria,
        c.nombre AS categoria,
        YEAR(v.fecha_venta)  AS anio,
        MONTH(v.fecha_venta) AS mes,
        SUM(dv.cantidad)     AS unidades_vendidas
    FROM Detalle_de_Ventas dv
    JOIN ventas v    ON dv.id_venta    = v.id_venta
    JOIN productos p ON dv.id_producto = p.id_producto
    JOIN categorias c ON p.id_categoria = c.id_categoria
    WHERE v.estado != 'Cancelado'
    GROUP BY c.id_categoria, c.nombre, anio, mes
)
SELECT
    id_categoria,
    categoria,
    ROUND(AVG(unidades_vendidas), 0) AS proyeccion_proximo_mes
FROM (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY id_categoria ORDER BY anio DESC, mes DESC) AS rn
    FROM ventas_mensuales_cat
) t
WHERE rn <= 3
GROUP BY id_categoria, categoria
ORDER BY proyeccion_proximo_mes DESC;