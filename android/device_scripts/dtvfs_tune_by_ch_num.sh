#!/usr/bin/env bash

source common_bash.sh

# 기기 내부용 common_bash.sh가 있다면 사용
[[ -f "./common_bash.sh" ]] && source ./common_bash.sh

function resultOfFrontEnd() {
    local streamers=(streamer_*)
    (( ${#streamers[@]} == 0 )) && return
    
    egrep -a "State|Uri|Signal" streamer_*/frontend | while read -r line; do
        local streamer="${line%%/*}"
        local values="${line#*/frontend:}"
        echo "========= $streamer ========="
        echo " - $values"

        if [[ "$line" == *"Uri:"* ]]; then
            local uri_id="${line##*/}"
            local dvb_uri="/mnt/dtvfs/live/dvb:$uri_id"
            [[ -d "$dvb_uri" ]] && ls -lh "$dvb_uri/infos.txt" "$dvb_uri/media.ts" 2>/dev/null
        fi
    done
}

# 기기 내부에서 직접 실행되는 루프
while true; do
    clear
    resultOfFrontEnd
    sleep 1
done
