#!/usr/bin/env bash

source common_bash.sh;
DEBUG_COMMON_BASH=false;
DEBUG=true;
TC_NAME="2.2.4 Channel Change Time"
TC_SUB_ITEM="Channel change to same Transport"

AUTHORITY="com.technicolor.android.dtvprovider"
if [ ! -z ${WORKSPACE_DTVPROVIDER_AUTHOR} ]; then
    AUTHORITY=${WORKSPACE_DTVPROVIDER_AUTHOR}
fi

function intro() {
    log -i " # $TC_NAME"
    log -i " - $TC_SUB_ITEM"
    log -i "  + monitoring : watch -d -n 5 'cat ${WORKSPACE_HOME}/zapping_time'"
}

function summery() {
    local zapping_time=0 
    local count=0 
    local _time=0;
    while read -r line; do  
        # _time=$(echo $line | cut -d"=" -f4)
        zapping_time=$((zapping_time + line)) 
        count=$((count+1)) 
    done <<< $(cut -d'=' -f4 temp/zapping_time)
    log -i "total = ${zapping_time}, count=${count}"
    avg=$((zapping_time / count))
    log -i " ## AVR : ${avg}"
}

function changeChannel() {
    do_execute -q adb shell input keyevent KEYCODE_CHANNEL_UP && sleep 2 && adb shell content query --uri content://${AUTHORITY}/players >> ${WORKSPACE_HOME}/zapping_time
}

function verify() {
    max_count=1000
    count=0;
    do_execute -i "rm -rf ${WORKSPACE_HOME}/zapping_time"

    while [ $max_count -gt ${count} ]
    do
        count=$(( $count + 1 ))
        log -i "change channel [${count} - ${max_count}]"
        changeChannel;
    done
}

intro

verify

summery;

