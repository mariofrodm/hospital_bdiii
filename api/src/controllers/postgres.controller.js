const pool = require('../config/postgres');

async function estado(req, res) {
  try {
    const resultado = await pool.query('SELECT NOW() AS fecha_servidor;');
    res.json({
      ok: true,
      fecha_servidor: resultado.rows[0].fecha_servidor
    });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
}

async function registrarPago(req, res) {
  try {
    const { id_factura, id_usuario, monto, metodo_pago, observacion } = req.body;
    if (!id_factura || !id_usuario || !monto || !metodo_pago) {
      return res.status(400).json({
        ok: false,
        mensaje: 'Debe enviar id_factura, id_usuario, monto y metodo_pago.'
      });
    }
    await pool.query(
      'CALL sp_registrar_pago($1, $2, $3, $4, $5);',
      [id_factura, id_usuario, monto, metodo_pago, observacion || 'Pago desde API']
    );
    res.json({
      ok: true,
      mensaje: 'Pago registrado correctamente'
    });
  } catch (error) {
    res.status(400).json({
      ok: false,
      error: error.message
    });
  }
}

async function cancelarCita(req, res) {
  try {
    const { id_cita, id_usuario, motivo_cancelacion } = req.body;
    if (!id_cita || !id_usuario || !motivo_cancelacion) {
      return res.status(400).json({
        ok: false,
        mensaje: 'Debe enviar id_cita, id_usuario y motivo_cancelacion.'
      });
    }
    await pool.query(
      'CALL sp_cancelar_cita($1, $2, $3);',
      [id_cita, id_usuario, motivo_cancelacion]
    );
    res.json({
      ok: true,
      mensaje: 'Cita cancelada correctamente'
    });
  } catch (error) {
    res.status(400).json({
      ok: false,
      error: error.message
    });
  }
}

async function agendaDiaria(req, res) {
  try {
    const { fecha } = req.query;
    if (!fecha) {
      return res.status(400).json({
        ok: false,
        mensaje: 'Debe enviar la fecha en formato YYYY-MM-DD.'
      });
    }
    const resultado = await pool.query(
      `SELECT * FROM vw_agenda_diaria WHERE fecha_cita = $1 ORDER BY hora_inicio;`,
      [fecha]
    );
    res.json({
      ok: true,
      total: resultado.rows.length,
      datos: resultado.rows
    });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
}

async function facturasPendientes(req, res) {
  try {
    const resultado = await pool.query(
      `SELECT * FROM vw_facturas_pendientes ORDER BY fecha_emision;`
    );
    res.json({
      ok: true,
      total: resultado.rows.length,
      datos: resultado.rows
    });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
}

async function facturacionMensual(req, res) {
  try {
    const resultado = await pool.query(
      `SELECT * FROM mv_facturacion_mensual ORDER BY mes, especialidad;`
    );
    res.json({
      ok: true,
      total: resultado.rows.length,
      datos: resultado.rows
    });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
}

async function rankingMedicos(req, res) {
  try {
    const resultado = await pool.query(
      `SELECT * FROM mv_ranking_medicos_trimestral ORDER BY citas_atendidas DESC, monto_facturado DESC;`
    );
    res.json({
      ok: true,
      total: resultado.rows.length,
      datos: resultado.rows
    });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
}

async function saldoPaciente(req, res) {
  try {
    const { id_paciente } = req.params;
    const resultado = await pool.query(
      `SELECT fn_saldo_paciente($1) AS saldo_paciente;`,
      [id_paciente]
    );
    res.json({
      ok: true,
      datos: resultado.rows[0]
    });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
}

module.exports = {
  estado,
  registrarPago,
  cancelarCita,
  agendaDiaria,
  facturasPendientes,
  facturacionMensual,
  rankingMedicos,
  saldoPaciente
};
