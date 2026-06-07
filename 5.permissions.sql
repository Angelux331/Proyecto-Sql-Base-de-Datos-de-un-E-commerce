USE E_commerce;

-- ============================================================
-- Seguridad y Permisos
-- ============================================================
 
-- ============================================================
-- VISTAS DE SEGURIDAD
-- (Se crean antes de los roles para que los GRANT funcionen)
-- ============================================================
 
-- Vista para Atención al Cliente: oculta contraseña y datos sensibles
CREATE OR REPLACE VIEW v_info_clientes_basica AS
SELECT
    id_cliente,
    nombre,
    apellido,
    email,
    direccion_envio,
    ciudad,
    region,
    fecha_registro,
    fecha_ultimo_pedido
FROM clientes;
 
-- Vista para Visitantes: solo productos activos sin costos internos
CREATE OR REPLACE VIEW v_productos_publicos AS
SELECT
    id_producto,
    nombre,
    descripcion,
    precio,
    stock,
    sku,
    activo,
    id_categoria
FROM productos
WHERE activo = 1;
 
-- Vista para Auditores: ventas sin datos personales identificables
CREATE OR REPLACE VIEW v_ventas_auditoria AS
SELECT
    v.id_venta,
    v.fecha_venta,
    v.estado,
    v.total,
    c.ciudad,
    c.region
FROM ventas v
JOIN clientes c ON v.id_cliente = c.id_cliente;
 
-- Vista por sucursal (req. 19)
CREATE OR REPLACE VIEW v_ventas_sucursal_1 AS
SELECT * FROM ventas WHERE id_sucursal = 1;
 
CREATE OR REPLACE VIEW v_ventas_sucursal_2 AS
SELECT * FROM ventas WHERE id_sucursal = 2;
 
-- ============================================================
-- ROLES
-- ============================================================
 
-- 1. Administrador_Sistema: todos los privilegios sobre la BD
DROP ROLE IF EXISTS 'Administrador_Sistema';
CREATE ROLE 'Administrador_Sistema';
GRANT ALL PRIVILEGES ON E_commerce.* TO 'Administrador_Sistema';
 
-- 2. Gerente_Marketing: lectura en ventas, clientes, productos
DROP ROLE IF EXISTS 'Gerente_Marketing';
CREATE ROLE 'Gerente_Marketing';
GRANT SELECT ON E_commerce.ventas         TO 'Gerente_Marketing';
GRANT SELECT ON E_commerce.clientes       TO 'Gerente_Marketing';
GRANT SELECT ON E_commerce.Detalle_de_Ventas TO 'Gerente_Marketing';
GRANT SELECT ON E_commerce.productos      TO 'Gerente_Marketing';
GRANT SELECT ON E_commerce.categorias     TO 'Gerente_Marketing';
GRANT SELECT ON E_commerce.kpis_mensuales TO 'Gerente_Marketing';
 
-- 3. Analista_Datos: lectura en tablas operativas, SIN tablas de auditoría
DROP ROLE IF EXISTS 'Analista_Datos';
CREATE ROLE 'Analista_Datos';
GRANT SELECT ON E_commerce.categorias        TO 'Analista_Datos';
GRANT SELECT ON E_commerce.proveedores       TO 'Analista_Datos';
GRANT SELECT ON E_commerce.productos         TO 'Analista_Datos';
GRANT SELECT ON E_commerce.clientes          TO 'Analista_Datos';
GRANT SELECT ON E_commerce.ventas            TO 'Analista_Datos';
GRANT SELECT ON E_commerce.Detalle_de_Ventas    TO 'Analista_Datos';
GRANT SELECT ON E_commerce.resenas_productos TO 'Analista_Datos';
GRANT SELECT ON E_commerce.ranking_productos TO 'Analista_Datos';
GRANT SELECT ON E_commerce.kpis_mensuales    TO 'Analista_Datos';
 
-- 4. Empleado_Inventario: solo puede ver y actualizar stock (NO precio)
DROP ROLE IF EXISTS 'Empleado_Inventario';
CREATE ROLE 'Empleado_Inventario';
GRANT SELECT         ON E_commerce.productos    TO 'Empleado_Inventario';
GRANT SELECT         ON E_commerce.categorias   TO 'Empleado_Inventario';
GRANT SELECT         ON E_commerce.proveedores  TO 'Empleado_Inventario';
GRANT SELECT         ON E_commerce.alertas_stock TO 'Empleado_Inventario';
GRANT UPDATE (stock) ON E_commerce.productos    TO 'Empleado_Inventario';
 
