#!/usr/bin/env bash

source common_menu.sh;
DEBUG_COMMON_BASH=false;
DEBUG=false;

#### STEP 1 : Declare variables ########################################################################################
declare -A action0=([name]="help"        [cmd]="./fastboot -h")
declare -A action1=([name]="build"       [cmd]="./fastboot -r -p 0.android/out/target/product/tmau400 " )
declare -A action2=([name]="all"         [cmd]="./fastboot -p 0.android/out/target/product/tmau400" )
declare -A action3=([name]="system"      [cmd]="./fastboot -p 0.android/out/target/product/tmau400 -i system")
declare -A action4=([name]="vendor"      [cmd]="./fastboot -p 0.android/out/target/product/tmau400 -i vendor")
declare -A action5=([name]="product"     [cmd]="./fastboot -p 0.android/out/target/product/tmau400 -i product")
declare -A action6=([name]="userdate"    [cmd]="./fastboot -p 0.android/out/target/product/tmau400 -i userdata")
declare -A action7=([name]="recovery"    [cmd]="./fastboot -p 0.android/out/target/product/tmau400 -i recovery")
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
