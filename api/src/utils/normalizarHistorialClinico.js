// ======================================================
// Proyecto Final Bases de Datos
// Sistema: Clínica Médica Privada
// Motor: MongoDB / Node.js
// Archivo: normalizarHistorialClinico.js
// Propósito:
// Normalizar y preparar un historial clínico antes de
// insertarlo en MongoDB.
// ======================================================

function normalizarTexto(valor) {
  if (valor === null || valor === undefined) {
    return '';
  }

  return String(valor).trim();
}

function normalizarArray(valor) {
  if (Array.isArray(valor)) {
    return valor;
  }

  return [];
}

function normalizarHistorialClinico(data) {
  if (!data) {
    throw new Error('No se recibieron datos para normalizar el historial clínico.');
  }

  if (!data.id_cita) {
    throw new Error('El historial clínico debe tener id_cita.');
  }

  if (!data.id_paciente) {
    throw new Error('El historial clínico debe tener id_paciente.');
  }

  if (!data.id_medico) {
    throw new Error('El historial clínico debe tener id_medico.');
  }

  if (!data.id_especialidad) {
    throw new Error('El historial clínico debe tener id_especialidad.');
  }

  if (!data.motivo_consulta || normalizarTexto(data.motivo_consulta) === '') {
    throw new Error('El historial clínico debe tener motivo_consulta.');
  }

  return {
    id_cita: Number(data.id_cita),
    id_paciente: Number(data.id_paciente),
    id_medico: Number(data.id_medico),
    id_especialidad: Number(data.id_especialidad),

    especialidad: normalizarTexto(data.especialidad),
    fecha_consulta: new Date(data.fecha_consulta),

    edad_paciente: Number(data.edad_paciente),
    grupo_etario: normalizarTexto(data.grupo_etario),

    motivo_consulta: normalizarTexto(data.motivo_consulta),

    signos_vitales: data.signos_vitales || {},

    diagnosticos: normalizarArray(data.diagnosticos),
    medicamentos: normalizarArray(data.medicamentos),
    examenes_solicitados: normalizarArray(data.examenes_solicitados),

    notas_adicionales: normalizarTexto(data.notas_adicionales),

    datos_especialidad: data.datos_especialidad || {},

    created_at: new Date(),
    updated_at: null
  };
}

module.exports = {
  normalizarHistorialClinico
};