-- 5. Atencion_Cliente: ve clientes (sin datos sensibles) y ventas
DROP ROLE IF EXISTS 'Atencion_Cliente';
CREATE ROLE 'Atencion_Cliente';
GRANT SELECT          ON E_commerce.v_info_clientes_basica TO 'Atencion_Cliente';
GRANT SELECT          ON E_commerce.ventas                 TO 'Atencion_Cliente';
GRANT SELECT          ON E_commerce.Detalle_de_Ventas         TO 'Atencion_Cliente';
GRANT SELECT          ON E_commerce.productos              TO 'Atencion_Cliente';
GRANT SELECT          ON E_commerce.resenas_productos      TO 'Atencion_Cliente';
GRANT UPDATE (estado) ON E_commerce.ventas                 TO 'Atencion_Cliente';
 
-- 6. Auditor_Financiero: lectura en ventas, productos y todos los logs
DROP ROLE IF EXISTS 'Auditor_Financiero';
CREATE ROLE 'Auditor_Financiero';
GRANT SELECT ON E_commerce.ventas                 TO 'Auditor_Financiero';
GRANT SELECT ON E_commerce.Detalle_de_Ventas         TO 'Auditor_Financiero';
GRANT SELECT ON E_commerce.productos              TO 'Auditor_Financiero';
GRANT SELECT ON E_commerce.clientes               TO 'Auditor_Financiero';
GRANT SELECT ON E_commerce.log_cambios_precio     TO 'Auditor_Financiero';
GRANT SELECT ON E_commerce.log_estado_pedidos     TO 'Auditor_Financiero';
GRANT SELECT ON E_commerce.log_auditoria_clientes TO 'Auditor_Financiero';
GRANT SELECT ON E_commerce.v_ventas_auditoria     TO 'Auditor_Financiero';
GRANT SELECT ON E_commerce.kpis_mensuales         TO 'Auditor_Financiero';
 
-- 7. Visitante: solo puede ver el catálogo público
DROP ROLE IF EXISTS 'Visitante';
CREATE ROLE 'Visitante';
GRANT SELECT ON E_commerce.v_productos_publicos TO 'Visitante';
GRANT SELECT ON E_commerce.categorias           TO 'Visitante';
 
-- ============================================================
-- USUARIOS
-- ============================================================
 
-- 7. admin_user → Administrador_Sistema
DROP USER IF EXISTS 'admin_user'@'localhost';
CREATE USER 'admin_user'@'localhost'
    IDENTIFIED BY 'Admin@Secure2024!'
    PASSWORD EXPIRE INTERVAL 90 DAY
    FAILED_LOGIN_ATTEMPTS 5 PASSWORD_LOCK_TIME 1;
GRANT 'Administrador_Sistema' TO 'admin_user'@'localhost';
SET DEFAULT ROLE 'Administrador_Sistema' TO 'admin_user'@'localhost';
 
-- 8. marketing_user → Gerente_Marketing
DROP USER IF EXISTS 'marketing_user'@'localhost';
CREATE USER 'marketing_user'@'localhost'
    IDENTIFIED BY 'Marketing@2024!'
    PASSWORD EXPIRE INTERVAL 90 DAY
    FAILED_LOGIN_ATTEMPTS 5 PASSWORD_LOCK_TIME 1;
GRANT 'Gerente_Marketing' TO 'marketing_user'@'localhost';
SET DEFAULT ROLE 'Gerente_Marketing' TO 'marketing_user'@'localhost';
 
-- 9. inventory_user → Empleado_Inventario
DROP USER IF EXISTS 'inventory_user'@'localhost';
CREATE USER 'inventory_user'@'localhost'
    IDENTIFIED BY 'Inventory@2024!'
    PASSWORD EXPIRE INTERVAL 90 DAY
    FAILED_LOGIN_ATTEMPTS 5 PASSWORD_LOCK_TIME 1;
GRANT 'Empleado_Inventario' TO 'inventory_user'@'localhost';
SET DEFAULT ROLE 'Empleado_Inventario' TO 'inventory_user'@'localhost';
 
-- 10. support_user → Atencion_Cliente
DROP USER IF EXISTS 'support_user'@'localhost';
CREATE USER 'support_user'@'localhost'
    IDENTIFIED BY 'Support@2024!'
    PASSWORD EXPIRE INTERVAL 90 DAY
    FAILED_LOGIN_ATTEMPTS 5 PASSWORD_LOCK_TIME 1;
GRANT 'Atencion_Cliente' TO 'support_user'@'localhost';
SET DEFAULT ROLE 'Atencion_Cliente' TO 'support_user'@'localhost';
 
-- auditor_user → Auditor_Financiero
DROP USER IF EXISTS 'auditor_user'@'localhost';
CREATE USER 'auditor_user'@'localhost'
    IDENTIFIED BY 'Auditor@2024!'
    PASSWORD EXPIRE INTERVAL 90 DAY
    FAILED_LOGIN_ATTEMPTS 5 PASSWORD_LOCK_TIME 1;
