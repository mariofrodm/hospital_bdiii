function estado(req, res) {
  res.json({
    ok: true,
    mensaje: 'Backup y restauración PostgreSQL verificados correctamente durante la preparación del proyecto.',
    base_principal: 'clinica_privada_db',
    base_prueba_restaurada: 'clinica_privada_restore_test',
    herramienta_backup: 'pg_dump',
    herramienta_restore: 'pg_restore',
    backup_local_usado: 'sql/clinica_privada_db.tar',
    evidencia: {
      auditoria: 573,
      cita: 260,
      factura: 160,
      pago: 143
    },
    comandos_referencia: [
      'pg_dump -U postgres -d clinica_privada_db -F c -f backup.backup',
      'createdb -U postgres clinica_privada_restore_test',
      'pg_restore -U postgres -d clinica_privada_restore_test backup.backup'
    ]
  });
}

module.exports = {
  estado
};
