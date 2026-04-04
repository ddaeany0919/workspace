#!/system/bin/sh

# # 사용법 안내
# if [ $# -lt 1 ]; then
#     echo "Usage: sh monitor.sh [package1] [package2:thread] ..."
#     echo "Example: sh monitor.sh com.android.hmg.evs2:GLThread com.hmg.car"
#     exit 1
# fi

LOG_FILE="/data/local/tmp/cpu_monitor_$(date +%Y%m%d_%H%M%S).csv"
INTERVAL=10

# CSV 헤더 생성
HEADER="Timestamp"
for arg in "$@"; do
    HEADER="$HEADER, $arg"
done
echo "$HEADER" > "$LOG_FILE"
PKG=""

if [ ! -z $1 ]; then
    echo "Monitoring CPU usage for: $@"
    PKG=$1
    PID=$(pidof $PKG)
    if [ -z "$PID" ]; then
        echo "Package $PKG is not running. Exiting."
        exit 1
    fi
    if [ ! -z "$2" ]; then
        echo "Monitoring thread $2 in package $PKG"
    else
        echo "Monitoring entire package $PKG"
    fi
    THREAD=$2
fi


echo "Log saved to: $LOG_FILE"
echo "Monitoring started... (Press Ctrl+C to stop)"

while true; do
    TIME=$(date +"%H:%M:%S")
    ROW="$TIME"

    # for arg in "$@"; do
        # 패키지명과 스레드명 분리 (구분자 ':')
        # PKG=$(echo $arg | cut -d':' -f1)
        # THREAD=$(echo $arg | cut -d':' -f2)
        
        # PID 찾기
    PID=$(pidof $PKG)
    
    if [ -z "$PID" ]; then
        VALUE="0"
    else
        if [ -z "$PKG" ]; then
            VALUE=$(top -d $INTERVAL -b -n 1 -q -m 3 | grep -v "top -d")

        elif [ -z "$THREAD" ]; then
            # 1. 패키지 전체 모니터링 (스레드명이 없을 때)
            VALUE=$(top -d $INTERVAL -b -n 1 -p $PID | grep "$PKG" | awk '{print $9}' | head -n 1)
        else
            # 2. 특정 스레드 모니터링
            VALUE=$(top -d $INTERVAL -b -n 1 -H -p $PID | grep "$THREAD" | awk '{print $9}' | head -n 1)
        fi
        # if [ "$PKG" = "$THREAD" ]; then
        #     # 1. 패키지 전체 모니터링 (스레드명이 없을 때)
        #     VALUE=$(top -b -n 1 -p $PID | grep "$PKG" | awk '{print $9}' | head -n 1)
        # else
        #     # 2. 특정 스레드 모니터링
        #     VALUE=$(top -b -n 1 -H -p $PID | grep "$THREAD" | awk '{print $9}' | head -n 1)
        # fi
    fi

    # 값이 비어있으면 0으로 치환
    [ -z "$VALUE" ] && VALUE="0"
    ROW="$ROW, $VALUE"
    # done

    # 결과 기록 및 화면 출력
    echo "$ROW" >> "$LOG_FILE"
    echo "$ROW"
    
    sleep $INTERVAL
done