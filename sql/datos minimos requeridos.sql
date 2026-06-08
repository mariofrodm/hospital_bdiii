--ingreso de datos
--especalidades y servicios

INSERT INTO especialidad (nombre, descripcion)
VALUES
('Pediatría', 'Atención médica para niños y adolescentes'),
('Dermatología', 'Diagnóstico y tratamiento de enfermedades de la piel'),
('Traumatología', 'Atención de lesiones óseas, musculares y articulares')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO servicio (nombre, descripcion, precio)
VALUES
('Consulta pediátrica', 'Consulta médica especializada para pacientes pediátricos', 200.00),
('Consulta dermatológica', 'Evaluación dermatológica general', 225.00),
('Consulta traumatológica', 'Consulta especializada en lesiones musculoesqueléticas', 275.00),
('Electrocardiograma', 'Examen básico para evaluación cardiaca', 180.00),
('Curación menor', 'Procedimiento de limpieza y curación de heridas menores', 100.00),
('Control médico', 'Consulta de seguimiento o control posterior', 125.00),
('Examen de laboratorio básico', 'Paquete básico de laboratorio clínico', 175.00),
('Procedimiento menor', 'Procedimiento ambulatorio menor realizado en clínica', 300.00)
ON CONFLICT (nombre) DO NOTHING;

--consulta
SELECT 'especialidad' AS tabla, COUNT(*) AS total FROM especialidad
UNION ALL
SELECT 'servicio', COUNT(*) FROM servicio
UNION ALL
SELECT 'rol', COUNT(*) FROM rol
ORDER BY tabla;


--Agregar medicos
INSERT INTO medico (
    id_especialidad,
    nombres,
    apellidos,
    numero_colegiado,
    telefono,
    correo
)
VALUES
(1, 'María Fernanda', 'Gómez Ruiz', 'COL-002', '5555-3002', 'maria.gomez@clinica.com'),
(2, 'Luis Alberto', 'Ramírez Soto', 'COL-003', '5555-3003', 'luis.ramirez@clinica.com'),
(2, 'Andrea Paola', 'Morales Castillo', 'COL-004', '5555-3004', 'andrea.morales@clinica.com'),
(3, 'José Miguel', 'Herrera López', 'COL-005', '5555-3005', 'jose.herrera@clinica.com'),
(3, 'Claudia Isabel', 'Fuentes Pérez', 'COL-006', '5555-3006', 'claudia.fuentes@clinica.com'),
(4, 'Roberto Carlos', 'Vásquez Molina', 'COL-007', '5555-3007', 'roberto.vasquez@clinica.com'),
(4, 'Gabriela Sofía', 'Pineda Torres', 'COL-008', '5555-3008', 'gabriela.pineda@clinica.com'),
(5, 'Fernando José', 'Aguilar Méndez', 'COL-009', '5555-3009', 'fernando.aguilar@clinica.com'),
(5, 'Valeria Alejandra', 'Cruz Navarro', 'COL-010', '5555-3010', 'valeria.cruz@clinica.com')
ON CONFLICT (numero_colegiado) DO NOTHING;

--Horarios medicos
INSERT INTO horario_medico (
    id_medico,
    dia_semana,
    hora_inicio,
    hora_fin
)
SELECT
    id_medico,
    dia_semana,
    hora_inicio,
    hora_fin
FROM (
    VALUES
    ('lunes', '08:00'::TIME, '12:00'::TIME),
    ('martes', '08:00'::TIME, '12:00'::TIME),
    ('miercoles', '08:00'::TIME, '12:00'::TIME),
    ('jueves', '14:00'::TIME, '18:00'::TIME),
    ('viernes', '14:00'::TIME, '18:00'::TIME)
) AS h(dia_semana, hora_inicio, hora_fin)
CROSS JOIN medico m
ON CONFLICT (id_medico, dia_semana, hora_inicio, hora_fin) DO NOTHING;

