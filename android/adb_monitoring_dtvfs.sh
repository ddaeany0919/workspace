#!/usr/bin/env bash

DEBUG=true;

function resultOfFrontEnd() {
    local command='
        resultSet=$(cd /mnt/dtvfs/streamers/; 
        COUNT=$(find ./ -name "streamer_*" | wc -l)
        COUNT=$((COUNT-1))
        if [[ $COUNT > 0 ]]; then
            STREAMER=$(echo "streamer_{$(seq -s, 0 ${COUNT})}"); 
            egrep -a "State|Uri|Signal" ${STREAMER}/frontend;
        else
            egrep -a "State|Uri|Signal" streamer_0/frontend
        fi
        )
        

        IFS=$'\'\\\n\''
        local streamer
        local values;
        local dvb_uri
        local sizes
        for line in $resultSet; do
            local _streamer=$(echo "${line}" | cut -d"/" -f1);
            values=${line#"${_streamer}/frontend:"}
            if [[ ${_streamer} != ${streamer} ]]; then
                if [[ "" != ${streamer} ]]; then
                    echo ""
                fi
                streamer="${_streamer}"
                echo "========= ${streamer} ========="
            
            fi
            echo " - ${values}"
            

            if [[ ${line} == *"Uri:"* ]]; then
                dvb_uri="/mnt/dtvfs/live/dvb:$(echo $line | toybox rev | cut -d"/" -f1 | toybox rev)"
                cd ${dvb_uri}
                sizes=$(ls -lh infos.txt media.ts | tr -s " ")
                for size in $sizes; do
                    echo " -----> $(echo $size | cut -d" " -f5) - $(echo $size | toybox rev | cut -d" " -f1 | toybox rev)"
                done
                
            fi
    done
    '
    # echo "${command}"

    adb shell "${command}"
}

function monitorDTVFS() {
    while read -r line; do
      echo  "$line"
    done <<< "$(resultOfFrontEnd)"
}

function monioring() {
    export -f resultOfFrontEnd
    export -f monitorDTVFS
    watch -t -c -d -n 1 -x bash -c "monitorDTVFS"
}

monioring;

