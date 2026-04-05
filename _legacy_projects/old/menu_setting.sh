#!/usr/bin/env bash

source common_menu.sh;
source common_android.sh

DEBUG_COMMON_BASH=false;
DEBUG=false;

#### STEP 1 : Declare variables ########################################################################################
declare -A action0=([name]="main"        [cmd]="app_action android.settings.SETTINGS")
declare -A action1=([name]="bluetooth"   [cmd]="app_comp com.android.tv.settings/.accessories.BluetoothDevicePickerActivity" )
declare -A action2=([name]="developer"   [cmd]="app_comp com.android.tv.settings/.system.development.DevelopmentActivity" )
declare -A action3=([name]="restric"     [cmd]="app_comp com.android.tv.settings/.system.SecurityActivity" )
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
log "\n"
  if ! showMenu; then
    exit 0;
  fi
done