--verificacion
SELECT 'medico' AS tabla, COUNT(*) AS total FROM medico
UNION ALL
SELECT 'horario_medico', COUNT(*) FROM horario_medico
ORDER BY tabla;

--Agregar pacientes
INSERT INTO paciente (
    nombres,
    apellidos,
    fecha_nacimiento,
    sexo,
    telefono,
    correo,
    direccion
)
VALUES
('Lucía Gabriela', 'Martínez López', '2018-03-12', 'femenino', '5555-4002', 'lucia.martinez@paciente.com', 'Zona 1, Quetzaltenango'),
('Diego Alejandro', 'Pérez Morales', '2015-07-25', 'masculino', '5555-4003', 'diego.perez@paciente.com', 'Zona 3, Quetzaltenango'),
('Sofía Isabel', 'Ramírez Castillo', '2012-11-08', 'femenino', '5555-4004', 'sofia.ramirez@paciente.com', 'La Esperanza'),
('Mateo José', 'García Herrera', '2009-01-19', 'masculino', '5555-4005', 'mateo.garcia@paciente.com', 'Olintepeque'),
('Camila Fernanda', 'Torres Aguilar', '2005-05-30', 'femenino', '5555-4006', 'camila.torres@paciente.com', 'Salcajá'),
('Juan Carlos', 'López Méndez', '1999-09-14', 'masculino', '5555-4007', 'juan.lopez@paciente.com', 'Zona 2, Quetzaltenango'),
('María José', 'Hernández Cruz', '1997-12-03', 'femenino', '5555-4008', 'maria.hernandez@paciente.com', 'Zona 7, Quetzaltenango'),
('Carlos Estuardo', 'Molina Reyes', '1994-06-21', 'masculino', '5555-4009', 'carlos.molina@paciente.com', 'Cantel'),
('Ana Patricia', 'Vásquez Gómez', '1992-04-11', 'femenino', '5555-4010', 'ana.vasquez@paciente.com', 'San Mateo'),
('Luis Fernando', 'Castillo Fuentes', '1989-10-09', 'masculino', '5555-4011', 'luis.castillo@paciente.com', 'Zona 8, Quetzaltenango'),
('Gabriela Alejandra', 'Navarro Pineda', '1987-02-17', 'femenino', '5555-4012', 'gabriela.navarro@paciente.com', 'Zona 5, Quetzaltenango'),
('Roberto Antonio', 'Soto Barrera', '1985-08-28', 'masculino', '5555-4013', 'roberto.soto@paciente.com', 'Totonicapán'),
('Elena Sofía', 'Rodas Chacón', '1983-03-06', 'femenino', '5555-4014', 'elena.rodas@paciente.com', 'Zona 6, Quetzaltenango'),
('Miguel Ángel', 'Paz Estrada', '1980-01-23', 'masculino', '5555-4015', 'miguel.paz@paciente.com', 'La Esperanza'),
('Claudia María', 'Orellana Juárez', '1978-07-13', 'femenino', '5555-4016', 'claudia.orellana@paciente.com', 'Zona 9, Quetzaltenango'),
('Jorge Mario', 'Cifuentes León', '1975-09-05', 'masculino', '5555-4017', 'jorge.cifuentes@paciente.com', 'San Juan Ostuncalco'),
('Rosa Elena', 'Méndez Arriaga', '1972-12-29', 'femenino', '5555-4018', 'rosa.mendez@paciente.com', 'Zona 10, Quetzaltenango'),
('Oscar David', 'Reyes Monroy', '1970-06-18', 'masculino', '5555-4019', 'oscar.reyes@paciente.com', 'Cantel'),
('Patricia Beatriz', 'Aguilar Salazar', '1968-04-04', 'femenino', '5555-4020', 'patricia.aguilar@paciente.com', 'Salcajá'),
('Héctor Manuel', 'Morales Díaz', '1965-11-16', 'masculino', '5555-4021', 'hector.morales@paciente.com', 'Zona 1, Quetzaltenango'),
('Silvia Carolina', 'Guzmán Franco', '1962-08-07', 'femenino', '5555-4022', 'silvia.guzman@paciente.com', 'Zona 3, Quetzaltenango'),
('Francisco Javier', 'Alvarado Peña', '1960-02-25', 'masculino', '5555-4023', 'francisco.alvarado@paciente.com', 'Totonicapán'),
('Marta Alicia', 'Herrera Caal', '1958-10-31', 'femenino', '5555-4024', 'marta.herrera@paciente.com', 'Zona 4, Quetzaltenango'),
('Ricardo Enrique', 'Pérez Lima', '1955-05-15', 'masculino', '5555-4025', 'ricardo.perez@paciente.com', 'La Esperanza'),
('Teresa Isabel', 'López Barrios', '1952-09-20', 'femenino', '5555-4026', 'teresa.lopez@paciente.com', 'San Mateo'),
('Manuel de Jesús', 'García Solís', '1950-01-10', 'masculino', '5555-4027', 'manuel.garcia@paciente.com', 'Olintepeque'),
('Carmen Lucía', 'Ramírez De León', '1948-06-27', 'femenino', '5555-4028', 'carmen.ramirez@paciente.com', 'Zona 2, Quetzaltenango'),
('Alberto José', 'Villatoro Méndez', '1945-03-18', 'masculino', '5555-4029', 'alberto.villatoro@paciente.com', 'Cantel'),
('Esperanza María', 'Chávez Robles', '1942-12-01', 'femenino', '5555-4030', 'esperanza.chavez@paciente.com', 'Zona 5, Quetzaltenango')
ON CONFLICT (correo) DO NOTHING;

