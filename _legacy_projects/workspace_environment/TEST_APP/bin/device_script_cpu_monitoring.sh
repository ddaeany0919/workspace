#!/system/bin/sh

# 모니터링할 프로세스 키워드 (공백으로 구분)
# 예: "system_server surfaceflinger com.android.phone"
TARGETS="system_server surfaceflinger com.android.systemui"

# 헤더 출력 (간격 조절 가능)
printf "%-10s %-10s %-10s %-20s\n" "PID" "CPU%" "MEM" "PROCESS"
echo "----------------------------------------------------------"

while true; do
    # top 명령어를 1회성(n 1) 배치 모드(-b)로 실행
    # 각 타겟 프로세스별로 순회하며 정보 추출
    for target in $TARGETS; do
        top -b -n 1 | grep "$target" | while read -r line; do
            # top 출력 컬럼: PID, USER, PR, NI, VIRT, RES, SHR, S, %CPU, %MEM, TIME+, COMMAND
            # awk를 사용하여 필요한 컬럼(PID, %CPU, RES, COMMAND)만 추출
            echo "$line" | awk '{printf "%-10s %-10s %-10s %-20s\n", $1, $9, $6, $12}'
        done
    done
    
    # 2초 간격으로 업데이트 (조절 가능)
    sleep 2
    echo "---------------------------"
done