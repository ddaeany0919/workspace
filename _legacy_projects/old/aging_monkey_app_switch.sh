#!/usr/bin/env bash
MY_PATH=$(dirname "$0")
source ${MY_PATH}/common/common_android.sh

while $true; do
    adb shell "monkey --ignore-crashes --ignore-timeouts --monitor-native-crashes \
    -p com.google.android.youtube.tv \
    -p com.netflix.ninja \
    -p com.lguplus.android.tv \
    --pct-appswitch 80 --pct-nav 10 --pct-majornav 10 --throttle 100 999999"
done