--consultar pacientes
SELECT COUNT(*) AS total_pacientes
FROM paciente;

--consultar edades varias
SELECT
    id_paciente,
    nombres || ' ' || apellidos AS paciente,
    fecha_nacimiento,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, fecha_nacimiento))::INTEGER AS edad
FROM paciente
ORDER BY fecha_nacimiento DESC;


---citas generadas
WITH fechas_laborales AS (
    SELECT
        fecha::DATE AS fecha_cita,
        EXTRACT(ISODOW FROM fecha)::INTEGER AS dia_numero
    FROM generate_series(
        DATE '2025-12-01',
        DATE '2026-06-05',
        INTERVAL '1 day'
    ) AS fecha
    WHERE EXTRACT(ISODOW FROM fecha) BETWEEN 1 AND 5
),
slots AS (
    SELECT
        fecha_cita,
        CASE
            WHEN dia_numero BETWEEN 1 AND 3
                THEN (TIME '08:00' + (slot_num * INTERVAL '30 minutes'))::TIME
            ELSE
                (TIME '14:00' + (slot_num * INTERVAL '30 minutes'))::TIME
        END AS hora_inicio,

        CASE
            WHEN dia_numero BETWEEN 1 AND 3
                THEN (TIME '08:00' + ((slot_num + 1) * INTERVAL '30 minutes'))::TIME
            ELSE
                (TIME '14:00' + ((slot_num + 1) * INTERVAL '30 minutes'))::TIME
        END AS hora_fin
    FROM fechas_laborales
    CROSS JOIN generate_series(0, 7) AS slot_num
),
citas_generadas AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY fecha_cita, hora_inicio) AS rn,
        fecha_cita,
        hora_inicio,
        hora_fin
    FROM slots
)
INSERT INTO cita (
    id_paciente,
    id_medico,
    fecha_cita,
    hora_inicio,
    hora_fin,
    estado,
    motivo_cancelacion
)
SELECT
    ((rn - 1) % 30) + 1 AS id_paciente,
    ((rn - 1) % 10) + 1 AS id_medico,
    fecha_cita,
    hora_inicio,
    hora_fin,
    CASE
        WHEN rn <= 150 THEN 'atendida'
        WHEN rn <= 170 THEN 'programada'
        WHEN rn <= 185 THEN 'confirmada'
        WHEN rn <= 192 THEN 'cancelada'
        ELSE 'no_asistio'
    END AS estado,
    CASE
        WHEN rn > 185 AND rn <= 192 THEN 'Cancelación generada para datos de prueba'
        ELSE NULL
    END AS motivo_cancelacion
