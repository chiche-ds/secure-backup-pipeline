#!/bin/bash
ENCRYPTED_FILE=$1
S3_BUCKET="secure-backups"
S3_PATH="backups/$(date +%Y-%m-%d)/"
LOG_FILE="/opt/secure-backup-pipeline/logs/backup_pipeline.log"

aws s3api put-object \
    --bucket $S3_BUCKET \
    --key "${S3_PATH}$(basename $ENCRYPTED_FILE)" \
    --body $ENCRYPTED_FILE \
    --object-lock-mode COMPLIANCE \
    --object-lock-retain-until-date $(date -d "+30 days" --utc +%Y-%m-%dT%H:%M:%SZ)

if [ $? -eq 0 ]; then
    echo "$(date) - Uploaded $(basename $ENCRYPTED_FILE) to $S3_BUCKET/$S3_PATH" >> $LOG_FILE
else
    echo "$(date) - Upload failed for $(basename $ENCRYPTED_FILE)" >> $LOG_FILE
fi
