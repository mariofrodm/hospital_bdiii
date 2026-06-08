// ======================================================
// Proyecto Final Bases de Datos
// Sistema: Clínica Médica Privada
// Motor: MongoDB
// Archivo: 03_pipelines_reportes.js
// Propósito:
// Consultas de aggregation para reportes clínicos.
// ======================================================

use('clinica_privada_mongo');

// ======================================================
// PIPELINE 1
// Top 5 diagnósticos más frecuentes por especialidad
// ======================================================

db.historiales_clinicos.aggregate([
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

// ======================================================
// PIPELINE 2
// Medicamentos más recetados por especialidad
// ======================================================

db.historiales_clinicos.aggregate([
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

// ======================================================
// PIPELINE 3
// Promedio de signos vitales por grupo etario
// ======================================================

db.historiales_clinicos.aggregate([
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

// ======================================================
// PIPELINE 4
// Tiempo promedio entre consultas por paciente
// ======================================================

db.historiales_clinicos.aggregate([
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

// ======================================================
// PIPELINE 5
// Reporte clínico consolidado usando $facet
// ======================================================

db.historiales_clinicos.aggregate([
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