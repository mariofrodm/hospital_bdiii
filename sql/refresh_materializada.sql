--refresh para vistas materializadas = 
--Sirve para sincronizar la vista materializada con los datos actuales de las tablas base.
--indices para refresh
CREATE UNIQUE INDEX uq_mv_facturacion_mensual
ON mv_facturacion_mensual (mes, id_especialidad);

CREATE UNIQUE INDEX uq_mv_ranking_medicos_trimestral
ON mv_ranking_medicos_trimestral (id_medico);

--consulta para refresh
REFRESH MATERIALIZED VIEW mv_facturacion_mensual;

REFRESH MATERIALIZED VIEW mv_ranking_medicos_trimestral;

--comprobacion
SELECT *
FROM mv_facturacion_mensual;

SELECT *
FROM mv_ranking_medicos_trimestral;