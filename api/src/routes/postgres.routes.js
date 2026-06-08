const express = require('express');
const postgresController = require('../controllers/postgres.controller');

const router = express.Router();

router.get('/postgres/estado', postgresController.estado);
router.post('/pagos', postgresController.registrarPago);
router.post('/citas/cancelar', postgresController.cancelarCita);
router.get('/reportes/agenda-diaria', postgresController.agendaDiaria);
router.get('/reportes/facturas-pendientes', postgresController.facturasPendientes);
router.get('/reportes/facturacion-mensual', postgresController.facturacionMensual);
router.get('/reportes/ranking-medicos', postgresController.rankingMedicos);
router.get('/reportes/saldo-paciente/:id_paciente', postgresController.saldoPaciente);

module.exports = router;