GRANT 'Auditor_Financiero' TO 'auditor_user'@'localhost';
SET DEFAULT ROLE 'Auditor_Financiero' TO 'auditor_user'@'localhost';
 
-- analista_user → Analista_Datos (con límite de consultas)
DROP USER IF EXISTS 'analista_user'@'localhost';
CREATE USER 'analista_user'@'localhost'
    IDENTIFIED BY 'Analista@2024!'
    WITH MAX_QUERIES_PER_HOUR    200
         MAX_CONNECTIONS_PER_HOUR 50
         MAX_UPDATES_PER_HOUR     0
    PASSWORD EXPIRE INTERVAL 90 DAY
    FAILED_LOGIN_ATTEMPTS 5 PASSWORD_LOCK_TIME 1;
GRANT 'Analista_Datos' TO 'analista_user'@'localhost';
SET DEFAULT ROLE 'Analista_Datos' TO 'analista_user'@'localhost';
 
-- ============================================================
-- 12. Gerente_Marketing puede ejecutar procedimientos de reportes
-- ============================================================
GRANT EXECUTE ON PROCEDURE E_commerce.sp_GenerarReporteMensualVentas
    TO 'Gerente_Marketing';
GRANT EXECUTE ON PROCEDURE E_commerce.sp_GenerarReporteMensualVentas
    TO 'marketing_user'@'localhost';
GRANT EXECUTE ON PROCEDURE E_commerce.sp_ObtenerDashboardAdmin
    TO 'marketing_user'@'localhost';
 
-- Permisos de EXECUTE para support_user
GRANT EXECUTE ON PROCEDURE E_commerce.sp_ObtenerHistorialComprasCliente
    TO 'support_user'@'localhost';
GRANT EXECUTE ON PROCEDURE E_commerce.sp_CambiarEstadoPedido
    TO 'support_user'@'localhost';
 
-- ============================================================
-- 13. Vista v_info_clientes_basica: acceso concedido a Atencion_Cliente
--     La vista ya excluye: contrasena, total_gastado, fecha_nacimiento.
--     Se crea además un procedimiento de solo lectura para el rol.
-- ============================================================
GRANT SELECT ON E_commerce.v_info_clientes_basica TO 'Atencion_Cliente';
GRANT SELECT ON E_commerce.v_info_clientes_basica TO 'support_user'@'localhost';
 
-- Revocar acceso directo a la tabla clientes para support_user
-- (debe usar solo la vista, no la tabla base)
REVOKE SELECT ON E_commerce.clientes FROM 'support_user'@'localhost';
 
-- ============================================================
-- 14. Revocar UPDATE sobre la columna precio al rol Empleado_Inventario
--     El rol solo tiene GRANT UPDATE(stock), precio nunca fue otorgado.
--     Se hace REVOKE explícito sobre el usuario para doble seguridad.
-- ============================================================
REVOKE UPDATE ON E_commerce.productos FROM 'inventory_user'@'localhost';
-- Solo se re-otorga UPDATE en la columna stock
GRANT UPDATE (stock) ON E_commerce.productos TO 'inventory_user'@'localhost';
 
-- ============================================================
-- 15. Política de contraseñas seguras para todos los usuarios
--     Se aplica la política global de validación de contraseñas.
-- ============================================================
SET GLOBAL validate_password.policy         = MEDIUM;
SET GLOBAL validate_password.length         = 10;
SET GLOBAL validate_password.mixed_case_count = 1;
SET GLOBAL validate_password.number_count   = 1;
SET GLOBAL validate_password.special_char_count = 1;
 
-- Forzar expiración inmediata para que cada usuario cambie su contraseña
--  en su primer inicio de sesión:
ALTER USER 'marketing_user'@'localhost'  PASSWORD EXPIRE;
ALTER USER 'inventory_user'@'localhost'  PASSWORD EXPIRE;
ALTER USER 'support_user'@'localhost'    PASSWORD EXPIRE;
ALTER USER 'auditor_user'@'localhost'    PASSWORD EXPIRE;
ALTER USER 'analista_user'@'localhost'   PASSWORD EXPIRE;
 
-- ============================================================
-- 16. Root sin acceso desde conexiones remotas
--     Se eliminan todas las entradas de root que no sean localhost.
-- ============================================================
DELETE FROM mysql.user
    WHERE User = 'root'
      AND Host NOT IN ('localhost', '127.0.0.1', '::1');
 
-- Bloquear también el usuario anónimo si existe
DELETE FROM mysql.user WHERE User = '';
 
FLUSH PRIVILEGES;
 
