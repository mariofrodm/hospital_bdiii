function respuestaMongoPendiente(res) {
  return res.json({
    ok: false,
    mensaje: 'MongoDB aún no ha sido integrado. Esta parte será conectada cuando la colección historiales_clinicos esté lista.',
    base_esperada: 'clinica_privada_mongo',
    coleccion_esperada: 'historiales_clinicos',
    responsable: 'Pendiente de entrega por el bloque MongoDB'
  });
}

function estado(req, res) {
  return res.json({
    ok: true,
    integrado: false,
    mensaje: 'La API está preparada para MongoDB, pero la integración queda en pausa hasta recibir los entregables de MongoDB.',
    base_esperada: 'clinica_privada_mongo',
    coleccion_esperada: 'historiales_clinicos',
    endpoints_preparados: [
      '/api/mongo/historiales/paciente/:id_paciente',
      '/api/mongo/reportes/diagnosticos-top',
      '/api/mongo/reportes/medicamentos'
    ]
  });
}

function historialesPorPaciente(req, res) {
  return respuestaMongoPendiente(res);
}

function diagnosticosTop(req, res) {
  return respuestaMongoPendiente(res);
}

function medicamentos(req, res) {
  return respuestaMongoPendiente(res);
}

module.exports = {
  estado,
  historialesPorPaciente,
  diagnosticosTop,
  medicamentos
};
