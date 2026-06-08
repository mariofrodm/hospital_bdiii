const express = require('express');
const catalogosController = require('../controllers/catalogos.controller');

const router = express.Router();

router.get('/resumen', catalogosController.resumen);
router.get('/especialidades', catalogosController.especialidades);
router.get('/medicos', catalogosController.medicos);
router.get('/pacientes', catalogosController.pacientes);
router.get('/servicios', catalogosController.servicios);
router.get('/facturas', catalogosController.facturas);
router.get('/citas-atendidas', catalogosController.citasAtendidas);

module.exports = router;
