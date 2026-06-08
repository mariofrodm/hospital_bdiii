const express = require('express');
const backupController = require('../controllers/backup.controller');

const router = express.Router();

router.get('/estado', backupController.estado);

module.exports = router;
