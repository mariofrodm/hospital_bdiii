const mongoose = require('mongoose');

const historialClinicoSchema = new mongoose.Schema(
  {},
  {
    collection: 'historiales_clinicos',
    strict: false,
    versionKey: false
  }
);

module.exports = mongoose.models.HistorialClinico || mongoose.model('HistorialClinico', historialClinicoSchema);
