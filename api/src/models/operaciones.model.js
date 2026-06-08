const pool = require('../config/postgres');

async function registrarPago({ id_factura, id_usuario, monto, metodo_pago, referencia }) {
  await pool.query(
    'CALL sp_registrar_pago($1, $2, $3, $4, $5)',
    [id_factura, id_usuario, monto, metodo_pago, referencia]
  );
}

async function cancelarCita({ id_cita, id_usuario, motivo_cancelacion }) {
  await pool.query(
    'CALL sp_cancelar_cita($1, $2, $3)',
    [id_cita, id_usuario, motivo_cancelacion]
  );
}

async function refrescarMaterializadas() {
  await pool.query('REFRESH MATERIALIZED VIEW mv_facturacion_mensual');
  await pool.query('REFRESH MATERIALIZED VIEW mv_ranking_medicos_trimestral');
}

module.exports = {
  registrarPago,
  cancelarCita,
  refrescarMaterializadas
};
