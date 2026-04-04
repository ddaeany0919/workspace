#!/usr/bin/env bash

source common_menu.sh;
source common_android.sh

#### Menu config
COMMON_MENU_CONFIG_ITEM_NAME_WIDTH=30


DEBUG_COMMON_BASH=false;
DEBUG=false;

ACTION="kr.altimedia.updater.action.TEST_UPGRADE"

NONE=-1;
NOEXCEPTION=0;
NOW=1;
DEFERRED=2;
DOWNLOAD_IDLE=1000;
DOWNLOAD_START=1001;
DOWNLOAD_LOADING=1002;
DOWNLOAD_STOPPED=1003;
DOWNLOAD_NOT_ENOUGH_MEMORY=1004;
DOWNLOAD_COMPLETED=1005;
DOWNLOAD_ALL_COMPLETED=1006;
UPDATE_CONFIRMED=1010;
UPDATE_START=1011;
UPDATE_LOADING=1012;
UPDATE_STOPPED=1013;
UPDATE_SUCCESS=1014;
UPDATE_FAIL=1015;

function broadcast() {
    local isFw=$1;
    local command=$2;
    local status=$3;

    case $command in
        "NONE")
            command=${NONE}
        ;;
        "NOW")
            command=${NOW}
        ;;
        "DEFERRED")
            command=${DEFERRED}
        ;;
        "NOEXCEPTION")
            command=${NOEXCEPTION}
        ;;
#        "NOW_TO_DEFERRED")
#            command=${NOW_TO_DEFERRED}
#        ;;
    esac

    case $status in
        "NONE")
            status=${NONE}
        ;;
        "DOWNLOAD_IDLE")
            status=${DOWNLOAD_IDLE}
        ;;
        "DOWNLOAD_START")
            status=${DOWNLOAD_START}
        ;;
        "DOWNLOAD_LOADING")
            status=${DOWNLOAD_LOADING}
        ;;
        "DOWNLOAD_STOPPED")
            status=${DOWNLOAD_STOPPED}
        ;;
        "DOWNLOAD_NOT_ENOUGH_MEMORY")
            status=${DOWNLOAD_NOT_ENOUGH_MEMORY}
        ;;
        "DOWNLOAD_COMPLETED")
            status=${DOWNLOAD_COMPLETED}
        ;;
        "DOWNLOAD_ALL_COMPLETED")
            status=${DOWNLOAD_ALL_COMPLETED}
        ;;
        "UPDATE_CONFIRMED")
            status=${UPDATE_CONFIRMED}
        ;;
        "UPDATE_START")
            status=${UPDATE_START}
        ;;
        "UPDATE_LOADING")
            status=${UPDATE_LOADING}
        ;;
        "UPDATE_STOPPED")
            status=${UPDATE_STOPPED}
        ;;
        "UPDATE_SUCCESS")
            status=${UPDATE_SUCCESS}
        ;;
        "UPDATE_FAIL")
            status=${UPDATE_FAIL}
        ;;
     esac

    do_execute -i adb shell am broadcast --receiver-include-background -a ${ACTION} --ez fw ${isFw} --ei command ${command} --ei status ${status}
}

set_menu_item_width 40

