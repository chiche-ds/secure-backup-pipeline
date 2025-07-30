#!/bin/bash
WATCH_DIR="/data/to-backup"
QUEUE_FILE="/tmp/backup_queue.txt"
LOG_FILE="/opt/secure-backup-pipeline/logs/backup_pipeline.log"

mkdir -p $WATCH_DIR

inotifywait -m -r -e create,modify,move $WATCH_DIR |
while read path action file; do
    echo "$(date) - Detected: $path$file ($action)" | tee -a $LOG_FILE
    echo "$path$file" >> $QUEUE_FILE
done
