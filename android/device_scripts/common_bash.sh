#!/bin/sh
ME=$(dirname "$0")
source ${ME}/common_log.sh;
DEBUG_COMMON_BASH=false;
DEBUG=false;

executeCnt=0;
# term="/dev/tty";
# if [ ! -z $SSH_TTY ]; then
#     term="$SSH_TTY"
# fi
VIRTUAL_MODE=false;

function do_execute() {
    local output="";
    local result=1;
    local quietMode=false;
    local notifyMode=false;
    local OPTIND log_args option command;
    if $DEBUG_COMMON_BASH; then
        print -d $FUNCNAME:    source   : ${BASH_SOURCE[1]};
        print -d $FUNCNAME:    options  : \"$*\";
        print -d $FUNCNAME:    OPTIND   : $OPTIND, option=$option;
        print -d $FUNCNAME:    log_args : $log_args;
    fi

    while getopts diewqnv option; do
        case ${option} in
            d)
                ## DEBUG
                log_args="-d"
                if $DEBUG_COMMON_BASH ; then
                    print -d $FUNCNAME: debug mode
                fi
            ;;
            i)
                ## INFO
                log_args="-i"
                if $DEBUG_COMMON_BASH ; then
                    print -d $FUNCNAME: info mode
                fi
            ;;
            e)
                ## ERROR
                log_args="-e"
                if $DEBUG_COMMON_BASH ; then
                    print -d $FUNCNAME: error mode
                fi
            ;;
            w)
                ## WARN
                log_args="-w"
                if $DEBUG_COMMON_BASH ; then
                    print -d $FUNCNAME: warn mode
                fi
            ;;
            q)
                ## HIDDEN
                quietMode=true;
                log_args="-q"
                if $DEBUG_COMMON_BASH ; then
                    print -d $FUNCNAME: quiet mode
                fi
            ;;
            n)
                ## NOTIFICATION
                notifyMode=true
                if $DEBUG_COMMON_BASH ; then
                    print -d $FUNCNAME: notify mode
                fi
            ;;
            *)
                print -w "Invalid option: -$OPTARG"
                exit 1
            ;;
        esac
    done


    shift $(($OPTIND - 1))
    command="$@"
    TAB="    "

    if [ ! $VIRTUAL_MODE ]; then
        if $quietMode ; then
            output=$(${command});
            result=$?;
        else
            executeCnt=$(($executeCnt+1));
            log $log_args "[$executeCnt] $command";
            # if [ -z /dev/tty ]; then
            #     ${command} | sed -e "s/^/${TAB}&/g;" > $term;
            # else
            eval ${command} | sed -e "s/^/${TAB}&/g;"
            # fi
            result=${PIPESTATUS[0]} ;
        fi
        if [ $result != 0 ]; then
            log -ie "${command}"
            log -ie "result code : ${result}"
        fi

        # Notify mode
        if $notifyMode ; then
            if [ $result -eq 0 ]; then
                iconFace="face-cool"
            else
                iconFace="face-angry"
            fi
            notify-send "${BASH_SOURCE[1]}" "$command" --icon=$iconFace
        fi
    else
        log $log_args "[$executeCnt] $command";
        result=0;
    fi

    if $DEBUG_COMMON_BASH; then
        print -d "<< ====================================="
        print -d $FUNCNAME: command     : $command
        print -d $FUNCNAME: logOpt      : $log_args
        print -d $FUNCNAME: quietMode   : $quietMode
        print -d $FUNCNAME: notifyMode  : $notifyMode
        print -d $FUNCNAME: result      : $result
        print -d ">> ====================================="
    fi
    return "${result}"
}
