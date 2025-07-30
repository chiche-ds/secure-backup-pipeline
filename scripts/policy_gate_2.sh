#!/bin/bash
FILE=$1
DESTINATION="s3://secure-backups"
LOG_FILE="/opt/secure-backup-pipeline/logs/backup_pipeline.log"

# Prepare JSON input for OPA
cat <<EOF > /tmp/file_input.json
{
    "filename": "$FILE",
    "destination": "$DESTINATION"
}
EOF

# Evaluate Post-Processing Policy
RESULT=$(opa eval --format=json --data /opt/secure-backup-pipeline/policies/post_policy.rego "data.backup.post_policy" --input /tmp/file_input.json)

# Check for denies
if echo "$RESULT" | grep -q "not encrypted\|Unauthorized"; then
    echo "$(date) - Policy Gate 2: DENIED for $FILE" >> $LOG_FILE
    exit 1
else
    echo "$(date) - Policy Gate 2: ALLOWED for $FILE" >> $LOG_FILE
    exit 0
fi
