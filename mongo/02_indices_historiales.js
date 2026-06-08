// ======================================================
// Proyecto Final Bases de Datos
// Sistema: Clínica Médica Privada
// Motor: MongoDB
// Archivo: 02_indices_historiales.js
// Propósito:
// Crear índices para acelerar consultas clínicas sobre
// la colección historiales_clinicos.
// ======================================================

use('clinica_privada_mongo');

// Índice para consultar el historial clínico completo de un paciente
// ordenado por fecha de consulta.
db.historiales_clinicos.createIndex(
  { id_paciente: 1, fecha_consulta: -1 },
  { name: 'idx_historial_paciente_fecha' }
);

// Índice para consultar atenciones realizadas por médico.
db.historiales_clinicos.createIndex(
  { id_medico: 1, fecha_consulta: -1 },
  { name: 'idx_historial_medico_fecha' }
);

// Índice para reportes agrupados por especialidad.
db.historiales_clinicos.createIndex(
  { id_especialidad: 1 },
  { name: 'idx_historial_especialidad_id' }
);

// Índice por nombre de especialidad para reportes legibles.
db.historiales_clinicos.createIndex(
  { especialidad: 1 },
  { name: 'idx_historial_especialidad_nombre' }
);

// Índice para reportes de diagnósticos frecuentes.
db.historiales_clinicos.createIndex(
  { 'diagnosticos.descripcion': 1 },
  { name: 'idx_historial_diagnostico_descripcion' }
);

// Índice para reportes de medicamentos más recetados.
db.historiales_clinicos.createIndex(
  { 'medicamentos.nombre': 1 },
  { name: 'idx_historial_medicamento_nombre' }
);

// Índice único para asegurar que una cita tenga solo un historial clínico.
db.historiales_clinicos.createIndex(
  { id_cita: 1 },
  { unique: true, name: 'uq_historial_id_cita' }
);

// Verificación de índices creados.
db.historiales_clinicos.getIndexes();