#!/bin/sh
ME="/data/device_scripts"
source ${ME}/common_color.sh;



DEBUG_LOG=true;
# term="/dev/tty";
# if [ ! -z $SSH_TTY ]; then
#     term=$SSH_TTY
# fi
function print_log() {
    local _color tag;
    # local log_message="${@}"
    # if $DEBUG_LOG; then
    #     echo "option=$#, $@"
    # fi
    # echo "message=$@"
    # if [[ ! -z $1 && $# -gt 1 ]]; then
    optspec="diwxeqn"
    while getopts "${optspec}}" option; do
        case ${option} in
            ## debug
            "d")
                # if $DEBUG; then
                    _color="\033[$format_none;$fg_cyan;$bg_default""m";
                    # echo -e "$_color"DEBUG"$COLOR_END\t"$log_message 
                    tag="$_color"DEBUG"$COLOR_END\t"
                # fi
                ;;
            ## info
            "i")
                _color="\033[$format_none;$fg_green;$bg_default""m";
                # echo -e "$_color"INFO"$COLOR_END\t"$log_message > $term;
                tag="$_color"INFO"$COLOR_END\t"
                ;;
            ## warning
            "w")
                _color="\033[$format_blink;$fg_red;$bg_default""m";
                # echo -e "$_color"WARN"$COLOR_END\t"$log_message > $term;
                tag="$_color"WRAN"$COLOR_END\t"
                ;;
            ## warning
            "x")
                _color="\033[$format_blink;$fg_red;$bg_default""m";
                # echo -e "$_color"HIGH"$COLOR_END\t"$log_message > $term;
                tag="$_color"HIGH"$COLOR_END\t"
                ;;
            # "-ie")
            #     _color="\033[$format_blink;$fg_yellow;$bg_default""m";
            #     # echo -e "\t$_color"ERROR"$COLOR_END\t"$log_message > $term;
            #     tag="$_color"ERROR"$COLOR_END\t"
                # ;;
            ## error
            "e")
                _color="\033[$format_blink;$fg_yellow;$bg_default""m";
                # echo -e "$_color"ERROR"$COLOR_END\t"$log_message > $term;
                tag="$_color"ERROR"$COLOR_END\t"
                ;;
            ## quite mode
            "q")
                _color="\033[$format_bold;$fg_light_blue;$bg_dark_grey""m";
                # echo -e "$_color"QUITE"$COLOR_END\t"$log_message > $term;
                tag="$_color"QUITE"$COLOR_END\t"
                ;;
            ## normal
            "n" )
                # _color="\033[$format_none;$fg_default;$bg_default""m";
                # echo -e "$_color$COLOR_END\t"$log_message > $term;
                # echo -e "\t"$log_message > $term;
                tag="\t"
                ;;
            * )
                _color="\033[$format_none;$fg_light_grey;$bg_default""m";
                # echo -e "$_color$COLOR_END\t"$log_message > $term;
                tag="$_color$COLOR_END\t"
                ;;
        esac;
    done
    shift $((OPTIND -1))
    # fi
    echo -e "$tag\t"$@;
    # echo -e "==>\t"$@;
}

# function print() {
# 	if [ $# -gt 1 ]; then
# 		log $1 "${@:2}" >&2;
# 	else
# 		echo -e "     \t$1" >&2;
# 	fi
# }

function log() {
	# if [ $# -gt 1 ]; then
	# 	print_log $1 $@;
	# else
		print_log $@;
	# fi
}