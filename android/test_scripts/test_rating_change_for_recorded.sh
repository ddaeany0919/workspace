#!/usr/bin/env bash
source ../dtv_tools/common_dtv.sh

TC_NAME="2.3.3 Parental rating"
TC_SUB_ITEM="Program rating change test"
MAX_COUNT=1
currTime=$(( $((Get-Date -UFormat %s)) * 1000 ))
RATING_PREFIX="com.android.tv/IN_TV"
TEST_MONITOR_CMD="watch -d -n 1 'adb shell cat /data/system/users/0/tv-input-manager-state.xml'"

source common_test_loop.sh

function test_step() {
    local rating=$1
    if [ -z "$rating" ];then
        log -w "Need argument: TV_U, TV_UA, TV_A"
        exit 1
    fi
    do_execute adb shell "content update $URI_PROGRAM --bind content_rating:s:$RATING_PREFIX/DVB_$rating --where "start_time_utc_millis <= $currTime and $currTime <= end_time_utc_millis""
}

run_test "$@"
