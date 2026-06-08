const mongoose = require('mongoose');
const HistorialClinico = require('../models/historialClinico.model');

function mongoConectado() {
  return mongoose.connection.readyState === 1;
}

function validarConexion(res) {
  if (!mongoConectado()) {
    res.status(503).json({
      ok: false,
      mensaje: 'MongoDB no está conectado. Revise MONGODB_URI en api/.env.'
    });
    return false;
  }

  return true;
}

async function estado(req, res) {
  try {
    if (!validarConexion(res)) return;

    const total = await HistorialClinico.countDocuments();
    const indices = await HistorialClinico.collection.indexes();

    res.json({
      ok: true,
      integrado: true,
      mensaje: 'MongoDB integrado correctamente con la API.',
      base: mongoose.connection.db.databaseName,
      coleccion: 'historiales_clinicos',
      documentos: total,
      indices: indices.length
    });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
}

async function historialesPorPaciente(req, res) {
  try {
    if (!validarConexion(res)) return;

    const idPaciente = Number(req.params.id_paciente);

    const datos = await HistorialClinico
      .find({ id_paciente: idPaciente })
      .sort({ fecha_consulta: -1 })
      .limit(20)
      .lean();

    res.json({
      ok: true,
      total: datos.length,
      datos
    });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
}

async function diagnosticosTop(req, res) {
  try {
    if (!validarConexion(res)) return;

    const datos = await HistorialClinico.aggregate([
      { $unwind: '$diagnosticos' },
      {
        $group: {
          _id: {
            especialidad: '$especialidad',
            diagnostico: '$diagnosticos.descripcion'
          },
          cantidad: { $sum: 1 }
        }
      },
      {
        $project: {
          _id: 0,
          especialidad: '$_id.especialidad',
          diagnostico: '$_id.diagnostico',
          cantidad: 1
        }
      },
      { $sort: { cantidad: -1, especialidad: 1 } },
      { $limit: 20 }
    ]);

    res.json({ ok: true, total: datos.length, datos });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
}

async function medicamentos(req, res) {
  try {
    if (!validarConexion(res)) return;

    const datos = await HistorialClinico.aggregate([
      { $unwind: '$medicamentos' },
      {
        $group: {
          _id: {
            especialidad: '$especialidad',
            medicamento: '$medicamentos.nombre'
          },
          cantidad: { $sum: 1 }
        }
      },
      {
        $project: {
          _id: 0,
          especialidad: '$_id.especialidad',
          medicamento: '$_id.medicamento',
          cantidad: 1
        }
      },
      { $sort: { cantidad: -1, especialidad: 1 } },
      { $limit: 20 }
    ]);

    res.json({ ok: true, total: datos.length, datos });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
}

async function signosVitales(req, res) {
  try {
    if (!validarConexion(res)) return;

    const datos = await HistorialClinico.aggregate([
      {
        $group: {
          _id: '$grupo_etario',
          cantidad_consultas: { $sum: 1 },
          promedio_presion_sistolica: { $avg: '$signos_vitales.presion_sistolica' },
          promedio_presion_diastolica: { $avg: '$signos_vitales.presion_diastolica' },
          promedio_frecuencia_cardiaca: { $avg: '$signos_vitales.frecuencia_cardiaca' },
          promedio_temperatura: { $avg: '$signos_vitales.temperatura' },
          promedio_peso_kg: { $avg: '$signos_vitales.peso_kg' }
        }
      },
      {
        $project: {
          _id: 0,
          grupo_etario: '$_id',
          cantidad_consultas: 1,
          promedio_presion_sistolica: { $round: ['$promedio_presion_sistolica', 2] },
          promedio_presion_diastolica: { $round: ['$promedio_presion_diastolica', 2] },
          promedio_frecuencia_cardiaca: { $round: ['$promedio_frecuencia_cardiaca', 2] },
          promedio_temperatura: { $round: ['$promedio_temperatura', 2] },
          promedio_peso_kg: { $round: ['$promedio_peso_kg', 2] }
        }
      },
      { $sort: { grupo_etario: 1 } }
    ]);

    res.json({ ok: true, total: datos.length, datos });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
}

async function tiempoConsultas(req, res) {
  try {
    if (!validarConexion(res)) return;

    const datos = await HistorialClinico.aggregate([
      { $sort: { id_paciente: 1, fecha_consulta: 1 } },
      {
        $setWindowFields: {
          partitionBy: '$id_paciente',
          sortBy: { fecha_consulta: 1 },
          output: {
            consulta_anterior: {
              $shift: {
                output: '$fecha_consulta',
                by: -1
              }
            }
          }
        }
      },
      {
        $addFields: {
          dias_entre_consultas: {
            $dateDiff: {
              startDate: { $toDate: '$consulta_anterior' },
              endDate: { $toDate: '$fecha_consulta' },
              unit: 'day'
            }
          }
        }
      },
      { $match: { dias_entre_consultas: { $ne: null } } },
      {
        $group: {
          _id: '$id_paciente',
          cantidad_intervalos: { $sum: 1 },
          promedio_dias_entre_consultas: { $avg: '$dias_entre_consultas' }
        }
      },
      {
        $project: {
          _id: 0,
          id_paciente: '$_id',
          cantidad_intervalos: 1,
          promedio_dias_entre_consultas: { $round: ['$promedio_dias_entre_consultas', 2] }
        }
      },
      { $sort: { promedio_dias_entre_consultas: -1 } },
      { $limit: 20 }
    ]);

    res.json({ ok: true, total: datos.length, datos });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
}

async function resumenFacet(req, res) {
  try {
    if (!validarConexion(res)) return;

    const datos = await HistorialClinico.aggregate([
      {
        $facet: {
          diagnosticos_frecuentes: [
            { $unwind: '$diagnosticos' },
            { $group: { _id: '$diagnosticos.descripcion', cantidad: { $sum: 1 } } },
            { $sort: { cantidad: -1 } },
            { $limit: 5 }
          ],
          medicamentos_frecuentes: [
            { $unwind: '$medicamentos' },
            { $group: { _id: '$medicamentos.nombre', cantidad: { $sum: 1 } } },
            { $sort: { cantidad: -1 } },
            { $limit: 5 }
          ],
          signos_vitales_generales: [
            {
              $group: {
                _id: null,
                total_historiales: { $sum: 1 },
                promedio_presion_sistolica: { $avg: '$signos_vitales.presion_sistolica' },
                promedio_presion_diastolica: { $avg: '$signos_vitales.presion_diastolica' },
                promedio_frecuencia_cardiaca: { $avg: '$signos_vitales.frecuencia_cardiaca' },
                promedio_temperatura: { $avg: '$signos_vitales.temperatura' }
              }
            },
            {
              $project: {
                _id: 0,
                total_historiales: 1,
                promedio_presion_sistolica: { $round: ['$promedio_presion_sistolica', 2] },
                promedio_presion_diastolica: { $round: ['$promedio_presion_diastolica', 2] },
                promedio_frecuencia_cardiaca: { $round: ['$promedio_frecuencia_cardiaca', 2] },
                promedio_temperatura: { $round: ['$promedio_temperatura', 2] }
              }
            }
          ]
        }
      }
    ]);

    res.json({ ok: true, datos: datos[0] });
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
}

module.exports = {
  estado,
  historialesPorPaciente,
  diagnosticosTop,
  medicamentos,
  signosVitales,
  tiempoConsultas,
  resumenFacet
};
