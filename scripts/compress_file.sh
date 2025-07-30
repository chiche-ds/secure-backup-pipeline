#!/bin/bash
FILE=$1
STAGING_DIR="/opt/secure-backup-pipeline/logs/staging"
LOG_FILE="/opt/secure-backup-pipeline/logs/backup_pipeline.log"

mkdir -p "$STAGING_DIR"

BASENAME=$(basename "$FILE")
COMPRESSED="$STAGING_DIR/${BASENAME}.zst"

# Compress with zstd
zstd -q -f "$FILE" -o "$COMPRESSED"

if [ -f "$COMPRESSED" ]; then
    echo "$(date) - Compressed $FILE -> $COMPRESSED" >> $LOG_FILE
    echo "$COMPRESSED"
    exit 0
else
    echo "$(date) - Compression failed for $FILE" >> $LOG_FILE
    exit 1
fi
