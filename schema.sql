CREATE DATABASE lab6;
USE lab6;

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


SELECT * FROM mercado_negro;
SELECT * FROM inventario_pirata;
SELECT * FROM logs_hashy;

-- ==========================================================

-- ==========================================================
-- CREACIÓN DE FUNCIONES
-- ==========================================================



-- ----------------------------------
-- LLAVE 1: fn_cernidor 
-- ----------------------------------


CREATE FUNCTION fn_cernidor(p_id INT)
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE v_es_primo BOOLEAN DEFAULT TRUE;
    DECLARE v_divisor INT DEFAULT 2;

    IF p_id IS NULL THEN RETURN FALSE; END IF;
    IF p_id < 2 THEN RETURN FALSE; END IF;

    WHILE v_divisor <= FLOOR(SQRT(p_id)) DO
        IF p_id % v_divisor = 0 THEN
            SET v_es_primo = FALSE;
        END IF;
        SET v_divisor = v_divisor + 1;
    END WHILE;

    RETURN v_es_primo;
END

DELIMITER ;

-- PRUEBA UNITARIA (evidencia de ejecución)
-- SELECT id, fn_cernidor(id) AS es_primo
-- FROM inventario_pirata;

-- ----------------------------------
-- LLAVE 2: fn_reloj_arena
-- ----------------------------------

CREATE FUNCTION fn_reloj_arena(p_fecha DATE, p_meses INT)
RETURNS VARCHAR(10)
DETERMINISTIC
BEGIN
    DECLARE v_fecha_actual    DATE;
    DECLARE v_fecha_vencimiento DATE;

    IF p_fecha IS NULL OR p_meses IS NULL THEN
        RETURN 'Expirado';
    END IF;

    SET v_fecha_actual = CURDATE();

    SET v_fecha_vencimiento = DATE_ADD(p_fecha, INTERVAL p_meses MONTH);

    IF v_fecha_vencimiento > v_fecha_actual THEN
        RETURN 'Fresco';
    ELSE
        RETURN 'Expirado';
    END IF;

END


-- PRUEBA UNITARIA (evidencia de ejecución)
/* SELECT
    id,
    fecha_ingreso,
    meses_validez,
    fn_reloj_arena(fecha_ingreso, meses_validez) AS estado
FROM inventario_pirata; */



-- ----------------------------------
-- LLAVE 3: El Espía de Tortuga (Tasación de Precios)
-- Requisitos: Bloque BEGIN/END, 2 variables locales, manejo de nulos.

USE lab6;


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
END

-- LLAVE 4: El Purificador (Sanitización de Nombres)
-- Requisitos: Bloque BEGIN/END, 2 variables locales, uso de REGEXP.
USE lab6;

DROP FUNCTION IF EXISTS fn_purificador$$

CREATE FUNCTION fn_purificador(p_nombre_sucio VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
    DECLARE v_nombre_limpio VARCHAR(255);
    DECLARE v_resultado_final VARCHAR(255);

    SET v_nombre_limpio = REGEXP_REPLACE(p_nombre_sucio, '[^a-zA-ZáéíóúÁÉÍÓÚñÑ]', '');
    SET v_resultado_final = TRIM(v_nombre_limpio);

    RETURN v_resultado_final;
END



-- ===============================================
-- Llave 05 fn_escultor
-- ===============================================

USE lab6;

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



-- PRUEBA
SELECT fn_escultor('gomitafresa', 0.8);
SELECT fn_escultor('GomitaMagica', 1.2);


-- ===============================================
-- Llave 06 fn_notario
-- ===============================================

-- 2. Activar permisos
SET GLOBAL log_bin_trust_function_creators = 1;


DELIMITER $$

CREATE FUNCTION fn_notario(p_texto TEXT)
RETURNS TEXT
NOT DETERMINISTIC
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
END

DELIMITER ;

-- Prueba
SELECT fn_notario('gomitafresa_regular');
SELECT * FROM logs_hashy;
-- ===============================================
-- Llave 07 fn_gran_sello
-- ===============================================
USE lab6;

DROP FUNCTION IF EXISTS fn_gran_sello;

CREATE FUNCTION fn_gran_sello(p_texto TEXT)
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
    DECLARE v_hash VARCHAR(255);
    SET v_hash = SHA2(p_texto, 256);
    RETURN LPAD(v_hash, 64, '0');
END

DELIMITER ;

-- Prueba rápida
SELECT fn_gran_sello('gomitafresa_regular');

-- ==========================================
-- Consulta maestra final
-- =========================================

SELECT
    GROUP_CONCAT(
        fn_gran_sello(
            fn_notario(
                fn_escultor(
                    fn_purificador(nombre_sucio),
                    fn_espia_tortuga(categoria, precio_finca)
                )
            )
        )
        ORDER BY id ASC
        SEPARATOR ' # '
    ) AS resultado_final_del_trio
FROM inventario_pirata
WHERE
    fn_cernidor(id) = TRUE
    AND
    fn_reloj_arena(fecha_ingreso, meses_validez) = 'Fresco';



SELECT * FROM logs_hashy;
