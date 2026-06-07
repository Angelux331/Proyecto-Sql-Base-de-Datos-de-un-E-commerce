DROP DATABASE IF EXISTS E_commerce;

CREATE DATABASE E_commerce;

USE E_commerce;

-- ======================================================
-- Creación de tablas para la base de datos de E-commerce
-- ======================================================

-- Tabla de Categorías
CREATE TABLE IF NOT EXISTS Categorias (
  id_categoria INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
  nombre VARCHAR(255) NOT NULL,
  descripcion TEXT
);

-- Tabla de Proveedores
CREATE TABLE IF NOT EXISTS Proveedores (
  id_proveedor INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
  nombre VARCHAR(255) NOT NULL,
  email VARCHAR(150) UNIQUE KEY NOT NULL,
  telefono VARCHAR(20) UNIQUE KEY NOT NULL
);

-- Tabla de Productos
CREATE TABLE IF NOT EXISTS Productos (
  id_producto INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
  nombre VARCHAR(255) UNIQUE KEY NOT NULL , 
  descripcion TEXT,
  precio DECIMAL(12, 2) NOT NULL,
  costo DECIMAL(12,2) NOT NULL,
  stock INT NOT NULL DEFAULT 0,
  sku VARCHAR(100) UNIQUE KEY NOT NULL,
  fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  activo BOOLEAN DEFAULT TRUE,
  fecha_modificacion DATETIME DEFAULT CURRENT_TIMESTAMP(),
  id_categoria INT,
  id_proveedor INT,

  CONSTRAINT chk_precio_positivo CHECK (precio > 0),
  CONSTRAINT chk_stock_no_negativo CHECK (stock >= 0),

  FOREIGN KEY (id_categoria) REFERENCES Categorias(id_categoria),
  FOREIGN KEY (id_proveedor) REFERENCES Proveedores(id_proveedor)
);

-- Tabla de Clientes
CREATE TABLE IF NOT EXISTS Clientes (
  id_cliente INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
  nombre VARCHAR(255) NOT NULL,
  apellido VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE KEY NOT NULL,
  contrasena VARCHAR(255) NOT NULL,
  direccion_envio VARCHAR(255),
  fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  fecha_nacimiento DATE,
  ciudad VARCHAR(100),
  region VARCHAR(100),
  codigo_postal VARCHAR(20),
  total_gastado DECIMAL(10, 2) DEFAULT 0.00,
  fecha_ultimo_pedido DATETIME
);

-- Tabla de Ventas
CREATE TABLE IF NOT EXISTS Ventas (
  id_venta INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
  id_cliente INT NOT NULL,
  fecha_venta TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  id_sucursal INT,
  estado ENUM('Pendiente de Pago', 'Procesando', 'Enviado', 'Entregado', 'Cancelado') NOT NULL DEFAULT 'Pendiente de Pago',
  total DECIMAL(10, 2) NOT NULL DEFAULT 0.00,

  FOREIGN KEY (id_cliente) REFERENCES Clientes(id_cliente)
);

-- Tabla de Detalle de Ventas
CREATE TABLE IF NOT EXISTS Detalle_de_Ventas (
  id_detalle INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
  id_venta INT NOT NULL,
  id_producto INT NOT NULL,
  cantidad INT NOT NULL,
  precio_unitario_congelado DECIMAL(10, 2) NOT NULL,

  CONSTRAINT chk_cantidad_positiva CHECK (cantidad > 0),

  FOREIGN KEY (id_venta) REFERENCES Ventas(id_venta) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (id_producto) REFERENCES Productos(id_producto) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- tablas auxiliarias (triggers y eventos)

-- Log de cambios de precio
CREATE TABLE IF NOT EXISTS log_cambios_precio (
  id_log INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
  id_producto INT NOT NULL,
  precio_anterior DECIMAL(10,2) NOT NULL,
  precio_nuevo DECIMAL(10,2) NOT NULL,
  usuario VARCHAR(100) DEFAULT (CURRENT_USER()),
  fecha_cambio DATeTIME NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

-- Log de auditoría general de clientes
CREATE TABLE IF NOT EXISTS log_auditoria_clientes (
  id_log INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
  id_cliente INT,
  accion VARCHAR(50) NOT NULL,
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  detalle TEXT
);

-- Log de cambios de estado de pedidos
CREATE TABLE IF NOT EXISTS log_estado_pedidos (
  id_log INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
  id_venta INT NOT NULL,
  estado_anterior VARCHAR(30),
  estado_nuevo VARCHAR(30),
  fecha_cambio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

-- Tabla de alertas de stock
CREATE TABLE IF NOT EXISTS alertas_stock (
  id_alerta INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
  id_producto INT NOT NULL,
  stock_actual INT NOT NULL,
  fecha_alerta DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  resuelta BOOLEAN DEFAULT FALSE
);

-- Tabla archivo de ventas eliminadas
CREATE TABLE IF NOT EXISTS archivo_ventas (
  id_ventas INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
  id_cliente INT,
  fecha_venta DATETIME,
  estado VARCHAR(20),
  total DECIMAL(12,2),
  fecha_archivo DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

-- Tabla de reporte de ventas semanales (eventos)
CREATE TABLE IF NOT EXISTS reporte_ventas_semanales (
  id_reporte INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
  semana_inicio DATE NOT NULL,
  semana_fin DATE NOT NULL,
  total_ventas DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  num_ordenes INT NOT NULL DEFAULT 0,
  generado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

-- Tabla de KPIs mensuales
CREATE TABLE IF NOT EXISTS kpis_mensuales (
  id_kpi INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
  anio INT NOT NULL UNIQUE KEY,
  mes INT NOT NULL UNIQUE KEY,
  total_ventas DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  num_ordenes INT NOT NULL DEFAULT 0,
  nuevos_clientes INT NOT NULL DEFAULT 0,
  calculado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

-- Tabla de reseñas de productos
CREATE TABLE IF NOT EXISTS resenas_productos (
  id_resena INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
  id_producto INT NOT NULL,
  id_cliente INT NOT NULL,
  clasificacion TINYINT NOT NULL,
  comentario TEXT,
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT chk_clasificacion CHECK (clasificacion BETWEEN 1 AND 5),

  FOREIGN KEY (id_producto) REFERENCES productos(id_producto),
  FOREIGN KEY (id_cliente)  REFERENCES clientes(id_cliente)
);

-- Tabla de carritos abandonados
CREATE TABLE IF NOT EXISTS carritos_abandonados (
  id_carrito INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
  id_cliente INT NOT NULL,
  id_producto INT NOT NULL,
  cantidad INT NOT NULL DEFAULT 1,
  fecha_agrego DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (id_cliente)  REFERENCES clientes(id_cliente),
  FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

-- Tabla de ranking de productos (que se actualiza por los eventos)
CREATE TABLE IF NOT EXISTS ranking_productos (
  id_producto INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
  nombre VARCHAR(100),
  total_vendido INT NOT NULL DEFAULT 0,
  ingresos DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  actualiza_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de log de permisos
CREATE TABLE IF NOT EXISTS log_permisos (
  id_log INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
  usuario VARCHAR(100) NOT NULL,
  accion VARCHAR(100),
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
)

