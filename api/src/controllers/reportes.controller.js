const reportesModel = require('../models/reportes.model');

async function agendaDiaria(req, res) {
  try {
    const { fecha } = req.query;

    if (!fecha) {
      return res.status(400).json({
        ok: false,
        mensaje: 'Debe enviar la fecha en formato YYYY-MM-DD.'
      });
    }

    const datos = await reportesModel.obtenerAgendaDiaria(fecha);

    res.json({
      ok: true,
      total: datos.length,
      datos
    });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
}

async function facturasPendientes(req, res) {
  try {
    const datos = await reportesModel.obtenerFacturasPendientes();
    res.json({ ok: true, total: datos.length, datos });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
}

async function facturacionMensual(req, res) {
  try {
    const datos = await reportesModel.obtenerFacturacionMensual();
    res.json({ ok: true, total: datos.length, datos });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
}

async function rankingMedicosTrimestral(req, res) {
  try {
    const datos = await reportesModel.obtenerRankingMedicosTrimestral();
    res.json({ ok: true, total: datos.length, datos });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
}

async function saldoPaciente(req, res) {
  try {
    const { id_paciente } = req.params;
    const datos = await reportesModel.obtenerSaldoPaciente(id_paciente);
    res.json({ ok: true, datos });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
}

module.exports = {
  agendaDiaria,
  facturasPendientes,
  facturacionMensual,
  rankingMedicosTrimestral,
  saldoPaciente
};
