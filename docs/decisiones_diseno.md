# Decisiones de Diseño de la Arquitectura de Datos

Este documento detalla las justificaciones técnicas y las decisiones de diseño tomadas durante la estructuración híbrida (SQL + NoSQL) de la base de datos de la Clínica Médica Privada.

---

## 1. Modelo Híbrido: PostgreSQL + MongoDB

### PostgreSQL (Motor Transaccional Relacional)
- **Propósito:** Alojar los datos estructurados, de alta criticidad, transaccionales y con restricciones estrictas de integridad referencial.
- **Entidades:** `paciente`, `medico`, `especialidad`, `cita`, `factura`, `detalle_factura`, `pago`, `auditoria`.
- **Justificación:** Los datos como facturación, citas y pagos requieren ACID al 100%. Un error en saldos o cruce de horarios puede invalidar el estado de negocio. El uso de llaves foráneas, restricciones CHECK y transacciones nativas asegura consistencia total.

### MongoDB (Motor de Historiales Clínicos Flexibles)
- **Propósito:** Alojar los historiales clínicos de los pacientes.
- **Entidades:** Colección `historiales_clinicos`.
- **Justificación:** Los historiales clínicos son semi-estructurados por naturaleza. Diferentes especialidades médicas requieren capturar parámetros completamente distintos (ej. cardiología requiere electrocardiogramas, oftalmología requiere agudeza visual). Utilizar un motor NoSQL basado en documentos permite una estructura JSON dinámica sin alterar el esquema global.

---

## 2. Modelado de Documentos en MongoDB (Embebido vs Referencia)

### Datos Embebidos (Denormalización)
- **Elementos Embebidos:** `diagnosticos`, `medicamentos`, `examenes_solicitados`, `signos_vitales`, `datos_especialidad`.
- **Justificación:** Un historial clínico es una foto en el tiempo de la consulta de un paciente. Si la descripción del diagnóstico o el nombre del medicamento cambia en el futuro, el historial debe conservar los valores exactos en la fecha que ocurrió la consulta. Embeber estos datos evita JOINs costosos en consultas masivas de reportes y mantiene el aislamiento del registro clínico.

### Referencias Lógicas (PostgreSQL -> MongoDB)
- **Elementos Referenciados:** `id_cita`, `id_paciente`, `id_medico`, `id_especialidad`.
- **Justificación:** No guardamos nombres completos de médicos o pacientes que puedan actualizarse en el futuro. Guardamos los IDs enteros (`id_paciente`, `id_medico`, `id_cita`) provenientes de PostgreSQL. Esto actúa como un puente lógico de integración entre ambos mundos, permitiendo búsquedas indexadas ultra rápidas por paciente o médico en MongoDB y cruces por API.

---

## 3. Delimitación de Responsabilidades

### Facturas, Pagos y Auditoría
- **Decisión:** Estos datos se almacenan de forma exclusiva en **PostgreSQL**.
- **Justificación:** No tienen cabida en la colección de MongoDB porque pertenecen al dominio financiero y operativo de la clínica. MongoDB se reserva estrictamente para la persistencia del flujo y análisis clínico.

### Lógica de Negocio en la Base de Datos
- **Decisión:** Reglas fuertes del negocio se aseguran directamente en la base de datos PostgreSQL utilizando:
  * **Constraints (PKEY, FKEY, CHECK, UNIQUE):** Evitan solapamiento de horarios de médicos o pacientes, citas en fechas pasadas y correos duplicados.
  * **Stored Procedures (`sp_registrar_pago`, `sp_cancelar_cita`):** Garantizan atomicidad en operaciones complejas de pagos (cálculo de saldos de facturas) y cancelaciones de citas de forma segura y centralizada.

### Vistas y Vistas Materializadas para Reportes
- **Decisión:** Los reportes de PostgreSQL usan vistas (`vw_agenda_diaria`, `vw_facturas_pendientes`) y vistas materializadas (`mv_facturacion_mensual`, `mv_ranking_medicos_trimestral`).
- **Justificación:** Las consultas analíticas gerenciales de facturación o rankings médicos requieren barrer miles de registros y cruzar múltiples tablas. En lugar de realizar esta costosa carga sobre el servidor transaccional principal en cada petición, las vistas materializadas almacenan los datos agrupados físicamente. Esto baja los tiempos de respuesta de la API a menos de 1ms, programando actualizaciones controladas mediante tareas programadas de refresco.
