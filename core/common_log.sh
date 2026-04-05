#!/usr/bin/env bash
echo -e "\033[5;33;49m[DEPRECATED] ?? Please use source common_bash.sh instead\033[0m" >&2

source common_color.sh
DEBUG_LOG=false

term="/dev/tty"
if [[ -n "${SSH_TTY:-}" ]]; then
    term="${SSH_TTY}"
elif [[ ! -c "$term" ]]; then
    term="/dev/stderr"
fi

draw_line_with_title() {
    local title="[ $1 ]"
    local char="${2:-?€}"
    local color="${3:-}"
    local reset='\033[0m'
    
    local total_width
    total_width=$(tput cols 2>/dev/null || echo 80)
    local title_length=${#title}
    local pad=$(( (total_width - title_length) / 2 ))

    # Create padding strings safely using native bash
    local left=""
    if (( pad > 0 )); then
        printf -v left "%*s" "$pad" ""
        left="${left// /$char}"
    fi
    local right="$left"

    local full_line="${left}${title}${right}"
    # Adjust for odd width
    if (( ${#full_line} < total_width )); then
        full_line+="$char"
    fi
    
    if [[ -n "$color" ]]; then
        echo -e "${color}${full_line}${reset}" > "$term"
    else
        echo "$full_line" > "$term"
    fi
}

draw_line() {
    local color="${1:-}"
    local char="${2:-\-}"
    local reset='\033[0m'
    local width
    width=$(tput cols 2>/dev/null || echo 80)

    local line
    printf -v line "%*s" "$width" ""
    line="${line// /$char}"

    if [[ -n "$color" ]]; then
        echo -e "${color}${line}${reset}" > "$term"
    else
        echo "$line" > "$term"
    fi
}

print_prefix_color() {
    local log_option="$1"
    shift
    local log_message="$*"
    local _color
    local currentTime=$(date +"%m-%d %H:%M:%S.%3N")

    if [[ "$DEBUG_LOG" == "true" ]]; then
        echo "option=$log_option, message=$log_message" > "$term"
    fi

    case "$log_option" in
        "-d")
            if [[ "$DEBUG" == "true" ]]; then
                _color="\033[${format_none:-0};${fg_cyan:-36};${bg_default:-49}m"
                echo -e "${currentTime} \xF0\x9F\x95\xB5\xEF\xB8\x8F\xE2\x80\x8D\xE2\x99\x82\xEF\xB8\x8F\t${_color}${log_message}\033[0m" > "$term"
            fi
            ;;
        "-i")
            _color="\033[${format_none:-0};${fg_green:-32};${bg_default:-49}m"
            echo -e "${currentTime} \xF0\x9F\x92\xA1\t${_color}${log_message}\033[0m" > "$term"
            ;;
        "-w")
            _color="\033[${format_blink:-5};${fg_red:-31};${bg_default:-49}m"
            echo -e "${currentTime} \xE2\x9A\xA0\xEF\xB8\x8F\t${_color}${log_message}\033[0m" > "$term"
            ;;
        "-x")
            _color="\033[${format_blink:-5};${fg_red:-31};${bg_default:-49}m"
            echo -e "${currentTime} \xF0\x9F\x9A\xA8\t${_color}${log_message}\033[0m" > "$term"
            ;;
        "-ie")
            _color="\033[${format_blink:-5};${fg_yellow:-33};${bg_default:-49}m"
            echo -e "${currentTime} \xF0\x9F\x92\xA5\t${_color}${log_message}\033[0m" > "$term"
            ;;
        "-e")
            _color="\033[${format_blink:-5};${fg_yellow:-33};${bg_default:-49}m"
            echo -e "${currentTime} \xF0\x9F\x91\xBD\t${_color}${log_message}\033[0m" > "$term"
            ;;
        "-q")
            _color="\033[${format_bold:-1};${fg_light_blue:-94};${bg_dark_grey:-100}m"
            echo -e "${currentTime} ${_color}QUIET\033[0m\t$log_message" > "$term"
            ;;
        "-n")
            echo -e "\t$log_message" > "$term"
            ;;
        *)
            _color="\033[${format_none:-0};${fg_light_grey:-37};${bg_default:-49}m"
            echo -e "${currentTime} ${_color}\t$log_message\033[0m" > "$term"
            ;;
    esac
}

function log() {
    if (( $# > 1 )); then
        print_prefix_color "$1" "${@:2}"
    else
        print_prefix_color "-n" "$@"
    fi
}
