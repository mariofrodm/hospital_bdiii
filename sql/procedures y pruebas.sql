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


--------------pruebas, cancelar una cita para que quede el puesto libre

UPDATE cita
SET 
    estado = 'cancelada',
    motivo_cancelacion = 'Paciente solicitó reprogramación',
    updated_at = CURRENT_TIMESTAMP
WHERE id_cita = 1;

---------- agendar una nueva cita en el espacio que se libero
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

----consulta
SELECT
    id_cita,
    id_paciente,
    id_medico,
    fecha_cita,
    hora_inicio,
    hora_fin,
    estado,
    motivo_cancelacion
FROM cita
WHERE id_medico = 1
AND fecha_cita = '2026-06-08'
ORDER BY id_cita;


--------CREAR FACTURA

INSERT INTO factura (
    id_paciente,
    id_usuario,
    id_cita,
    total,
    estado
)
VALUES (
    1,
    1,
    3,
    150.00,
    'pendiente'
);

----DETALLE FACTURA
INSERT INTO detalle_factura (
    id_factura,
    id_servicio,
    cantidad,
    precio_unitario,
    subtotal
)
VALUES (
    1,
    1,
    1,
    150.00,
    150.00
);

---CONSULTA
SELECT
    f.id_factura,
    p.nombres || ' ' || p.apellidos AS paciente,
    u.usuario AS usuario_emisor,
    c.id_cita,
    s.nombre AS servicio,
    df.cantidad,
    df.precio_unitario,
    df.subtotal,
    f.total,
    f.estado
FROM factura f
INNER JOIN paciente p ON f.id_paciente = p.id_paciente
INNER JOIN usuario u ON f.id_usuario = u.id_usuario
LEFT JOIN cita c ON f.id_cita = c.id_cita
INNER JOIN detalle_factura df ON f.id_factura = df.id_factura
INNER JOIN servicio s ON df.id_servicio = s.id_servicio
WHERE f.id_factura = 1;

--------PAGO PARCIAL
INSERT INTO pago (
    id_factura,
    id_usuario,
    monto,
    metodo_pago,
    referencia,
    estado
)
VALUES (
    1,
    1,
    50.00,
    'efectivo',
    'Pago inicial de prueba',
    'registrado'
);

---CONSULTA
SELECT
    f.id_factura,
    f.total AS total_factura,
    COALESCE(SUM(p.monto), 0) AS total_pagado,
    f.total - COALESCE(SUM(p.monto), 0) AS saldo_pendiente,
    f.estado
FROM factura f
LEFT JOIN pago p 
    ON f.id_factura = p.id_factura
    AND p.estado = 'registrado'
WHERE f.id_factura = 1
GROUP BY
    f.id_factura,
    f.total,
    f.estado;

----CALCULAR SALDO DE FACTURA

