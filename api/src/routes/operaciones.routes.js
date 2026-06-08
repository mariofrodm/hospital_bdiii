const express = require('express');
const operacionesController = require('../controllers/operaciones.controller');

const router = express.Router();

router.post('/registrar-pago', operacionesController.registrarPago);
router.post('/cancelar-cita', operacionesController.cancelarCita);
router.post('/refresh-materializadas', operacionesController.refreshMaterializadas);

module.exports = router;
