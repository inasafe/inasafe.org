#!/bin/bash


DATE=$(date +%d%B%Y)
YEAR=$(date +%Y)
MONTH=$(date +%m)

BACKUP_PATH=./backups/${YEAR}/${MONTH}
mkdir -p $BACKUP_PATH

tar cfz ${BACKUP_PATH}/${DATE}.wp-content-backup.tar.gz wp-content
