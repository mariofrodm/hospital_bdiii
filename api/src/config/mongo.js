const mongoose = require('mongoose');
require('dotenv').config();

async function conectarMongo() {
  if (!process.env.MONGODB_URI || process.env.MONGODB_URI.includes('USUARIO')) {
    console.log('MongoDB no configurado todavía. Se omitió conexión.');
    return;
  }

  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Conexión a MongoDB establecida.');
  } catch (error) {
    console.error('Error conectando a MongoDB:', error.message);
  }
}

module.exports = conectarMongo;
