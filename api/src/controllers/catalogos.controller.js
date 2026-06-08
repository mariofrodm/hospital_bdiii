const catalogosModel = require('../models/catalogos.model');

async function responderConsulta(res, consulta) {
  try {
    const datos = await consulta();
    res.json({ ok: true, total: datos.length, datos });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
}

function resumen(req, res) {
  return responderConsulta(res, catalogosModel.obtenerResumen);
}

function especialidades(req, res) {
  return responderConsulta(res, catalogosModel.obtenerEspecialidades);
}

function medicos(req, res) {
  return responderConsulta(res, catalogosModel.obtenerMedicos);
}

function pacientes(req, res) {
  return responderConsulta(res, catalogosModel.obtenerPacientes);
}

function servicios(req, res) {
  return responderConsulta(res, catalogosModel.obtenerServicios);
}

function facturas(req, res) {
  return responderConsulta(res, catalogosModel.obtenerFacturas);
}

function citasAtendidas(req, res) {
  return responderConsulta(res, catalogosModel.obtenerCitasAtendidas);
}

module.exports = {
  resumen,
  especialidades,
  medicos,
  pacientes,
  servicios,
  facturas,
  citasAtendidas
};
