#!/usr/bin/env bash

# ==========================================
# 1. Colors
# ==========================================
export COLOR_END='\033[0m'
export COLOR_BLACK="\033[0;30;49m"
export COLOR_RED="\033[0;31;49m"
export COLOR_GREEN="\033[0;32;49m"
export COLOR_BLUE="\033[0;34;49m"
export COLOR_YELLOW="\033[0;33;49m"
export COLOR_CYAN="\033[0;36;49m"

# ==========================================
# 2. Logging System
# ==========================================
DEBUG=false
executeCnt=0
term="/dev/tty"
[[ -n "${SSH_TTY:-}" ]] && term="$SSH_TTY"
[[ ! -c "$term" ]] && term="/dev/stderr"

function print_prefix_color() {
    local log_option="$1"
    shift
    local log_message="$*"
    local currentTime
    printf -v currentTime '%(%m-%d %H:%M:%S)T' -1

    case "$log_option" in
        "-d") [[ "$DEBUG" == "true" ]] && echo -e "${currentTime} ?•µï¸?t\033[0;36;49m${log_message}\033[0m" > "$term" ;;
        "-i") echo -e "${currentTime} ?’¡\t\033[0;32;49m${log_message}\033[0m" > "$term" ;;
        "-w") echo -e "${currentTime} ? ï¸\t\033[5;31;49m${log_message}\033[0m" > "$term" ;;
        "-e") echo -e "${currentTime} ?‘¾\t\033[5;33;49m${log_message}\033[0m" > "$term" ;;
        "-q") echo -e "${currentTime} \033[1;94;100mQUIET\033[0m\t$log_message" > "$term" ;;
        "-n") echo -e "\t$log_message" > "$term" ;;
        *)    echo -e "${currentTime} \033[0;37;49m\t$log_message\033[0m" > "$term" ;;
    esac
}

function log() {
    if (( $# > 1 )); then
        print_prefix_color "$1" "${@:2}"
    else
        print_prefix_color "-n" "$@"
    fi
}

function draw_line() {
    local color="${1:-}"
    local char="${2:-\-}"
    local reset='\033[0m'
    local width=$(tput cols 2>/dev/null || echo 80)
    local line
    printf -v line "%*s" "$width" ""
    line="${line// /$char}"
    echo -e "${color}${line}${reset}" > "$term"
}

function draw_line_with_title() {
    local title="[ $1 ]"
    local char="${2:-?€}"
    local color="${3:-}"
    local reset='\033[0m'
    local total_width=$(tput cols 2>/dev/null || echo 80)
    local pad=$(( (total_width - ${#title}) / 2 ))
    local left=""
    if (( pad > 0 )); then
        printf -v left "%*s" "$pad" ""
        left="${left// /$char}"
    fi
    local full_line="${left}${title}${left}"
    (( ${#full_line} < total_width )) && full_line+="$char"
    echo -e "${color}${full_line}${reset}" > "$term"
}

# ==========================================
# 3. Execution Engine
# ==========================================
function do_execute() {
    local result=1 quietMode=false log_args=""
    local OPTIND=1 option command
    while getopts diewq option; do
        case ${option} in
            d) log_args="-d" ;; i) log_args="-i" ;; e) log_args="-e" ;;
            w) log_args="-w" ;; q) quietMode=true; log_args="-q" ;;
        esac
    done
    shift $((OPTIND - 1))
    command="$*"
    if $quietMode; then
        eval "$command"; result=$?
    else
        ((executeCnt++))
        log $log_args "[$executeCnt] $command"
        eval "$command" 2>&1 | sed -e "s/^/    /g;" > "$term"; result=${PIPESTATUS[0]}
    fi
    (( result != 0 )) && log -e "Failed (code: $result): $command"
    return "$result"
}