FROM citas_generadas
WHERE rn <= 197;

--consulta
SELECT COUNT(*) AS total_citas
FROM cita;

--cosulta estado
SELECT
    estado,
    COUNT(*) AS total
FROM cita
GROUP BY estado
ORDER BY estado;

--consulta atendidas
SELECT COUNT(*) AS total_citas_atendidas
FROM cita
WHERE estado = 'atendida';

--Agregar facturas y detalles
CREATE TEMP TABLE tmp_citas_facturar AS
SELECT
    ROW_NUMBER() OVER (ORDER BY c.id_cita) AS rn,
    c.id_cita,
    c.id_paciente,
    (c.fecha_cita + c.hora_fin) AS fecha_emision
FROM cita c
WHERE c.estado = 'atendida'
  AND NOT EXISTS (
      SELECT 1
      FROM factura f
      WHERE f.id_cita = c.id_cita
  )
ORDER BY c.id_cita
LIMIT 99;

INSERT INTO factura (
    id_paciente,
    id_usuario,
    id_cita,
    fecha_emision,
    total,
    estado
)
SELECT
    id_paciente,
    1 AS id_usuario,
    id_cita,
    fecha_emision,
    0 AS total,
    'pendiente' AS estado
FROM tmp_citas_facturar;

WITH servicios_ordenados AS (
    SELECT
        id_servicio,
        precio,
        ROW_NUMBER() OVER (ORDER BY id_servicio) AS rn_servicio
    FROM servicio
),
total_servicios AS (
    SELECT COUNT(*) AS total
    FROM servicio
)
INSERT INTO detalle_factura (
    id_factura,
    id_servicio,
    cantidad,
    precio_unitario,
    subtotal
)
SELECT
    f.id_factura,
    s.id_servicio,
    1 AS cantidad,
    s.precio AS precio_unitario,
    s.precio AS subtotal
FROM factura f
INNER JOIN tmp_citas_facturar t
    ON f.id_cita = t.id_cita
CROSS JOIN total_servicios ts
INNER JOIN servicios_ordenados s
    ON s.rn_servicio = ((t.rn - 1) % ts.total) + 1;

UPDATE factura f
SET total = sub.total_factura
FROM (
    SELECT
        id_factura,
        SUM(subtotal) AS total_factura
    FROM detalle_factura
    GROUP BY id_factura
) sub
WHERE f.id_factura = sub.id_factura
  AND f.id_cita IN (
      SELECT id_cita
      FROM tmp_citas_facturar
  );

DROP TABLE tmp_citas_facturar;

--consulta
SELECT 'factura' AS tabla, COUNT(*) AS total FROM factura
UNION ALL
SELECT 'detalle_factura', COUNT(*) FROM detalle_factura
ORDER BY tabla;

--consulta que no existe ninguna factura sin detalle 
SELECT
    COUNT(*) AS facturas_sin_detalle
FROM factura f
LEFT JOIN detalle_factura df
    ON f.id_factura = df.id_factura
WHERE df.id_detalle_factura IS NULL;

--generar pago
DO $$
DECLARE
    r RECORD;
    v_monto NUMERIC(10,2);
    v_contador INTEGER := 0;
