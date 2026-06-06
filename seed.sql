USE DATABASE E-commerce

-- ===============
-- DATOS DE PRUEBA
-- ===============

-- Categorías
INSERT INTO categorias (nombre, descripcion) VALUES
('Electrónica',   'Dispositivos electrónicos, gadgets y accesorios tecnológicos'),
('Ropa',          'Prendas de vestir para hombre, mujer y niños'),
('Hogar',         'Artículos para el hogar, decoración y menaje'),
('Deportes',      'Equipamiento y ropa deportiva'),
('Libros',        'Libros, revistas y material educativo'),
('Juguetes',      'Juguetes y juegos para todas las edades'),
('Alimentos',     'Alimentos no perecederos y suplementos'),
('Belleza',       'Cosméticos, cuidado personal y perfumería'),
('Automotriz',    'Accesorios y repuestos para vehículos'),
('General',       'Categoría general para productos sin clasificar');
 
-- Proveedores
INSERT INTO proveedores (nombre, email, telefono) VALUES
('TechWorld S.A.',          'ventas@techworld.com',      '+57 1 234 5678'),
('Moda Global Ltda.',       'pedidos@modaglobal.co',     '+57 4 321 8765'),
('Casa y Vida Corp.',       'info@casayvida.com',        '+57 2 111 2233'),
('SportPro Distribuciones', 'stock@sportpro.net',        '+57 5 444 5566'),
('Editorial Saber',         'libros@editorialsaber.com', '+57 1 777 8899'),
('Juguetería Feliz',        'pedidos@jugueteriafeliz.co','+57 3 555 6677'),
('NutriDistrib Ltda.',      'comercial@nutridistrib.com','+57 6 999 0011'),
('Belleza Total S.A.S.',    'ventas@bellezatotal.co',    '+57 1 888 7766'),
('AutoPartes Colombia',     'partes@autopartes.co',      '+57 7 333 4455'),
('Distribuidora General',   'info@distgeneral.com',      '+57 8 222 3344');
 
-- Productos
INSERT INTO productos (nombre, descripcion, precio, costo, stock, sku, id_categoria, id_proveedor) VALUES
('Smartphone Galaxy S23',   'Teléfono inteligente 256GB RAM 8GB',    2500000, 1800000,  50, 'ELEC-SGS23-001', 1, 1),
('Laptop ProBook 15',       'Laptop Intel i7 16GB RAM 512GB SSD',    4800000, 3500000,  25, 'ELEC-LPB15-002', 1, 1),
('Auriculares Bluetooth X1','Auriculares inalámbricos con ANC',        350000,  210000, 100, 'ELEC-ABX1-003',  1, 1),
('Camiseta Polo Clásica',   'Camiseta polo 100% algodón talla M',      85000,   42000, 200, 'ROPA-CPC-004',   2, 2),
('Jeans Slim Fit Azul',     'Pantalón jeans corte slim talla 32',     160000,   85000, 150, 'ROPA-JSF-005',   2, 2),
('Chaqueta Impermeable',    'Chaqueta con capucha resistente al agua', 320000,  190000,  80, 'ROPA-CHI-006',   2, 2),
('Juego de Ollas Antiadh.', 'Set 5 ollas antiadherentes acero inox',  480000,  280000,  60, 'HOGAR-JOA-007',  3, 3),
('Aspiradora Turbo 2000',   'Aspiradora 2000W sin bolsa',             650000,  400000,  40, 'HOGAR-AT2-008',  3, 3),
('Silla Ergonómica Pro',    'Silla de oficina con soporte lumbar',    890000,  550000,  30, 'HOGAR-SEP-009',  3, 3),
('Bicicleta MTB 29"',       'Bicicleta de montaña 21 velocidades',  1800000, 1200000,  20, 'DEP-MTB29-010',  4, 4),
('Balón Fútbol Pro',        'Balón FIFA Quality Pro talla 5',          95000,   55000, 300, 'DEP-BFP-011',    4, 4),
('Pesas Mancuernas 10kg',   'Par de mancuernas de hierro fundido',    180000,  100000,  90, 'DEP-PM10-012',   4, 4),
('El Quijote Ed. Ilustrada','Edición ilustrada de lujo pasta dura',   120000,   65000, 120, 'LIB-QUI-013',    5, 5),
('Python para Todos',       'Libro de programación Python nivel básico',55000,   28000, 200, 'LIB-PYT-014',   5, 5),
('Enciclopedia Universal',  'Enciclopedia 10 tomos edición 2023',     750000,  450000,  15, 'LIB-ENC-015',    5, 5),
('LEGO Creator 3en1',       'Set LEGO 500 piezas para mayores de 8',  380000,  220000,  70, 'JUG-LEG-016',    6, 6),
('Muñeca Interactiva',      'Muñeca con movimiento y sonido',          190000,  105000, 110, 'JUG-MUI-017',   6, 6),
('Proteína Whey 2kg',       'Suplemento proteico sabor vainilla',      280000,  160000, 150, 'ALI-PW2-018',   7, 7),
('Crema Hidratante Premium','Crema facial con vitamina C 50ml',         95000,   48000, 250, 'BEL-CHP-019',   8, 8),
('Aceite para Motor 5W-30', 'Aceite sintético para motor 4L',          120000,   72000, 200, 'AUTO-AM5-020',  9, 9);
 
