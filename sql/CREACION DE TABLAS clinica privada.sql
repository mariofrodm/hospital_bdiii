CREATE TABLE especialidad (
    id_especialidad SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    estado VARCHAR(20) NOT NULL DEFAULT 'activo',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    CONSTRAINT chk_especialidad_estado
        CHECK (estado IN ('activo', 'inactivo'))
);

CREATE TABLE rol (
    id_rol SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT,
    estado VARCHAR(20) NOT NULL DEFAULT 'activo',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    CONSTRAINT chk_rol_estado
        CHECK (estado IN ('activo', 'inactivo'))
);

CREATE TABLE servicio (
    id_servicio SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    precio NUMERIC(10,2) NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'activo',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    CONSTRAINT chk_servicio_precio
        CHECK (precio >= 0),
    CONSTRAINT chk_servicio_estado
        CHECK (estado IN ('activo', 'inactivo'))
);

CREATE TABLE paciente (
    id_paciente SERIAL PRIMARY KEY,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    sexo VARCHAR(20) NOT NULL,
    telefono VARCHAR(20),
    correo VARCHAR(150),
    direccion TEXT,
    estado VARCHAR(20) NOT NULL DEFAULT 'activo',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    CONSTRAINT uq_paciente_correo UNIQUE (correo),
    CONSTRAINT chk_paciente_sexo
        CHECK (sexo IN ('masculino', 'femenino', 'otro')),
    CONSTRAINT chk_paciente_estado
        CHECK (estado IN ('activo', 'inactivo'))
);

CREATE TABLE medico (
    id_medico SERIAL PRIMARY KEY,
    id_especialidad INTEGER NOT NULL,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    numero_colegiado VARCHAR(50) NOT NULL UNIQUE,
    telefono VARCHAR(20),
    correo VARCHAR(150),
    estado VARCHAR(20) NOT NULL DEFAULT 'activo',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,

    CONSTRAINT fk_medico_especialidad
        FOREIGN KEY (id_especialidad)
        REFERENCES especialidad(id_especialidad),

    CONSTRAINT uq_medico_correo UNIQUE (correo),

    CONSTRAINT chk_medico_estado
        CHECK (estado IN ('activo', 'inactivo'))
);

CREATE TABLE usuario (
    id_usuario SERIAL PRIMARY KEY,
    id_rol INTEGER NOT NULL,
    id_medico INTEGER,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    usuario VARCHAR(50) NOT NULL UNIQUE,
    correo VARCHAR(150) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'activo',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,

    CONSTRAINT fk_usuario_rol
        FOREIGN KEY (id_rol)
        REFERENCES rol(id_rol),

    CONSTRAINT fk_usuario_medico
        FOREIGN KEY (id_medico)
        REFERENCES medico(id_medico),

    CONSTRAINT uq_usuario_medico UNIQUE (id_medico),

    CONSTRAINT chk_usuario_estado
        CHECK (estado IN ('activo', 'inactivo'))
);

CREATE TABLE horario_medico (
    id_horario SERIAL PRIMARY KEY,
    id_medico INTEGER NOT NULL,
    dia_semana VARCHAR(20) NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'activo',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,

    CONSTRAINT fk_horario_medico
        FOREIGN KEY (id_medico)
        REFERENCES medico(id_medico),

    CONSTRAINT uq_horario_medico
        UNIQUE (id_medico, dia_semana, hora_inicio, hora_fin),

    CONSTRAINT chk_horario_dia
        CHECK (dia_semana IN (
            'lunes',
            'martes',
            'miercoles',
            'jueves',
            'viernes',
            'sabado',
            'domingo'
        )),

    CONSTRAINT chk_horario_horas
        CHECK (hora_fin > hora_inicio),

    CONSTRAINT chk_horario_estado
        CHECK (estado IN ('activo', 'inactivo'))
);

