#!/bin/bash

# ---------------- CONFIGURATION ----------------
LOG_FILE="/opt/secure-backup-pipeline/logs/backup_pipeline.log"
QUEUE_FILE="/tmp/backup_queue.txt"
SCRIPTS_DIR="/opt/secure-backup-pipeline/scripts"
HASH_DB="/opt/secure-backup-pipeline/logs/hashes.json"

# ---------------- COLORS ----------------
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ---------------- ALERT FUNCTIONS ----------------
play_sound() {
    case $1 in
        success) for i in {1..3}; do echo -ne '\007'; sleep 0.2; done ;; # 3 short beeps
        fail) echo -ne '\007'; sleep 0.5; echo -ne '\007' ;; # 2 long beeps
    esac
}

notify_user() {
    if command -v notify-send &> /dev/null; then
        if [ "$1" = "success" ]; then
            notify-send "✅ Backup Successful" "$2 processed and uploaded!"
        else
            notify-send "❌ Backup Failed" "$2 failed during processing!"
        fi
    fi
}

# ---------------- FANCY PROGRESS BAR ----------------
progress_bar() {
    local duration=$1
    local message=$2
    local cols=$(tput cols)
    local bar_length=$((cols - 30))
    local progress=0

    echo -ne "${YELLOW}${message}...${NC}\n"
    while [ $progress -le $duration ]; do
        local percent=$((100 * progress / duration))
        local filled=$((bar_length * progress / duration))
        local empty=$((bar_length - filled))

        FILLED_BAR=$(printf "%0.s█" $(seq 1 $filled))
        EMPTY_BAR=$(printf "%0.s░" $(seq 1 $empty))

        if [ $percent -le 33 ]; then COLOR=$RED
        elif [ $percent -le 66 ]; then COLOR=$YELLOW
        else COLOR=$GREEN; fi

        printf "\r${COLOR}[%s%s] %3d%%${NC}" "$FILLED_BAR" "$EMPTY_BAR" "$percent"
        sleep 1
        progress=$((progress + 1))
    done
    echo -e "\n"
}

# ---------------- LOG SYSTEM STATS ----------------
log_system_stats() {
    if command -v mpstat &> /dev/null; then
        CPU_USAGE=$(mpstat 1 1 | awk '/Average/ && $NF ~ /[0-9.]+/ { print 100 - $NF }')
    else
        CPU_USAGE=$(top -bn2 | grep "Cpu(s)" | tail -n 1 | awk '{print 100 - $8}')
    fi
    MEM_USAGE=$(free -m | awk '/Mem:/ { printf "%.2f", ($3/$2)*100 }')
    echo "$(date) - 📊 CPU Usage: ${CPU_USAGE}% | Memory Usage: ${MEM_USAGE}%" >> $LOG_FILE
}

# ---------------- LIVE ROLLING SUMMARY ----------------
rolling_summary() {
    local current_time=$(date +%s)
    local elapsed=$((current_time - START_TIME))
    local total_processed=$((SUCCESS_COUNT + FAIL_COUNT + SKIP_COUNT))

    local avg_time=0
    if [ $total_processed -gt 0 ]; then
        avg_time=$((elapsed / total_processed))
    fi

    echo -e "${CYAN}-----------------------------------------------${NC}"
    echo -e "${CYAN}📊 LIVE PIPELINE STATUS${NC}"
    echo -e "${GREEN}✔ Success: $SUCCESS_COUNT${NC} | ${YELLOW}⚠ Skipped: $SKIP_COUNT${NC} | ${RED}✖ Failed: $FAIL_COUNT${NC}"
    echo -e "${CYAN}⏱ Total Processed: $total_processed | Avg Time/File: ${avg_time}s${NC}"
    echo -e "${CYAN}-----------------------------------------------${NC}"
}

# ---------------- ASCII BANNER ----------------
clear
echo -e "${CYAN}"
echo "==============================================="
echo "      🔐  WELCOME TO SECURE BACKUP SYSTEM  🔐"
echo "==============================================="
echo -e "${NC}"
echo -e "${YELLOW}This pipeline will automatically process, encrypt, and upload your files securely.${NC}\n"
sleep 2

