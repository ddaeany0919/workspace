#!/usr/bin/env bash
source common_bash.sh
# declare -A action0=([name]="EPG"        [cmd]="adb shell am start -n com.alticast.android.tv.local/.MainActivity")
# declare -A action1=([name]="Developer"  [cmd]="adb shell am start -n com.android.tv.settings/.system.development.DevelopmentActivity")
# declare -A action2=([name]="test"       [cmd]="cmd cmd cmd" [desc]="aslkdhjaskjd")
# declare -A action3=([name]="Setting"    [cmd]='adb shell am start -a android.settings.SETTINGS')

#### CONFIG
COMMON_MENU_CONFIG_ITEM_NAME_WIDTH=30
COMMON_MENU_CONFIG_ITEM_NUMBER_WIDTH=2

DEFAULT_ALL="**ALL"

usage() {
    print -h "usage:"

    # TODO
    print -h "declare -A action0=([name]=\"EPG\"        [cmd]=\"adb shell am start -n com.alticast.android.tv.local/.MainActivity\")  "
    print -h "declare -A action1=([name]=\"Developer\"  [cmd]=\"adb shell am start -n com.android.tv.settings/.system.development.DevelopmentActivity\")"
    print -h "declare -A action2=([name]=\"test\"       [cmd]=\"cmd cmd cmd\" [desc]=\"aslkdhjaskjd\")"
    print -h "declare -A action3=([name]=\"Setting\"    [cmd]='adb shell am start -a android.settings.SETTINGS')"
    print -h "show_actions_menu \${!action@};"
}

COLOR_GUIDELINE="\e[$format_bold;$fg_cyan;$bg_default""m"
COLOR_NUM="\e[$format_bold;$fg_light_yellow;$bg_default""m"
COLOR_NAME="\e[$format_bold;$fg_light_green;$bg_default""m"
COLOR_SUB="\e[$format_italic;$fg_default;$bg_default""m"
COLOR_DESC="\e[$format_none;$fg_default;$bg_default""m"
FORMAT_1="\t** ${COLOR_NUM}%"${COMMON_MENU_CONFIG_ITEM_NUMBER_WIDTH}"d${COLOR_END}) ${COLOR_NAME}%-"${COMMON_MENU_CONFIG_ITEM_NAME_WIDTH}"s${COLOR_END}"
FORMAT_2="${FORMAT_1} ${COLOR_SUB}%s${COLOR_END}"
FORMAT_3="${FORMAT_2}\n\t${COLOR_DESC}%29s${COLOR_END}"

function set_menu_item_width() {
    local width="$1"
    log -d width=${width}
    FORMAT_1="\t** ${COLOR_NUM}%"${COMMON_MENU_CONFIG_ITEM_NUMBER_WIDTH}"d${COLOR_END}) ${COLOR_NAME}%-"$width"s${COLOR_END}"
    FORMAT_2="${FORMAT_1} ${COLOR_SUB}%s${COLOR_END}"
    FORMAT_3="${FORMAT_2}\n\t${COLOR_DESC}%29s${COLOR_END}"
}

function show_actions_menu() {
    eval "declare -a map_array=( "$@" )"
    echo -e "\t${COLOR_GUIDELINE}* ${0%} ${COLOR_END}" >/dev/tty
    echo -e "\t${COLOR_GUIDELINE}*********************************************${COLOR_END}" >/dev/tty
    for i in "${!map_array[@]}"; do
        map=$(declare -p "${map_array[$i]}")
        eval "declare -A item_array="${map#*=}
        keys=(${!item_array[@]})
        print_array=($(($i + 1)))
        case ${#keys[@]} in
        1)
            item_name="${item_array[name]}"
            item_sub=""
            item_desc=""
            prefix_color="${FORMAT_1}\n"
            print_array+=("${item_name}")
            ;;
        2)
            item_name="${item_array[name]}"
            item_sub="${item_array[cmd]}"
            item_desc=""
            prefix_color="${FORMAT_2}\n"
            print_array+=("${item_name}" "${item_sub}")
            ;;
        3)
            item_name="${item_array[name]}"
            item_sub="${item_array[cmd]}"
            item_desc="${item_array[desc]}"
            prefix_color="${FORMAT_3}\n"
            print_array+=("${item_name}" "${item_sub}" "${item_desc}")
            ;;
        *) ;;

        esac
        # printf "$prefix_color" "${i}" "${item_name}" "${item_sub}" "${item_desc}"
        printf "$prefix_color" "${print_array[@]}" >/dev/tty
        # for key in "${!item_array[@]}"; do
        #     echo "key: $key, value=${item_array[$key]}"
        # done
    done
    printf "\t${COLOR_YELLOW}Please enter a menu option and enter or ${COLOR_RED}enter to exit. ${COLOR_END}\n\t" >/dev/tty

    read read_items

    log -d "$FUNCNAME read_items=$read_items"

    echo $read_items
}

