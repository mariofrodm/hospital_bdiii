const express = require('express');
const mongoController = require('../controllers/mongo.controller');

const router = express.Router();

router.get('/estado', mongoController.estado);
router.get('/historiales/paciente/:id_paciente', mongoController.historialesPorPaciente);
router.get('/reportes/diagnosticos-top', mongoController.diagnosticosTop);
router.get('/reportes/medicamentos', mongoController.medicamentos);

module.exports = router;
