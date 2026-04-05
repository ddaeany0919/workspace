#!/usr/bin/env bash

source common_bash.sh

function resultOfFrontEnd() {
    local command='
        resultSet=$(cd /mnt/dtvfs/streamers/ 2>/dev/null || exit; 
        streamers=(streamer_*)
        count=${#streamers[@]}
        if (( count > 0 )); then
            egrep -a "State|Uri|Signal" streamer_*/frontend
        fi
        )

        local streamer=""
        while read -r line; do
            _streamer="${line%%/*}"
            values="${line#*/frontend:}"
            if [[ "$_streamer" != "$streamer" ]]; then
                [[ -n "$streamer" ]] && echo ""
                streamer="$_streamer"
                echo "========= $streamer ========="
            fi
            echo " - $values"

            if [[ "$line" == *"Uri:"* ]]; then
                uri_id="${line##*/}"
                dvb_uri="/mnt/dtvfs/live/dvb:$uri_id"
                if cd "$dvb_uri" 2>/dev/null; then
                    ls -lh infos.txt media.ts 2>/dev/null | awk "{print \" -----> \" \$5 \" - \" \$9}"
                fi
            fi
        done <<< "$resultSet"
    '
    adb shell "${command}"
}

function monitoring() {
    watch -t -c -d -n 1 "adb shell '$(declare -f resultOfFrontEnd); resultOfFrontEnd'"
}

monitoring
