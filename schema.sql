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



-- * . °•★|•°∵ ∵°•|☆•° . ** . °•★|•°∵ ∵°•|☆•° . *
-- IMPLEMENTACIÓN DE LLAVES: INTEGRANTE B (Ana Carolina)
-- * . °•★|•°∵ ∵°•|☆•° . ** . °•★|•°∵ ∵°•|☆•° . *

DELIMITER //

-- LLAVE 3: El Espía de Tortuga (Tasación de Precios)
-- Requisitos: Bloque BEGIN/END, 2 variables locales, manejo de nulos.
CREATE FUNCTION fn_espia_tortuga(p_categoria VARCHAR(100), p_precio_finca DECIMAL(10,2)) 
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE v_promedio_mercado DECIMAL(10,2);
    DECLARE v_factor_ajuste DECIMAL(10,2);

    
    SELECT precio_referencia INTO v_promedio_mercado 
    FROM mercado_negro 
    WHERE categoria = p_categoria;

    -- manejar nulls
    IF v_promedio_mercado IS NULL THEN
        SET v_factor_ajuste = 1.0; -- Si no hay referencia, no se altera el precio
    ELSEIF p_precio_finca > v_promedio_mercado THEN
        SET v_factor_ajuste = 1.2; -- 20% de recargo si es más caro que el mercado
    ELSE
        SET v_factor_ajuste = 0.8; -- 20% de descuento si es más barato
    END IF;

    RETURN v_factor_ajuste;
END //

-- LLAVE 4: El Purificador (Sanitización de Nombres)
-- Requisitos: Bloque BEGIN/END, 2 variables locales, uso de REGEXP.
CREATE FUNCTION fn_purificador(p_nombre_sucio VARCHAR(255)) 
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
    DECLARE v_nombre_limpio VARCHAR(255);
    DECLARE v_resultado_final VARCHAR(255);

    -- Eliminar cualquier carácter que no sea una letra (tildes y ñ)
    SET v_nombre_limpio = REGEXP_REPLACE(p_nombre_sucio, '[^a-zA-ZáéíóúÁÉÍÓÚñÑ]', '');

    -- espacios en blanco accidentales
    SET v_resultado_final = TRIM(v_nombre_limpio);

    RETURN v_resultado_final;
END //

DELIMITER ;