CREATE TABLE cita (
    id_cita SERIAL PRIMARY KEY,
    id_paciente INTEGER NOT NULL,
    id_medico INTEGER NOT NULL,
    fecha_cita DATE NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'programada',
    motivo_cancelacion TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,

    CONSTRAINT fk_cita_paciente
        FOREIGN KEY (id_paciente)
        REFERENCES paciente(id_paciente),

    CONSTRAINT fk_cita_medico
        FOREIGN KEY (id_medico)
        REFERENCES medico(id_medico),

    CONSTRAINT chk_cita_estado
        CHECK (estado IN (
            'programada',
            'confirmada',
            'atendida',
            'cancelada',
            'no_asistio'
        )),

    CONSTRAINT chk_cita_horas
        CHECK (hora_fin > hora_inicio),

    CONSTRAINT chk_cita_motivo_cancelacion
        CHECK (
            estado <> 'cancelada'
            OR motivo_cancelacion IS NOT NULL
        )
); 

CREATE TABLE factura (
    id_factura SERIAL PRIMARY KEY,
    id_paciente INTEGER NOT NULL,
    id_usuario INTEGER NOT NULL,
    id_cita INTEGER,
    fecha_emision TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total NUMERIC(10,2) NOT NULL DEFAULT 0,
    estado VARCHAR(20) NOT NULL DEFAULT 'pendiente',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,

    CONSTRAINT fk_factura_paciente
        FOREIGN KEY (id_paciente)
        REFERENCES paciente(id_paciente),

    CONSTRAINT fk_factura_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario),

    CONSTRAINT fk_factura_cita
        FOREIGN KEY (id_cita)
        REFERENCES cita(id_cita),

    CONSTRAINT uq_factura_cita
        UNIQUE (id_cita),

    CONSTRAINT chk_factura_total
        CHECK (total >= 0),

    CONSTRAINT chk_factura_estado
        CHECK (estado IN (
            'pendiente',
            'pagada_parcial',
            'pagada',
            'anulada'
        ))
);

CREATE TABLE detalle_factura (
    id_detalle_factura SERIAL PRIMARY KEY,
    id_factura INTEGER NOT NULL,
    id_servicio INTEGER NOT NULL,
    cantidad INTEGER NOT NULL,
    precio_unitario NUMERIC(10,2) NOT NULL,
    subtotal NUMERIC(10,2) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,

    CONSTRAINT fk_detalle_factura
        FOREIGN KEY (id_factura)
        REFERENCES factura(id_factura),

    CONSTRAINT fk_detalle_servicio
        FOREIGN KEY (id_servicio)
        REFERENCES servicio(id_servicio),

    CONSTRAINT chk_detalle_cantidad
        CHECK (cantidad > 0),

    CONSTRAINT chk_detalle_precio_unitario
        CHECK (precio_unitario >= 0),

    CONSTRAINT chk_detalle_subtotal
        CHECK (subtotal >= 0)
);

CREATE TABLE pago (
    id_pago SERIAL PRIMARY KEY,
    id_factura INTEGER NOT NULL,
    id_usuario INTEGER NOT NULL,
    fecha_pago TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    monto NUMERIC(10,2) NOT NULL,
    metodo_pago VARCHAR(30) NOT NULL,
    referencia VARCHAR(100),
    estado VARCHAR(20) NOT NULL DEFAULT 'registrado',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,

    CONSTRAINT fk_pago_factura
        FOREIGN KEY (id_factura)
        REFERENCES factura(id_factura),

    CONSTRAINT fk_pago_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario),

    CONSTRAINT chk_pago_monto
        CHECK (monto > 0),

    CONSTRAINT chk_pago_metodo
        CHECK (metodo_pago IN (
            'efectivo',
            'tarjeta',
            'transferencia',
            'cheque'
        )),

    CONSTRAINT chk_pago_estado
        CHECK (estado IN (
            'registrado',
            'anulado'
        ))
);

CREATE TABLE auditoria (
    id_auditoria SERIAL PRIMARY KEY,
    id_usuario INTEGER NOT NULL,
    tabla_afectada VARCHAR(100) NOT NULL,
    id_registro_afectado INTEGER,
    accion VARCHAR(50) NOT NULL,
    descripcion TEXT,
    fecha_evento TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    datos_anteriores JSONB,
    datos_nuevos JSONB,

    CONSTRAINT fk_auditoria_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario),

    CONSTRAINT chk_auditoria_accion
        CHECK (accion IN (
            'INSERT',
            'UPDATE',
            'DELETE',
            'CANCELAR_CITA',
            'REGISTRAR_PAGO',
            'ANULAR_FACTURA'
        ))
);