#!/bin/bash
FILE=$1
LOG_FILE="/opt/secure-backup-pipeline/logs/backup_pipeline.log"

# GPG symmetric encryption with a predefined passphrase (stored in env)
ENCRYPTED="${FILE}.gpg"

# Use a passphrase stored in /opt/secure-backup-pipeline/.gpg_pass
PASSPHRASE_FILE="/opt/secure-backup-pipeline/.gpg_pass"
if [ ! -f "$PASSPHRASE_FILE" ]; then
    echo "ChangeThisPassphrase" > "$PASSPHRASE_FILE"
fi

gpg --batch --yes --symmetric --cipher-algo AES256 \
    --passphrase-file "$PASSPHRASE_FILE" \
    -o "$ENCRYPTED" "$FILE"

if [ -f "$ENCRYPTED" ]; then
    echo "$(date) - Encrypted $FILE -> $ENCRYPTED" >> $LOG_FILE
    echo "$ENCRYPTED"
    exit 0
else
    echo "$(date) - Encryption failed for $FILE" >> $LOG_FILE
    exit 1
fi
