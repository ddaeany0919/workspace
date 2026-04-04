#!/bin/bash

# 미러 저장소 경로
REPO_DIR="/mnt/ext1/mirror/mobis/"

# 로그 파일
LOG_FILE="${HOME}/logs/repo_mirror_sync.log"
CPU_COUNT="-j$(nproc)"

if $(nslookup bitbucket.mobis.co.kr >/dev/null 2>&1); then
    echo "Bitbucket server is reachable." >> "$LOG_FILE"
else
    echo "Bitbucket server is not reachable. Exiting." >> "$LOG_FILE"
    exit 1
fi


# 현재 날짜를 로그에 기록
echo "--------------------------------------------" >> "$LOG_FILE"
echo "Sync started at $(date)" >> "$LOG_FILE"

# repo sync 실행
cd "$REPO_DIR"
repo sync $CPU_COUNT --no-tags >> "$LOG_FILE" 2>&1

# 동기화 완료 로그
if [ $? -eq 0 ]; then
    echo "Sync completed successfully at $(date)" >> "$LOG_FILE"
else
    echo "Sync failed at $(date)" >> "$LOG_FILE"
fi

