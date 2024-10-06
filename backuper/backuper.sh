#/bin/bash
source ./pathList.sh

TARGET_DIR_NAME=target
ARCHIVE_DIR_NAME=archive
BACKUP_ZIP_NAME=backup.zip

if [ -d ${TARGET_DIR_NAME}/${ARCHIVE_DIR_NAME} ]; then
   rm -r ${TARGET_DIR_NAME}/${ARCHIVE_DIR_NAME}/*
fi

for i in $(seq 0 $((${BACKUP_TARGET_CNT} - 1))); do
   rsync -av --mkpath --delete ${BACKUP_BEFORE_PATH[${i}]} ${TARGET_DIR_NAME}/${ARCHIVE_DIR_NAME}/${BACKUP_AFTER_DIR[${i}]}
done

if [ -f ${TARGET_DIR_NAME}/${BACKUP_ZIP_NAME} ]; then
   rm ${TARGET_DIR_NAME}/${BACKUP_ZIP_NAME}
fi

zip -r ${TARGET_DIR_NAME}/${BACKUP_ZIP_NAME} ${TARGET_DIR_NAME}/${ARCHIVE_DIR_NAME}
