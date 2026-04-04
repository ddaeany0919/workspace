#!/usr/bin/env bash

source common_color.sh
DEBUG_LOG=false
term="/dev/tty"
if [ ! -z $SSH_TTY ]; then
    term=$SSH_TTY
fi

# draw_line_with_title "빌드 시작"
# draw_line_with_title "🚀 DEPLOYING" "="
# draw_line_with_title "⚠️ WARNING ZONE ⚠️" "~" '\033[1;33m'   # 노란색
# draw_line_with_title "🧨 FAILURE" "-" '\033[1;31m'            # 빨간색
draw_line_with_title() {
    local title="[ $1 ]"
    local char="${2:-─}"
    local color="${3:-}"
    local reset='\033[0m'
    
    # local pad=$($($(tput cols) - ${#title}) / 2)
    
    local total_width=$(tput cols)
    local title_length=${#title}
    local left_pad=$(( (total_width - title_length) / 2 ))
    local pad=$(( (total_width - title_length) / 2 ))

    local left=$(printf "%.0s$char" $(seq 1 $pad))
    local right=$(printf "%.0s$char" $(seq 1 $pad))

    local full_line="${left}${title}${right}"
    
    if [ -n "$color" ]; then
        echo -e "${color}${full_line}${reset}"
    else
        echo "$full_line"
    fi
}


draw_line() {
    local color="${1:-}"
    local char="${2:-\-}"
    local reset='\033[0m'
    local width=$(tput cols)

    if [ -n "$color" ]; then
        printf "${color}%*s${reset}\n" "$width" '' | tr ' ' "$char"
    else
        printf '%*s\n' "$width" '' | tr ' ' "$char"
    fi
}

print_prefix_color() {
    local log_option=$1
    shift
    local log_message="$*"
    local _color
    local currentTime=$(date +"%m-%d %H:%M:%S.%3N")

    if $DEBUG_LOG; then
        echo "option=$log_option, message=$log_message"
    fi

    case $log_option in
        "-d")
            if $DEBUG; then
                _color="\033[$format_none;$fg_cyan;$bg_default""m"
                echo -e "${currentTime} 🕵️‍♂️\t$log_message" > $term
            fi
            ;;
        "-i")
            _color="\033[$format_none;$fg_green;$bg_default""m"
            echo -e "${currentTime} 💡\t$log_message" > $term
            ;;
        "-w")
            _color="\033[$format_blink;$fg_red;$bg_default""m"
            echo -e "${currentTime} ⚠️\t$log_message" > $term
            ;;
        "-x")
            _color="\033[$format_blink;$fg_red;$bg_default""m"
            echo -e "${currentTime} 🚨\t$log_message" > $term
            ;;
        "-ie")
            _color="\033[$format_blink;$fg_yellow;$bg_default""m"
            echo -e "${currentTime} 💥\t$log_message" > $term
            ;;
        "-e")
            _color="\033[$format_blink;$fg_yellow;$bg_default""m"
            echo -e "${currentTime} 👽\t$log_message" > $term
            ;;
        "-q")
            _color="\033[$format_bold;$fg_light_blue;$bg_dark_grey""m"
            echo -e "${currentTime} $_color"QUITE"$COLOR_END\t$log_message" > $term
            ;;
        "-n")
            echo -e "\t$log_message" > $term
            ;;
        *)
            _color="\033[$format_none;$fg_light_grey;$bg_default""m"
            echo -e "${currentTime} $_color$COLOR_END\t$log_message" > $term
            ;;
    esac
}

# function print() {
# 	if [ $# -gt 1 ]; then
# 		log $1 "${@:2}" >&2;
# 	else
# 		echo -e "     \t$1" >&2;
# 	fi
# }

function log() {
    if [ $# -gt 1 ]; then
        print_prefix_color "$1" "${@:2}"
    else
        print_prefix_color "-n" "$@"
    fi
}
