#!/bin/sh
# cpu_stress.sh - ADB CPU 부하 테스트 스크립트
#
# 사용법:
#   sh cpu_stress.sh <count> <duration>
#
# 인자:
#   count     - dd 프로세스 수 (예: 4)
#   duration  - 실행 시간 초 (예: 30)
#
# 예시:
#   adb shell sh /data/local/tmp/cpu_stress.sh 4 30

COUNT=$1
DURATION=$2

# adb shell 로 실행되는데, ctrl+c로 중단할 때, 모든 dd 프로세스를 종료처리
trap "echo 'Stopping all processes...'; pkill -f 'dd if=/dev/zero of=/dev/null'; echo 'Done.'; exit" EXIT

# 인자 검증
if [ -z "$COUNT" ] || [ -z "$DURATION" ]; then
  echo "Usage: sh cpu_stress.sh <count> <duration>"
  echo "  count    : number of dd processes"
  echo "  duration : run time in seconds (if 0, runs indefinitely)"
  echo ""
  echo "Example: sh cpu_stress.sh 4 30"
  exit 1
fi

if [ "$COUNT" -le 0 ] 2>/dev/null || [ "$DURATION" -lt 0 ] 2>/dev/null; then
  echo "Error: count and duration must be positive integers"
  exit 1
fi

echo "==============================="
echo " CPU Stress Test"
echo " Processes : $COUNT"
# if DURATION is 0, it will run indefinitely
if [ "$DURATION" -eq 0 ]; then
  echo " Duration  : Infinite (until manually stopped)"
else
  echo " Duration  : ${DURATION}s"
fi
echo "==============================="

PIDS=""
i=1
while [ $i -le $COUNT ]; do
  dd if=/dev/zero of=/dev/null bs=1M > /dev/null 2>&1 &
  PIDS="$PIDS $!"
  echo "[+] PID $! started ($i/$COUNT)"
  i=$((i + 1))
done

echo ""
echo "All $COUNT processes running."

if [ "$DURATION" -eq 0 ]; then
  echo "waiting indefinitely... Press Ctrl+C to stop."
  while true; do
    sleep 1
  done
else
  echo "Waiting ${DURATION}s..."
  echo ""
  sleep $DURATION
fi

echo "Stopping all processes..."
for PID in $PIDS; do
  kill $PID 2>/dev/null && echo "[-] Killed PID $PID" || echo "[!] PID $PID already exited"
done

echo ""
echo "Done."