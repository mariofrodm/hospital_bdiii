---1. Vista Agenda diaria
CREATE OR REPLACE VIEW vw_agenda_diaria AS
SELECT
    c.id_cita,
    c.fecha_cita,
    c.hora_inicio,
    c.hora_fin,
    c.estado,
    c.motivo_cancelacion,

    p.id_paciente,
    p.nombres || ' ' || p.apellidos AS paciente,

    m.id_medico,
    m.nombres || ' ' || m.apellidos AS medico,

    e.id_especialidad,
    e.nombre AS especialidad
FROM cita c
INNER JOIN paciente p
    ON c.id_paciente = p.id_paciente
INNER JOIN medico m
    ON c.id_medico = m.id_medico
INNER JOIN especialidad e
    ON m.id_especialidad = e.id_especialidad;



---Vista de facturas pendientes
CREATE OR REPLACE VIEW vw_facturas_pendientes AS
SELECT
    f.id_factura,
    f.fecha_emision,
    f.estado,
    f.total,

    p.id_paciente,
    p.nombres || ' ' || p.apellidos AS paciente,

    COALESCE(SUM(pg.monto), 0)::NUMERIC(10,2) AS total_pagado,
    (f.total - COALESCE(SUM(pg.monto), 0))::NUMERIC(10,2) AS saldo_pendiente
FROM factura f
INNER JOIN paciente p
    ON f.id_paciente = p.id_paciente
LEFT JOIN pago pg
    ON f.id_factura = pg.id_factura
    AND pg.estado = 'registrado'
WHERE f.estado IN ('pendiente', 'pagada_parcial')
GROUP BY
    f.id_factura,
    f.fecha_emision,
    f.estado,
    f.total,
    p.id_paciente,
    p.nombres,
    p.apellidos
HAVING (f.total - COALESCE(SUM(pg.monto), 0)) > 0;

--Consulta por ambas vistas creadas
SELECT
    table_name
FROM information_schema.views
WHERE table_schema = 'public'
ORDER BY table_name;

--prueba de vista 1
SELECT *
FROM vw_agenda_diaria
WHERE fecha_cita = '2026-06-08'
ORDER BY hora_inicio;

--prueba de vista 2
SELECT *
FROM vw_facturas_pendientes;

---VISTA MATERIALIZADA facturacion mensual
--RC-03. Facturación mensual: total facturado, cobrado y saldo pendiente, 
--agrupado por mes y especialidad.
CREATE MATERIALIZED VIEW mv_facturacion_mensual AS
SELECT
    DATE_TRUNC('month', f.fecha_emision)::DATE AS mes,
    e.id_especialidad,
    e.nombre AS especialidad,
    COUNT(DISTINCT f.id_factura) AS cantidad_facturas,
    COALESCE(SUM(f.total), 0)::NUMERIC(10,2) AS total_facturado,
    COALESCE(SUM(pg.total_pagado), 0)::NUMERIC(10,2) AS total_cobrado,
    (COALESCE(SUM(f.total), 0) - COALESCE(SUM(pg.total_pagado), 0))::NUMERIC(10,2) AS saldo_pendiente
FROM factura f
INNER JOIN cita c
    ON f.id_cita = c.id_cita
INNER JOIN medico m
    ON c.id_medico = m.id_medico
INNER JOIN especialidad e
    ON m.id_especialidad = e.id_especialidad
LEFT JOIN (
    SELECT
        id_factura,
        SUM(monto) AS total_pagado
    FROM pago
    WHERE estado = 'registrado'
    GROUP BY id_factura
) pg
    ON f.id_factura = pg.id_factura
WHERE f.estado <> 'anulada'
GROUP BY
    DATE_TRUNC('month', f.fecha_emision)::DATE,
    e.id_especialidad,
    e.nombre;

--VISTA MATERIALIZADA 2 RANKING DE MEDICOS TRIMESTRAL 
--RC-04. Ranking trimestral de médicos: médicos ordenados por número de citas 
--atendidas y monto facturado en el último trimestre.

CREATE MATERIALIZED VIEW mv_ranking_medicos_trimestral AS
SELECT
    m.id_medico,
    m.nombres || ' ' || m.apellidos AS medico,
    e.nombre AS especialidad,
    COUNT(DISTINCT c.id_cita) AS citas_atendidas,
    COALESCE(SUM(f.total), 0)::NUMERIC(10,2) AS monto_facturado
FROM medico m
INNER JOIN especialidad e
    ON m.id_especialidad = e.id_especialidad
LEFT JOIN cita c
    ON m.id_medico = c.id_medico
    AND c.estado = 'atendida'
    AND c.fecha_cita >= (CURRENT_DATE - INTERVAL '3 months')
LEFT JOIN factura f
    ON c.id_cita = f.id_cita
    AND f.estado <> 'anulada'
GROUP BY
    m.id_medico,
    m.nombres,
    m.apellidos,
    e.nombre
ORDER BY
    citas_atendidas DESC,
    monto_facturado DESC;

--INDICES PARA LAS VISTAS MATERIALIZADAS
CREATE INDEX idx_mv_facturacion_mensual_mes
ON mv_facturacion_mensual (mes);

CREATE INDEX idx_mv_facturacion_mensual_especialidad
ON mv_facturacion_mensual (id_especialidad);

CREATE INDEX idx_mv_ranking_medicos_citas
ON mv_ranking_medicos_trimestral (citas_atendidas DESC);

--VERIFICACION
SELECT
    matviewname
FROM pg_matviews
WHERE schemaname = 'public'
ORDER BY matviewname;

--CONSULTA VISTA MATERIALIZADA 1
SELECT *
FROM mv_facturacion_mensual;

--CONSULTA VISTA MATERIALIZADA 2
SELECT *
FROM mv_ranking_medicos_trimestral;


