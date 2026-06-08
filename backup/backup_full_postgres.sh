#!/bin/bash

set -e

DB_NAME="clinica_privada_db"
DB_USER="postgres"
BACKUP_DIR="/home/nova/Documentos/Meso/Bases de Datos III/Proyecto/backup/full"
LOG_DIR="/home/nova/Documentos/Meso/Bases de Datos III/Proyecto/backup/logs"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_full_${DATE}.backup"
LOG_FILE="$LOG_DIR/backup_${DATE}.log"

mkdir -p "$BACKUP_DIR"
mkdir -p "$LOG_DIR"

echo "Inicio de backup: $(date)" >> "$LOG_FILE"

# Se usa -h localhost para evitar autenticación Peer de UNIX socket
pg_dump -h localhost -U "$DB_USER" -d "$DB_NAME" -F c -f "$BACKUP_FILE" >> "$LOG_FILE" 2>&1

echo "Backup creado: $BACKUP_FILE" >> "$LOG_FILE"

find "$BACKUP_DIR" -type f -name "${DB_NAME}_full_*.backup" -mtime +7 -delete

echo "Backups antiguos eliminados según retención de 7 días." >> "$LOG_FILE"
echo "Fin de backup: $(date)" >> "$LOG_FILE"
