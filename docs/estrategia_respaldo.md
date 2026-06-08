# Estrategia de Respaldo y Recuperación (Disaster Recovery)

Este documento detalla la política, frecuencia y procedimientos prácticos para el respaldo y restauración de datos en los motores PostgreSQL y MongoDB del sistema.

---

## 1. Respaldo de PostgreSQL (Transaccional)

### Política de Respaldo
- **Tipo:** Backup Full lógico usando la herramienta nativa `pg_dump`.
- **Frecuencia:** Diario al cierre de operaciones (ej. 23:59 hrs).
- **Retención:** 7 días en almacenamiento local (los archivos más antiguos se eliminan automáticamente mediante el script `backup_full_postgres.sh`).
- **Ubicación:** Los respaldos se guardan en la carpeta del proyecto bajo `backup/full/` y los logs del proceso en `backup/logs/`.

### Comandos de Respaldo
Para ejecutar un respaldo manual de la base de datos transaccional:
```bash
pg_dump -h localhost -U postgres -d clinica_privada_db -F c -f backup/full/clinica_privada_db_full.backup
```

### Proceso de Restauración
Para restaurar la base de datos sobre una instancia limpia (por ejemplo, para pruebas de recuperación o migración):

1. **Crear base de datos limpia de destino:**
   ```bash
   createdb -h localhost -U postgres clinica_privada_restore_test
   ```
2. **Restaurar el backup utilizando `pg_restore`:**
   ```bash
   pg_restore -h localhost -U postgres -d clinica_privada_restore_test backup/full/clinica_privada_db_full.backup
   ```

### Validación del Respaldo
El equipo de TI debe validar la consistencia de los datos ejecutando consultas de conteo en las tablas críticas, comparándolos con el servidor de producción:
```sql
SELECT COUNT(*) FROM paciente;
SELECT COUNT(*) FROM medico;
SELECT COUNT(*) FROM cita;
SELECT COUNT(*) FROM factura;
```

### Respaldos Incrementales (WAL Archiving)
Para ambientes de alta disponibilidad o producción a gran escala, se documenta la activación del archivado de logs de transacciones (Write-Ahead Logging - WAL) para permitir la recuperación en el punto de falla (Point-in-Time Recovery - PITR):

1. Configurar en `postgresql.conf`:
   ```ini
   wal_level = replica
   archive_mode = on
   archive_command = 'test ! -f /var/lib/postgresql/data/archive/%f && cp %p /var/lib/postgresql/data/archive/%f'
   ```
2. Crear un backup base físico periódico con `pg_basebackup`.

---

## 2. Respaldo de MongoDB (No Relacional)

### Política de Respaldo
- **Tipo:** Dump lógico con `mongodump`.
- **Frecuencia:** Diario, concurrente con el proceso de PostgreSQL.
- **Ubicación:** Carpeta `backup/mongodb_dump/`.

### Comandos de Respaldo
Para generar el respaldo lógico de la colección de historiales clínicos:
```bash
mongodump --uri "mongodb://localhost:27017/clinica_privada_mongo" --out backup/mongodb_dump
```

### Proceso de Restauración
Para recuperar los datos en una base de datos de pruebas o producción en caso de falla:
```bash
mongorestore --uri "mongodb://localhost:27017/" --nsFrom "clinica_privada_mongo.*" --nsTo "clinica_privada_mongo_restore_test.*" backup/mongodb_dump/clinica_privada_mongo
```
Esto restaurará la colección `historiales_clinicos` dentro de una base de datos de prueba aislada llamada `clinica_privada_mongo_restore_test`.