BEGIN
    FOR r IN
        SELECT
            id_factura,
            total,
            fn_calcular_saldo_factura(id_factura) AS saldo
        FROM factura
        WHERE estado IN ('pendiente', 'pagada_parcial')
        ORDER BY id_factura
        LIMIT 80
    LOOP
        v_contador := v_contador + 1;

        IF v_contador % 3 = 0 THEN
            v_monto := r.saldo;
        ELSE
            v_monto := ROUND((r.saldo * 0.50)::NUMERIC, 2);
        END IF;

        IF v_monto > 0 THEN
            CALL sp_registrar_pago(
                r.id_factura,
                1,
                v_monto,
                CASE
                    WHEN v_contador % 4 = 0 THEN 'tarjeta'
                    WHEN v_contador % 4 = 1 THEN 'efectivo'
                    WHEN v_contador % 4 = 2 THEN 'transferencia'
                    ELSE 'cheque'
                END,
                'Pago generado para datos de prueba'
            );
        END IF;
    END LOOP;
END;
$$;

--consulta el total de pagos
SELECT COUNT(*) AS total_pagos
FROM pago;

--consulta factura por estado
SELECT
    estado,
    COUNT(*) AS total
FROM factura
GROUP BY estado
ORDER BY estado;

--auditoria de pagos
SELECT
    accion,
    COUNT(*) AS total
FROM auditoria
GROUP BY accion
ORDER BY accion;

--registrar auditorias
INSERT INTO auditoria (
    id_usuario,
    tabla_afectada,
    id_registro_afectado,
    accion,
    descripcion,
    datos_anteriores,
    datos_nuevos
)
SELECT
    1 AS id_usuario,
    CASE
        WHEN gs % 5 = 0 THEN 'cita'
        WHEN gs % 5 = 1 THEN 'paciente'
        WHEN gs % 5 = 2 THEN 'factura'
        WHEN gs % 5 = 3 THEN 'pago'
        ELSE 'servicio'
    END AS tabla_afectada,

    CASE
        WHEN gs % 5 = 0 THEN ((gs - 1) % 200) + 1
        WHEN gs % 5 = 1 THEN ((gs - 1) % 30) + 1
        WHEN gs % 5 = 2 THEN ((gs - 1) % 100) + 1
        WHEN gs % 5 = 3 THEN ((gs - 1) % 83) + 1
        ELSE ((gs - 1) % 10) + 1
    END AS id_registro_afectado,

    CASE
        WHEN gs % 4 = 0 THEN 'INSERT'
        WHEN gs % 4 = 1 THEN 'UPDATE'
        WHEN gs % 4 = 2 THEN 'REGISTRAR_PAGO'
        ELSE 'CANCELAR_CITA'
    END AS accion,

    CASE
        WHEN gs % 5 = 0 THEN 'Registro de actividad sobre citas generado para datos de prueba'
        WHEN gs % 5 = 1 THEN 'Registro de actividad sobre pacientes generado para datos de prueba'
        WHEN gs % 5 = 2 THEN 'Registro de actividad sobre facturación generado para datos de prueba'
        WHEN gs % 5 = 3 THEN 'Registro de actividad sobre pagos generado para datos de prueba'
        ELSE 'Registro de actividad sobre servicios generado para datos de prueba'
    END AS descripcion,

    jsonb_build_object(
        'origen', 'generacion_datos_prueba',
        'registro_simulado', gs,
        'estado_anterior', 'valor_anterior'
    ) AS datos_anteriores,

    jsonb_build_object(
        'origen', 'generacion_datos_prueba',
        'registro_simulado', gs,
        'estado_nuevo', 'valor_nuevo'
    ) AS datos_nuevos
FROM generate_series(1, 430) AS gs;


--consulta total auditoria
SELECT COUNT(*) AS total_auditoria
FROM auditoria;

--por accion
SELECT
    accion,
    COUNT(*) AS total
FROM auditoria
GROUP BY accion
ORDER BY accion;

--por tabla afectada
SELECT
    tabla_afectada,
    COUNT(*) AS total
FROM auditoria
GROUP BY tabla_afectada
ORDER BY tabla_afectada;