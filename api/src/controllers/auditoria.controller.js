const auditoriaModel = require('../models/auditoria.model');

async function auditoria(req, res) {
  try {
    const datos = await auditoriaModel.obtenerAuditoria();
    res.json({ ok: true, total: datos.length, datos });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
}

async function auditoriaPorAccion(req, res) {
  try {
    const { accion } = req.params;
    const datos = await auditoriaModel.obtenerAuditoriaPorAccion(accion);
    res.json({ ok: true, total: datos.length, datos });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
}

async function resumen(req, res) {
  try {
    const datos = await auditoriaModel.obtenerResumenAuditoria();
    res.json({ ok: true, total: datos.length, datos });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
}

module.exports = {
  auditoria,
  auditoriaPorAccion,
  resumen
};
