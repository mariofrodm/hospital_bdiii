const operacionesModel = require('../models/operaciones.model');

async function registrarPago(req, res) {
  try {
    const { id_factura, id_usuario, monto, metodo_pago, referencia } = req.body;

    if (!id_factura || !id_usuario || !monto || !metodo_pago) {
      return res.status(400).json({
        ok: false,
        mensaje: 'Debe enviar id_factura, id_usuario, monto y metodo_pago.'
      });
    }

    await operacionesModel.registrarPago({
      id_factura,
      id_usuario,
      monto,
      metodo_pago,
      referencia: referencia || 'Pago desde API'
    });

    res.json({
      ok: true,
      mensaje: 'Pago registrado correctamente.'
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

    await operacionesModel.cancelarCita({
      id_cita,
      id_usuario,
      motivo_cancelacion
    });

    res.json({
      ok: true,
      mensaje: 'Cita cancelada correctamente.'
    });
  } catch (error) {
    res.status(400).json({
      ok: false,
      error: error.message
    });
  }
}

async function refreshMaterializadas(req, res) {
  try {
    await operacionesModel.refrescarMaterializadas();

    res.json({
      ok: true,
      mensaje: 'Vistas materializadas refrescadas correctamente.'
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      error: error.message
    });
  }
}

module.exports = {
  registrarPago,
  cancelarCita,
  refreshMaterializadas
};
