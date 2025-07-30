FILE=$1
QUARANTINE="/opt/secure-backup-pipeline/logs/quarantine"
LOG_FILE="/opt/secure-backup-pipeline/logs/backup_pipeline.log"

mkdir -p $QUARANTINE

if clamscan --no-summary "$FILE" | grep -q "FOUND"; then
    mv "$FILE" "$QUARANTINE/"
    echo "$(date) - VIRUS DETECTED: $FILE moved to quarantine" >> $LOG_FILE
    exit 1
else
    echo "$(date) - CLEAN: $FILE passed virus scan" >> $LOG_FILE
fi
