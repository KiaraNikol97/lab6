-- ==========================================================
-- SCRIPT DE TRABAJO: LABORATORIO HASHY EL GOLOSO (MySQL)
-- TEC - Arquitectura de Datos
-- ==========================================================

-- 1. BITÁCORA DE OPERACIONES (Misión de la Llave 6)
-- Registra el rastro de cada transformación del pipeline.
CREATE TABLE logs_hashy (
    id SERIAL PRIMARY KEY,
    nombre_funcion VARCHAR(255),
    fecha_ejecucion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    mensaje_accion TEXT,
    usuario_db VARCHAR(100) DEFAULT (CURRENT_USER())
);

-- 2. MERCADO NEGRO DE TORTUGA (Misión de la Llave 3)
-- Sirve para realizar las subconsultas de comparación de precios.
CREATE TABLE mercado_negro (
    id SERIAL PRIMARY KEY,
    categoria VARCHAR(100) UNIQUE, 
    precio_referencia DECIMAL(10,2),
    ultima_actualizacion DATE
);

-- 3. INVENTARIO DE GOLOSINAS (La tabla principal)
-- Contiene los datos "sucios" que deben ser procesados por las 7 llaves.
CREATE TABLE inventario_pirata (
    id INT PRIMARY KEY,               -- Usado para la Llave 1 (Primalidad)
    nombre_sucio VARCHAR(255),        -- Usado para la Llave 4 (Sanitización)
    categoria VARCHAR(100),           -- Relación con Mercado Negro
    precio_finca DECIMAL(10,2),       -- Usado para la Llave 3 (Tasación)
    prioridad_logica INT,             -- Metadata adicional
    fecha_ingreso DATE,               -- Usado para la Llave 2 (Reloj de Arena)
    meses_validez INT,                -- Usado para la Llave 2 (Reloj de Arena)
    FOREIGN KEY (categoria) REFERENCES mercado_negro(categoria)
);

-- ==========================================================
-- DATOS SEMILLA
-- ==========================================================

-- Llenado del Mercado Negro
INSERT INTO mercado_negro (categoria, precio_referencia, ultima_actualizacion) VALUES 
('Caramelos', 15.00, '2026-01-01'),
('Chocolates', 45.00, '2026-01-01'),
('Gomitas', 20.00, '2026-01-01');

-- Llenado del Inventario
-- Incluimos la 'Gomita Mágica' (ID 7) para que haya variedad en el resultado.
INSERT INTO inventario_pirata (id, nombre_sucio, categoria, precio_finca, prioridad_logica, fecha_ingreso, meses_validez) VALUES 
(1, '  cArr-Amelo_Menta  ', 'Caramelos', 12.00, 2, '2026-02-15', 6),   -- ID 1: No es primo.
(2, 'CHoco-late...Amargo', 'Chocolates', 55.00, 3, '2025-10-01', 3),     -- ID 2: VENCIDO.
(3, ' gomita-O_O-fresa ', 'Gomitas', 18.00, 4, '2026-03-01', 12),         -- ID 3: PASA (Primo + Fresco).
(4, '---TRUFA_Oscura---', 'Chocolates', 40.00, 5, '2026-01-10', 5),       -- ID 4: No es primo.
(5, 'Caramelo_Salado!!', 'Caramelos', 18.00, 7, '2025-12-01', 2),         -- ID 5: VENCIDO.
(6, 'Gomita_Osa', 'Gomitas', 25.00, 11, '2026-04-10', 8),                  -- ID 6: No es primo.
(7, '  !!Gomita_Mágica??  ', 'Gomitas', 22.00, 13, '2026-04-01', 10);     -- ID 7: PASA (Primo + Fresco).

-- ==========================================================
-- RESULTADO FINAL ESPERADO (VERIFICACIÓN)
-- ==========================================================
-- Los únicos IDs que deben generar un Hash al final son el 3 y el 7.
-- La consulta final debe devolver: hash(ID 3) # hash(ID 7)









-- ==========================================================
-- LLAVES 5, 6 Y 7 - INTEGRANTE C
-- ==========================================================

-- LLAVE 5: fn_escultor
CREATE FUNCTION fn_escultor(p_nombre TEXT, p_factor DECIMAL(3,2))
RETURNS TEXT
DETERMINISTIC
BEGIN
    DECLARE v_texto_transformado TEXT;
    DECLARE v_sufijo TEXT;

    IF p_factor > 1.0 THEN
        SET v_texto_transformado = UPPER(p_nombre);
        SET v_sufijo = '_PREMIUM';
    ELSE
        SET v_texto_transformado = LOWER(p_nombre);
        SET v_sufijo = '_regular';
    END IF;

    RETURN CONCAT(v_texto_transformado, v_sufijo);
END;

-- LLAVE 6: fn_notario
CREATE FUNCTION fn_notario(p_texto TEXT)
RETURNS TEXT
DETERMINISTIC
MODIFIES SQL DATA
BEGIN
    DECLARE v_usuario VARCHAR(100);
    DECLARE v_timestamp DATETIME;
    DECLARE v_mensaje TEXT;

    SET v_usuario   = CURRENT_USER();
    SET v_timestamp = NOW();
    SET v_mensaje   = CONCAT(
        'PUNTO DE CONTROL - Llave 6 | ',
        'Texto en pipeline: [', p_texto, '] | ',
        'Longitud: ', CHAR_LENGTH(p_texto), ' caracteres | ',
        'Estado: Procesado por Llaves 3, 4 y 5'
    );

    INSERT INTO logs_hashy (nombre_funcion, fecha_ejecucion, mensaje_accion, usuario_db)
    VALUES ('fn_notario', v_timestamp, v_mensaje, v_usuario);

    RETURN p_texto;
END;

-- LLAVE 7: fn_gran_sello
CREATE FUNCTION fn_gran_sello(p_texto TEXT)
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
    DECLARE v_hash_crudo VARCHAR(64);
    DECLARE v_sello_final VARCHAR(255);

    SET v_hash_crudo  = SHA2(p_texto, 256);
    SET v_sello_final = LPAD(v_hash_crudo, 64, '0');

    RETURN v_sello_final;
END;