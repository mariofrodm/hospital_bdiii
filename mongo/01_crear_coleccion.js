// ======================================================
// Proyecto Final Bases de Datos
// Sistema: Clínica Médica Privada
// Motor: MongoDB
// Propósito:
// Crear la base de datos clinica_privada_mongo
// y la colección historiales_clinicos.
// ======================================================

// Selecciona o crea la base de datos de MongoDB.
use('clinica_privada_mongo');

// Crea la colección principal para almacenar historiales clínicos.
// Cada documento representará una consulta médica atendida.
db.createCollection('historiales_clinicos');

// Verifica que la colección haya sido creada correctamente.
db.getCollectionNames();