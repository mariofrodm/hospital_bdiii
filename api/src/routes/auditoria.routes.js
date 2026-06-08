const express = require('express');
const auditoriaController = require('../controllers/auditoria.controller');

const router = express.Router();

router.get('/', auditoriaController.auditoria);
router.get('/resumen', auditoriaController.resumen);
router.get('/accion/:accion', auditoriaController.auditoriaPorAccion);

module.exports = router;
