# Reporte de Performance - PostgreSQL

Este documento presenta la comparación y el análisis de performance de dos consultas clave del sistema, contrastando el uso de vistas y vistas materializadas frente a sus consultas base equivalentes utilizando `EXPLAIN ANALYZE`.

---

## Consulta 1: Agenda Diaria

### Consulta Optimizada (Vista `vw_agenda_diaria`)
```sql
EXPLAIN ANALYZE
SELECT *
FROM vw_agenda_diaria
WHERE fecha_cita = '2026-06-08'
ORDER BY hora_inicio;
```

**Resultado de `EXPLAIN ANALYZE`:**
```txt
 Sort  (cost=12.46..12.47 rows=4 width=368) (actual time=0.221..0.224 rows=3 loops=1)
   Sort Key: c.hora_inicio
   Sort Method: quicksort  Memory: 25kB
   ->  Hash Join  (cost=4.01..12.42 rows=4 width=368) (actual time=0.150..0.189 rows=3 loops=1)
         Hash Cond: (m.id_especialidad = e.id_especialidad)
         ->  Hash Join  (cost=2.90..11.26 rows=4 width=958) (actual time=0.106..0.143 rows=3 loops=1)
               Hash Cond: (c.id_medico = m.id_medico)
               ->  Hash Join  (cost=1.68..10.02 rows=4 width=518) (actual time=0.071..0.107 rows=3 loops=1)
                     Hash Cond: (c.id_paciente = p.id_paciente)
                     ->  Seq Scan on cita c  (cost=0.00..8.34 rows=4 width=82) (actual time=0.014..0.046 rows=3 loops=1)
                           Filter: (fecha_cita = '2026-06-08'::date)
                           Rows Removed by Filter: 257
                     ->  Hash  (cost=1.30..1.30 rows=30 width=440) (actual time=0.039..0.039 rows=30 loops=1)
                           Buckets: 1024  Batches: 1  Memory Usage: 10kB
                           ->  Seq Scan on paciente p  (cost=0.00..1.30 rows=30 width=440) (actual time=0.007..0.028 rows=30 loops=1)
               ->  Hash  (cost=1.10..1.10 rows=10 width=444) (actual time=0.018..0.018 rows=10 loops=1)
                     Buckets: 1024  Batches: 1  Memory Usage: 9kB
                     ->  Seq Scan on medico m  (cost=0.00..1.10 rows=10 width=444) (actual time=0.009..0.011 rows=10 loops=1)
         ->  Hash  (cost=1.05..1.05 rows=5 width=222) (actual time=0.027..0.027 rows=5 loops=1)
               Buckets: 1024  Batches: 1  Memory Usage: 9kB
               ->  Seq Scan on especialidad e  (cost=0.00..1.05 rows=5 width=222) (actual time=0.012..0.014 rows=5 loops=1)
 Planning Time: 1.201 ms
 Execution Time: 0.341 ms
```

### Consulta Base Equivalente
```sql
EXPLAIN ANALYZE
SELECT
    c.id_cita,
    c.fecha_cita,
    c.hora_inicio,
    c.hora_fin,
    c.estado,
    c.motivo_cancelacion,
    p.id_paciente,
    (p.nombres::text || ' '::text) || p.apellidos::text AS paciente,
    m.id_medico,
    (m.nombres::text || ' '::text) || m.apellidos::text AS medico,
    e.id_especialidad,
    e.nombre AS especialidad
FROM cita c
INNER JOIN paciente p ON c.id_paciente = p.id_paciente
INNER JOIN medico m ON c.id_medico = m.id_medico
INNER JOIN especialidad e ON m.id_especialidad = e.id_especialidad
WHERE c.fecha_cita = '2026-06-08'
ORDER BY c.hora_inicio;
```

