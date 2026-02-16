#!/bin/bash

# Variables
BACKUP_DIR="/home/sgall/backup"
DATE=$(date +'%Y%m%d')
BACKUP_FILE="backup-matrix-sergigallart-${DATE}.tar.gz"
HOMESERVER_DB="/data/homeserver.db"
CONTAINER_NAME="matrix-synapse-dgutierrez"

# Detener el servidor Synapse
echo "Deteniendo el servidor Synapse ... "
docker-compose -f ~/matrix-sergigallart/docker-compose.yml down

# Crear la copia de seguridad
echo "Haciendo la copia de seguridad de homeserver.db ... "
docker cp $CONTAINER_NAME: $HOMESERVER_DB $BACKUP_DIR/$BACKUP_FILE

# Comprimir la copia de seguridad
echo "Comprimiendo la copia de seguridad ... "
tar -czf $BACKUP_DIR/$BACKUP_FILE $BACKUP_DIR/$BACKUP_FILE

# Reiniciar el servidor Synapse
echo "Reiniciando el servidor Synapse ... "
docker-compose -f ~/matrix-sergigallart/docker-compose.yml up -d

# Confirmación
echo "Backup completado: $BACKUP_DIR/$BACKUP_FILE"
