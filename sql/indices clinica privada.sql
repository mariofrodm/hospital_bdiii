-- Índice para consultar agenda diaria por fecha.
-- Se usará en el reporte RC-01: agenda diaria.
CREATE INDEX idx_cita_fecha
ON cita (fecha_cita);

-- Índice compuesto para buscar citas de un médico en una fecha específica.
-- Ayuda a validar disponibilidad y evitar doble reserva.
CREATE INDEX idx_cita_medico_fecha
ON cita (id_medico, fecha_cita);

-- Índice parcial para evitar que un médico tenga dos citas activas en el mismo horario.
-- Solo aplica a citas programadas, confirmadas o atendidas.
-- No bloquea horarios de citas canceladas o marcadas como no_asistio.
CREATE UNIQUE INDEX uq_cita_medico_horario_activa
ON cita (id_medico, fecha_cita, hora_inicio, hora_fin)
WHERE estado IN ('programada', 'confirmada', 'atendida');

-- Índice para consultar facturas pendientes o parcialmente pagadas.
-- Se usará en el reporte RC-02: facturas pendientes.
CREATE INDEX idx_factura_estado_fecha
ON factura (estado, fecha_emision);

-- Índice para consultar facturas de un paciente.
-- Se usará para calcular saldo por paciente.
CREATE INDEX idx_factura_paciente
ON factura (id_paciente);

-- Índice para consultar pagos por factura.
-- Se usará en cálculo de saldo pendiente.
CREATE INDEX idx_pago_factura
ON pago (id_factura);

-- Índice para consultar facturación por fecha.
-- Se usará en reportes mensuales.
CREATE INDEX idx_factura_fecha_emision
ON factura (fecha_emision);

-- Índice para consultar auditoría por usuario.
CREATE INDEX idx_auditoria_usuario
ON auditoria (id_usuario);

-- Índice para consultar auditoría por tabla afectada y fecha.
CREATE INDEX idx_auditoria_tabla_fecha
ON auditoria (tabla_afectada, fecha_evento);

-----------------------------------------------------------------

SELECT
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;


---------------------------------------------
---------Pruebas de reglas criticas con datos
----------------------------------------------

INSERT INTO especialidad (nombre, descripcion)
VALUES
('Medicina General', 'Atención médica general'),
('Cardiología', 'Atención de enfermedades cardiovasculares');

INSERT INTO rol (nombre, descripcion)
VALUES
('Recepcionista', 'Usuario encargado de citas y facturación'),
('Medico', 'Usuario médico que atiende pacientes'),
('Administrador', 'Usuario con permisos administrativos');

INSERT INTO servicio (nombre, descripcion, precio)
VALUES
('Consulta general', 'Consulta médica general', 150.00),
('Consulta especializada', 'Consulta con especialista', 250.00);

INSERT INTO paciente (
    nombres,
    apellidos,
    fecha_nacimiento,
    sexo,
    telefono,
    correo,
    direccion
)
VALUES (
    'Alex',
    'Perez',
    '1995-04-15',
    'masculino',
    '5555-1111',
    'Alex.Perez@test.com',
    'Quetzaltenango'
);

INSERT INTO medico (
    id_especialidad,
    nombres,
    apellidos,
    numero_colegiado,
    telefono,
    correo
)
VALUES (
    1,
    'Carlos',
    'Diaz',
    'COL-001',
    '5555-2222',
    'carlos.diaz@test.com'
);

INSERT INTO usuario (
    id_rol,
    id_medico,
    nombres,
    apellidos,
    usuario,
    correo,
    password_hash
)
VALUES (
    2,
    1,
    'Carlos',
    'Diaz',
    'cdiaz',
    'cdiaz@test.com',
    'hash_temporal'
);

INSERT INTO horario_medico (
    id_medico,
    dia_semana,
    hora_inicio,
    hora_fin
)
VALUES (
    1,
    'lunes',
    '08:00',
    '12:00'
);

INSERT INTO cita (
    id_paciente,
    id_medico,
    fecha_cita,
    hora_inicio,
    hora_fin,
    estado
)
VALUES (
    1,
    1,
    '2026-06-08',
    '08:00',
    '08:30',
    'programada'
);


------------------------------
-------consulta de verificacion 
------------------------------

SELECT
    c.id_cita,
    p.nombres || ' ' || p.apellidos AS paciente,
    m.nombres || ' ' || m.apellidos AS medico,
    e.nombre AS especialidad,
    c.fecha_cita,
    c.hora_inicio,
    c.hora_fin,
    c.estado
FROM cita c
INNER JOIN paciente p ON c.id_paciente = p.id_paciente
INNER JOIN medico m ON c.id_medico = m.id_medico
INNER JOIN especialidad e ON m.id_especialidad = e.id_especialidad;

