#!/bin/bash
while [ true ]
do
   adb shell input keyevent 23
   sleep 1
   adb shell input keyevent 23
   sleep 1
   adb shell input keyevent 23
   sleep 1
   adb shell input keyevent 23
   sleep 1
   adb shell input keyevent 23
   sleep 30
   adb shell input keyevent 111
   sleep 1
   adb shell input keyevent 23
   sleep 1
   adb shell input keyevent 111
   sleep 1
   adb shell input keyevent 3
   sleep 1
done
