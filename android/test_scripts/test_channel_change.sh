#!/usr/bin/env bash
source ../dtv_tools/common_dtv.sh

TC_NAME="2.2.4 Channel Change Time"
TC_SUB_ITEM="Channel change to same Transport"
MAX_COUNT=1000
TEST_LOG_FILE="$WORKSPACE_HOME/zapping_time"
TEST_MONITOR_CMD="watch -d -n 5 'cat $TEST_LOG_FILE'"

source common_test_loop.sh

function test_step() {
    do_execute -q "adb shell input keyevent KEYCODE_CHANNEL_UP && sleep 2 && adb shell content query --uri content://$AUTHORITY/players >> $TEST_LOG_FILE"
}

run_test "$@"
