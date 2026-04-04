#!/usr/bin/env bash

# set -euo pipefail
# trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND"' ERR

DEBUG_COMMON_BASH=false;
DEBUG=false
source common_log.sh
executeCnt=0
term="/dev/tty"
if [ ! -z $SSH_TTY ]; then
    term="$SSH_TTY"
fi
VIRTUAL_MODE=false

function is_safe_command() {
    local cmd="$1"
    if [[ "$cmd" =~ [\;\|\&\`\$\>\<] ]]; then
        log -e "⚠️  위험한 문자가 포함되어 있어 실행을 중단합니다."
        log -e "⛔  명령어: $cmd"
        return 1
    fi
    return 0
}

function do_execute() {
    local output=""
    local result=1
    local quietMode=false
    local notifyMode=false
    local log_args=""
    local option command
    local slient_result=false;
    local OPTIND=1  # Reset OPTIND at the start
    
    # Process options first
    while getopts diewqnvs option; do
        case ${option} in
        d) log_args="-d"
           [[ $DEBUG_COMMON_BASH == true ]] && print -d "$FUNCNAME: debug mode" ;;
        i) log_args="-i"
           [[ $DEBUG_COMMON_BASH == true ]] && print -d "$FUNCNAME: info mode" ;;
        e) log_args="-e"
           [[ $DEBUG_COMMON_BASH == true ]] && print -d "$FUNCNAME: error mode" ;;
        w) log_args="-w"
           [[ $DEBUG_COMMON_BASH == true ]] && print -d "$FUNCNAME: warn mode" ;;
        s) slient_result=true ;;
        q) quietMode=true
           log_args="-q"
           [[ $DEBUG_COMMON_BASH == true ]] && print -d "$FUNCNAME: quiet mode" ;;
        n) notifyMode=true
           [[ $DEBUG_COMMON_BASH == true ]] && print -d "$FUNCNAME: notify mode" ;;
        *) print -w "Invalid option: -$OPTARG"
           return 1 ;;
        esac
    done

    # Get the command after option processing
    shift $(($OPTIND - 1))
    command="$*"
    TAB="    "


    # if [ ! $VIRTUAL_MODE ]; then
    if $quietMode; then
        output=$(eval "$command")
        result=$?
    else
        executeCnt=$(($executeCnt + 1))
        log $log_args "[$executeCnt] $command"
        if [ -z /dev/tty ]; then
            eval "${command}" | sed -e "s/^/${TAB}&/g;" > $term
        else
            eval "${command}" | sed -e "s/^/${TAB}&/g;"
        fi
        result=${PIPESTATUS[0]}
    fi

    if [[ $result -ne 0 ]]; then
        log -ie "${command}"
        log -ie "result code : ${result}"
    fi

    # Notify mode
    if $notifyMode; then
        if [[ $result -eq 0 ]]; then
            iconFace="face-cool"
        else
            iconFace="face-angry"
        fi
        notify-send "${BASH_SOURCE[1]}" "$command" --icon=$iconFace
    fi
    # else
    #     log $log_args "[$executeCnt] $command";
    #     result=0;
    # fi

    # if $DEBUG_COMMON_BASH; then
    #     print -d "<< ====================================="
    #     print -d $FUNCNAME: command : $command
    #     print -d $FUNCNAME: logOpt : $log_args
    #     print -d $FUNCNAME: quietMode : $quietMode
    #     print -d $FUNCNAME: notifyMode : $notifyMode
    #     print -d $FUNCNAME: result : $result
    #     print -d ">> ====================================="
    # fi
    return "${result}"
}

function isNumber() {
    if [[ $1 =~ ^-?[0-9]+$ ]]; then
        echo 1
    else
        echo 0
    fi
}
