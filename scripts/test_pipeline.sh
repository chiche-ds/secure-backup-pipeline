#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

TEST_DIR="/data/to-backup/test-pipeline"
QUEUE_FILE="/tmp/backup_queue.txt"
LOG_FILE="/opt/secure-backup-pipeline/logs/backup_pipeline.log"
PIPELINE_SCRIPT="/opt/secure-backup-pipeline/scripts/run_pipeline.sh"

# ---------------- PREPARE TEST ----------------
echo -e "${CYAN}🔹 Preparing test environment...${NC}"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"
> "$QUEUE_FILE"  # clear queue

# 1️⃣ Normal File
echo "This is a normal log file for backup testing $(date)" > "$TEST_DIR/normal_file.txt"

# 2️⃣ Duplicate File (exact same content as normal)
cp "$TEST_DIR/normal_file.txt" "$TEST_DIR/duplicate_file.txt"

# 3️⃣ Sensitive File
echo "This file contains confidential client data and passwords." > "$TEST_DIR/sensitive_file.txt"

# 4️⃣ Virus Test File (EICAR Standard)
echo "X5O!P%@AP[4\PZX54(P^)7CC)7}\$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*" > "$TEST_DIR/virus_file.txt"

# Queue all test files
for FILE in "$TEST_DIR"/*.txt; do
    echo "$FILE" >> "$QUEUE_FILE"
done

echo -e "${CYAN}✅ Test files created and queued.${NC}"
sleep 1

# ---------------- RUN PIPELINE ----------------
echo -e "${CYAN}🔹 Running pipeline test...${NC}"
bash "$PIPELINE_SCRIPT"

# ---------------- VERIFY RESULTS ----------------
echo -e "\n${CYAN}🔹 Checking results...${NC}"

NORMAL_RESULT=$(grep -E "DONE processing .*normal_file.txt" "$LOG_FILE" | tail -1)
DUPLICATE_RESULT=$(grep -E "DUPLICATE skipped: .*duplicate_file.txt" "$LOG_FILE" | tail -1)
SENSITIVE_RESULT=$(grep -E "Classified .*sensitive_file.txt as SENSITIVE_FILE" "$LOG_FILE" | tail -1)
VIRUS_RESULT=$(grep -E "VIRUS DETECTED: .*virus_file.txt" "$LOG_FILE" | tail -1)

TOTAL_PASSED=0
TOTAL_TESTS=4

# Normal File
if [ -n "$NORMAL_RESULT" ]; then
    echo -e "${GREEN}✔ Normal File Test Passed${NC}"
    TOTAL_PASSED=$((TOTAL_PASSED+1))
else
    echo -e "${RED}✖ Normal File Test Failed${NC}"
fi

# Duplicate File
if [ -n "$DUPLICATE_RESULT" ]; then
    echo -e "${GREEN}✔ Duplicate File Test Passed${NC}"
    TOTAL_PASSED=$((TOTAL_PASSED+1))
else
    echo -e "${RED}✖ Duplicate File Test Failed${NC}"
fi

# Sensitive File
if [ -n "$SENSITIVE_RESULT" ]; then
    echo -e "${GREEN}✔ Sensitive File Test Passed${NC}"
    TOTAL_PASSED=$((TOTAL_PASSED+1))
else
    echo -e "${RED}✖ Sensitive File Test Failed${NC}"
fi

# Virus File
if [ -n "$VIRUS_RESULT" ]; then
    echo -e "${GREEN}✔ Virus File Test Passed${NC}"
    TOTAL_PASSED=$((TOTAL_PASSED+1))
else
    echo -e "${RED}✖ Virus File Test Failed${NC}"
fi

# ---------------- TEST SUMMARY ----------------
echo -e "\n${CYAN}==============================================="
echo "           📊 PIPELINE TEST SUMMARY"
echo "==============================================="
echo -e "✅ Tests Passed: ${TOTAL_PASSED}/${TOTAL_TESTS}"
if [ $TOTAL_PASSED -eq $TOTAL_TESTS ]; then
    echo -e "${GREEN}🎉 All tests passed! Your pipeline works correctly.${NC}"
else
    echo -e "${RED}⚠ Some tests failed. Check your logs for details.${NC}"
fi
echo -e "${CYAN}===============================================${NC}\n"
