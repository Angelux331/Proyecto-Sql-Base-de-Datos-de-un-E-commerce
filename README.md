# 🛒 Proyecto de Base de Datos para un E-commerce

## Descripción

Este proyecto implementa el núcleo de una base de datos relacional para una tienda en línea, desarrollado en **MySQL 8.0+**. El sistema gestiona de forma eficiente y segura el ciclo de vida completo de un e-commerce: catálogo de productos, inventario, clientes, ventas y análisis de negocio. La arquitectura está diseñada para ser robusta, escalable y garantizar la integridad de los datos en todo momento, aplicando buenas prácticas de seguridad, automatización y reporteo avanzado.

---

## 👥 Integrantes del Equipo

| Nombre completo | Rol en el proyecto |
|---|---|
| _(Angelux331)_ | Esquema, datos, consultas, Funciones, procedimiento, Triggers , eventos, Seguridad y permisos|

## ⚙️ Requisitos Previos

- **MySQL Server** 8.0 o superior
- **MySQL Workbench** (recomendado) o cualquier cliente SQL compatible
- Usuario con privilegios `SUPER` o `ALL PRIVILEGES` para crear la base de datos, roles y eventos
- El **Event Scheduler** se activa automáticamente en `06_Eventos.sql` (`SET GLOBAL event_scheduler = ON`)
- El plugin `validate_password` debe estar instalado para aplicar las políticas del archivo `04_Seguridad.sql`

---

## 🚀 Instrucciones de Ejecución

Los archivos **deben ejecutarse en el orden indicado**. Cada script depende de los objetos creados por el anterior.

### Paso 1 — Esquema y datos iniciales
```sql
SOURCE 1.schema.sql and 2.seed.sql ;
```
Crea la base de datos `ecommerce_db`, todas las tablas (principales y auxiliares) e inserta los datos de ejemplo: 10 categorías, 10 proveedores, 20 productos, 15 clientes, 20 ventas y sus detalles.

---

### Paso 2 — Consultas avanzadas
```sql
SOURCE 3.querys.sql;
```
Contiene 20 consultas de análisis de negocio. Pueden ejecutarse individualmente o en bloque para verificar que los datos del paso anterior son correctos. No crea objetos permanentes.

---

### Paso 3 — Funciones
```sql
SOURCE 4.functions.sql;
```
Crea las 20 funciones de usuario (`UDF`). Algunas son usadas internamente por los procedimientos almacenados del paso 7, por lo que deben existir antes de ejecutar ese archivo.

---

### Paso 4 — Seguridad
```sql
SOURCE 5.permissions.sql;
```
Crea las vistas de seguridad, los 7 roles, los usuarios del sistema y aplica todos los permisos y restricciones. **Requiere privilegios de administrador** (`SUPER` o `CREATE USER`, `GRANT OPTION`).

> ⚠️ Las líneas que eliminan el acceso remoto de `root` y borran usuarios anónimos deben ser revisadas por el DBA antes de ejecutar en producción.

---

### Paso 5 — Triggers
```sql
SOURCE 6.triggers.sql;
```
Crea los 20 disparadores que automatizan la integridad de datos: control de0 stock, auditoría de precios, validaciones, logs de estado y contadores de categorías.

---

### Paso 6 — Eventos programados
```sql
SOURCE 7.events.sql;
```
Activa el `event_scheduler` y crea los 20 eventos automáticos: reportes semanales, limpieza de logs, alertas de stock, KPIs mensuales, detección de fraude, entre otros.

---

### Paso 7 — Procedimientos almacenados
```sql
SOURCE 8.Program_Porcessor.sql;
```
Crea los 20 procedimientos que encapsulan operaciones complejas y transaccionales: procesar ventas, devoluciones, registrar clientes, cambiar estados de pedidos, generar reportes y más.

---

## 📋 Resumen de Contenidos

### 🗃️ Tablas principales
| Tabla | Descripción |
|---|---|
| `categorias` | Clasificación de productos |
| `proveedores` | Datos de contacto de proveedores |
| `productos` | Catálogo completo con precios, costo y stock |
| `clientes` | Usuarios registrados con datos de envío |
| `ventas` | Encabezado de cada transacción |
| `detalle_ventas` | Líneas de productos por venta (precio histórico congelado) |

### 🗃️ Tablas auxiliares
`log_cambios_precio`, `log_auditoria_clientes`, `log_estado_pedidos`, `log_intentos_fallidos`, `alertas_stock`, `archivo_ventas`, `reporte_ventas_semanales`, `kpis_mensuales`, `resenas_productos`, `carritos_abandonados`, `ranking_productos`, `log_permisos`

---

