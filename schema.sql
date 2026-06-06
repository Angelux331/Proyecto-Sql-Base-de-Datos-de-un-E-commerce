DROP DATABASE IF EXISTS E-commerce

CREATE DATABASE E-commerce

USE DATABASE E-commerce


-- Creación de tablas para la base de datos de E-commerce

-- Tabla de Categorías
CREATE TABLE IF NOT EXISTS Categorias (
  id_categoria INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
  nombre VARCHAR(255) NOT NULL,
  descripcion TEXT
),

-- Tabla de Proveedores
CREATE TABLE IF NOT EXISTS Proveedores (
  id_proveedor INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
  nombre VARCHAR(255) NOT NULL,
  email VARCHAR(150) UNIQUE KEY NOT NULL,
  telefono VARCHAR(20) UNIQUE KEY NOT NULL,
)

-- Tabla de Productos
CREATE TABLE IF NOT EXISTS Productos (
  id_producto INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
  nombre VARCHAR(255) UNIQUE KEY NOT NULL , 
  descripcion TEXT,
  precio DECIMAL(10, 2) NOT NULL,
  stock INT NOT NULL DEFAULT 0,
  sku VARCHAR(100) UNIQUE KEY NOT NULL,
  fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  activo BOOLEAN DEFAULT TRUE,
  id_categoria INT,
  id_proveedor INT,

  CONSTRAINT chk_precio_positivo CHECK (precio > 0),
  CONSTRAINT chk_stock_no_negativo CHECK (stock >= 0),

  FOREIGN KEY (id_categoria) REFERENCES Categorias(id_categoria),
  FOREIGN KEY (id_proveedor) REFERENCES Proveedores(id_proveedor)
),

-- Tabla de Clientes
CREATE TABLE IF NOT EXISTS Clientes (
  id_cliente INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
  nombre VARCHAR(255) NOT NULL,
  apellido VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE KEY NOT NULL,
  contrasena VARCHAR(255) NOT NULL,
  direccion_envio VARCHAR(255),
  fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  fecha_nacimiento DATE,
  ciudad VARCHAR(100),
  region VARCHAR(100),
  codigo_postal VARCHAR(20),
  total_gastado DECIMAL(10, 2) DEFAULT 0.00
  fecha_ultimo_pedido DATETIME,
)

-- Tabla de Ventas
CREATE TABLE IF NOT EXISTS Ventas (
  id_venta INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
  id_cliente INT NOT NULL,
  fecha_venta TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  total DECIMAL(10, 2) NOT NULL,
  estado ENUM('Pendiente de Pago', 'Procesando', 'Enviado', 'Entregado', 'Cancelado') NOT NULL DEFAULT 'Pendiente de Pago',
  total DECIMAL(10, 2) NOT NULL DEFAULT 0.00,

  FOREIGN KEY (id_cliente) REFERENCES Clientes(id_cliente)
)

-- Tabla de Detalle de Ventas
CREATE TABLE IF NOT EXISTS Detalle de Ventas (
  id_detalle INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
  id_venta INT NOT NULL,
  id_producto INT NOT NULL,
  cantidad INT NOT NULL,
  precio_unitario_congelado DECIMAL(10, 2) NOT NULL,

  CONSTRAINT chk_cantidad_positiva CHECK (cantidad > 0),

  FOREIGN KEY (id_venta) REFERENCES Ventas(id_venta) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (id_producto) REFERENCES Productos(id_producto) ON DELETE RESTRICT ON UPDATE CASCADE
)

--tablas auxiliarias (triggers y eventos)

-- Log de cambios de precio
CREATE TABLE IF NOT EXISTS log_cambios_precio (
  id_log INT PRIMARY KEY AUTO_INCREMENT NOT NULL
  id_producto INT NOT NULL,
  precio_anterior DECIMAL(10,2) NOT NULL,
  precio_nuevo DECIMAL(10,2) NOT NULL,
  usuario VARCHAR(100) DEFAULT CURRENT_USER(),
  fecha_cambio DATATIME NOT NULL DEFAULT CURRENT_TIMESTAMP
)

