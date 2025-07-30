#!/bin/bash
FILE=$1
LOG_FILE="/opt/secure-backup-pipeline/logs/backup_pipeline.log"

FILENAME=$(basename "$FILE")
EXT="${FILENAME##*.}"
CONTENT_SAMPLE=$(head -n 50 "$FILE" | tr '[:upper:]' '[:lower:]')

CATEGORY="GENERAL_FILE"

##############################################
# Classification Logic
##############################################

# Check for sensitive keywords
if echo "$CONTENT_SAMPLE" | grep -qE "password|secret|confidential|classified|private_key"; then
    CATEGORY="SENSITIVE_FILE"

# Check for personal data indicators
elif echo "$CONTENT_SAMPLE" | grep -qE "name|address|phone|email|dob|id card|passport"; then
    CATEGORY="PERSONAL_FILE"

# Check by file type
elif [[ "$EXT" == "log" || "$EXT" == "txt" || "$EXT" == "csv" ]]; then
    CATEGORY="GENERAL_FILE"
else
    CATEGORY="GENERAL_FILE"
fi

echo "$(date) - Classified $FILE as $CATEGORY" >> $LOG_FILE
echo "$CATEGORY"
exit 0