**Resultado de `EXPLAIN ANALYZE`:**
```txt
 Sort  (cost=12.46..12.47 rows=4 width=368) (actual time=0.135..0.137 rows=3 loops=1)
   Sort Key: c.hora_inicio
   Sort Method: quicksort  Memory: 25kB
   ->  Hash Join  (cost=4.01..12.42 rows=4 width=368) (actual time=0.098..0.119 rows=3 loops=1)
         Hash Cond: (m.id_especialidad = e.id_especialidad)
         ->  Hash Join  (cost=2.90..11.26 rows=4 width=958) (actual time=0.049..0.068 rows=3 loops=1)
               Hash Cond: (c.id_medico = m.id_medico)
               ->  Hash Join  (cost=1.68..10.02 rows=4 width=518) (actual time=0.027..0.046 rows=3 loops=1)
                     Hash Cond: (c.id_paciente = p.id_paciente)
                     ->  Seq Scan on cita c  (cost=0.00..8.34 rows=4 width=82) (actual time=0.005..0.022 rows=3 loops=1)
                           Filter: (fecha_cita = '2026-06-08'::date)
                           Rows Removed by Filter: 257
                     ->  Hash  (cost=1.30..1.30 rows=30 width=440) (actual time=0.011..0.011 rows=30 loops=1)
                           Buckets: 1024  Batches: 1  Memory Usage: 10kB
                           ->  Seq Scan on paciente p  (cost=0.00..1.30 rows=30 width=440) (actual time=0.003..0.005 rows=30 loops=1)
               ->  Hash  (cost=1.10..1.10 rows=10 width=444) (actual time=0.008..0.008 rows=10 loops=1)
                     Buckets: 1024  Batches: 1  Memory Usage: 9kB
                     ->  Seq Scan on medico m  (cost=0.00..1.10 rows=10 width=444) (actual time=0.004..0.005 rows=10 loops=1)
         ->  Hash  (cost=1.05..1.05 rows=5 width=222) (actual time=0.013..0.014 rows=5 loops=1)
               Buckets: 1024  Batches: 1  Memory Usage: 9kB
               ->  Seq Scan on especialidad e  (cost=0.00..1.05 rows=5 width=222) (actual time=0.007..0.007 rows=5 loops=1)
 Planning Time: 0.712 ms
 Execution Time: 0.200 ms
```

### Análisis y Comparación (Consulta 1)
- **Planning Time:** ~0.71 ms a 1.20 ms.
- **Execution Time:** ~0.20 ms a 0.34 ms.
- **Tipo de Scan Usado:** `Seq Scan` (Escaneo Secuencial) en las tablas de `cita`, `paciente`, `medico` y `especialidad`.
- **Uso de Índices:** Aunque existe un índice en la fecha de la cita (`idx_cita_fecha`), el planificador de PostgreSQL opta por un escaneo secuencial en este caso. Esto se debe a que la tabla `cita` cuenta con un volumen de datos pequeño en el ambiente local (aproximadamente 260 registros) y leer las páginas del índice agregaría más sobrecarga que barrer la tabla directamente.
- **Conclusión:** La vista `vw_agenda_diaria` actúa como un alias o macro expansible para la consulta relacional subyacente. Los planes de ejecución son virtualmente idénticos e igual de eficientes. La vista proporciona una excelente abstracción sin penalizar el rendimiento.

---

## Consulta 2: Facturación Mensual

### Consulta Optimizada (Vista Materializada `mv_facturacion_mensual`)
```sql
EXPLAIN ANALYZE
SELECT *
FROM mv_facturacion_mensual
ORDER BY mes, especialidad;
```

**Resultado de `EXPLAIN ANALYZE`:**
```txt
 Sort  (cost=1.75..1.81 rows=23 width=42) (actual time=0.039..0.040 rows=23 loops=1)
   Sort Key: mes, especialidad
   Sort Method: quicksort  Memory: 26kB
   ->  Seq Scan on mv_facturacion_mensual  (cost=0.00..1.23 rows=23 width=42) (actual time=0.005..0.006 rows=23 loops=1)
 Planning Time: 0.251 ms
 Execution Time: 0.063 ms
```

### Consulta Base Equivalente (Cálculo Completo de Agregaciones y Joins)
```sql
EXPLAIN ANALYZE
SELECT
    DATE_TRUNC('month', f.fecha_emision)::DATE AS mes,
    e.id_especialidad,
    e.nombre AS especialidad,
    COUNT(f.id_factura) AS cantidad_facturas,
    SUM(f.total) AS total_facturado,
    COALESCE(SUM(pagos.total_pagado), 0) AS total_cobrado,
    SUM(f.total - COALESCE(pagos.total_pagado, 0)) AS saldo_pendiente
FROM factura f
INNER JOIN cita c ON f.id_cita = c.id_cita
INNER JOIN medico m ON c.id_medico = m.id_medico
INNER JOIN especialidad e ON m.id_especialidad = e.id_especialidad
LEFT JOIN (
    SELECT
        id_factura,
        SUM(monto) AS total_pagado
    FROM pago
    GROUP BY id_factura
) pagos ON f.id_factura = pagos.id_factura
GROUP BY
    DATE_TRUNC('month', f.fecha_emision)::DATE,
    e.id_especialidad,
    e.nombre
ORDER BY mes, especialidad;
```

