#!/usr/bin/env bash

source common_bash.sh;
DEBUG_COMMON_BASH=false;
DEBUG=true;
TC_NAME="CPU Stress test"
TC_SUB_ITEM="CPU Stress test use by DD"

function intro() {
    log -i " # $TC_NAME"
    log -i " - $TC_SUB_ITEM"
    # log -i "  + monitoring : watch -d -n 5 'cat ${WORKSPACE_HOME}/zapping_time'"
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
    local command="tc_count=20 && tc_item=0;"
    command="${command}while [ ${tc_count} -gt ${tc_item} ]; do tc_item=$((tc_item+1)); dd if=/dev/zero of=/dev/null& ; done;"
    do_execute adb shell ${command}
    
}

function verify() {
    max_count=50
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

