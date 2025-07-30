#!/bin/bash
FILE=$1
LOG_FILE="/opt/secure-backup-pipeline/logs/backup_pipeline.log"

# Prepare JSON input for OPA
SIZE_MB=$(du -m "$FILE" | cut -f1)
cat <<EOF > /tmp/file_input.json
{
    "filename": "$FILE",
    "size_mb": $SIZE_MB
}
EOF

# Evaluate Pre-Processing Policy
RESULT=$(opa eval --format=json --data /opt/secure-backup-pipeline/policies/pre_policy.rego "data.backup.pre_policy" --input /tmp/file_input.json)

# Check for denies
if echo "$RESULT" | grep -q "File too large\|Unsupported file type"; then
    echo "$(date) - Policy Gate 1: DENIED for $FILE" >> $LOG_FILE
    exit 1
else
    echo "$(date) - Policy Gate 1: ALLOWED for $FILE" >> $LOG_FILE
    exit 0
fi