# ---------------- INIT ----------------
touch "$QUEUE_FILE"
if [ ! -s "$HASH_DB" ]; then echo "{}" > "$HASH_DB"; fi

SUCCESS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
START_TIME=$(date +%s)

# ---------------- PIPELINE LOOP ----------------
while true; do
    FILE=$(head -n 1 "$QUEUE_FILE")
    [ -z "$FILE" ] && break
    sed -i '1d' "$QUEUE_FILE"   # Remove file from queue immediately

    FILE_START=$(date +%s)
    echo -e "\n${CYAN}🔹 Processing file: $FILE ${NC}"
    echo "$(date) - START processing $FILE" >> $LOG_FILE

    # 1️⃣ Duplicate Check
    echo -e "${YELLOW}🔹 Step 1: Checking for duplicates...${NC}"
    python3 "$SCRIPTS_DIR/check_duplicates.py" "$FILE"
    if [ $? -ne 0 ]; then
        echo -e "${RED}✖ Duplicate detected. Skipping: $FILE${NC}"
        echo "$(date) - DUPLICATE skipped: $FILE" >> $LOG_FILE
        SKIP_COUNT=$((SKIP_COUNT+1))
        play_sound fail; notify_user fail "$FILE"; log_system_stats; rolling_summary
        continue
    fi
    echo -e "${GREEN}✔ No duplicate found${NC}"

    # 2️⃣ Classify File
    echo -e "${YELLOW}🔹 Step 2: Classifying file type and content...${NC}"
    CLASS=$(bash "$SCRIPTS_DIR/classify_file.sh" "$FILE")
    echo -e "${CYAN}ℹ Classification Result: $CLASS ${NC}"

    # 3️⃣ Policy Gate 1
    echo -e "${YELLOW}🔹 Step 3: Applying Policy Gate 1...${NC}"
    bash "$SCRIPTS_DIR/policy_gate_1.sh" "$FILE"
    if [ $? -ne 0 ]; then
        echo -e "${RED}✖ Policy Gate 1 denied: $FILE${NC}"
        echo "$(date) - DENIED by Policy Gate 1: $FILE" >> $LOG_FILE
        SKIP_COUNT=$((SKIP_COUNT+1))
        play_sound fail; notify_user fail "$FILE"; log_system_stats; rolling_summary
        continue
    fi
    echo -e "${GREEN}✔ Policy Gate 1 passed${NC}"

    # 4️⃣ Virus Scan
    echo -e "${YELLOW}🔹 Step 4: Scanning for viruses...${NC}"
    bash "$SCRIPTS_DIR/scan_and_quarantine.sh" "$FILE"
    if [ $? -ne 0 ]; then
        echo -e "${RED}✖ Virus detected! File quarantined: $FILE${NC}"
        echo "$(date) - VIRUS DETECTED: $FILE" >> $LOG_FILE
        SKIP_COUNT=$((SKIP_COUNT+1))
        play_sound fail; notify_user fail "$FILE"; log_system_stats; rolling_summary
        continue
    fi
    echo -e "${GREEN}✔ File is clean${NC}"

    # 5️⃣ Compression
    echo -e "${YELLOW}🔹 Step 5: Compressing file...${NC}"
    progress_bar 5 "Compressing"
    COMPRESSED=$(bash "$SCRIPTS_DIR/compress_file.sh" "$FILE")
    if [ ! -f "$COMPRESSED" ]; then
        echo -e "${RED}✖ Compression failed${NC}"
        echo "$(date) - COMPRESSION FAILED: $FILE" >> $LOG_FILE
        FAIL_COUNT=$((FAIL_COUNT+1))
        play_sound fail; notify_user fail "$FILE"; log_system_stats; rolling_summary
        continue
    fi
    echo -e "${GREEN}✔ Compression completed${NC}"

    # 6️⃣ Encryption
    echo -e "${YELLOW}🔹 Step 6: Encrypting file...${NC}"
    progress_bar 5 "Encrypting"
    ENCRYPTED=$(bash "$SCRIPTS_DIR/encrypt_file.sh" "$COMPRESSED")
    if [ ! -f "$ENCRYPTED" ]; then
        echo -e "${RED}✖ Encryption failed${NC}"
        echo "$(date) - ENCRYPTION FAILED: $FILE" >> $LOG_FILE
        FAIL_COUNT=$((FAIL_COUNT+1))
        play_sound fail; notify_user fail "$FILE"; log_system_stats; rolling_summary
        continue
    fi
    echo -e "${GREEN}✔ Encryption successful${NC}"

    # 7️⃣ Policy Gate 2
    echo -e "${YELLOW}🔹 Step 7: Applying Policy Gate 2...${NC}"
    bash "$SCRIPTS_DIR/policy_gate_2.sh" "$ENCRYPTED"
    if [ $? -ne 0 ]; then
        echo -e "${RED}✖ Policy Gate 2 denied upload${NC}"
        echo "$(date) - DENIED by Policy Gate 2: $ENCRYPTED" >> $LOG_FILE
        SKIP_COUNT=$((SKIP_COUNT+1))
        play_sound fail; notify_user fail "$FILE"; log_system_stats; rolling_summary
        continue
    fi
    echo -e "${GREEN}✔ Policy Gate 2 passed${NC}"

    # 8️⃣ Upload to S3
    echo -e "${YELLOW}🔹 Step 8: Uploading to S3...${NC}"
    progress_bar 7 "Uploading to S3"
    bash "$SCRIPTS_DIR/upload_to_s3.sh" "$ENCRYPTED"
    if [ $? -ne 0 ]; then
        echo -e "${RED}✖ Upload failed for: $ENCRYPTED${NC}"
        echo "$(date) - UPLOAD FAILED: $ENCRYPTED" >> $LOG_FILE
        FAIL_COUNT=$((FAIL_COUNT+1))
        play_sound fail; notify_user fail "$FILE"; log_system_stats; rolling_summary
        continue
    fi
    echo -e "${GREEN}✔ Upload successful${NC}"
    SUCCESS_COUNT=$((SUCCESS_COUNT+1))
    play_sound success; notify_user success "$FILE"; log_system_stats

    FILE_END=$(date +%s)
    FILE_TIME=$((FILE_END - FILE_START))
    echo -e "${CYAN}⏱ File processed in ${FILE_TIME}s${NC}"
    echo "$(date) - DONE processing $FILE in ${FILE_TIME}s" >> $LOG_FILE

    rolling_summary
