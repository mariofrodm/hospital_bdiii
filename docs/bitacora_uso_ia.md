# Bitácora de Uso de Inteligencia Artificial

Este documento describe la interacción, soporte y validaciones conjuntas realizadas con el asistente de IA para el desarrollo e integración del proyecto de base de datos híbrida de la Clínica Médica Privada.

---

## 1. Usos del Asistente de IA en el Proyecto

1. **Diagnóstico del Modelo Entidad-Relación (ER):**
   - Apoyo en la conceptualización de las tablas relacionales de PostgreSQL y su cardinalidad para garantizar la integridad referencial de citas, facturas y pagos.
2. **Revisión de Constraints:**
   - Análisis y depuración de restricciones CHECK y UNIQUE complejas (por ejemplo, evitar solapamiento de citas médicas para un mismo médico o paciente).
3. **Pruebas de Procedimientos Almacenados (Stored Procedures):**
   - Simulación y verificación del flujo lógico en los SP `sp_registrar_pago` y `sp_cancelar_cita` para validar la correcta actualización del estado de las facturas y citas.
4. **Planificación y Normalización en MongoDB:**
   - Diseño del esquema dinámico JSON para historiales clínicos embebidos.
   - Definición del proceso de validación cruzada y cálculo dinámico de edad y grupo etario desde PostgreSQL para normalización en MongoDB.
5. **Generación de Prompts de Trabajo y Casos de Prueba:**
   - Creación de planes de prueba y comandos `curl` detallados para agilizar la validación de la API Express.

---

## 2. Errores Diagnosticados y Corregidos

Durante el desarrollo, se identificaron y solucionaron los siguientes errores técnicos gracias a la asistencia de la IA:

- **Error en `generate_series` con tipo `TIME`:**
  * *Problema:* PostgreSQL no permite generar intervalos de tiempo directamente con `generate_series(start_time, end_time, interval)` si son variables estrictamente de tipo `TIME` sin convertirlas a `TIMESTAMP`.
  * *Solución:* Se ajustaron los scripts utilizando conversiones explícitas a `TIMESTAMP` o realizando operaciones directas de suma de intervalos sobre la base inicial.
- **Falla inicial de importación en MongoDB por `MONGODB_URI` no configurada:**
  * *Problema:* Las pruebas automatizadas fallaban al intentar conectarse al clúster remoto Atlas debido a restricciones de red local y falta de variables de entorno correctas.
  * *Solución:* Se forzó la conexión y configuración de la API para ejecutarse de forma 100% local (`mongodb://localhost:27017/clinica_privada_mongo`) y se corrigieron las variables en el archivo `.env`.
- **Inconsistencia en el nombre del archivo de índices de MongoDB:**
  * *Problema:* El script para la inicialización de índices poseía diferencias de mayúsculas y minúsculas o nombres inconsistentes en la documentación.
  * *Solución:* Se estandarizó el nombre del archivo final a `02_indices_historiales.js`.
- **Pipeline 4 de MongoDB estructurado como un simple arreglo:**
  * *Problema:* En `03_pipelines_reportes.js`, el Pipeline 4 estaba definido únicamente como un bloque de arreglo JSON `[ ... ]` en lugar de una llamada de agregación ejecutable (`db.historiales_clinicos.aggregate([ ... ])`), provocando errores de sintaxis en el intérprete `mongosh`.
  * *Solución:* Se corrigió el archivo envolviendo el pipeline en la llamada de agregación correspondiente y se adaptó a la API Express.

---

## 3. Validaciones Reales Realizadas

Todo el código e infraestructura presentados en el proyecto han sido verificados de forma empírica en el entorno de desarrollo local:
- Verificación de los conteos y planes de ejecución (`EXPLAIN ANALYZE`) directamente en PostgreSQL.
- Verificación del conteo de documentos (150) e índices (7) en MongoDB.
- Ejecución local y pruebas de integración de la API Express mediante comandos `curl` verificando los códigos de respuesta (`200`, `201`, `400`, `404` y `503`).
- Simulación completa de fallos y generación exitosa del respaldo de PostgreSQL con el script automático `backup_full_postgres.sh`.
