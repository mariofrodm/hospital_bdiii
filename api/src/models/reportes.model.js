const pool = require('../config/postgres');

async function obtenerAgendaDiaria(fecha) {
  const resultado = await pool.query(
    `SELECT *
     FROM vw_agenda_diaria
     WHERE fecha_cita = $1
     ORDER BY hora_inicio`,
    [fecha]
  );

  return resultado.rows;
}

async function obtenerFacturasPendientes() {
  const resultado = await pool.query(
    `SELECT *
     FROM vw_facturas_pendientes
     ORDER BY fecha_emision`
  );

  return resultado.rows;
}

async function obtenerFacturacionMensual() {
  const resultado = await pool.query(
    `SELECT *
     FROM mv_facturacion_mensual
     ORDER BY mes, especialidad`
  );

  return resultado.rows;
}

async function obtenerRankingMedicosTrimestral() {
  const resultado = await pool.query(
    `SELECT *
     FROM mv_ranking_medicos_trimestral
     ORDER BY citas_atendidas DESC, monto_facturado DESC`
  );

  return resultado.rows;
}

async function obtenerSaldoPaciente(idPaciente) {
  const resultado = await pool.query(
    `SELECT fn_saldo_paciente($1) AS saldo_paciente`,
    [idPaciente]
  );

  return resultado.rows[0];
}

module.exports = {
  obtenerAgendaDiaria,
  obtenerFacturasPendientes,
  obtenerFacturacionMensual,
  obtenerRankingMedicosTrimestral,
  obtenerSaldoPaciente
};