CREATE OR REPLACE FUNCTION fn_calcular_saldo_factura(
    p_id_factura INTEGER
)
RETURNS NUMERIC(10,2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_factura NUMERIC(10,2);
    v_total_pagado NUMERIC(10,2);
    v_saldo NUMERIC(10,2);
BEGIN
    SELECT total
    INTO v_total_factura
    FROM factura
    WHERE id_factura = p_id_factura;

    IF v_total_factura IS NULL THEN
        RAISE EXCEPTION 'La factura con id % no existe.', p_id_factura;
    END IF;

    SELECT COALESCE(SUM(monto), 0)
    INTO v_total_pagado
    FROM pago
    WHERE id_factura = p_id_factura
      AND estado = 'registrado';

    v_saldo := v_total_factura - v_total_pagado;

    RETURN v_saldo;
END;
$$;

---CONSULTA
SELECT fn_calcular_saldo_factura(1) AS saldo_pendiente;

---FUNCION QUE RETORNA UNA TABLA
---Su objetivo será mostrar facturas con saldo pendiente.

CREATE OR REPLACE FUNCTION fn_facturas_pendientes()
RETURNS TABLE (
    id_factura INTEGER,
    paciente TEXT,
    fecha_emision TIMESTAMP,
    total NUMERIC(10,2),
    total_pagado NUMERIC(10,2),
    saldo_pendiente NUMERIC(10,2),
    estado VARCHAR(20)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        f.id_factura,
        p.nombres || ' ' || p.apellidos AS paciente,
        f.fecha_emision,
        f.total,
        COALESCE(SUM(pg.monto), 0)::NUMERIC(10,2) AS total_pagado,
        (f.total - COALESCE(SUM(pg.monto), 0))::NUMERIC(10,2) AS saldo_pendiente,
        f.estado
    FROM factura f
    INNER JOIN paciente p
        ON f.id_paciente = p.id_paciente
    LEFT JOIN pago pg
        ON f.id_factura = pg.id_factura
        AND pg.estado = 'registrado'
    WHERE f.estado IN ('pendiente', 'pagada_parcial')
    GROUP BY
        f.id_factura,
        p.nombres,
        p.apellidos,
        f.fecha_emision,
        f.total,
        f.estado
    HAVING (f.total - COALESCE(SUM(pg.monto), 0)) > 0
    ORDER BY f.fecha_emision ASC;
END;
$$;

----CONSULTA
SELECT *
FROM fn_facturas_pendientes();

---FUNCION SALDO TOTAL DEL PACIENTE
CREATE OR REPLACE FUNCTION fn_saldo_paciente(
    p_id_paciente INTEGER
)
RETURNS NUMERIC(10,2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_existe_paciente INTEGER;
    v_saldo_total NUMERIC(10,2);
BEGIN
    SELECT COUNT(*)
    INTO v_existe_paciente
    FROM paciente
    WHERE id_paciente = p_id_paciente;

    IF v_existe_paciente = 0 THEN
        RAISE EXCEPTION 'El paciente con id % no existe.', p_id_paciente;
    END IF;

    SELECT COALESCE(SUM(
        f.total - COALESCE((
            SELECT SUM(pg.monto)
            FROM pago pg
            WHERE pg.id_factura = f.id_factura
              AND pg.estado = 'registrado'
        ), 0)
    ), 0)
    INTO v_saldo_total
    FROM factura f
    WHERE f.id_paciente = p_id_paciente
      AND f.estado IN ('pendiente', 'pagada_parcial');

    RETURN v_saldo_total;
END;
$$;

--CONSULTA
SELECT fn_saldo_paciente(1) AS saldo_total_paciente;


---procedure registro de pago

CREATE OR REPLACE PROCEDURE sp_registrar_pago(
    p_id_factura INTEGER,
    p_id_usuario INTEGER,
    p_monto NUMERIC(10,2),
    p_metodo_pago VARCHAR(30),
    p_referencia VARCHAR(100)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado_factura VARCHAR(20);
    v_saldo_actual NUMERIC(10,2);
    v_nuevo_saldo NUMERIC(10,2);
    v_nuevo_estado VARCHAR(20);
    v_id_pago INTEGER;
BEGIN
    SELECT estado
    INTO v_estado_factura
    FROM factura
    WHERE id_factura = p_id_factura
    FOR UPDATE;

    IF v_estado_factura IS NULL THEN
        RAISE EXCEPTION 'La factura con id % no existe.', p_id_factura;
    END IF;

    IF v_estado_factura = 'anulada' THEN
        RAISE EXCEPTION 'No se pueden registrar pagos sobre una factura anulada.';
    END IF;

    IF p_monto <= 0 THEN
        RAISE EXCEPTION 'El monto del pago debe ser mayor que cero.';
    END IF;

    v_saldo_actual := fn_calcular_saldo_factura(p_id_factura);

    IF p_monto > v_saldo_actual THEN
        RAISE EXCEPTION 'El pago % excede el saldo pendiente %.', p_monto, v_saldo_actual;
    END IF;

    INSERT INTO pago (
        id_factura,
        id_usuario,
        monto,
        metodo_pago,
        referencia,
        estado
    )
    VALUES (
        p_id_factura,
        p_id_usuario,
        p_monto,
        p_metodo_pago,
        p_referencia,
        'registrado'
    )
    RETURNING id_pago INTO v_id_pago;

    v_nuevo_saldo := v_saldo_actual - p_monto;

    IF v_nuevo_saldo = 0 THEN
        v_nuevo_estado := 'pagada';
    ELSE
        v_nuevo_estado := 'pagada_parcial';
    END IF;

    UPDATE factura
    SET
        estado = v_nuevo_estado,
        updated_at = CURRENT_TIMESTAMP
    WHERE id_factura = p_id_factura;

    INSERT INTO auditoria (
        id_usuario,
        tabla_afectada,
        id_registro_afectado,
        accion,
        descripcion,
        datos_nuevos
    )
    VALUES (
        p_id_usuario,
        'pago',
        v_id_pago,
        'REGISTRAR_PAGO',
        'Registro de pago sobre factura ' || p_id_factura,
        jsonb_build_object(
            'id_factura', p_id_factura,
            'id_pago', v_id_pago,
            'monto', p_monto,
            'metodo_pago', p_metodo_pago,
            'saldo_anterior', v_saldo_actual,
            'saldo_nuevo', v_nuevo_saldo,
            'estado_factura_nuevo', v_nuevo_estado
        )
    );

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al registrar pago: %', SQLERRM;
END;
$$;
--Registro procedure
CALL sp_registrar_pago(
    1,
    1,
    50.00,
    'efectivo',
    'Segundo pago de prueba'
);

---consulta
SELECT
    f.id_factura,
    f.total,
    COALESCE(SUM(p.monto), 0) AS total_pagado,
    fn_calcular_saldo_factura(f.id_factura) AS saldo_pendiente,
    f.estado
FROM factura f
LEFT JOIN pago p
    ON f.id_factura = p.id_factura
    AND p.estado = 'registrado'
WHERE f.id_factura = 1
GROUP BY f.id_factura, f.total, f.estado;

---procedure tambien tomo en cuenta auditoria
SELECT
    id_auditoria,
    id_usuario,
    tabla_afectada,
    id_registro_afectado,
    accion,
    descripcion,
    fecha_evento,
    datos_nuevos
FROM auditoria
WHERE accion = 'REGISTRAR_PAGO'
ORDER BY id_auditoria DESC;

--rechaza un pago mayor al saldo 
CALL sp_registrar_pago(
    1,
    1,
    100.00,
    'efectivo',
    'Pago inválido de prueba'
);

---PAGO FINAL
CALL sp_registrar_pago(
    1,
    1,
    50.00,
    'efectivo',
    'Pago final de prueba'
);

--VERIFICAR ESTADO FINAL DE LA FACTURA
SELECT
    f.id_factura,
    f.total,
    COALESCE(SUM(p.monto), 0) AS total_pagado,
    fn_calcular_saldo_factura(f.id_factura) AS saldo_pendiente,
    f.estado
FROM factura f
LEFT JOIN pago p
    ON f.id_factura = p.id_factura
    AND p.estado = 'registrado'
WHERE f.id_factura = 1
GROUP BY f.id_factura, f.total, f.estado;

--AUDITORIA PAGO FINAL
SELECT
    id_auditoria,
    id_usuario,
    tabla_afectada,
    id_registro_afectado,
    accion,
    descripcion,
    datos_nuevos
FROM auditoria
WHERE accion = 'REGISTRAR_PAGO'
ORDER BY id_auditoria DESC;

--PROCEDURE CANCELACION DE CITA

CREATE OR REPLACE PROCEDURE sp_cancelar_cita(
    p_id_cita INTEGER,
    p_id_usuario INTEGER,
    p_motivo_cancelacion TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado_actual VARCHAR(20);
    v_datos_anteriores JSONB;
BEGIN
    SELECT estado
    INTO v_estado_actual
    FROM cita
    WHERE id_cita = p_id_cita
    FOR UPDATE;

    IF v_estado_actual IS NULL THEN
        RAISE EXCEPTION 'La cita con id % no existe.', p_id_cita;
    END IF;

    IF v_estado_actual = 'atendida' THEN
        RAISE EXCEPTION 'No se puede cancelar una cita que ya fue atendida.';
    END IF;

    IF v_estado_actual = 'cancelada' THEN
        RAISE EXCEPTION 'La cita ya se encuentra cancelada.';
    END IF;

    IF p_motivo_cancelacion IS NULL OR LENGTH(TRIM(p_motivo_cancelacion)) = 0 THEN
        RAISE EXCEPTION 'Debe indicar el motivo de cancelación.';
    END IF;

    SELECT jsonb_build_object(
        'id_cita', id_cita,
        'id_paciente', id_paciente,
        'id_medico', id_medico,
        'fecha_cita', fecha_cita,
        'hora_inicio', hora_inicio,
        'hora_fin', hora_fin,
        'estado_anterior', estado,
        'motivo_cancelacion_anterior', motivo_cancelacion
    )
    INTO v_datos_anteriores
    FROM cita
    WHERE id_cita = p_id_cita;

    UPDATE cita
    SET
        estado = 'cancelada',
        motivo_cancelacion = p_motivo_cancelacion,
        updated_at = CURRENT_TIMESTAMP
    WHERE id_cita = p_id_cita;

    INSERT INTO auditoria (
        id_usuario,
        tabla_afectada,
        id_registro_afectado,
        accion,
        descripcion,
        datos_anteriores,
        datos_nuevos
    )
    VALUES (
        p_id_usuario,
        'cita',
        p_id_cita,
        'CANCELAR_CITA',
        'Cancelación de cita ' || p_id_cita,
        v_datos_anteriores,
        jsonb_build_object(
            'id_cita', p_id_cita,
            'estado_nuevo', 'cancelada',
            'motivo_cancelacion', p_motivo_cancelacion
        )
    );

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al cancelar cita: %', SQLERRM;
END;
$$;

--PRUEBAS ESTA CITA 3 PROGRAMADA
CALL sp_cancelar_cita(
    3,
    1,
    'Paciente no podrá asistir a la consulta'
);

--CONSULTA QUE SI SE CANCELO
SELECT
    id_cita,
    estado,
    motivo_cancelacion
FROM cita
WHERE id_cita = 3;

--VERIFICAR AUDITORIA
SELECT
    id_auditoria,
    id_usuario,
    tabla_afectada,
    id_registro_afectado,
    accion,
    descripcion,
    datos_anteriores,
    datos_nuevos
FROM auditoria
WHERE accion = 'CANCELAR_CITA'
ORDER BY id_auditoria DESC;

--RECHAZO CUANDO UNA CITA YA SE CANCELO
CALL sp_cancelar_cita(
    3,
    1,
    'Intento de cancelar nuevamente la cita'
);

--cita atendida no se puede cancelar
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
    'atendida'
);

--consulta nuevo id cita
SELECT
    id_cita,
    fecha_cita,
    hora_inicio,
    hora_fin,
    estado
FROM cita
WHERE id_medico = 1
AND fecha_cita = '2026-06-08'
ORDER BY id_cita DESC
LIMIT 1;

--id 4 ya fue atendido, no deberia poderse cancelar
CALL sp_cancelar_cita(
    4,
    1,
    'Intento de cancelar cita atendida'
);