### 📊 Consultas avanzadas (02)
| # | Consulta |
|---|---|
| 1 | Top 10 productos más vendidos por ingresos |
| 2 | Productos con bajas ventas (percentil 10%) |
| 3 | Clientes VIP — Top 5 por gasto histórico (LTV) |
| 4 | Análisis de ventas mensuales |
| 5 | Crecimiento de clientes por trimestre |
| 6 | Tasa de compra repetida |
| 7 | Productos comprados juntos frecuentemente |
| 8 | Rotación de inventario por categoría |
| 9 | Productos que necesitan reabastecimiento (stock < 30) |
| 10 | Análisis de carrito abandonado (> 72 h) |
| 11 | Rendimiento de proveedores por volumen de ventas |
| 12 | Análisis geográfico de ventas por ciudad/región |
| 13 | Ventas por hora del día |
| 14 | Impacto de promociones (antes, durante y después) |
| 15 | Análisis de cohort — retención mensual |
| 16 | Margen de beneficio por producto |
| 17 | Tiempo promedio entre compras por cliente |
| 18 | Productos más comprados con ranking |
| 19 | Segmentación RFM de clientes (Recencia, Frecuencia, Monetario) |
| 20 | Predicción de demanda simple (promedio móvil 3 meses) |

---

### 🔧 Funciones (03)
| Función | Descripción |
|---|---|
| `fn_CalcularTotalVenta` | Monto total de una venta |
| `fn_VerificarDisponibilidadStock` | Verifica si hay stock suficiente |
| `fn_ObtenerPrecioProducto` | Precio actual de un producto |
| `fn_CalcularEdadCliente` | Edad del cliente desde su fecha de nacimiento |
| `fn_FormatearNombreCompleto` | Nombre en formato "Apellido, Nombre" |
| `fn_EsClienteNuevo` | TRUE si su primera compra fue en los últimos 30 días |
| `fn_CalcularCostoEnvio` | Costo de envío (1% del total, mín. $8.000) |
| `fn_AplicarDescuento` | Aplica un porcentaje de descuento a un monto |
| `fn_ObtenerUltimaFechaCompra` | Fecha de la última compra del cliente |
| `fn_ValidarFormatoEmail` | Valida formato de correo con expresión regular |
| `fn_ObtenerNombreCategoria` | Nombre de categoría por ID de producto |
| `fn_ContarVentasCliente` | Total de compras de un cliente |
| `fn_CalcularDiasDesdeUltimaCompra` | Días desde la última compra |
| `fn_DeterminarEstadoLealtad` | Nivel Bronce / Plata / Oro según gasto |
| `fn_GenerarSKU` | Genera SKU único por nombre y categoría |
| `fn_CalcularIVA` | IVA (19%) sobre el total de una venta |
| `fn_ObtenerStockTotalPorCategoria` | Stock total activo por categoría |
| `fn_EstimarFechaEntrega` | Fecha estimada según ciudad del cliente |
| `fn_ConvertirMoneda` | Conversión COP → USD / EUR / GBP |
| `fn_ValidarComplejidadContrasena` | Valida longitud, mayúscula, número y carácter especial |

---

### 🔐 Seguridad (04)
| Elemento | Detalle |
|---|---|
| **Roles** | `Administrador_Sistema`, `Gerente_Marketing`, `Analista_Datos`, `Empleado_Inventario`, `Atencion_Cliente`, `Auditor_Financiero`, `Visitante` |
| **Usuarios** | `admin_user`, `marketing_user`, `inventory_user`, `support_user`, `auditor_user`, `analista_user`, `visitante_user`, `sucursal1_user`, `sucursal2_user` |
| **Vistas de seguridad** | `v_info_clientes_basica`, `v_productos_publicos`, `v_ventas_auditoria`, `v_ventas_sucursal_1`, `v_ventas_sucursal_2` |
| **Política de contraseñas** | Mínimo 10 chars, mayúscula, número y carácter especial (`validate_password` MEDIUM) |
| **Auditoría de login** | Tabla `log_intentos_fallidos` + evento cada 15 min |
| **Límites por usuario** | `analista_user`: máx. 200 consultas/hora, 5 conexiones simultáneas |

---

### ⚡ Triggers (05)
| Trigger | Evento |
|---|---|
| `trg_audit_precio_producto_after_update` | Log de cambios de precio |
| `trg_check_stock_before_insert_venta` | Verifica stock antes de venta |
| `trg_update_stock_after_insert_venta` | Decrementa stock tras venta |
| `trg_prevent_delete_categoria_with_products` | Bloquea borrado de categorías con productos activos |
| `trg_log_new_customer_after_insert` | Log de nuevos clientes |
| `trg_update_total_gastado_cliente` | Actualiza gasto total del cliente |
| `trg_set_fecha_modificacion_producto` | Fecha de última modificación automática |
| `trg_prevent_negative_stock` | Bloquea stock negativo |
| `trg_capitalize_nombre_cliente` | Capitaliza nombre y apellido |
| `trg_recalculate_total_venta_on_detalle_change` | Recalcula total de venta al editar detalle |
| `trg_log_order_status_change` | Audita cambios de estado de pedido |
| `trg_prevent_price_zero_or_less` | Bloquea precio ≤ 0 |
| `trg_send_stock_alert_on_low_stock` | Alerta cuando stock < 30 |
| `trg_archive_deleted_venta` | Archiva ventas antes de eliminarlas |
| `trg_validate_email_format_on_customer` | Valida formato de email al insertar cliente |
| `trg_update_last_order_date_customer` | Actualiza fecha último pedido del cliente |
| `trg_prevent_self_referral` | Bloquea autoreferidos |
| `trg_log_permission_changes` | Audita cambios de permisos |
| `trg_assign_default_category_on_null` | Asigna categoría "General" si viene nula |
| `trg_update_producto_count_in_categoria` | Mantiene contador de productos por categoría |