**Resultado de `EXPLAIN ANALYZE`:**
```txt
 Sort  (cost=41.09..41.49 rows=160 width=330) (actual time=0.446..0.449 rows=23 loops=1)
   Sort Key: ((date_trunc('month'::text, f.fecha_emision))::date), e.nombre
   Sort Method: quicksort  Memory: 26kB
   ->  HashAggregate  (cost=31.64..35.24 rows=160 width=330) (actual time=0.406..0.416 rows=23 loops=1)
         Group Key: (date_trunc('month'::text, f.fecha_emision))::date, e.id_especialidad
         Batches: 1  Memory Usage: 64kB
         ->  Hash Left Join  (cost=18.02..28.84 rows=160 width=267) (actual time=0.226..0.340 rows=160 loops=1)
               Hash Cond: (f.id_factura = pagos.id_factura)
               ->  Hash Join  (cost=7.94..17.53 rows=160 width=239) (actual time=0.088..0.171 rows=160 loops=1)
                     Hash Cond: (m.id_especialidad = e.id_especialidad)
                     ->  Hash Join  (cost=6.82..15.82 rows=160 width=21) (actual time=0.068..0.132 rows=160 loops=1)
                           Hash Cond: (c.id_medico = m.id_medico)
                           ->  Hash Join  (cost=5.60..13.99 rows=160 width=21) (actual time=0.047..0.093 rows=160 loops=1)
                                 Hash Cond: (c.id_cita = f.id_cita)
                                 ->  Seq Scan on cita c  (cost=0.00..7.47 rows=347 width=8) (actual time=0.002..0.019 rows=260 loops=1)
                                 ->  Hash  (cost=3.60..3.60 rows=160 width=21) (actual time=0.033..0.034 rows=160 loops=1)
                                       Buckets: 1024  Batches: 1  Memory Usage: 17kB
                                       ->  Seq Scan on factura f  (cost=0.00..3.60 rows=160 width=21) (actual time=0.003..0.014 rows=160 loops=1)
                           ->  Hash  (cost=1.10..1.10 rows=10 width=8) (actual time=0.009..0.009 rows=10 loops=1)
                                 Buckets: 1024  Batches: 1  Memory Usage: 9kB
                                 ->  Seq Scan on medico m  (cost=0.00..1.10 rows=10 width=8) (actual time=0.006..0.007 rows=10 loops=1)
                     ->  Hash  (cost=1.05..1.05 rows=5 width=222) (actual time=0.013..0.013 rows=5 loops=1)
                           Buckets: 1024  Batches: 1  Memory Usage: 9kB
                           ->  Seq Scan on especialidad e  (cost=0.00..1.05 rows=5 width=222) (actual time=0.005..0.006 rows=5 loops=1)
               ->  Hash  (cost=8.32..8.32 rows=141 width=36) (actual time=0.122..0.122 rows=141 loops=1)
                     Buckets: 1024  Batches: 1  Memory Usage: 15kB
                     ->  Subquery Scan on pagos  (cost=5.14..8.32 rows=141 width=36) (actual time=0.069..0.108 rows=141 loops=1)
                           ->  HashAggregate  (cost=5.14..6.91 rows=141 width=36) (actual time=0.069..0.097 rows=141 loops=1)
                                 Group Key: pago.id_factura
                                 Batches: 1  Memory Usage: 96kB
                                 ->  Seq Scan on pago  (cost=0.00..4.43 rows=143 width=9) (actual time=0.003..0.011 rows=147 loops=1)
 Planning Time: 0.904 ms
 Execution Time: 0.584 ms
```

### Análisis y Comparación (Consulta 2)
- **Planning Time (Planificada):** 0.251 ms vs 0.904 ms (3.6x más rápida usando la vista materializada).
- **Execution Time (Ejecutada):** 0.063 ms vs 0.584 ms (**9.2x más rápida** usando la vista materializada).
- **Conclusión:** La vista materializada evita recalcular `JOIN`s complejos entre 5 tablas (`factura`, `cita`, `medico`, `especialidad` y subconsulta de `pago`) y operaciones pesadas de agregación (`GROUP BY` y `SUM`). En lugar de realizar costosos escaneos múltiples y agrupaciones en memoria al vuelo, PostgreSQL lee los resultados precalculados directamente desde disco. Esto reduce drásticamente el costo de entrada/salida y procesamiento.

---

## Estrategia de Refresco (Refresh) de Vistas Materializadas

Las vistas materializadas del sistema son:
- `mv_facturacion_mensual`
- `mv_ranking_medicos_trimestral`

### Instrucciones de Refresco:
```sql
REFRESH MATERIALIZED VIEW mv_facturacion_mensual;
REFRESH MATERIALIZED VIEW mv_ranking_medicos_trimestral;
```

### Justificación de la Estrategia:
1. **Evita Sobrecarga en Tiempo Real:** El cálculo de la facturación histórica y el ranking de médicos no requiere actualizarse al segundo. Mantenerlo materializado protege al motor transaccional de consultas concurrentes pesadas que podrían degradar la experiencia de usuario.
2. **Programación al Cierre de Operaciones:** Se programa un job (por ejemplo, mediante pgAgent o cron) para ejecutarse diariamente por la noche al cierre de operaciones, o inmediatamente después de cargas masivas de datos.
3. **Optimización de Reportes Gerenciales:** Al precalcular los resultados complejos, los dashboards gerenciales cargan de forma instantánea (en menos de 1 milisegundo) consumiendo mínimos recursos del servidor.
