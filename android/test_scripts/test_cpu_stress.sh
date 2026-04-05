#!/usr/bin/env bash
source ../common_android.sh

TC_NAME="CPU Stress test"
TC_SUB_ITEM="CPU Stress test use by DD"
MAX_COUNT=50

source common_test_loop.sh

function test_step() {
    local command="tc_count=20; tc_item=0; while [ \$tc_count -gt \$tc_item ]; do tc_item=\; dd if=/dev/zero of=/dev/null & done;"
    do_execute adb shell "$command"
}

run_test "$@"
