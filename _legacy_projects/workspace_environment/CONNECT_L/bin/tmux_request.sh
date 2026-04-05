#!/bin/bash
source common_bash.sh

SESSION=${LAGVM_PRODUCT_NAME}
BUILD_CMD="${@:-make -j8}"  # 전달 명령 없으면 make -j8
ME=$(basename "$0")
trap cleanup SIGINT

echo "================================================================"
log -i "$ME: $BUILD_CMD"
echo "================================================================"
function cleanup() {
    log -i "빌드 중단됨. tmux 세션 '$SESSION' 종료."
    tmux send-keys -t ${SESSION} C-c
    kill $TAIL_PID
    exit 1
}

LOG_FILE="${WORKSPACE_HOME}/temp/tmux.log"
RESULT_FILE="${WORKSPACE_HOME}/temp/tmux_result.txt"
# 세션이 존재하지 않으면 생성
if ! tmux has-session -t $SESSION 2>/dev/null; then
    tmux new-session -d -s $SESSION
    log -i "새 tmux 세션 '$SESSION' 생성됨."
    do_execute -i tmux send-keys -t $SESSION \"cd ${WORKSPACE_ANDROID_HOME}\" C-m
    do_execute -i tmux send-keys -t $SESSION \"source build/envsetup.sh\" C-m
    do_execute -i tmux send-keys -t $SESSION \"lunch ${LAGVM_PRODUCT_NAME}-${LAGVM_BUILD_VARIANT}\" C-m
# else
    # log -i "기존 tmux 세션 '$SESSION'에 연결합니다."
fi

# # 빌드 명령 템플릿 (종료코드 기록)
rm -f $LOG_FILE $RESULT_FILE 2>/dev/null

SEND_CMD="(${BUILD_CMD} 2>&1 | tee $LOG_FILE; echo \${PIPESTATUS[0]} > $RESULT_FILE)"

# # tmux로 명령 전달
tmux send-keys -t $SESSION "$SEND_CMD" C-m


# log 파일이 생성될 때까지 대기
while [ ! -f "$LOG_FILE" ]; do sleep 0.1; done

# 백그라운드로 tail 실행 & PID 저장
tail -f "$LOG_FILE" &
TAIL_PID=$!

# result 파일 생성 대기
while [ ! -f "$RESULT_FILE" ]; do sleep 1; done

# tail 종료
kill $TAIL_PID

# 결과 표시
RETVAL=$(cat "$RESULT_FILE")
exit ${RETVAL}
# echo
# echo "=========================="
# echo "빌드 종료 코드: $RETVAL"
# if [ "$RETVAL" = "0" ]; then
# else
#     echo "빌드 실패!"
# fi
# echo "=========================="
