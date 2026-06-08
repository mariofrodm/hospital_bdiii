# Resultados de Pruebas - Módulo MongoDB

## 1. Fecha de Validación
* **Fecha:** 2026-06-08

## 2. Comando Usado para Importar JSON
```bash
mongoimport --uri "mongodb://localhost:27017/clinica_privada_mongo" --collection historiales_clinicos --file mongo/historiales_clinicos.json --jsonArray --drop
```

## 3. Conteo de Documentos
* **Total de documentos en `historiales_clinicos`:** 150

## 4. Lista de Índices
Se verificó la existencia de 8 índices (incluyendo `_id_`):
```json
[
  {
    "v": 2,
    "key": { "_id": 1 },
    "name": "_id_"
  },
  {
    "v": 2,
    "key": { "id_paciente": 1, "fecha_consulta": -1 },
    "name": "idx_historial_paciente_fecha"
  },
  {
    "v": 2,
    "key": { "id_medico": 1, "fecha_consulta": -1 },
    "name": "idx_historial_medico_fecha"
  },
  {
    "v": 2,
    "key": { "id_especialidad": 1 },
    "name": "idx_historial_especialidad_id"
  },
  {
    "v": 2,
    "key": { "especialidad": 1 },
    "name": "idx_historial_especialidad_nombre"
  },
  {
    "v": 2,
    "key": { "diagnosticos.descripcion": 1 },
    "name": "idx_historial_diagnostico_descripcion"
  },
  {
    "v": 2,
    "key": { "medicamentos.nombre": 1 },
    "name": "idx_historial_medicamento_nombre"
  },
  {
    "v": 2,
    "key": { "id_cita": 1 },
    "name": "uq_historial_id_cita",
    "unique": true
  }
]
```

## 5. Resultado Breve de Pipeline 1
**Top 5 diagnósticos más frecuentes por especialidad:**
* **Cardiología:** Angina de pecho (9), Dolor torácico (6), Hipertensión esencial (6), Insuficiencia cardiaca (5), Arritmia cardiaca (4).
* **Dermatología:** Dermatitis (7), Micosis superficial (6), Psoriasis (6), Acné (6), Urticaria (5).
* **Medicina General:** Fiebre no especificada (7), Dolor lumbar (7), Gastritis (6), Cefalea (6), Resfriado común (5).
* **Pediatría:** Asma pediátrica (7), Fiebre (7), Dermatitis atópica (6), Infección aguda de vías respiratorias superiores (5), Gastroenteritis infecciosa (5).
* **Traumatología:** Esguince de tobillo (11), Dolor articular (5), Contusión de rodilla (5), Fractura de antebrazo (5), Dolor de espalda (3).

## 6. Resultado Breve de Pipeline 2
**Medicamentos más recetados por especialidad (Muestra):**
* **Cardiología:** Aspirina (12 - 27.91%), Nitroglicerina (8 - 18.6%), Amlodipino (5 - 11.63%), Losartán (5 - 11.63%).
* **Dermatología:** Cetirizina (10 - 21.74%), Clindamicina tópica (6 - 13.04%), Calcipotriol (6 - 13.04%).
* **Medicina General:** Acetaminofén (14 - 29.79%), Ibuprofeno (10 - 21.28%), Metocarbamol (6 - 12.77%).

## 7. Resultado Breve de Pipeline 3
**Promedio de signos vitales por grupo etario:**
* **Adolescente (10 consultas):** Presión Sistólica: 104.60, Diastólica: 70.40, Frec. Cardiaca: 83.40, Temp: 37.58°C, Peso: 44.86 kg.
* **Adulto (81 consultas):** Presión Sistólica: 120.37, Diastólica: 77.42, Frec. Cardiaca: 79.59, Temp: 37.18°C, Peso: 72.56 kg.
* **Adulto Mayor (49 consultas):** Presión Sistólica: 121.20, Diastólica: 75.80, Frec. Cardiaca: 80.02, Temp: 37.07°C, Peso: 73.78 kg.
* **Niño (10 consultas):** Presión Sistólica: 108.90, Diastólica: 72.20, Frec. Cardiaca: 86.80, Temp: 37.25°C, Peso: 61.63 kg.

## 8. Resultado Breve de Pipeline 4
**Tiempo promedio entre consultas por paciente:**
* Los pacientes muestran intervalos consistentes entre consultas, con un promedio general alrededor de 5 a 5.25 días para la mayoría de los casos analizados (ej. paciente 30: promedio de 5.0 días con 3 intervalos; paciente 27: promedio de 5.25 días con 4 intervalos).

## 9. Resultado Breve de Pipeline 5 con `$facet`
**Reporte clínico consolidado:**
* **Diagnósticos Frecuentes:** Esguince de tobillo (11), Angina de pecho (9), Fiebre no especificada (7), Fiebre (7), Dolor lumbar (7).
* **Medicamentos Frecuentes:** Ibuprofeno (25), Acetaminofén (22), Loratadina (15), Diclofenaco gel (15), Naproxeno (12).
* **Signos Vitales Generales:**
  * Total de Historiales: 150
  * Promedio Presión Sistólica: 118.83
  * Promedio Presión Diastolica: 76.07
  * Promedio Frecuencia Cardiaca: 80.47
  * Promedio Temperatura: 37.18°C

## 10. Dictamen
**MongoDB aprobado localmente.**
