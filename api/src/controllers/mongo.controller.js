const mongoose = require('mongoose');
const HistorialClinico = require('../models/historialClinico.model');
const pool = require('../config/postgres');
const { normalizarHistorialClinico } = require('../utils/normalizarHistorialClinico');

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
    res.json({
      ok: true,
      coleccion: 'historiales_clinicos',
      documentos: total
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
      .lean();

    res.json(datos);
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
}

async function crearHistorial(req, res) {
  try {
    if (!validarConexion(res)) return;

    const { id_cita } = req.body;
    if (!id_cita) {
      return res.status(400).json({
        ok: false,
        mensaje: 'Debe enviar id_cita en el cuerpo de la petición.'
      });
    }

    const resultado = await pool.query(
      `SELECT
        c.id_cita,
        c.id_paciente,
        c.id_medico,
        m.id_especialidad,
        e.nombre AS especialidad,
        c.fecha_cita,
        c.hora_inicio,
        c.estado,
        p.fecha_nacimiento
      FROM cita c
      INNER JOIN medico m ON c.id_medico = m.id_medico
      INNER JOIN especialidad e ON m.id_especialidad = e.id_especialidad
      INNER JOIN paciente p ON c.id_paciente = p.id_paciente
      WHERE c.id_cita = $1;`,
      [id_cita]
    );

    if (resultado.rows.length === 0) {
      return res.status(404).json({
        ok: false,
        mensaje: `La cita con id_cita ${id_cita} no existe en PostgreSQL.`
      });
    }

    const dbCita = resultado.rows[0];

    if (dbCita.estado !== 'atendida') {
      return res.status(400).json({
        ok: false,
        mensaje: `No se puede registrar el historial. La cita debe estar en estado 'atendida' (estado actual: '${dbCita.estado}').`
      });
    }

    // Calcular edad y grupo etario
    const fechaNac = new Date(dbCita.fecha_nacimiento);
    const fechaCita = new Date(dbCita.fecha_cita);
    let edad = fechaCita.getFullYear() - fechaNac.getFullYear();
    const m = fechaCita.getMonth() - fechaNac.getMonth();
    if (m < 0 || (m === 0 && fechaCita.getDate() < fechaNac.getDate())) {
      edad--;
    }

    let grupoEtario = 'adulto';
    if (edad < 13) {
      grupoEtario = 'niño';
    } else if (edad < 18) {
      grupoEtario = 'adolescente';
    } else if (edad < 60) {
      grupoEtario = 'adulto';
    } else {
      grupoEtario = 'adulto_mayor';
    }

    // Construir objeto para normalizar
    const rawHistorial = {
      id_cita: dbCita.id_cita,
      id_paciente: dbCita.id_paciente,
      id_medico: dbCita.id_medico,
      id_especialidad: dbCita.id_especialidad,
      especialidad: dbCita.especialidad,
      fecha_consulta: dbCita.fecha_cita,
      edad_paciente: edad,
      grupo_etario: grupoEtario,
      motivo_consulta: req.body.motivo_consulta,
      signos_vitales: req.body.signos_vitales,
      diagnosticos: req.body.diagnosticos,
      medicamentos: req.body.medicamentos,
      examenes_solicitados: req.body.examenes_solicitados,
      notas_adicionales: req.body.notas_adicionales,
      datos_especialidad: req.body.datos_especialidad
    };

    const normalized = normalizarHistorialClinico(rawHistorial);
    const nuevoHistorial = new HistorialClinico(normalized);
    const guardado = await nuevoHistorial.save();

    res.status(201).json({
      ok: true,
      mensaje: 'Historial clínico registrado correctamente en MongoDB.',
      datos: guardado
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
      { $sort: { especialidad: 1, cantidad: -1 } },
      {
        $group: {
          _id: '$especialidad',
          diagnosticos: {
            $push: {
              diagnostico: '$diagnostico',
              cantidad: '$cantidad'
            }
          }
        }
      },
      {
        $project: {
          _id: 0,
          especialidad: '$_id',
          diagnosticos: { $slice: ['$diagnosticos', 5] }
        }
      },
      { $sort: { especialidad: 1 } }
    ]);

    res.json(datos);
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
        $group: {
          _id: '$_id.especialidad',
          total_prescripciones: { $sum: '$cantidad' },
          medicamentos: {
            $push: {
              medicamento: '$_id.medicamento',
              cantidad: '$cantidad'
            }
          }
        }
      },
      { $unwind: '$medicamentos' },
      {
        $project: {
          _id: 0,
          especialidad: '$_id',
          medicamento: '$medicamentos.medicamento',
          cantidad: '$medicamentos.cantidad',
          total_prescripciones: 1,
          porcentaje: {
            $round: [
              {
                $multiply: [
                  { $divide: ['$medicamentos.cantidad', '$total_prescripciones'] },
                  100
                ]
              },
              2
            ]
          }
        }
      },
      { $sort: { especialidad: 1, cantidad: -1 } }
    ]);

    res.json(datos);
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

    res.json(datos);
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
}

