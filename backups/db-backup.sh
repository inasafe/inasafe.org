#!/bin/bash


USER_ID=`ls -lahn /backups | tail -1 | awk {'print $3'}`
GROUP_ID=`ls -lahn /backups | tail -1 | awk {'print $4'}`
USER_NAME=`ls -lah /backups | tail -1 | awk '{print $9}'`

DATE=$(date +%d%B%Y)
YEAR=$(date +%Y)
MONTH=$(date +%m)

BACKUP_PATH=/backups/${YEAR}/${MONTH}
mkdir -p $BACKUP_PATH

mysqldump wordpress -u root > ${BACKUP_PATH}/${DATE}.sql

chown -R ${USER_ID}.${GROUP_ID} /backups
