#!/usr/bin/env bash

source common_bash.sh

function key_input() {
  adb shell input keyevent KEYCODE_$1
}

function app_kill() {
  pid=$(adb shell pidof $1)
  if [ $pid != "" ]; then
    do_execute -i "adb shell kill $pid"
  fi
}

function app_comp() {
  do_execute -i "adb shell \"am start -n $1\""
}


function app_action () {
    do_execute -i "adb shell \"am start -a $1\""
}
