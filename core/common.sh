#!/usr/bin/env bash
echo -e "\033[5;33;49m[DEPRECATED] ?? Please use source common_bash.sh instead\033[0m" >&2

source common_log.sh

DEBUG=false
COMMON_DEBUG=false

LOG_PREFIX="=======LOG "
CMD_LOG_PREFIX="=======CMD "
PRINT_PREFIX="=== RESULT :	"
mCommandCnt=1

CUR_DIR="$PWD"
RESULT_FILE="$HOME/bin/result"
MENU_LIST=("")

function option_picked() {
    local COLOR='\e[01;31m' # bold red
    local RESET='\e[00;00m' # normal white
    local MESSAGE="${*:-"${RESET}Error: No message passed"}"
    echo -e "${COLOR}${MESSAGE}${RESET}"
}

function show_menu() {
    local NORMAL='\e[m'
    local MENU='\e[36m'   #Cyan
    local NUMBER='\e[33m' #yellow
    local FGRED='\e[41m'
    local RED_TEXT='\e[31m'
    local ENTER_LINE='\e[33m'
    
    echo -e "\t${MENU}*********************************************${NORMAL}"
    local count=1
    for menu in "${MENU_LIST[@]}"; do
        echo -e "\t${MENU}**${NUMBER} $count) $menu ${NORMAL}"
        ((count++))
    done
    echo -e "\t${MENU}*********************************************${NORMAL}"
    echo -e "\t${ENTER_LINE}Please enter a menu option and press enter or ${RED_TEXT}just enter to exit. ${NORMAL}"

    if [[ -n "$*" ]]; then
        opt="$*"
    else
        read -r opt
    fi
}

PRINT() {
    log "$LOG_PREFIX $*"
}

RESULT_PRINT() {
    local output="$1"
    local type="$2"
    if [[ -n "$output" ]]; then
        case "$type" in
        "-i") log -i "$output" ;;
        "-e") log -e "$output" ;;
        esac
    fi
}

EXCUTE_CMD() {
    local command=""
    local isPrint=""
    local type=""
    output="" # Exposing output globally for caller compatibility
    result="" # Exposing result globally for caller compatibility
    
    for arg in "$@"; do
        case "$arg" in
        "-h") isPrint="$arg" ;;
        "-i"|"-e"|"-w") type="$arg" ;;
        *) command+=" $arg" ;;
        esac
    done

    # Remove leading space
    command="${command# }"

    log "$type" "$mCommandCnt. #) $command"
    ((mCommandCnt++))

    if [[ "$isPrint" != "-h" && -z "$type" ]]; then
        if [[ -c /dev/tty ]]; then
            output=$(eval "$command" 2>&1 | tee /dev/tty)
        else
            output=$(eval "$command" 2>&1)
        fi
        result=$?

        if [[ "$COMMON_DEBUG" == "true" ]]; then
            local var_out="${output#*-------------}"
            printf "EXCUTE_CMD(), var_out=%s\n" "$var_out"
        fi
    else
        output=$(eval "$command" 2>&1)
        result=$?
    fi

    if [[ "$COMMON_DEBUG" == "true" ]]; then
        printf "EXCUTE_CMD(), result=%d\n" "$result"
    fi

    return "$result"
}

EXCUTE_CMD_CHECK() {
    EXCUTE_CMD "$@"
    if (( result > 0 )); then
        echo "result = $result"
        exit "$result"
    fi
    return "$result"
}