-- ============================================================
-- 17. Rol Visitante: acceso solo a tabla productos (activos)
--     Se crea un usuario de demostración asignado a este rol.
-- ============================================================
DROP USER IF EXISTS 'visitante_user'@'%';
CREATE USER 'visitante_user'@'%'
    IDENTIFIED BY 'Visitante@2024!'
    PASSWORD EXPIRE INTERVAL 60 DAY
    FAILED_LOGIN_ATTEMPTS 3 PASSWORD_LOCK_TIME 1;
GRANT 'Visitante' TO 'visitante_user'@'%';
SET DEFAULT ROLE 'Visitante' TO 'visitante_user'@'%';
 
-- Confirmar que Visitante NO tiene acceso a clientes, ventas ni logs
REVOKE ALL PRIVILEGES ON E_commerce.* FROM 'visitante_user'@'%';
GRANT SELECT ON E_commerce.v_productos_publicos TO 'visitante_user'@'%';
GRANT SELECT ON E_commerce.categorias           TO 'visitante_user'@'%';
 
-- ============================================================
-- 18. Limitar número de consultas por hora para Analista_Datos
--     Aplicado al usuario analista_user en su CREATE USER arriba.
--     Se actualiza aquí también con ALTER USER por si ya existía.
-- ============================================================
ALTER USER 'analista_user'@'localhost'
    WITH MAX_QUERIES_PER_HOUR    200
         MAX_CONNECTIONS_PER_HOUR 50
         MAX_UPDATES_PER_HOUR     0
         MAX_USER_CONNECTIONS     5;
 
-- ============================================================
-- 19. Restricción por sucursal: cada usuario solo ve su sucursal.
--     Se crean usuarios por sucursal y se les da acceso solo a
--     la vista correspondiente.
-- ============================================================
DROP USER IF EXISTS 'sucursal1_user'@'localhost';
CREATE USER 'sucursal1_user'@'localhost'
    IDENTIFIED BY 'Sucursal1@2024!'
    PASSWORD EXPIRE INTERVAL 90 DAY
    FAILED_LOGIN_ATTEMPTS 5 PASSWORD_LOCK_TIME 1;
GRANT SELECT ON E_commerce.v_ventas_sucursal_1 TO 'sucursal1_user'@'localhost';
GRANT SELECT ON E_commerce.v_productos_publicos TO 'sucursal1_user'@'localhost';
 
DROP USER IF EXISTS 'sucursal2_user'@'localhost';
CREATE USER 'sucursal2_user'@'localhost'
    IDENTIFIED BY 'Sucursal2@2024!'
    PASSWORD EXPIRE INTERVAL 90 DAY
    FAILED_LOGIN_ATTEMPTS 5 PASSWORD_LOCK_TIME 1;
GRANT SELECT ON E_commerce.v_ventas_sucursal_2 TO 'sucursal2_user'@'localhost';
GRANT SELECT ON E_commerce.v_productos_publicos TO 'sucursal2_user'@'localhost';
 
-- ============================================================
-- 20. Auditoría de intentos de inicio de sesión fallidos
--     Se crea una tabla de auditoría de accesos y un evento
--     que revisa y registra los usuarios bloqueados por intentos fallidos.
-- ============================================================
 
-- Tabla donde se registran los bloqueos detectados
CREATE TABLE IF NOT EXISTS log_intentos_fallidos (
    id_log        INT          NOT NULL AUTO_INCREMENT,
    usuario       VARCHAR(100) NOT NULL,
    host          VARCHAR(100) NOT NULL,
    intentos      INT          NOT NULL DEFAULT 0,
    bloqueado     TINYINT(1)   NOT NULL DEFAULT 0,
    fecha_deteccion DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_log)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
 
-- Evento que detecta usuarios bloqueados (cada 15 minutos)
DROP EVENT IF EXISTS evt_detect_failed_logins;
CREATE EVENT evt_detect_failed_logins
ON SCHEDULE EVERY 15 MINUTE
STARTS NOW()
DO
    INSERT INTO E_commerce.log_intentos_fallidos
        (usuario, host, intentos, bloqueado)
    SELECT
        User,
        Host,
        JSON_UNQUOTE(JSON_EXTRACT(User_attributes, '$.failed_login_attempts')),
        CASE
            WHEN JSON_UNQUOTE(JSON_EXTRACT(User_attributes, '$.password_lock_time_days')) > 0
            THEN 1 ELSE 0
        END
    FROM mysql.user
    WHERE User_attributes IS NOT NULL
      AND JSON_UNQUOTE(JSON_EXTRACT(User_attributes, '$.failed_login_attempts')) > 0;
 
-- Activar el scheduler si no está activo (necesario para el evento anterior)
SET GLOBAL event_scheduler = ON;
 
-- Activar log de errores detallado a nivel de servidor para
-- capturar intentos de autenticación fallidos en el log del sistema:
SET GLOBAL log_error_verbosity = 3;
 
FLUSH PRIVILEGES;