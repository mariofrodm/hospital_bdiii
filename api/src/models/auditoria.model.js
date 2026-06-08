const pool = require('../config/postgres');

async function obtenerAuditoria() {
  const resultado = await pool.query(
    `SELECT *
     FROM auditoria
     ORDER BY fecha_evento DESC
     LIMIT 100`
  );

  return resultado.rows;
}

async function obtenerAuditoriaPorAccion(accion) {
  const resultado = await pool.query(
    `SELECT *
     FROM auditoria
     WHERE accion = $1
     ORDER BY fecha_evento DESC
     LIMIT 100`,
    [accion]
  );

  return resultado.rows;
}

async function obtenerResumenAuditoria() {
  const resultado = await pool.query(
    `SELECT accion, COUNT(*) AS total
     FROM auditoria
     GROUP BY accion
     ORDER BY accion`
  );

  return resultado.rows;
}

module.exports = {
  obtenerAuditoria,
  obtenerAuditoriaPorAccion,
  obtenerResumenAuditoria
};
