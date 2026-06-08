# Sistema de Clínica Médica Privada - Proyecto Final

Este es el repositorio del proyecto final para el curso de **Bases de Datos III**. El proyecto consiste en el diseño, implementación e integración de un sistema de base de datos híbrido (SQL y NoSQL) para gestionar operaciones clínicas y financieras.

---

## 1. Descripción del Proyecto
El sistema gestiona la información de pacientes, médicos, especialidades, programación de citas, facturación y pagos de forma relacional y estructurada. A su vez, gestiona los historiales clínicos de los pacientes en un motor de base de datos orientado a documentos para brindar flexibilidad en la captura de datos diagnósticos y clínicos según la especialidad del médico.

## 2. Stack Tecnológico
- **Base de Datos Relacional:** PostgreSQL 16+
- **Base de Datos No Relacional:** MongoDB 8.0+
- **Backend:** Node.js, Express.js (conexión directa sin ORMs, utilizando los drivers `pg` y `mongoose`)
- **Gestor de Servidor:** Nodemon (para desarrollo)

---

## 3. Estructura de Carpetas Principal
```txt
/ (Raíz del Proyecto)
├── api/                             # Backend en Node.js/Express
│   ├── src/
│   │   ├── config/                  # Conexiones a BD (postgres.js, mongodb.js)
│   │   ├── controllers/             # Controladores (postgres.controller.js, mongo.controller.js)
│   │   ├── routes/                  # Definición de rutas (postgres.routes.js, mongo.routes.js)
│   │   └── utils/                   # Normalización de historiales clínicos
│   ├── .env.example                 # Variables de entorno de ejemplo
│   ├── package.json                 # Dependencias y scripts de ejecución
│   └── README_API.md                # Guía de pruebas curl y API
├── backup/                          # Respaldos y scripts automáticos
│   ├── full/                        # Archivos de respaldo físico (.backup)
│   ├── logs/                        # Logs de ejecución del backup
│   └── backup_full_postgres.sh      # Script de respaldo automatizado
├── docs/                            # Documentación técnica del proyecto
│   ├── bitacora_uso_ia.md           # Bitácora de trabajo e IA
│   ├── decisiones_diseno.md         # Documento de decisiones de diseño de la BD
│   ├── estrategia_respaldo.md       # Estrategias de backup y restauración
│   └── reporte_performance.md       # Análisis de performance (EXPLAIN ANALYZE)
├── mongo/                           # Módulo NoSQL (MongoDB)
│   ├── 01_crear_coleccion.js        # Script de inicialización de colecciones
│   ├── 02_indices_historiales.js    # Script para generar índices optimizados
│   ├── 03_pipelines_reportes.js     # Pipelines de agregación para reportes
│   ├── historiales_clinicos.json    # Datos clínicos iniciales en JSON
│   ├── resultados_pruebas_mongo.md  # Evidencia de ejecución de MongoDB local
│   └── normalizarHistorialClinico.js # Utilidad original de normalización
└── sql/                             # Módulo SQL (PostgreSQL)
```

---

## 4. Cómo Restaurar PostgreSQL
Para restaurar la base de datos relacional desde el archivo de backup en una instancia limpia:

1. **Crear la base de datos:**
   ```bash
   createdb -h localhost -U postgres clinica_privada_db
   ```
2. **Restaurar el archivo de backup:**
   ```bash
   pg_restore -h localhost -U postgres -d clinica_privada_db backup/full/clinica_privada_db_full_*.backup
   ```

## 5. Cómo Importar Datos en MongoDB
Para realizar la importación masiva del archivo JSON en MongoDB local:
```bash
mongoimport --uri "mongodb://localhost:27017/clinica_privada_mongo" --collection historiales_clinicos --file mongo/historiales_clinicos.json --jsonArray --drop
```

## 6. Cómo Ejecutar Índices en MongoDB
Para aplicar los índices optimizados a la colección de historiales clínicos:
```bash
mongosh "mongodb://localhost:27017/clinica_privada_mongo" < mongo/02_indices_historiales.js
```

## 7. Cómo Ejecutar Pipelines en MongoDB
Para ejecutar y probar los 5 pipelines de agregación directamente desde la terminal de mongo:
```bash
mongosh "mongodb://localhost:27017/clinica_privada_mongo" < mongo/03_pipelines_reportes.js
```

---

## 8. Cómo Levantar la API
1. Dirígete a la carpeta `api/`:
   ```bash
   cd api
   ```
2. Crea tu archivo de variables de entorno `.env` copiando el ejemplo:
   ```bash
   cp .env.example .env
   ```
   *Edita el `.env` con las credenciales locales de tu base de datos.*
3. Inicia el servidor de desarrollo:
   ```bash
   npm run dev
   ```

---

## 9. Endpoints Principales

### Endpoints PostgreSQL
- `GET /api/postgres/estado` -> Comprobación de salud y fecha del servidor.
- `POST /api/pagos` -> Registrar pago de factura (SP).
- `POST /api/citas/cancelar` -> Cancelar una cita médica (SP).
- `GET /api/reportes/agenda-diaria?fecha=YYYY-MM-DD` -> Consulta de agenda (Vista).
- `GET /api/reportes/facturas-pendientes` -> Facturas impagas (Vista).
- `GET /api/reportes/facturacion-mensual` -> Resumen financiero (Vista Materializada).
- `GET /api/reportes/ranking-medicos` -> Ranking trimestral (Vista Materializada).
- `GET /api/reportes/saldo-paciente/:id_paciente` -> Saldo del paciente (Función).

### Endpoints MongoDB
- `GET /api/mongo/estado` -> Conteo de documentos de historiales.
- `GET /api/mongo/historiales/paciente/:id_paciente` -> Historiales del paciente.
- `POST /api/mongo/historiales` -> Inserta historial clínico previo chequeo de cita atendida en PostgreSQL.
- `GET /api/mongo/reportes/diagnosticos-top` -> Pipeline 1 (Top Diagnósticos).
- `GET /api/mongo/reportes/medicamentos` -> Pipeline 2 (Top Medicamentos).
- `GET /api/mongo/reportes/signos-vitales` -> Pipeline 3 (Promedio Signos).
- `GET /api/mongo/reportes/tiempo-consultas` -> Pipeline 4 (Frecuencia de consultas).
- `GET /api/mongo/reportes/resumen-facet` -> Pipeline 5 (Reporte $facet).

---

## 10. Cómo Ejecutar el Backup Automático de PostgreSQL
1. Dale permisos de ejecución al script si aún no los tiene:
   ```bash
   chmod +x backup/backup_full_postgres.sh
   ```
2. Ejecuta el script:
   ```bash
   PGPASSWORD=postgres backup/backup_full_postgres.sh
   ```
*Nota: Reemplaza `postgres` con tu contraseña real de PostgreSQL en la terminal.*

## 11. Cómo Validar que Todo Funciona Correctamente
1. Asegúrate de levantar los servicios locales de PostgreSQL y MongoDB en sus puertos estándar (`5432` y `27017`).
2. Verifica la salud global y conectividad de ambos motores consumiendo el endpoint de la API:
   ```bash
   curl -s http://localhost:3000/api/health
   ```
   *Deberías recibir un JSON con `"ok": true` indicando la correcta integración de PostgreSQL y MongoDB.*
