const express = require('express');
const reportesController = require('../controllers/reportes.controller');

const router = express.Router();

router.get('/agenda-diaria', reportesController.agendaDiaria);
router.get('/facturas-pendientes', reportesController.facturasPendientes);
router.get('/facturacion-mensual', reportesController.facturacionMensual);
router.get('/ranking-medicos-trimestral', reportesController.rankingMedicosTrimestral);
router.get('/saldo-paciente/:id_paciente', reportesController.saldoPaciente);

module.exports = router;
