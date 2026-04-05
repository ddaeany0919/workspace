#!/usr/bin/env bash
MY_PATH=$(dirname "$0")
source ${MY_PATH}/common/common_android.sh

while $true; do
    do_execute "app_comp com.netflix.ninja/.MainActivity"
    sleep 10
    do_execute "key_input DPAD_CENTER"
    sleep 10
    do_execute "key_input DPAD_CENTER"
    sleep 10
    do_execute "key_input DPAD_CENTER"
    sleep 60
    do_execute "key_input TV"
    sleep 30
done
