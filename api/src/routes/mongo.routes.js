const express = require('express');
const mongoController = require('../controllers/mongo.controller');

const router = express.Router();

router.get('/estado', mongoController.estado);
router.get('/historiales/paciente/:id_paciente', mongoController.historialesPorPaciente);
router.post('/historiales', mongoController.crearHistorial);
router.get('/reportes/diagnosticos-top', mongoController.diagnosticosTop);
router.get('/reportes/medicamentos', mongoController.medicamentos);
router.get('/reportes/signos-vitales', mongoController.signosVitales);
router.get('/reportes/tiempo-consultas', mongoController.tiempoConsultas);
router.get('/reportes/resumen-facet', mongoController.resumenFacet);

module.exports = router;
