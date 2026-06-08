# MongoDB — Clínica Médica Privada

## 1. Propósito

Esta carpeta contiene los archivos necesarios para crear, poblar, consultar y documentar la parte MongoDB del proyecto final de Bases de Datos.

MongoDB se utiliza para almacenar los historiales clínicos flexibles de la clínica médica privada.

La información transaccional, financiera y estructurada se mantiene en PostgreSQL. MongoDB almacena únicamente la parte clínica variable.

---

## 2. Base de datos y colección

Base de datos MongoDB:

clinica_privada_mongo

Colección principal:

historiales_clinicos

Cada documento representa una consulta médica atendida.

## 3. Archivos incluidos

01_crear_coleccion.js
02_indices_historiales.js
03_pipelines_reportes.js
normalizarHistorialClinico.js
generar_historiales.py
citas_atendidas_mongo.csv
historiales_clinicos.json
README_MongoDB.md

4. Origen de los datos

El archivo:
citas_atendidas_mongo.csv

fue exportado desde PostgreSQL usando citas en estado atendida.

Este archivo contiene datos reales de PostgreSQL:

id_cita
id_paciente
id_medico
id_especialidad
especialidad
fecha_cita
hora_inicio
hora_fin
fecha_nacimiento
edad_paciente

Estos datos se usaron como base para generar los historiales clínicos en MongoDB.

## 5. Generación de historiales clínicos

El archivo:

generar_historiales.py

genera el archivo:

historiales_clinicos.json

El comando utilizado fue:

python generar_historiales.py

El resultado fue:

150 historiales clínicos generados

## 6. Estructura general de un historial clínico

Cada documento contiene:

id_cita
id_paciente
id_medico
id_especialidad
especialidad
fecha_consulta
edad_paciente
grupo_etario
motivo_consulta
signos_vitales
diagnosticos
medicamentos
examenes_solicitados
notas_adicionales
datos_especialidad
created_at
updated_at

Ejemplo conceptual:

{
  "id_cita": 4,
  "id_paciente": 1,
  "id_medico": 1,
  "id_especialidad": 1,
  "especialidad": "Medicina General",
  "fecha_consulta": "2026-06-08T08:00:00",
  "edad_paciente": 31,
  "grupo_etario": "adulto",
  "motivo_consulta": "Consulta por malestar general",
  "signos_vitales": {
    "presion_sistolica": 120,
    "presion_diastolica": 80,
    "frecuencia_cardiaca": 78,
    "temperatura": 36.7,
    "peso_kg": 70.5,
    "altura_cm": 170.2
  },
  "diagnosticos": [
    {
      "codigo": "J00",
      "descripcion": "Resfriado común",
      "tipo": "principal"
    }
  ],
  "medicamentos": [
    {
      "nombre": "Acetaminofén",
      "dosis": "500 mg",
      "frecuencia": "Cada 8 horas",
      "duracion": "5 días"
    }
  ],
  "examenes_solicitados": [
    {
      "nombre": "Hemograma completo",
      "prioridad": "normal",
      "observaciones": "Solicitado como apoyo diagnóstico"
    }
  ],
  "notas_adicionales": "Paciente estable al finalizar la consulta.",
  "datos_especialidad": {
    "requiere_seguimiento": true,
    "dias_reposo": 2
  },
  "created_at": "2026-06-06T10:00:00",
  "updated_at": null
}

## 7. Justificación del uso de MongoDB

MongoDB se usa porque los historiales clínicos tienen estructura variable.

Por ejemplo, Cardiología puede registrar riesgo cardiovascular, Dermatología puede registrar tipo de lesión y Traumatología puede registrar zona de lesión.

Guardar todo esto en PostgreSQL obligaría a crear muchas columnas opcionales o tablas adicionales. En MongoDB, estos datos pueden almacenarse de forma flexible dentro del campo:

datos_especialidad

La información financiera y transaccional permanece en PostgreSQL para mantener integridad, relaciones y transacciones.

## 8. Decisión de embebido vs referencias

Se embeben dentro del documento:

signos_vitales
diagnosticos
medicamentos
examenes_solicitados
datos_especialidad

Se decidió embeberlos porque pertenecen directamente a una consulta médica y normalmente se consultan junto con el historial.

Se guardan como referencias lógicas hacia PostgreSQL:

id_cita
id_paciente
id_medico
id_especialidad

MongoDB no maneja claves foráneas reales hacia PostgreSQL, pero la integración lógica se mantiene mediante estos identificadores.

## 9. Índices creados

Se crearon índices sobre:

id_paciente + fecha_consulta
id_medico + fecha_consulta
id_especialidad
especialidad
diagnosticos.descripcion
medicamentos.nombre

Estos índices permiten optimizar consultas por paciente, médico, especialidad, diagnósticos y medicamentos.

En Compass algunos índices pueden aparecer con nombres automáticos, por ejemplo:

id_paciente_1_fecha_consulta_-1
id_medico_1_fecha_consulta_-1
id_especialidad_1
especialidad_1
diagnosticos.descripcion_1
medicamentos.nombre_1

## 10. Pipelines implementados

Se implementaron y probaron 5 pipelines:

1. Diagnósticos más frecuentes por especialidad.
2. Medicamentos más recetados por especialidad.
3. Promedio de signos vitales por grupo etario.
4. Tiempo promedio entre consultas por paciente.
5. Resumen clínico consolidado usando $facet.

El proyecto exige al menos 4 pipelines y al menos 1 con $facet.

## 11. Resultados de prueba
Pipeline 1

Agrupa diagnósticos frecuentes por especialidad.

Resultado esperado:

especialidad
diagnosticos
cantidad
Pipeline 2

Calcula medicamentos más recetados por especialidad.

Ejemplo obtenido:

{
  "total_prescripciones": 43,
  "especialidad": "Cardiología",
  "medicamento": "Aspirina",
  "cantidad": 12,
  "porcentaje": 27.91
}
Pipeline 3

Calcula promedios de signos vitales por grupo etario.

Ejemplo obtenido:

{
  "cantidad_consultas": 10,
  "grupo_etario": "adolescente",
  "promedio_presion_sistolica": 104.6,
  "promedio_presion_diastolica": 70.4,
  "promedio_frecuencia_cardiaca": 83.4,
  "promedio_temperatura": 37.58,
  "promedio_peso_kg": 44.86
}
Pipeline 4

Calcula tiempo promedio entre consultas por paciente.

Ejemplo obtenido:

{
  "cantidad_intervalos": 3,
  "id_paciente": 30,
  "promedio_dias_entre_consultas": 5
}

En este pipeline se usa $toDate porque fecha_consulta fue importada como texto desde JSON.

Pipeline 5 con $facet

Devuelve un resumen consolidado con:

diagnosticos_frecuentes
medicamentos_frecuentes
signos_vitales_generales

Ejemplo obtenido:

total_historiales: 150
promedio_presion_sistolica: 118.83
promedio_presion_diastolica: 76.07
promedio_frecuencia_cardiaca: 80.47
promedio_temperatura: 37.18

## 12. Cómo reconstruir MongoDB
Crear la base:
clinica_privada_mongo
Crear la colección:
historiales_clinicos
Importar el archivo:
historiales_clinicos.json
Crear índices usando:
02_indices_historiales.js
Ejecutar pipelines desde:
03_pipelines_reportes.js

## 13. Estado

MongoDB quedó con:

150 documentos importados
6 índices creados
4 pipelines requeridos funcionando
1 pipeline con $facet funcionando