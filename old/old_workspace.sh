#!/usr/bin/env bash

source common_menu.sh;
source common_android.sh

DEBUG=false;

set_menu_item_width 15

#### STEP 1 : Declare variables ########################################################################################
declare -A action00=([name]="sshfs-dev"            [cmd]="sshfs build:/home/ss.kim1/workspace/cj/kaon/ 0.android")
declare -A action02=([name]="fastboot"             [cmd]="fastboot")
declare -A action03=([name]="Android Setting"      [cmd]="./menu_setting")
declare -A action04=([name]="SYSTEM-kill"          [cmd]="app_kill com.alticast.system")
declare -A action05=([name]="HIDDEN-start"         [cmd]="app_comp com.alticast.cabhidden/.ui.MainActivity")
declare -A action06=([name]="HIDDEN-kill"          [cmd]="app_kill com.alticast.cabhidden")
declare -A action07=([name]="Live Channel"         [cmd]="adb shell \"am start -n com.google.android.tv/com.android.tv.MainActivity\"")
declare -A action08=([name]="restart TIS"          [cmd]="app_kill kr.altimedia.cj.agent ; adb shell am start-foreground-service -n kr.altimedia.cj.agent/kr.altimedia.agent.AgentService")
declare -A action09=([name]="EPG Taurus"           [cmd]="app_comp kr.altimedia.android.epgtaurus/.View.TaurusChannelActivity")
declare -A action10=([name]="restart dummy TIS"    [cmd]="app_kill kr.altimedia.dummy.agent ; adb shell am start-foreground-service -n kr.altimedia.dummy.agent/kr.altimedia.agent.AgentService")
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
