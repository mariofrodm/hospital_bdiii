const express = require('express');
const cors = require('cors');
const pool = require('./config/postgres');

const app = express();

app.use(cors());
app.use(express.json());

app.get('/api/health', async (req, res) => {
  try {
    const resultado = await pool.query('SELECT current_database() AS database, current_user AS usuario, NOW() AS fecha_servidor');
    res.json({
      ok: true,
      mensaje: 'API Clínica Privada funcionando correctamente.',
      postgres: resultado.rows[0],
      mongodb: 'pendiente de integración'
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      mensaje: 'La API inició, pero no pudo conectarse a PostgreSQL.',
      error: error.message
    });
  }
});

app.use((req, res) => {
  res.status(404).json({
    ok: false,
    mensaje: 'Ruta no encontrada.'
  });
});

module.exports = app;
