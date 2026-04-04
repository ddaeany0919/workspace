#!/usr/bin/env bash

source common_menu.sh;
source common_bash.sh

set_menu_item_width 25
readme_file="${WORKSPACE_HOME}/README.md"
if [ -f "${readme_file}" ]; then
  draw_line_with_title " 📰 README   "
  while IFS= read -r line
  do
    echo "$line"
  done < "${readme_file}"
  draw_line_with_title " 📰 README   "
fi

#### STEP 1 : Declare variables ########################################################################################
declare -A action01=([name]="build modules"         [cmd]="xbuild_module.sh")
declare -A action02=([name]="Android Setting"      [cmd]="menu_setting.sh")

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
