const pool = require('../config/postgres');

async function obtenerResumen() {
  const resultado = await pool.query(
    `SELECT 'especialidades' AS nombre, COUNT(*) AS total FROM especialidad
     UNION ALL
     SELECT 'medicos', COUNT(*) FROM medico
     UNION ALL
     SELECT 'pacientes', COUNT(*) FROM paciente
     UNION ALL
     SELECT 'citas', COUNT(*) FROM cita
     UNION ALL
     SELECT 'facturas', COUNT(*) FROM factura
     UNION ALL
     SELECT 'pagos', COUNT(*) FROM pago
     UNION ALL
     SELECT 'auditoria', COUNT(*) FROM auditoria
     ORDER BY nombre`
  );

  return resultado.rows;
}

async function obtenerEspecialidades() {
  const resultado = await pool.query('SELECT * FROM especialidad ORDER BY id_especialidad');
  return resultado.rows;
}

async function obtenerMedicos() {
  const resultado = await pool.query('SELECT * FROM medico ORDER BY id_medico');
  return resultado.rows;
}

async function obtenerPacientes() {
  const resultado = await pool.query('SELECT * FROM paciente ORDER BY id_paciente');
  return resultado.rows;
}

async function obtenerServicios() {
  const resultado = await pool.query('SELECT * FROM servicio ORDER BY id_servicio');
  return resultado.rows;
}

async function obtenerFacturas() {
  const resultado = await pool.query('SELECT * FROM factura ORDER BY id_factura LIMIT 100');
  return resultado.rows;
}

async function obtenerCitasAtendidas() {
  const resultado = await pool.query(
    `SELECT
        c.id_cita,
        c.id_paciente,
        c.id_medico,
        m.id_especialidad,
        e.nombre AS especialidad,
        c.fecha_cita,
        c.hora_inicio,
        c.hora_fin,
        p.fecha_nacimiento,
        EXTRACT(YEAR FROM AGE(c.fecha_cita, p.fecha_nacimiento))::INTEGER AS edad_paciente
     FROM cita c
     INNER JOIN medico m
        ON c.id_medico = m.id_medico
     INNER JOIN especialidad e
        ON m.id_especialidad = e.id_especialidad
     INNER JOIN paciente p
        ON c.id_paciente = p.id_paciente
     WHERE c.estado = 'atendida'
     ORDER BY c.id_cita
     LIMIT 150`
  );

  return resultado.rows;
}

module.exports = {
  obtenerResumen,
  obtenerEspecialidades,
  obtenerMedicos,
  obtenerPacientes,
  obtenerServicios,
  obtenerFacturas,
  obtenerCitasAtendidas
};
