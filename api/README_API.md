# API Clínica Privada - Documentación y Pruebas

Esta API conecta PostgreSQL y MongoDB sin el uso de ORMs pesados o relacionales, usando únicamente `pg` y `mongoose`.

## Configuración

1. Asegúrate de configurar las credenciales correctas en tu archivo `.env` basándote en `.env.example`.
2. Para iniciar el servidor de desarrollo, ejecuta:
   ```bash
   cd api
   npm run dev
   ```

## Comandos curl para pruebas

### Endpoints PostgreSQL

1. **Estado de PostgreSQL:**
   ```bash
   curl http://localhost:3000/api/postgres/estado
   ```

2. **Registrar un Pago (Store Procedure):**
   ```bash
   curl -X POST http://localhost:3000/api/pagos \
     -H "Content-Type: application/json" \
     -d '{"id_factura": 1, "id_usuario": 1, "monto": 50.00, "metodo_pago": "efectivo", "observacion": "Pago desde API"}'
   ```

3. **Cancelar una Cita (Store Procedure):**
   ```bash
   curl -X POST http://localhost:3000/api/citas/cancelar \
     -H "Content-Type: application/json" \
     -d '{"id_cita": 3, "id_usuario": 1, "motivo_cancelacion": "Paciente no podrá asistir"}'
   ```

4. **Reporte - Agenda Diaria (Vista):**
   ```bash
   curl "http://localhost:3000/api/reportes/agenda-diaria?fecha=2026-06-08"
   ```

5. **Reporte - Facturas Pendientes (Vista):**
   ```bash
   curl http://localhost:3000/api/reportes/facturas-pendientes
   ```

6. **Reporte - Facturación Mensual (Vista Materializada):**
   ```bash
   curl http://localhost:3000/api/reportes/facturacion-mensual
   ```

7. **Reporte - Ranking de Médicos (Vista Materializada):**
   ```bash
   curl http://localhost:3000/api/reportes/ranking-medicos
   ```

8. **Función - Saldo de Paciente:**
   ```bash
   curl http://localhost:3000/api/reportes/saldo-paciente/1
   ```

---

### Endpoints MongoDB

1. **Estado de MongoDB:**
   ```bash
   curl http://localhost:3000/api/mongo/estado
   ```

2. **Historiales por Paciente:**
   ```bash
   curl http://localhost:3000/api/mongo/historiales/paciente/1
   ```

3. **Insertar Historial Clínico (Valida primero cita en PostgreSQL):**
   ```bash
   curl -X POST http://localhost:3000/api/mongo/historiales \
     -H "Content-Type: application/json" \
     -d '{"id_cita": 2, "motivo_consulta": "Dolor abdominal recurrente", "signos_vitales": {"presion_sistolica": 120, "presion_diastolica": 80, "frecuencia_cardiaca": 75, "temperatura": 36.8, "peso_kg": 70}, "diagnosticos": [{"codigo_cie10": "K29.7", "descripcion": "Gastritis no especificada"}], "medicamentos": [{"nombre": "Omeprazol", "dosis": "20mg", "frecuencia": "cada 24 horas", "duracion_dias": 14}]}'
   ```

4. **Reporte - Diagnósticos Frecuentes:**
   ```bash
   curl http://localhost:3000/api/mongo/reportes/diagnosticos-top
   ```

5. **Reporte - Medicamentos Recetados:**
   ```bash
   curl http://localhost:3000/api/mongo/reportes/medicamentos
   ```

6. **Reporte - Signos Vitales Promedio:**
   ```bash
   curl http://localhost:3000/api/mongo/reportes/signos-vitales
   ```

7. **Reporte - Tiempo entre Consultas:**
   ```bash
   curl http://localhost:3000/api/mongo/reportes/tiempo-consultas
   ```

8. **Reporte Consolidado con $facet:**
   ```bash
   curl http://localhost:3000/api/mongo/reportes/resumen-facet
   ```
