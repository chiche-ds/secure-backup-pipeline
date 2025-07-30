#!/bin/bash
FILE=$1
LOG_FILE="/opt/secure-backup-pipeline/logs/backup_pipeline.log"

# Quick demo policy: reject files larger than 500MB or non-.txt
SIZE_MB=$(du -m "$FILE" | cut -f1)
EXT="${FILE##*.}"

if [ "$SIZE_MB" -gt 500 ]; then
    echo "$(date) - Policy Gate 1: DENIED (File too large) $FILE" >> $LOG_FILE
    exit 1
fi

if [ "$EXT" != "txt" ]; then
    echo "$(date) - Policy Gate 1: DENIED (Unsupported type) $FILE" >> $LOG_FILE
    exit 1
fi

echo "$(date) - Policy Gate 1: ALLOWED $FILE" >> $LOG_FILE
exit 0
