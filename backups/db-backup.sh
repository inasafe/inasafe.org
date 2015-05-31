#!/bin/bash

DATE=$(date +%d%B%Y)
YEAR=$(date +%Y)
MONTH=$(date +%m)

BACKUP_PATH=/backups/${YEAR}/${MONTH}
mkdir -p $BACKUP_PATH

mysqldump wordpress -u root > ${BACKUP_PATH}/${DATE}.sql
