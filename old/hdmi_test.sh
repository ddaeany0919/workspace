#!/usr/bin/env bash

source common_menu.sh;
source common_android.sh

DEBUG=false;

set_menu_item_width 15

#### STEP 1 : Declare variables ########################################################################################
declare -A action01=([name]="system_audio"  [cmd]="broadcast com.lge.sys.TERMINATE_ARC --ei MODE 2")
declare -A action02=([name]="live"         [cmd]="broadcast com.lge.sys.TERMINATE_ARC --ei MODE 0")
declare -A action08=([name]="CEC Off"              [cmd]="adb shell settings put global hdmi_control_enabled 0")
declare -A action09=([name]="CEC On"               [cmd]="adb shell settings put global hdmi_control_enabled 1")
declare -A action10=([name]="module build"         [cmd]="module_build.sh")
declare -a menu_items=( ${!action@} )
#### STEP 2 : Declare variables ########################################################################################
function showMenu() {
  select_items=($(show_actions_menu ${!action@} ))

  log -d "select_items=$select_items"
  log -d "count=${#select_items[@]}"

  if [ ${#select_items[@]} -eq 0 ]; then
    return 1;
  else
    for index in ${select_items[@]}; do
      if [ $(isNumber $index) == 1 ]; then
        if [ $index -gt ${#menu_items[@]} ]; then
          continue;
        fi
        index=$(($index - 1))
        declare -n item=${menu_items[$index]}
        #log -i ${item[name]}
        do_execute -i "${item[cmd]}"
      fi
    done
    return 0
  fi
}

while true; do
  if ! showMenu; then
    exit 0;
  fi
done
