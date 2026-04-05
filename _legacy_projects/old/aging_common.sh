#!/usr/bin/env bash
source common/common_bash.sh

function aging_loop() {
    local max_count="${1:-100}"
    log -i "Starting aging test: max_count=${max_count}"
    
    # seq 대신 bash 내장 루프 사용
    for ((i=1; i<=max_count; i++)); do
        log -i "Iteration [$i / $max_count]"
        do_execute "adb shell input keyevent KEYCODE_POWER"
        sleep 2
        # ... (중략)
    done
}

aging_loop "$@"
