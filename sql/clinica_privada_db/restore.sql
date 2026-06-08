--
-- NOTE:
--
-- File paths need to be edited. Search for $$PATH$$ and
-- replace it with the path to the directory containing
-- the extracted data files.
--
--
-- PostgreSQL database dump
--

-- Dumped from database version 16.13
-- Dumped by pg_dump version 17.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE clinica_privada_db;
--
-- Name: clinica_privada_db; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE clinica_privada_db WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'English_United States.1252';


ALTER DATABASE clinica_privada_db OWNER TO postgres;

\unrestrict (null)
\connect clinica_privada_db
\restrict (null)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: fn_calcular_saldo_factura(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_calcular_saldo_factura(p_id_factura integer) RETURNS numeric
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


ALTER FUNCTION public.fn_calcular_saldo_factura(p_id_factura integer) OWNER TO postgres;

--
-- Name: fn_facturas_pendientes(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_facturas_pendientes() RETURNS TABLE(id_factura integer, paciente text, fecha_emision timestamp without time zone, total numeric, total_pagado numeric, saldo_pendiente numeric, estado character varying)
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


ALTER FUNCTION public.fn_facturas_pendientes() OWNER TO postgres;

--
-- Name: fn_saldo_paciente(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_saldo_paciente(p_id_paciente integer) RETURNS numeric
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


ALTER FUNCTION public.fn_saldo_paciente(p_id_paciente integer) OWNER TO postgres;

--
-- Name: sp_cancelar_cita(integer, integer, text); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_cancelar_cita(IN p_id_cita integer, IN p_id_usuario integer, IN p_motivo_cancelacion text)
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


ALTER PROCEDURE public.sp_cancelar_cita(IN p_id_cita integer, IN p_id_usuario integer, IN p_motivo_cancelacion text) OWNER TO postgres;

--
-- Name: sp_registrar_pago(integer, integer, numeric, character varying, character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_registrar_pago(IN p_id_factura integer, IN p_id_usuario integer, IN p_monto numeric, IN p_metodo_pago character varying, IN p_referencia character varying)
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


ALTER PROCEDURE public.sp_registrar_pago(IN p_id_factura integer, IN p_id_usuario integer, IN p_monto numeric, IN p_metodo_pago character varying, IN p_referencia character varying) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: auditoria; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auditoria (
    id_auditoria integer NOT NULL,
    id_usuario integer NOT NULL,
    tabla_afectada character varying(100) NOT NULL,
    id_registro_afectado integer,
    accion character varying(50) NOT NULL,
    descripcion text,
    fecha_evento timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    datos_anteriores jsonb,
    datos_nuevos jsonb,
    CONSTRAINT chk_auditoria_accion CHECK (((accion)::text = ANY ((ARRAY['INSERT'::character varying, 'UPDATE'::character varying, 'DELETE'::character varying, 'CANCELAR_CITA'::character varying, 'REGISTRAR_PAGO'::character varying, 'ANULAR_FACTURA'::character varying])::text[])))
);


ALTER TABLE public.auditoria OWNER TO postgres;

--
-- Name: auditoria_id_auditoria_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.auditoria_id_auditoria_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.auditoria_id_auditoria_seq OWNER TO postgres;

--
-- Name: auditoria_id_auditoria_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.auditoria_id_auditoria_seq OWNED BY public.auditoria.id_auditoria;


--
-- Name: cita; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cita (
    id_cita integer NOT NULL,
    id_paciente integer NOT NULL,
    id_medico integer NOT NULL,
    fecha_cita date NOT NULL,
    hora_inicio time without time zone NOT NULL,
    hora_fin time without time zone NOT NULL,
    estado character varying(20) DEFAULT 'programada'::character varying NOT NULL,
    motivo_cancelacion text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    CONSTRAINT chk_cita_estado CHECK (((estado)::text = ANY ((ARRAY['programada'::character varying, 'confirmada'::character varying, 'atendida'::character varying, 'cancelada'::character varying, 'no_asistio'::character varying])::text[]))),
    CONSTRAINT chk_cita_horas CHECK ((hora_fin > hora_inicio)),
    CONSTRAINT chk_cita_motivo_cancelacion CHECK ((((estado)::text <> 'cancelada'::text) OR (motivo_cancelacion IS NOT NULL)))
);


ALTER TABLE public.cita OWNER TO postgres;

--
-- Name: cita_id_cita_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cita_id_cita_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cita_id_cita_seq OWNER TO postgres;

--
-- Name: cita_id_cita_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cita_id_cita_seq OWNED BY public.cita.id_cita;


--
-- Name: detalle_factura; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.detalle_factura (
    id_detalle_factura integer NOT NULL,
    id_factura integer NOT NULL,
    id_servicio integer NOT NULL,
    cantidad integer NOT NULL,
    precio_unitario numeric(10,2) NOT NULL,
    subtotal numeric(10,2) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    CONSTRAINT chk_detalle_cantidad CHECK ((cantidad > 0)),
    CONSTRAINT chk_detalle_precio_unitario CHECK ((precio_unitario >= (0)::numeric)),
    CONSTRAINT chk_detalle_subtotal CHECK ((subtotal >= (0)::numeric))
);


ALTER TABLE public.detalle_factura OWNER TO postgres;

--
-- Name: detalle_factura_id_detalle_factura_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.detalle_factura_id_detalle_factura_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.detalle_factura_id_detalle_factura_seq OWNER TO postgres;

--
-- Name: detalle_factura_id_detalle_factura_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.detalle_factura_id_detalle_factura_seq OWNED BY public.detalle_factura.id_detalle_factura;


--
-- Name: especialidad; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.especialidad (
    id_especialidad integer NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion text,
    estado character varying(20) DEFAULT 'activo'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    CONSTRAINT chk_especialidad_estado CHECK (((estado)::text = ANY ((ARRAY['activo'::character varying, 'inactivo'::character varying])::text[])))
);


ALTER TABLE public.especialidad OWNER TO postgres;

--
-- Name: especialidad_id_especialidad_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.especialidad_id_especialidad_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.especialidad_id_especialidad_seq OWNER TO postgres;

--
-- Name: especialidad_id_especialidad_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.especialidad_id_especialidad_seq OWNED BY public.especialidad.id_especialidad;


--
-- Name: factura; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.factura (
    id_factura integer NOT NULL,
    id_paciente integer NOT NULL,
    id_usuario integer NOT NULL,
    id_cita integer,
    fecha_emision timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    total numeric(10,2) DEFAULT 0 NOT NULL,
    estado character varying(20) DEFAULT 'pendiente'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    CONSTRAINT chk_factura_estado CHECK (((estado)::text = ANY ((ARRAY['pendiente'::character varying, 'pagada_parcial'::character varying, 'pagada'::character varying, 'anulada'::character varying])::text[]))),
    CONSTRAINT chk_factura_total CHECK ((total >= (0)::numeric))
);


ALTER TABLE public.factura OWNER TO postgres;

--
-- Name: factura_id_factura_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.factura_id_factura_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.factura_id_factura_seq OWNER TO postgres;

--
-- Name: factura_id_factura_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.factura_id_factura_seq OWNED BY public.factura.id_factura;


--
-- Name: horario_medico; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.horario_medico (
    id_horario integer NOT NULL,
    id_medico integer NOT NULL,
    dia_semana character varying(20) NOT NULL,
    hora_inicio time without time zone NOT NULL,
    hora_fin time without time zone NOT NULL,
    estado character varying(20) DEFAULT 'activo'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    CONSTRAINT chk_horario_dia CHECK (((dia_semana)::text = ANY ((ARRAY['lunes'::character varying, 'martes'::character varying, 'miercoles'::character varying, 'jueves'::character varying, 'viernes'::character varying, 'sabado'::character varying, 'domingo'::character varying])::text[]))),
    CONSTRAINT chk_horario_estado CHECK (((estado)::text = ANY ((ARRAY['activo'::character varying, 'inactivo'::character varying])::text[]))),
    CONSTRAINT chk_horario_horas CHECK ((hora_fin > hora_inicio))
);


ALTER TABLE public.horario_medico OWNER TO postgres;

--
-- Name: horario_medico_id_horario_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.horario_medico_id_horario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.horario_medico_id_horario_seq OWNER TO postgres;

--
-- Name: horario_medico_id_horario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.horario_medico_id_horario_seq OWNED BY public.horario_medico.id_horario;


--
-- Name: medico; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.medico (
    id_medico integer NOT NULL,
    id_especialidad integer NOT NULL,
    nombres character varying(100) NOT NULL,
    apellidos character varying(100) NOT NULL,
    numero_colegiado character varying(50) NOT NULL,
    telefono character varying(20),
    correo character varying(150),
    estado character varying(20) DEFAULT 'activo'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    CONSTRAINT chk_medico_estado CHECK (((estado)::text = ANY ((ARRAY['activo'::character varying, 'inactivo'::character varying])::text[])))
);


ALTER TABLE public.medico OWNER TO postgres;

--
-- Name: medico_id_medico_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.medico_id_medico_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.medico_id_medico_seq OWNER TO postgres;

--
-- Name: medico_id_medico_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.medico_id_medico_seq OWNED BY public.medico.id_medico;


--
-- Name: pago; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pago (
    id_pago integer NOT NULL,
    id_factura integer NOT NULL,
    id_usuario integer NOT NULL,
    fecha_pago timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    monto numeric(10,2) NOT NULL,
    metodo_pago character varying(30) NOT NULL,
    referencia character varying(100),
    estado character varying(20) DEFAULT 'registrado'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    CONSTRAINT chk_pago_estado CHECK (((estado)::text = ANY ((ARRAY['registrado'::character varying, 'anulado'::character varying])::text[]))),
    CONSTRAINT chk_pago_metodo CHECK (((metodo_pago)::text = ANY ((ARRAY['efectivo'::character varying, 'tarjeta'::character varying, 'transferencia'::character varying, 'cheque'::character varying])::text[]))),
    CONSTRAINT chk_pago_monto CHECK ((monto > (0)::numeric))
);


ALTER TABLE public.pago OWNER TO postgres;

--
-- Name: mv_facturacion_mensual; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW public.mv_facturacion_mensual AS
 SELECT (date_trunc('month'::text, f.fecha_emision))::date AS mes,
    e.id_especialidad,
    e.nombre AS especialidad,
    count(DISTINCT f.id_factura) AS cantidad_facturas,
    (COALESCE(sum(f.total), (0)::numeric))::numeric(10,2) AS total_facturado,
    (COALESCE(sum(pg.total_pagado), (0)::numeric))::numeric(10,2) AS total_cobrado,
    ((COALESCE(sum(f.total), (0)::numeric) - COALESCE(sum(pg.total_pagado), (0)::numeric)))::numeric(10,2) AS saldo_pendiente
   FROM ((((public.factura f
     JOIN public.cita c ON ((f.id_cita = c.id_cita)))
     JOIN public.medico m ON ((c.id_medico = m.id_medico)))
     JOIN public.especialidad e ON ((m.id_especialidad = e.id_especialidad)))
     LEFT JOIN ( SELECT pago.id_factura,
            sum(pago.monto) AS total_pagado
           FROM public.pago
          WHERE ((pago.estado)::text = 'registrado'::text)
          GROUP BY pago.id_factura) pg ON ((f.id_factura = pg.id_factura)))
  WHERE ((f.estado)::text <> 'anulada'::text)
  GROUP BY ((date_trunc('month'::text, f.fecha_emision))::date), e.id_especialidad, e.nombre
  WITH NO DATA;


ALTER MATERIALIZED VIEW public.mv_facturacion_mensual OWNER TO postgres;

--
-- Name: mv_ranking_medicos_trimestral; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW public.mv_ranking_medicos_trimestral AS
 SELECT m.id_medico,
    (((m.nombres)::text || ' '::text) || (m.apellidos)::text) AS medico,
    e.nombre AS especialidad,
    count(DISTINCT c.id_cita) AS citas_atendidas,
    (COALESCE(sum(f.total), (0)::numeric))::numeric(10,2) AS monto_facturado
   FROM (((public.medico m
     JOIN public.especialidad e ON ((m.id_especialidad = e.id_especialidad)))
     LEFT JOIN public.cita c ON (((m.id_medico = c.id_medico) AND ((c.estado)::text = 'atendida'::text) AND (c.fecha_cita >= (CURRENT_DATE - '3 mons'::interval)))))
     LEFT JOIN public.factura f ON (((c.id_cita = f.id_cita) AND ((f.estado)::text <> 'anulada'::text))))
  GROUP BY m.id_medico, m.nombres, m.apellidos, e.nombre
  ORDER BY (count(DISTINCT c.id_cita)) DESC, ((COALESCE(sum(f.total), (0)::numeric))::numeric(10,2)) DESC
  WITH NO DATA;


ALTER MATERIALIZED VIEW public.mv_ranking_medicos_trimestral OWNER TO postgres;

--
-- Name: paciente; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.paciente (
    id_paciente integer NOT NULL,
    nombres character varying(100) NOT NULL,
    apellidos character varying(100) NOT NULL,
    fecha_nacimiento date NOT NULL,
    sexo character varying(20) NOT NULL,
    telefono character varying(20),
    correo character varying(150),
    direccion text,
    estado character varying(20) DEFAULT 'activo'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    CONSTRAINT chk_paciente_estado CHECK (((estado)::text = ANY ((ARRAY['activo'::character varying, 'inactivo'::character varying])::text[]))),
    CONSTRAINT chk_paciente_sexo CHECK (((sexo)::text = ANY ((ARRAY['masculino'::character varying, 'femenino'::character varying, 'otro'::character varying])::text[])))
);


ALTER TABLE public.paciente OWNER TO postgres;

--
-- Name: paciente_id_paciente_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.paciente_id_paciente_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.paciente_id_paciente_seq OWNER TO postgres;

--
-- Name: paciente_id_paciente_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.paciente_id_paciente_seq OWNED BY public.paciente.id_paciente;


--
-- Name: pago_id_pago_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pago_id_pago_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pago_id_pago_seq OWNER TO postgres;

--
-- Name: pago_id_pago_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pago_id_pago_seq OWNED BY public.pago.id_pago;


--
-- Name: rol; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rol (
    id_rol integer NOT NULL,
    nombre character varying(50) NOT NULL,
    descripcion text,
    estado character varying(20) DEFAULT 'activo'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    CONSTRAINT chk_rol_estado CHECK (((estado)::text = ANY ((ARRAY['activo'::character varying, 'inactivo'::character varying])::text[])))
);


ALTER TABLE public.rol OWNER TO postgres;

--
-- Name: rol_id_rol_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.rol_id_rol_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rol_id_rol_seq OWNER TO postgres;

--
-- Name: rol_id_rol_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.rol_id_rol_seq OWNED BY public.rol.id_rol;


--
-- Name: servicio; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.servicio (
    id_servicio integer NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion text,
    precio numeric(10,2) NOT NULL,
    estado character varying(20) DEFAULT 'activo'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    CONSTRAINT chk_servicio_estado CHECK (((estado)::text = ANY ((ARRAY['activo'::character varying, 'inactivo'::character varying])::text[]))),
    CONSTRAINT chk_servicio_precio CHECK ((precio >= (0)::numeric))
);


ALTER TABLE public.servicio OWNER TO postgres;

--
-- Name: servicio_id_servicio_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.servicio_id_servicio_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.servicio_id_servicio_seq OWNER TO postgres;

--
-- Name: servicio_id_servicio_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.servicio_id_servicio_seq OWNED BY public.servicio.id_servicio;


--
-- Name: usuario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuario (
    id_usuario integer NOT NULL,
    id_rol integer NOT NULL,
    id_medico integer,
    nombres character varying(100) NOT NULL,
    apellidos character varying(100) NOT NULL,
    usuario character varying(50) NOT NULL,
    correo character varying(150) NOT NULL,
    password_hash text NOT NULL,
    estado character varying(20) DEFAULT 'activo'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    CONSTRAINT chk_usuario_estado CHECK (((estado)::text = ANY ((ARRAY['activo'::character varying, 'inactivo'::character varying])::text[])))
);


ALTER TABLE public.usuario OWNER TO postgres;

--
-- Name: usuario_id_usuario_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.usuario_id_usuario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.usuario_id_usuario_seq OWNER TO postgres;

--
-- Name: usuario_id_usuario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.usuario_id_usuario_seq OWNED BY public.usuario.id_usuario;


--
-- Name: vw_agenda_diaria; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_agenda_diaria AS
 SELECT c.id_cita,
    c.fecha_cita,
    c.hora_inicio,
    c.hora_fin,
    c.estado,
    c.motivo_cancelacion,
    p.id_paciente,
    (((p.nombres)::text || ' '::text) || (p.apellidos)::text) AS paciente,
    m.id_medico,
    (((m.nombres)::text || ' '::text) || (m.apellidos)::text) AS medico,
    e.id_especialidad,
    e.nombre AS especialidad
   FROM (((public.cita c
     JOIN public.paciente p ON ((c.id_paciente = p.id_paciente)))
     JOIN public.medico m ON ((c.id_medico = m.id_medico)))
     JOIN public.especialidad e ON ((m.id_especialidad = e.id_especialidad)));


ALTER VIEW public.vw_agenda_diaria OWNER TO postgres;

--
-- Name: vw_facturas_pendientes; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_facturas_pendientes AS
 SELECT f.id_factura,
    f.fecha_emision,
    f.estado,
    f.total,
    p.id_paciente,
    (((p.nombres)::text || ' '::text) || (p.apellidos)::text) AS paciente,
    (COALESCE(sum(pg.monto), (0)::numeric))::numeric(10,2) AS total_pagado,
    ((f.total - COALESCE(sum(pg.monto), (0)::numeric)))::numeric(10,2) AS saldo_pendiente
   FROM ((public.factura f
     JOIN public.paciente p ON ((f.id_paciente = p.id_paciente)))
     LEFT JOIN public.pago pg ON (((f.id_factura = pg.id_factura) AND ((pg.estado)::text = 'registrado'::text))))
  WHERE ((f.estado)::text = ANY ((ARRAY['pendiente'::character varying, 'pagada_parcial'::character varying])::text[]))
  GROUP BY f.id_factura, f.fecha_emision, f.estado, f.total, p.id_paciente, p.nombres, p.apellidos
 HAVING ((f.total - COALESCE(sum(pg.monto), (0)::numeric)) > (0)::numeric);


ALTER VIEW public.vw_facturas_pendientes OWNER TO postgres;

--
-- Name: auditoria id_auditoria; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auditoria ALTER COLUMN id_auditoria SET DEFAULT nextval('public.auditoria_id_auditoria_seq'::regclass);


--
-- Name: cita id_cita; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cita ALTER COLUMN id_cita SET DEFAULT nextval('public.cita_id_cita_seq'::regclass);


--
-- Name: detalle_factura id_detalle_factura; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_factura ALTER COLUMN id_detalle_factura SET DEFAULT nextval('public.detalle_factura_id_detalle_factura_seq'::regclass);


--
-- Name: especialidad id_especialidad; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.especialidad ALTER COLUMN id_especialidad SET DEFAULT nextval('public.especialidad_id_especialidad_seq'::regclass);


--
-- Name: factura id_factura; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factura ALTER COLUMN id_factura SET DEFAULT nextval('public.factura_id_factura_seq'::regclass);


--
-- Name: horario_medico id_horario; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.horario_medico ALTER COLUMN id_horario SET DEFAULT nextval('public.horario_medico_id_horario_seq'::regclass);


--
-- Name: medico id_medico; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medico ALTER COLUMN id_medico SET DEFAULT nextval('public.medico_id_medico_seq'::regclass);


--
-- Name: paciente id_paciente; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.paciente ALTER COLUMN id_paciente SET DEFAULT nextval('public.paciente_id_paciente_seq'::regclass);


--
-- Name: pago id_pago; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pago ALTER COLUMN id_pago SET DEFAULT nextval('public.pago_id_pago_seq'::regclass);


--
-- Name: rol id_rol; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rol ALTER COLUMN id_rol SET DEFAULT nextval('public.rol_id_rol_seq'::regclass);


--
-- Name: servicio id_servicio; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.servicio ALTER COLUMN id_servicio SET DEFAULT nextval('public.servicio_id_servicio_seq'::regclass);


--
-- Name: usuario id_usuario; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario ALTER COLUMN id_usuario SET DEFAULT nextval('public.usuario_id_usuario_seq'::regclass);


--
-- Data for Name: auditoria; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auditoria (id_auditoria, id_usuario, tabla_afectada, id_registro_afectado, accion, descripcion, fecha_evento, datos_anteriores, datos_nuevos) FROM stdin;
\.
COPY public.auditoria (id_auditoria, id_usuario, tabla_afectada, id_registro_afectado, accion, descripcion, fecha_evento, datos_anteriores, datos_nuevos) FROM '$$PATH$$/5117.dat';

--
-- Data for Name: cita; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cita (id_cita, id_paciente, id_medico, fecha_cita, hora_inicio, hora_fin, estado, motivo_cancelacion, created_at, updated_at) FROM stdin;
\.
COPY public.cita (id_cita, id_paciente, id_medico, fecha_cita, hora_inicio, hora_fin, estado, motivo_cancelacion, created_at, updated_at) FROM '$$PATH$$/5109.dat';

--
-- Data for Name: detalle_factura; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.detalle_factura (id_detalle_factura, id_factura, id_servicio, cantidad, precio_unitario, subtotal, created_at, updated_at) FROM stdin;
\.
COPY public.detalle_factura (id_detalle_factura, id_factura, id_servicio, cantidad, precio_unitario, subtotal, created_at, updated_at) FROM '$$PATH$$/5113.dat';

--
-- Data for Name: especialidad; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.especialidad (id_especialidad, nombre, descripcion, estado, created_at, updated_at) FROM stdin;
\.
COPY public.especialidad (id_especialidad, nombre, descripcion, estado, created_at, updated_at) FROM '$$PATH$$/5095.dat';

--
-- Data for Name: factura; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.factura (id_factura, id_paciente, id_usuario, id_cita, fecha_emision, total, estado, created_at, updated_at) FROM stdin;
\.
COPY public.factura (id_factura, id_paciente, id_usuario, id_cita, fecha_emision, total, estado, created_at, updated_at) FROM '$$PATH$$/5111.dat';

--
-- Data for Name: horario_medico; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.horario_medico (id_horario, id_medico, dia_semana, hora_inicio, hora_fin, estado, created_at, updated_at) FROM stdin;
\.
COPY public.horario_medico (id_horario, id_medico, dia_semana, hora_inicio, hora_fin, estado, created_at, updated_at) FROM '$$PATH$$/5107.dat';

--
-- Data for Name: medico; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.medico (id_medico, id_especialidad, nombres, apellidos, numero_colegiado, telefono, correo, estado, created_at, updated_at) FROM stdin;
\.
COPY public.medico (id_medico, id_especialidad, nombres, apellidos, numero_colegiado, telefono, correo, estado, created_at, updated_at) FROM '$$PATH$$/5103.dat';

--
-- Data for Name: paciente; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.paciente (id_paciente, nombres, apellidos, fecha_nacimiento, sexo, telefono, correo, direccion, estado, created_at, updated_at) FROM stdin;
\.
COPY public.paciente (id_paciente, nombres, apellidos, fecha_nacimiento, sexo, telefono, correo, direccion, estado, created_at, updated_at) FROM '$$PATH$$/5101.dat';

--
-- Data for Name: pago; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pago (id_pago, id_factura, id_usuario, fecha_pago, monto, metodo_pago, referencia, estado, created_at, updated_at) FROM stdin;
\.
COPY public.pago (id_pago, id_factura, id_usuario, fecha_pago, monto, metodo_pago, referencia, estado, created_at, updated_at) FROM '$$PATH$$/5115.dat';

--
-- Data for Name: rol; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.rol (id_rol, nombre, descripcion, estado, created_at, updated_at) FROM stdin;
\.
COPY public.rol (id_rol, nombre, descripcion, estado, created_at, updated_at) FROM '$$PATH$$/5097.dat';

--
-- Data for Name: servicio; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.servicio (id_servicio, nombre, descripcion, precio, estado, created_at, updated_at) FROM stdin;
\.
COPY public.servicio (id_servicio, nombre, descripcion, precio, estado, created_at, updated_at) FROM '$$PATH$$/5099.dat';

--
-- Data for Name: usuario; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.usuario (id_usuario, id_rol, id_medico, nombres, apellidos, usuario, correo, password_hash, estado, created_at, updated_at) FROM stdin;
\.
COPY public.usuario (id_usuario, id_rol, id_medico, nombres, apellidos, usuario, correo, password_hash, estado, created_at, updated_at) FROM '$$PATH$$/5105.dat';

--
-- Name: auditoria_id_auditoria_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auditoria_id_auditoria_seq', 573, true);


--
-- Name: cita_id_cita_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cita_id_cita_seq', 261, true);


--
-- Name: detalle_factura_id_detalle_factura_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.detalle_factura_id_detalle_factura_seq', 160, true);


--
-- Name: especialidad_id_especialidad_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.especialidad_id_especialidad_seq', 5, true);


--
-- Name: factura_id_factura_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.factura_id_factura_seq', 160, true);


--
-- Name: horario_medico_id_horario_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.horario_medico_id_horario_seq', 51, true);


--
-- Name: medico_id_medico_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.medico_id_medico_seq', 10, true);


--
-- Name: paciente_id_paciente_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.paciente_id_paciente_seq', 30, true);


--
-- Name: pago_id_pago_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pago_id_pago_seq', 143, true);


--
-- Name: rol_id_rol_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.rol_id_rol_seq', 3, true);


--
-- Name: servicio_id_servicio_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.servicio_id_servicio_seq', 10, true);


--
-- Name: usuario_id_usuario_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.usuario_id_usuario_seq', 1, true);


--
-- Name: auditoria auditoria_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auditoria
    ADD CONSTRAINT auditoria_pkey PRIMARY KEY (id_auditoria);


--
-- Name: cita cita_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cita
    ADD CONSTRAINT cita_pkey PRIMARY KEY (id_cita);


--
-- Name: detalle_factura detalle_factura_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_factura
    ADD CONSTRAINT detalle_factura_pkey PRIMARY KEY (id_detalle_factura);


--
-- Name: especialidad especialidad_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.especialidad
    ADD CONSTRAINT especialidad_nombre_key UNIQUE (nombre);


--
-- Name: especialidad especialidad_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.especialidad
    ADD CONSTRAINT especialidad_pkey PRIMARY KEY (id_especialidad);


--
-- Name: factura factura_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factura
    ADD CONSTRAINT factura_pkey PRIMARY KEY (id_factura);


--
-- Name: horario_medico horario_medico_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.horario_medico
    ADD CONSTRAINT horario_medico_pkey PRIMARY KEY (id_horario);


--
-- Name: medico medico_numero_colegiado_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medico
    ADD CONSTRAINT medico_numero_colegiado_key UNIQUE (numero_colegiado);


--
-- Name: medico medico_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medico
    ADD CONSTRAINT medico_pkey PRIMARY KEY (id_medico);


--
-- Name: paciente paciente_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.paciente
    ADD CONSTRAINT paciente_pkey PRIMARY KEY (id_paciente);


--
-- Name: pago pago_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pago
    ADD CONSTRAINT pago_pkey PRIMARY KEY (id_pago);


--
-- Name: rol rol_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rol
    ADD CONSTRAINT rol_nombre_key UNIQUE (nombre);


--
-- Name: rol rol_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rol
    ADD CONSTRAINT rol_pkey PRIMARY KEY (id_rol);


--
-- Name: servicio servicio_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.servicio
    ADD CONSTRAINT servicio_nombre_key UNIQUE (nombre);


--
-- Name: servicio servicio_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.servicio
    ADD CONSTRAINT servicio_pkey PRIMARY KEY (id_servicio);


--
-- Name: factura uq_factura_cita; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factura
    ADD CONSTRAINT uq_factura_cita UNIQUE (id_cita);


--
-- Name: horario_medico uq_horario_medico; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.horario_medico
    ADD CONSTRAINT uq_horario_medico UNIQUE (id_medico, dia_semana, hora_inicio, hora_fin);


--
-- Name: medico uq_medico_correo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medico
    ADD CONSTRAINT uq_medico_correo UNIQUE (correo);


--
-- Name: paciente uq_paciente_correo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.paciente
    ADD CONSTRAINT uq_paciente_correo UNIQUE (correo);


--
-- Name: usuario uq_usuario_medico; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT uq_usuario_medico UNIQUE (id_medico);


--
-- Name: usuario usuario_correo_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_correo_key UNIQUE (correo);


--
-- Name: usuario usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id_usuario);


--
-- Name: usuario usuario_usuario_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_usuario_key UNIQUE (usuario);


--
-- Name: idx_auditoria_tabla_fecha; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_auditoria_tabla_fecha ON public.auditoria USING btree (tabla_afectada, fecha_evento);


--
-- Name: idx_auditoria_usuario; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_auditoria_usuario ON public.auditoria USING btree (id_usuario);


--
-- Name: idx_cita_fecha; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cita_fecha ON public.cita USING btree (fecha_cita);


--
-- Name: idx_cita_medico_fecha; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cita_medico_fecha ON public.cita USING btree (id_medico, fecha_cita);


--
-- Name: idx_factura_estado_fecha; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_factura_estado_fecha ON public.factura USING btree (estado, fecha_emision);


--
-- Name: idx_factura_fecha_emision; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_factura_fecha_emision ON public.factura USING btree (fecha_emision);


--
-- Name: idx_factura_paciente; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_factura_paciente ON public.factura USING btree (id_paciente);


--
-- Name: idx_mv_facturacion_mensual_especialidad; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mv_facturacion_mensual_especialidad ON public.mv_facturacion_mensual USING btree (id_especialidad);


--
-- Name: idx_mv_facturacion_mensual_mes; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mv_facturacion_mensual_mes ON public.mv_facturacion_mensual USING btree (mes);


--
-- Name: idx_mv_ranking_medicos_citas; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mv_ranking_medicos_citas ON public.mv_ranking_medicos_trimestral USING btree (citas_atendidas DESC);


--
-- Name: idx_pago_factura; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pago_factura ON public.pago USING btree (id_factura);


--
-- Name: uq_cita_medico_horario_activa; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_cita_medico_horario_activa ON public.cita USING btree (id_medico, fecha_cita, hora_inicio, hora_fin) WHERE ((estado)::text = ANY ((ARRAY['programada'::character varying, 'confirmada'::character varying, 'atendida'::character varying])::text[]));


--
-- Name: uq_mv_facturacion_mensual; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_mv_facturacion_mensual ON public.mv_facturacion_mensual USING btree (mes, id_especialidad);


--
-- Name: uq_mv_ranking_medicos_trimestral; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_mv_ranking_medicos_trimestral ON public.mv_ranking_medicos_trimestral USING btree (id_medico);


--
-- Name: auditoria fk_auditoria_usuario; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auditoria
    ADD CONSTRAINT fk_auditoria_usuario FOREIGN KEY (id_usuario) REFERENCES public.usuario(id_usuario);


--
-- Name: cita fk_cita_medico; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cita
    ADD CONSTRAINT fk_cita_medico FOREIGN KEY (id_medico) REFERENCES public.medico(id_medico);


--
-- Name: cita fk_cita_paciente; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cita
    ADD CONSTRAINT fk_cita_paciente FOREIGN KEY (id_paciente) REFERENCES public.paciente(id_paciente);


--
-- Name: detalle_factura fk_detalle_factura; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_factura
    ADD CONSTRAINT fk_detalle_factura FOREIGN KEY (id_factura) REFERENCES public.factura(id_factura);


--
-- Name: detalle_factura fk_detalle_servicio; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_factura
    ADD CONSTRAINT fk_detalle_servicio FOREIGN KEY (id_servicio) REFERENCES public.servicio(id_servicio);


--
-- Name: factura fk_factura_cita; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factura
    ADD CONSTRAINT fk_factura_cita FOREIGN KEY (id_cita) REFERENCES public.cita(id_cita);


--
-- Name: factura fk_factura_paciente; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factura
    ADD CONSTRAINT fk_factura_paciente FOREIGN KEY (id_paciente) REFERENCES public.paciente(id_paciente);


--
-- Name: factura fk_factura_usuario; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factura
    ADD CONSTRAINT fk_factura_usuario FOREIGN KEY (id_usuario) REFERENCES public.usuario(id_usuario);


--
-- Name: horario_medico fk_horario_medico; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.horario_medico
    ADD CONSTRAINT fk_horario_medico FOREIGN KEY (id_medico) REFERENCES public.medico(id_medico);


--
-- Name: medico fk_medico_especialidad; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medico
    ADD CONSTRAINT fk_medico_especialidad FOREIGN KEY (id_especialidad) REFERENCES public.especialidad(id_especialidad);


--
-- Name: pago fk_pago_factura; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pago
    ADD CONSTRAINT fk_pago_factura FOREIGN KEY (id_factura) REFERENCES public.factura(id_factura);


--
-- Name: pago fk_pago_usuario; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pago
    ADD CONSTRAINT fk_pago_usuario FOREIGN KEY (id_usuario) REFERENCES public.usuario(id_usuario);


--
-- Name: usuario fk_usuario_medico; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT fk_usuario_medico FOREIGN KEY (id_medico) REFERENCES public.medico(id_medico);


--
-- Name: usuario fk_usuario_rol; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT fk_usuario_rol FOREIGN KEY (id_rol) REFERENCES public.rol(id_rol);


--
-- Name: mv_facturacion_mensual; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: postgres
--

REFRESH MATERIALIZED VIEW public.mv_facturacion_mensual;


--
-- Name: mv_ranking_medicos_trimestral; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: postgres
--

REFRESH MATERIALIZED VIEW public.mv_ranking_medicos_trimestral;


--
-- PostgreSQL database dump complete
--

