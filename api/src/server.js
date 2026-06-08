require('dotenv').config();

const app = require('./app');
const conectarMongo = require('./config/mongo');

const PORT = process.env.PORT || 3000;

conectarMongo();

app.listen(PORT, () => {
  console.log(`API Clínica Privada ejecutándose en http://localhost:${PORT}`);
});