#### STEP 1 : Declare variables ########################################################################################
declare -A action00=([name]="[NONE]"                                                [cmd]="broadcast true NONE NONE")
#declare -A action01=([name]="[FW-Now]           - DOWNLOAD_IDLE"                    [cmd]="broadcast true NOW DOWNLOAD_IDLE")
#declare -A action02=([name]="[FW-Now]           - DOWNLOAD_START"                   [cmd]="broadcast true NOW DOWNLOAD_START")
#declare -A action03=([name]="[FW-Now]           - DOWNLOAD_LOADING"                 [cmd]="broadcast true NOW DOWNLOAD_LOADING")
#declare -A action04=([name]="[FW-Now]           - DOWNLOAD_STOPPED"                 [cmd]="broadcast true NOW DOWNLOAD_STOPPED")
#declare -A action05=([name]="[FW-Now]           - DOWNLOAD_NOT_ENOUGH_MEMORY"       [cmd]="broadcast true NOW DOWNLOAD_NOT_ENOUGH_MEMORY")
declare -A action06=([name]="[FW-Now]           - DOWNLOAD_COMPLETED"               [cmd]="broadcast true NOW DOWNLOAD_COMPLETED")
#declare -A action07=([name]="[FW-Now]           - DOWNLOAD_ALL_COMPLETED"           [cmd]="broadcast true NOW DOWNLOAD_ALL_COMPLETED")
#declare -A action08=([name]="[FW-Now]           - UPDATE_CONFIRMED"                 [cmd]="broadcast true NOW UPDATE_CONFIRMED")
#declare -A action09=([name]="[FW-Now]           - UPDATE_START"                     [cmd]="broadcast true NOW UPDATE_START")
#declare -A action10=([name]="[FW-Now]           - UPDATE_LOADING"                   [cmd]="broadcast true NOW UPDATE_LOADING")
#declare -A action11=([name]="[FW-Now]           - UPDATE_STOPPED"                   [cmd]="broadcast true NOW UPDATE_STOPPED")
declare -A action12=([name]="[FW-Now]           - UPDATE_SUCCESS"                   [cmd]="broadcast true NOW UPDATE_SUCCESS")
declare -A action13=([name]="[FW-Now]           - UPDATE_FAIL"                      [cmd]="broadcast true NOW UPDATE_FAIL")
#declare -A action14=([name]="[FW-DEFERRED]      - DOWNLOAD_IDLE"                    [cmd]="broadcast true DEFERRED DOWNLOAD_IDLE")
#declare -A action15=([name]="[FW-DEFERRED]      - DOWNLOAD_START"                   [cmd]="broadcast true DEFERRED DOWNLOAD_START")
#declare -A action16=([name]="[FW-DEFERRED]      - DOWNLOAD_LOADING"                 [cmd]="broadcast true DEFERRED DOWNLOAD_LOADING")
#declare -A action17=([name]="[FW-DEFERRED]      - DOWNLOAD_STOPPED"                 [cmd]="broadcast true DEFERRED DOWNLOAD_STOPPED")
#declare -A action18=([name]="[FW-DEFERRED]      - DOWNLOAD_NOT_ENOUGH_MEMORY"       [cmd]="broadcast true DEFERRED DOWNLOAD_NOT_ENOUGH_MEMORY")
declare -A action19=([name]="[FW-DEFERRED]      - DOWNLOAD_COMPLETED"               [cmd]="broadcast true DEFERRED DOWNLOAD_COMPLETED")
#declare -A action20=([name]="[FW-DEFERRED]      - DOWNLOAD_ALL_COMPLETED"           [cmd]="broadcast true DEFERRED DOWNLOAD_ALL_COMPLETED")
#declare -A action21=([name]="[FW-DEFERRED]      - UPDATE_CONFIRMED"                 [cmd]="broadcast true DEFERRED UPDATE_CONFIRMED")
#declare -A action22=([name]="[FW-DEFERRED]      - UPDATE_START"                     [cmd]="broadcast true DEFERRED UPDATE_START")
#declare -A action23=([name]="[FW-DEFERRED]      - UPDATE_LOADING"                   [cmd]="broadcast true DEFERRED UPDATE_LOADING")
#declare -A action24=([name]="[FW-DEFERRED]      - UPDATE_STOPPED"                   [cmd]="broadcast true DEFERRED UPDATE_STOPPED")
declare -A action25=([name]="[FW-DEFERRED]      - UPDATE_SUCCESS"                   [cmd]="broadcast true DEFERRED UPDATE_SUCCESS")
declare -A action26=([name]="[FW-DEFERRED]      - UPDATE_FAIL"                      [cmd]="broadcast true DEFERRED UPDATE_FAIL")
#declare -A action27=([name]="[FW-NOEXCEPTION]   - DOWNLOAD_IDLE"                    [cmd]="broadcast true NOEXCEPTION DOWNLOAD_IDLE")
#declare -A action28=([name]="[FW-NOEXCEPTION]   - DOWNLOAD_START"                   [cmd]="broadcast true NOEXCEPTION DOWNLOAD_START")
#declare -A action29=([name]="[FW-NOEXCEPTION]   - DOWNLOAD_LOADING"                 [cmd]="broadcast true NOEXCEPTION DOWNLOAD_LOADING")
#declare -A action30=([name]="[FW-NOEXCEPTION]   - DOWNLOAD_STOPPED"                 [cmd]="broadcast true NOEXCEPTION DOWNLOAD_STOPPED")
#declare -A action31=([name]="[FW-NOEXCEPTION]   - DOWNLOAD_NOT_ENOUGH_MEMORY"       [cmd]="broadcast true NOEXCEPTION DOWNLOAD_NOT_ENOUGH_MEMORY")
declare -A action32=([name]="[FW-NOEXCEPTION]   - DOWNLOAD_COMPLETED"               [cmd]="broadcast true NOEXCEPTION DOWNLOAD_COMPLETED")
#declare -A action33=([name]="[FW-NOEXCEPTION]   - DOWNLOAD_ALL_COMPLETED"           [cmd]="broadcast true NOEXCEPTION DOWNLOAD_ALL_COMPLETED")
#declare -A action34=([name]="[FW-NOEXCEPTION]   - UPDATE_CONFIRMED"                 [cmd]="broadcast true NOEXCEPTION UPDATE_CONFIRMED")
#declare -A action35=([name]="[FW-NOEXCEPTION]   - UPDATE_START"                     [cmd]="broadcast true NOEXCEPTION UPDATE_START")
#declare -A action36=([name]="[FW-NOEXCEPTION]   - UPDATE_LOADING"                   [cmd]="broadcast true NOEXCEPTION UPDATE_LOADING")
#declare -A action37=([name]="[FW-NOEXCEPTION]   - UPDATE_STOPPED"                   [cmd]="broadcast true NOEXCEPTION UPDATE_STOPPED")
declare -A action38=([name]="[FW-NOEXCEPTION]   - UPDATE_SUCCESS"                   [cmd]="broadcast true NOEXCEPTION UPDATE_SUCCESS")
declare -A action39=([name]="[FW-NOEXCEPTION]   - UPDATE_FAIL"                      [cmd]="broadcast true NOEXCEPTION UPDATE_FAIL")
#declare -A action40=([name]="[APP-Now]          - DOWNLOAD_IDLE"                    [cmd]="broadcast false NOW DOWNLOAD_IDLE")
#declare -A action41=([name]="[APP-Now]          - DOWNLOAD_START"                   [cmd]="broadcast false NOW DOWNLOAD_START")
#declare -A action42=([name]="[APP-Now]          - DOWNLOAD_LOADING"                 [cmd]="broadcast false NOW DOWNLOAD_LOADING")
#declare -A action43=([name]="[APP-Now]          - DOWNLOAD_STOPPED"                 [cmd]="broadcast false NOW DOWNLOAD_STOPPED")
#declare -A action44=([name]="[APP-Now]          - DOWNLOAD_NOT_ENOUGH_MEMORY"       [cmd]="broadcast false NOW DOWNLOAD_NOT_ENOUGH_MEMORY")
declare -A action45=([name]="[APP-Now]          - DOWNLOAD_COMPLETED"               [cmd]="broadcast false NOW DOWNLOAD_COMPLETED")
#declare -A action46=([name]="[APP-Now]          - DOWNLOAD_ALL_COMPLETED"           [cmd]="broadcast false NOW DOWNLOAD_ALL_COMPLETED")
#declare -A action47=([name]="[APP-Now]          - UPDATE_CONFIRMED"                 [cmd]="broadcast false NOW UPDATE_CONFIRMED")
#declare -A action48=([name]="[APP-Now]          - UPDATE_START"                     [cmd]="broadcast false NOW UPDATE_START")
#declare -A action49=([name]="[APP-Now]          - UPDATE_LOADING"                   [cmd]="broadcast false NOW UPDATE_LOADING")
#declare -A action50=([name]="[APP-Now]          - UPDATE_STOPPED"                   [cmd]="broadcast false NOW UPDATE_STOPPED")
declare -A action51=([name]="[APP-Now]          - UPDATE_SUCCESS"                   [cmd]="broadcast false NOW UPDATE_SUCCESS")
declare -A action52=([name]="[APP-Now]          - UPDATE_FAIL"                      [cmd]="broadcast false NOW UPDATE_FAIL")
#declare -A action53=([name]="[APP-DEFERRED]     - DOWNLOAD_IDLE"                    [cmd]="broadcast false DEFERRED DOWNLOAD_IDLE")
#declare -A action54=([name]="[APP-DEFERRED]     - DOWNLOAD_START"                   [cmd]="broadcast false DEFERRED DOWNLOAD_START")
#declare -A action55=([name]="[APP-DEFERRED]     - DOWNLOAD_LOADING"                 [cmd]="broadcast false DEFERRED DOWNLOAD_LOADING")
#declare -A action56=([name]="[APP-DEFERRED]     - DOWNLOAD_STOPPED"                 [cmd]="broadcast false DEFERRED DOWNLOAD_STOPPED")
#declare -A action57=([name]="[APP-DEFERRED]     - DOWNLOAD_NOT_ENOUGH_MEMORY"       [cmd]="broadcast false DEFERRED DOWNLOAD_NOT_ENOUGH_MEMORY")
#declare -A action58=([name]="[APP-DEFERRED]     - DOWNLOAD_COMPLETED"               [cmd]="broadcast false DEFERRED DOWNLOAD_COMPLETED")
#declare -A action59=([name]="[APP-DEFERRED]     - DOWNLOAD_ALL_COMPLETED"           [cmd]="broadcast false DEFERRED DOWNLOAD_ALL_COMPLETED")
#declare -A action60=([name]="[APP-DEFERRED]     - UPDATE_CONFIRMED"                 [cmd]="broadcast false DEFERRED UPDATE_CONFIRMED")
#declare -A action61=([name]="[APP-DEFERRED]     - UPDATE_START"                     [cmd]="broadcast false DEFERRED UPDATE_START")
#declare -A action62=([name]="[APP-DEFERRED]     - UPDATE_LOADING"                   [cmd]="broadcast false DEFERRED UPDATE_LOADING")
#declare -A action63=([name]="[APP-DEFERRED]     - UPDATE_STOPPED"                   [cmd]="broadcast false DEFERRED UPDATE_STOPPED")
#declare -A action64=([name]="[APP-DEFERRED]     - UPDATE_SUCCESS"                   [cmd]="broadcast false DEFERRED UPDATE_SUCCESS")
#declare -A action65=([name]="[APP-DEFERRED]     - UPDATE_FAIL"                      [cmd]="broadcast false DEFERRED UPDATE_FAIL")
#declare -A action66=([name]="[APP-NOEXCEPTION]  - DOWNLOAD_IDLE"                    [cmd]="broadcast false NOEXCEPTION DOWNLOAD_IDLE")
#declare -A action67=([name]="[APP-NOEXCEPTION]  - DOWNLOAD_START"                   [cmd]="broadcast false NOEXCEPTION DOWNLOAD_START")
#declare -A action68=([name]="[APP-NOEXCEPTION]  - DOWNLOAD_LOADING"                 [cmd]="broadcast false NOEXCEPTION DOWNLOAD_LOADING")
#declare -A action69=([name]="[APP-NOEXCEPTION]  - DOWNLOAD_STOPPED"                 [cmd]="broadcast false NOEXCEPTION DOWNLOAD_STOPPED")
#declare -A action70=([name]="[APP-NOEXCEPTION]  - DOWNLOAD_NOT_ENOUGH_MEMORY"       [cmd]="broadcast false NOEXCEPTION DOWNLOAD_NOT_ENOUGH_MEMORY")
#declare -A action71=([name]="[APP-NOEXCEPTION]  - DOWNLOAD_COMPLETED"               [cmd]="broadcast false NOEXCEPTION DOWNLOAD_COMPLETED")
#declare -A action72=([name]="[APP-NOEXCEPTION]  - DOWNLOAD_ALL_COMPLETED"           [cmd]="broadcast false NOEXCEPTION DOWNLOAD_ALL_COMPLETED")
#declare -A action73=([name]="[APP-NOEXCEPTION]  - UPDATE_CONFIRMED"                 [cmd]="broadcast false NOEXCEPTION UPDATE_CONFIRMED")
#declare -A action74=([name]="[APP-NOEXCEPTION]  - UPDATE_START"                     [cmd]="broadcast false NOEXCEPTION UPDATE_START")
#declare -A action75=([name]="[APP-NOEXCEPTION]  - UPDATE_LOADING"                   [cmd]="broadcast false NOEXCEPTION UPDATE_LOADING")
#declare -A action76=([name]="[APP-NOEXCEPTION]  - UPDATE_STOPPED"                   [cmd]="broadcast false NOEXCEPTION UPDATE_STOPPED")
#declare -A action77=([name]="[APP-NOEXCEPTION]  - UPDATE_SUCCESS"                   [cmd]="broadcast false NOEXCEPTION UPDATE_SUCCESS")
#declare -A action78=([name]="[APP-NOEXCEPTION]  - UPDATE_FAIL"                      [cmd]="broadcast false NOEXCEPTION UPDATE_FAIL")
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
        eval "${item[cmd]}"
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