---

### 📅 Eventos (06)
| Evento | Frecuencia |
|---|---|
| `evt_generate_weekly_sales_report` | Semanal (lunes 01:00) |
| `evt_cleanup_temp_tables_daily` | Diario (03:00) |
| `evt_archive_old_logs_monthly` | Mensual (día 1, 02:00) |
| `evt_deactivate_expired_promotions_hourly` | Cada hora |
| `evt_recalculate_customer_loyalty_tiers_nightly` | Diario (02:30) |
| `evt_generate_reorder_list_daily` | Diario (06:00) |
| `evt_rebuild_indexes_weekly` | Semanal (domingo 04:00) |
| `evt_suspend_inactive_accounts_quarterly` | Trimestral |
| `evt_aggregate_daily_sales_data` | Diario (23:55) |
| `evt_check_data_consistency_nightly` | Diario (03:30) |
| `evt_send_birthday_greetings_daily` | Diario (08:00) |
| `evt_update_product_rankings_hourly` | Cada hora |
| `evt_backup_critical_tables_daily` | Diario (01:00) |
| `evt_clear_abandoned_carts_daily` | Diario (04:00) |
| `evt_calculate_monthly_kpis` | Mensual (día 1, 00:30) |
| `evt_refresh_materialized_views_nightly` | Diario (02:00) |
| `evt_log_database_size_weekly` | Semanal |
| `evt_detect_fraudulent_activity_hourly` | Cada hora |
| `evt_generate_supplier_performance_report_monthly` | Mensual |
| `evt_purge_soft_deleted_records_weekly` | Semanal (03:00) |

---

### 📦 Procedimientos almacenados (07)
| Procedimiento | Descripción |
|---|---|
| `sp_RealizarNuevaVenta` | Procesa una venta completa de forma transaccional |
| `sp_AgregarNuevoProducto` | Inserta un producto validando datos y generando SKU |
| `sp_ActualizarDireccionCliente` | Actualiza dirección, ciudad y región del cliente |
| `sp_ProcesarDevolucion` | Cancela venta y restaura stock |
| `sp_ObtenerHistorialComprasCliente` | Historial completo de compras de un cliente |
| `sp_AjustarNivelStock` | Ajuste manual de stock con registro de motivo |
| `sp_EliminarClienteDeFormaSegura` | Anonimiza datos del cliente (GDPR-friendly) |
| `sp_AplicarDescuentoPorCategoria` | Aplica descuento % a todos los productos de una categoría |
| `sp_GenerarReporteMensualVentas` | Reporte completo de ventas por mes/año |
| `sp_CambiarEstadoPedido` | Cambia estado del pedido con validaciones de flujo |
| `sp_RegistrarNuevoCliente` | Registro de cliente con validación de email único |
| `sp_ObtenerDetallesProductoCompleto` | Producto con datos de categoría y proveedor |
| `sp_FusionarCuentasCliente` | Fusiona dos cuentas duplicadas en una |
| `sp_AsignarProductoAProveedor` | Cambia o asigna proveedor a un producto |
| `sp_BuscarProductos` | Búsqueda avanzada con filtros múltiples |
| `sp_ObtenerDashboardAdmin` | KPIs del día para panel de administración |
| `sp_ProcesarPago` | Simula procesamiento de pago (90% aprobación) |
| `sp_AnadirResenaProducto` | Reseña de producto solo si fue comprado y entregado |
| `sp_ObtenerProductosRelacionados` | Productos frecuentemente comprados juntos |
| `sp_MoverProductosEntreCategorias` | Mueve productos entre categorías de forma transaccional |

---

## 🛠️ Notas Técnicas

- **Motor de almacenamiento:** InnoDB en todas las tablas para soporte de transacciones y llaves foráneas.
- **Integridad referencial:** Todas las relaciones entre tablas están protegidas con `FOREIGN KEY` con acciones `ON DELETE` y `ON UPDATE` definidas explícitamente.
- **Precio histórico:** El campo `precio_unitario_congelado` en `detalle_ventas` garantiza que los reportes históricos sean siempre precisos, independientemente de cambios futuros en el precio del producto.
- **Seguridad de contraseñas:** Las contraseñas de clientes se almacenan como hash `SHA2-256`. El plugin `validate_password` aplica política MEDIUM a nivel de servidor.
- **Transacciones:** Los procedimientos críticos (`sp_RealizarNuevaVenta`, `sp_ProcesarDevolucion`, `sp_FusionarCuentasCliente`) usan `START TRANSACTION / COMMIT / ROLLBACK` para garantizar atomicidad.

---

## 📌 Orden de ejecución resumido

```
01 → 02 → 03 → 04 → 05 → 06 → 07
```

> El archivo `2.seed.sql` no crea objetos permanentes y puede ejecutarse en cualquier momento después del paso 01 para verificar los datos.