#!/usr/bin/env bash

source common_color.sh
DEBUG_LOG=false;
print_prefix_color() {

    local log_option=$1 _color;
    local log_message="${@:3}"
    if $DEBUG_LOG; then
        echo "option=$#, $@"
    fi
    case $log_option in
        ## debug
        "-d")
            if $DEBUG; then
                _color="\033[$format_none;$fg_cyan;$bg_default""m";
                echo -e "$_color"DEBUG"$COLOR_END\t"$log_message > /dev/tty;
            fi
            ;;
        ## info
        "-i")
            _color="\033[$format_none;$fg_green;$bg_default""m";
            echo -e "$_color"INFO"$COLOR_END\t"$log_message > /dev/tty;
            ;;
        ## warning
        "-w")
            _color="\033[$format_blink;$fg_red;$bg_default""m";
            echo -e "$_color"WARN"$COLOR_END\t"$log_message > /dev/tty;
            ;;
        ## warning
        "-x")
            _color="\033[$format_blink;$fg_red;$bg_default""m";
            echo -e "$_color"HIGH"$COLOR_END\t"$log_message > /dev/tty;
            ;;
        "-ie")
            _color="\033[$format_blink;$fg_yellow;$bg_default""m";
            echo -e "\t$_color"ERROR"$COLOR_END\t"$log_message > /dev/tty;
            ;;
        ## error
        "-e")
            _color="\033[$format_blink;$fg_yellow;$bg_default""m";
            echo -e "$_color"ERROR"$COLOR_END\t"$log_message > /dev/tty;
            ;;
        ## quite mode
        "-q")
            _color="\033[$format_bold;$fg_light_blue;$bg_dark_grey""m";
            echo -e "$_color"QUITE"$COLOR_END\t"$log_message > /dev/tty;
            ;;
        ## normal
        "-n" )
            # _color="\033[$format_none;$fg_default;$bg_default""m";
            # echo -e "$_color$COLOR_END\t"$log_message > /dev/tty;
            echo -e "\t"$log_message > /dev/tty;
            ;;
         * )
            _color="\033[$format_none;$fg_light_grey;$bg_default""m";
            echo -e "$_color$COLOR_END\t"$log_message > /dev/tty;
            ;;
    esac;
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
		print_prefix_color $1 ${@:1:$#};
	else
		print_prefix_color "-n" "" $@;
	fi
}