show_menu() {
    local read_items=()
    local result=()
    local default_index=-1
    local list=()
    local has_default_item=false
    local is_return_index_number=false
    local index=1
    local menu_item
    local menu_index

    if [ $# -eq 0 ]; then
        usage
        exit 1
    fi

    while getopts dn option; do
        case ${option} in
        d)
            ## add default item to menu list
            has_default_item=true
            debug $FUNCNAME: add default menu item that is \"$DEFAULT_ALL\"
            ;;
        n)
            is_return_index_number=true
            debug $FUNCNAME: is_return_index_number=$is_return_index_number
            ;;
        esac
    done

    shift $(($OPTIND - 1))
    list=("$@")

    debug $FUNCNAME hasDefault=$has_default_item

    if $has_default_item; then
        default_index=$#
        list[${#list[@]}]="$DEFAULT_ALL"
    fi

    debug $FUNCNAME list=${list[@]}

    NORMAL=$(echo "\033[m")
    MENU=$(echo "\033[36m")   #Blue
    NUMBER=$(echo "\033[33m") #yellow
    FGRED=$(echo "\033[41m")
    RED_TEXT=$(echo "\033[31m")
    ENTER_LINE=$(echo "\033[33m")
    echo -e "\t${MENU}*********************************************${NORMAL}" >&2

    for ((index; index <= ${#list[@]}; index++)); do
        menu_index=$(expr $index - 1)
        menu_item=${list[menu_index]}
        if [ $index -lt $default_index ]; then
            echo -e "\t${MENU}**${NUMBER} $index) $menu_item ${NORMAL}" >&2
        else
            ## TODO
            echo -e "\t${MENU}**${NUMBER} $index) $menu_item ${NORMAL}" >&2
        fi
    done

    echo -e "\t${MENU}*********************************************${NORMAL}" >&2

    if $has_default_item; then
        echo -e "\t${ENTER_LINE}Please enter a menu option and enter or ${RED_TEXT}enter is ${list[$default_index]}\"\". ${NORMAL}" >&2
    else
        echo -e "\t${ENTER_LINE}Please enter a menu option and enter or ${RED_TEXT}enter to exit. ${NORMAL}" >&2
    fi

    read read_items

    debug "$FUNCNAME read_items=$read_items"

    ## if selected items are "enter"
    if [ ${#read_items[@]} -eq 0 ] || [ -z "$read_items" ]; then
        if $has_default_item; then
            result=($(getAllItems $is_return_index_number $@))
        fi
    else
        for selected_item in $read_items; do
            debug $FUNCNAME selected_item="$selected_item"
            ## if selected default item
            if [ $default_index == $(expr $selected_item - 1) ]; then
                result=($(getAllItems $is_return_index_number $@))
                break
            else
                ## selected item
                selected_item=$(expr $selected_item - 1)
                if $is_return_index_number; then
                    result[${#result[@]}]=$selected_item
                else
                    result[${#result[@]}]=${list[$selected_item]}
                fi
            fi

        done
    fi

    debug $FUNCNAME result=${result[@]}

    echo ${result[@]}
}

function getAllItems() {
    local is_return_number=$1
    local index=1
    local args=($@)
    local item
    local result=()

    debug $FUNCNAME: is_return_number=$is_return_number, args=${args[@]}

    for ((index; index < $#; index++)); do
        if $is_return_number; then
            item=$(expr $index - 1)
        else
            item=${args[$index]}
        fi
        debug $FUNCNAME: item=$item
        result[${#result[@]}]=$item
    done

    debug $FUNCNAME: result=${result[@]}

    echo ${result[@]}

}