done

# ---------------- FINAL SUMMARY ----------------
END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))

if command -v mpstat &> /dev/null; then
    CPU_USAGE=$(mpstat 1 1 | awk '/Average/ && $NF ~ /[0-9.]+/ { print 100 - $NF }')
else
    CPU_USAGE=$(top -bn2 | grep "Cpu(s)" | tail -n 1 | awk '{print 100 - $8}')
fi
MEM_USAGE=$(free -m | awk '/Mem:/ { printf "%.2f", ($3/$2)*100 }')

echo "$(date) - 📊 SUMMARY: Success=$SUCCESS_COUNT | Skipped=$SKIP_COUNT | Failed=$FAIL_COUNT | Runtime=${TOTAL_TIME}s | CPU=${CPU_USAGE}% | Memory=${MEM_USAGE}%" >> $LOG_FILE

echo -e "\n${CYAN}==============================================="
echo "        📊  PIPELINE SUMMARY REPORT  📊"
echo "==============================================="
echo -e "${GREEN}✔ Successful Files: ${SUCCESS_COUNT}${NC}"
echo -e "${YELLOW}⚠ Skipped Files:    ${SKIP_COUNT}${NC}"
echo -e "${RED}✖ Failed Files:     ${FAIL_COUNT}${NC}"
echo -e "${CYAN}⏱ Total Runtime:    ${TOTAL_TIME}s${NC}"
echo -e "${CYAN}💻 CPU Utilization:  ${CPU_USAGE}%%${NC}"
echo -e "${CYAN}🖥 Memory Usage:     ${MEM_USAGE}%%${NC}"
echo -e "===============================================${NC}\n"