-- Clientes
INSERT INTO clientes (nombre, apellido, email, contrasena, direccion_envio, fecha_nacimiento, ciudad, region) VALUES
('Carlos',    'Rodríguez',  'carlos.rodriguez@email.com',  SHA2('Pass@1234', 256), 'Cra 15 #45-23 Bogotá',       '1988-03-12', 'Bogotá',    'Cundinamarca'),
('María',     'González',   'maria.gonzalez@email.com',    SHA2('Secure#99', 256), 'Cl 80 #12-34 Medellín',       '1992-07-25', 'Medellín',  'Antioquia'),
('Jorge',     'Martínez',   'jorge.martinez@email.com',    SHA2('JorgePwd!2', 256),'Av 4N #38-20 Cali',           '1985-11-30', 'Cali',      'Valle del Cauca'),
('Ana',       'López',      'ana.lopez@email.com',         SHA2('AnaL0pez#', 256), 'Cl 70 #50-10 Barranquilla',   '1995-01-08', 'Barranquilla','Atlántico'),
('Pedro',     'Sánchez',    'pedro.sanchez@email.com',     SHA2('PedroS@22', 256), 'Cra 43 #15-67 Bucaramanga',   '1990-09-18', 'Bucaramanga','Santander'),
('Laura',     'Ramírez',    'laura.ramirez@email.com',     SHA2('LauraR!23', 256), 'Cl 5 #20-30 Cartagena',       '1998-04-22', 'Cartagena', 'Bolívar'),
('Andrés',    'Torres',     'andres.torres@email.com',     SHA2('Andres#77', 256), 'Cra 9 #80-15 Pereira',        '1987-12-05', 'Pereira',   'Risaralda'),
('Sofía',     'Vargas',     'sofia.vargas@email.com',      SHA2('SofiaV@88', 256), 'Av 15 #10-25 Manizales',      '1993-06-14', 'Manizales', 'Caldas'),
('Diego',     'Herrera',    'diego.herrera@email.com',     SHA2('DiegoH!90', 256), 'Cl 100 #30-40 Pasto',         '1991-02-28', 'Pasto',     'Nariño'),
('Valentina', 'Jiménez',    'valentina.jimenez@email.com', SHA2('ValJim#11', 256), 'Cra 20 #60-80 Ibagué',        '1996-08-17', 'Ibagué',    'Tolima'),
('Felipe',    'Morales',    'felipe.morales@email.com',    SHA2('FelipeM!5', 256), 'Cl 50 #8-90 Bogotá',          '1984-10-03', 'Bogotá',    'Cundinamarca'),
('Camila',    'Cruz',       'camila.cruz@email.com',       SHA2('CamilaC#3', 256), 'Av 68 #25-50 Bogotá',         '1999-05-11', 'Bogotá',    'Cundinamarca'),
('Sebastián', 'Ramos',      'sebastian.ramos@email.com',   SHA2('SebRam@9', 256),  'Cl 30 #45-12 Medellín',       '1989-07-07', 'Medellín',  'Antioquia'),
('Isabella',  'Flores',     'isabella.flores@email.com',   SHA2('IsaFlo!6', 256),  'Cra 5 #18-30 Cali',           '1994-03-29', 'Cali',      'Valle del Cauca'),
('Mateo',     'Díaz',       'mateo.diaz@email.com',        SHA2('MateD@44', 256),  'Cl 12 #34-56 Bucaramanga',    '1997-11-16', 'Bucaramanga','Santander');
 
