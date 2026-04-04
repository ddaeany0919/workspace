#!/bin/bash

while $true; do

  pid=`adb shell pidof $1`
  echo "pid=$pid"
  adb shell dumpsys meminfo $pid
  adb shell pmap $pid | wc -l
  sleep 2

done
