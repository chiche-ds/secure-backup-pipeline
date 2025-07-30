#!/bin/bash
FILE=$1
STAGING="/opt/secure-backup-pipeline/logs/staging"
mkdir -p $STAGING

COMPRESSED="$STAGING/$(basename $FILE).zst"
ENCRYPTED="$STAGING/$(basename $FILE).zst.gpg"
LOG_FILE="/opt/secure-backup-pipeline/logs/backup_pipeline.log"

# Load passphrase from secure file
PASSPHRASE_FILE="/opt/secure-backup-pipeline/configs/gpg_passphrase.txt"

# Compress file
zstd "$FILE" -o "$COMPRESSED"

# Encrypt using stored passphrase
gpg --batch --yes --passphrase-file "$PASSPHRASE_FILE" --symmetric --cipher-algo AES256 "$COMPRESSED"

if [ $? -eq 0 ]; then
    echo "$(date) - Compressed & Encrypted: $ENCRYPTED" >> $LOG_FILE
else
    echo "$(date) - ERROR: Compression/Encryption failed for $FILE" >> $LOG_FILE
    exit 1
fi

echo $ENCRYPTED