-- Ventas
INSERT INTO ventas (id_cliente, estado, fecha_venta) VALUES
(1, 'Entregado',        '2024-01-15 10:30:00'),
(2, 'Entregado',        '2024-01-20 14:00:00'),
(3, 'Enviado',          '2024-02-05 09:15:00'),
(1, 'Entregado',        '2024-02-18 16:45:00'),
(4, 'Entregado',        '2024-03-01 11:00:00'),
(5, 'Procesando',       '2024-03-10 08:30:00'),
(2, 'Entregado',        '2024-03-22 13:20:00'),
(6, 'Entregado',        '2024-04-05 17:00:00'),
(7, 'Enviado',          '2024-04-15 10:10:00'),
(8, 'Entregado',        '2024-05-02 12:00:00'),
(9, 'Entregado',        '2024-05-18 15:30:00'),
(10,'Pendiente de Pago','2024-06-01 09:00:00'),
(11,'Entregado',        '2024-06-12 11:45:00'),
(12,'Entregado',        '2024-07-03 14:30:00'),
(13,'Cancelado',        '2024-07-20 16:00:00'),
(1, 'Entregado',        '2024-08-08 10:00:00'),
(14,'Entregado',        '2024-08-25 09:30:00'),
(15,'Procesando',       '2024-09-10 13:00:00'),
(3, 'Entregado',        '2024-09-28 15:15:00'),
(2, 'Entregado',        '2024-10-15 11:00:00');
 
-- Detalle de ventas
INSERT INTO detalle_ventas (id_venta, id_producto, cantidad, precio_unitario_congelado) VALUES
(1,  1,  1, 2500000), (1,  3,  2,  350000),
(2,  4,  3,   85000), (2,  5,  2,  160000),
(3,  10, 1, 1800000), (3,  11, 2,   95000),
(4,  2,  1, 4800000),
(5,  7,  1,  480000), (5,  8,  1,  650000),
(6,  12, 2,  180000), (6,  11, 3,   95000),
(7,  6,  2,  320000), (7,  4,  1,   85000),
(8,  19, 3,   95000), (8,  18, 1,  280000),
(9,  9,  1,  890000),
(10, 13, 2,  120000), (10, 14, 3,   55000),
(11, 20, 4,  120000),
(12, 16, 2,  380000), (12, 17, 1,  190000),
(13, 1,  1, 2500000),
(14, 3,  1,  350000), (14, 19, 2,   95000),
(15, 5,  2,  160000),
(16, 1,  1, 2500000), (16, 18, 2,  280000),
(17, 15, 1,  750000),
(18, 10, 1, 1800000), (18, 12, 1,  180000),
(19, 2,  1, 4800000), (19, 3,  1,  350000),
(20, 7,  2,  480000), (20, 8,  1,  650000);
 