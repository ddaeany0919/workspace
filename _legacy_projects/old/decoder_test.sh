#!/bin/bash
while [ true ]
do
   adb shell input keyevent KEYCODE_HOME
   sleep 2
   adb shell am start -n com.google.android.youtube.tv/com.google.android.apps.youtube.tv.activity.ShellActivity
   sleep 2
done