async function tiempoConsultas(req, res) {
  try {
    if (!validarConexion(res)) return;

    const datos = await HistorialClinico.aggregate([
      {
        $addFields: {
          fecha_consulta_date: {
            $toDate: "$fecha_consulta"
          }
        }
      },
      {
        $setWindowFields: {
          partitionBy: "$id_paciente",
          sortBy: { fecha_consulta_date: 1 },
          output: {
            fecha_consulta_anterior: {
              $shift: {
                output: "$fecha_consulta_date",
                by: -1
              }
            }
          }
        }
      },
      {
        $match: {
          fecha_consulta_anterior: { $ne: null }
        }
      },
      {
        $project: {
          id_paciente: 1,
          dias_entre_consultas: {
            $dateDiff: {
              startDate: "$fecha_consulta_anterior",
              endDate: "$fecha_consulta_date",
              unit: "day"
            }
          }
        }
      },
      {
        $group: {
          _id: "$id_paciente",
          cantidad_intervalos: { $sum: 1 },
          promedio_dias_entre_consultas: {
            $avg: "$dias_entre_consultas"
          }
        }
      },
      {
        $project: {
          _id: 0,
          id_paciente: "$_id",
          cantidad_intervalos: 1,
          promedio_dias_entre_consultas: {
            $round: ["$promedio_dias_entre_consultas", 2]
          }
        }
      },
      {
        $sort: {
          promedio_dias_entre_consultas: 1
        }
      }
    ]);

    res.json(datos);
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
            { $unwind: "$diagnosticos" },
            {
              $group: {
                _id: "$diagnosticos.descripcion",
                cantidad: { $sum: 1 }
              }
            },
            { $sort: { cantidad: -1 } },
            { $limit: 5 }
          ],

          medicamentos_frecuentes: [
            { $unwind: "$medicamentos" },
            {
              $group: {
                _id: "$medicamentos.nombre",
                cantidad: { $sum: 1 }
              }
            },
            { $sort: { cantidad: -1 } },
            { $limit: 5 }
          ],

          signos_vitales_generales: [
            {
              $group: {
                _id: null,
                total_historiales: { $sum: 1 },
                promedio_presion_sistolica: { $avg: "$signos_vitales.presion_sistolica" },
                promedio_presion_diastolica: { $avg: "$signos_vitales.presion_diastolica" },
                promedio_frecuencia_cardiaca: { $avg: "$signos_vitales.frecuencia_cardiaca" },
                promedio_temperatura: { $avg: "$signos_vitales.temperatura" }
              }
            },
            {
              $project: {
                _id: 0,
                total_historiales: 1,
                promedio_presion_sistolica: { $round: ["$promedio_presion_sistolica", 2] },
                promedio_presion_diastolica: { $round: ["$promedio_presion_diastolica", 2] },
                promedio_frecuencia_cardiaca: { $round: ["$promedio_frecuencia_cardiaca", 2] },
                promedio_temperatura: { $round: ["$promedio_temperatura", 2] }
              }
            }
          ]
        }
      }
    ]);

    res.json(datos);
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
}

module.exports = {
  estado,
  historialesPorPaciente,
  crearHistorial,
  diagnosticosTop,
  medicamentos,
  signosVitales,
  tiempoConsultas,
  resumenFacet
};
