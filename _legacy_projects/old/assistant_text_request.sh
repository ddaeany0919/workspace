#!/usr/bin/env bash

#### STEP 1 : Declare variables ########################################################################################
DEBUG=true
source common_bash.sh

package_name="com.kaonmedia.assistant"
demoMode=false
###################### SEND BROADCAST INTENT ######################
function begin_demo_mode() {
    demoMode=true
    do_execute -i adb shell am broadcast -a \"$package_name.debug.DEMO_MODE\" --ez \"value\" \"true\"
}

function finish_demo_mode() {
    demoMode=false
    do_execute -i adb shell am broadcast -a \"$package_name.debug.DEMO_MODE\" --ez \"value\" \"false\"
}

function send_custom_request() {
    do_execute -i adb shell am broadcast -a \"$package_name.debug.CUSTOM_REQUEST\" --es \"value\" \"$@\"
}

function send_iot_command() {
    do_execute -i adb shell am broadcast -a \"$package_name.debug.IOT\" --es \"value\" \"$@\"
}
###################################################################

function show_demo_mode() {
    print_prefix_color -i "" "Enter the text"
    read text
    if [ -z "$text" ]; then
        finish_demo_mode
    else
        send_custom_request $text
    fi
}

function show_intent_menu() {
    echo "=================================="
    echo "=================================="
    echo "=================================="
    log -q "0. start demo mode"
    log -q "99. finish demo mode"
    echo " - - - - - - - - - - - - - - - - -"
    log -q "1. go to"
    log -q "2. tune to"
    log -q "3. move to"
    log -q "4. start"
    log -q "5. launch"
    log -q "6. execute"
    log -q "7. play"
    log -q "8. watch"
    log -q "9. display"
    log -q "10. show"
    log -q "11. move"
    log -q "12. go"
    log -q "13. vod"
    log -q "14. youtube"
    log -q "15. music"
    log -q "16. arrow"
    log -q "17. iot"
    read intent_index

    re='^[0-9]+$'
    # check is number?
    if ! [[ $intent_index =~ $re ]]; then
        send_custom_request $intent_index
    else
        if [ $intent_index == 0 ]; then
            begin_demo_mode
        elif [ $intent_index == 99 ]; then
            finish_demo_mode
        else
            update_intent_text $intent_index
            show_entity_menu $intent_text
        fi
    fi
}

function update_intent_text() {
    debug "update_intent_text: args=$1"
    case $1 in
    1)
        intent_text="go to"
        ;;
    2)
        intent_text="tune to"
        ;;
    3)
        intent_text="move to"
        ;;
    4)
        intent_text="start"
        ;;
    5)
        intent_text="launch"
        ;;
    6)
        intent_text="execute"
        ;;
    7)
        intent_text="play"
        ;;
    8)
        intent_text="watch"
        ;;
    9)
        intent_text="display"
        ;;
    10)
        intent_text="show"
        ;;
    11)
        intent_text="move"
        ;;
    12)
        intent_text="go"
        ;;
    13)
        intent_text="arrow"
        ;;
    17)
        intent_text="iot"
        ;;
    esac
    log -i $intent_text
}

function show_entity_menu() {
    debug "show_entity_menu: args=$@"
    case $@ in
    "go to" | "move to")
        show_entity_menu_goto
        ;;
    "start")
        show_entity_menu_start
        ;;
    "launch" | "execute" | "play" | "watch" | "display" | "show" | "move" | "go")
        show_entity_menu_launch
        ;;
    "tune to")
        show_entity_menu_tune
        ;;
    "arrow" | "go")
        show_entity_menu_arrow
        ;;
    "play")
        show_entity_menu_play
        ;;
    "iot")
        show_entity_menu_iot
        ;;
    esac
}

###################### ENTRY MENU ######################
function show_entity_menu_goto() {
    log -q "\t1. preference"
    log -q "\t2. live tv"
    log -q "\t3. program guide"
    log -q "\t4. app and game"
    log -q "\t5. home"
    log -q "\t6. main menu"
    read entity_index

    re='^[0-9]+$'
    # check is number?
    if ! [[ $entity_index =~ $re ]]; then
        send_custom_request $intent_text $intent_index
    else
        case $entity_index in
        1)
            send_custom_request $intent_text "preference"
            ;;
        2)
            send_custom_request $intent_text "live tv"
            ;;
        3)
            send_custom_request $intent_text "program guide"
            ;;
        4)
            send_custom_request $intent_text "app and game"
            ;;
        5)
            send_custom_request $intent_text "home"
            ;;
        6)
            send_custom_request $intent_text "main menu"
            ;;
        esac
    fi

}
function show_entity_menu_start() {
    log -q "\t1. preference"
    log -q "\t2. live tv"
    log -q "\t3. program guide"
    log -q "\t4. app and game"
    log -q "\t5. music"
    log -q "\t6. vod"
    log -q "\t7. youtube"
    log -q "\t8. live channel"
    read entity_index

    re='^[0-9]+$'
    # check is number?
    if ! [[ $entity_index =~ $re ]]; then
        send_custom_request $intent_text $intent_index
    else
        case $entity_index in
        1)
            send_custom_request $intent_text "preference"
            ;;
        2)
            send_custom_request $intent_text "live tv"
            ;;
        3)
            send_custom_request $intent_text "program guide"
            ;;
        4)
            send_custom_request $intent_text "app and game"
            ;;
        5)
            send_custom_request $intent_text "music"
            ;;
        6)
            send_custom_request $intent_text "vod"
            ;;
        7)
            send_custom_request $intent_text "youtube"
            ;;
        8)
            send_custom_request $intent_text "live channel"
            ;;

        esac
    fi

}
function show_entity_menu_launch() {
    log -q "\t1. music"
    log -q "\t2. vod"
    log -q "\t3. youtube"
    log -q "\t4. live channel"
    read entity_index

    re='^[0-9]+$'
    # check is number?
    if ! [[ $entity_index =~ $re ]]; then
        send_custom_request $intent_text $intent_index
    else
        case $entity_index in
        1)
            send_custom_request $intent_text "music"
            ;;
        2)
            send_custom_request $intent_text "vod"
            ;;
        3)
            send_custom_request $intent_text "youtube"
            ;;
        4)
            send_custom_request $intent_text "live channel"
            ;;

        esac
    fi

}
function show_entity_menu_tune() {
    log -q "\t1. 1"
    log -q "\t2. one"
    log -q "\t3. 2"
    log -q "\t4. three"
    log -q "\t5. cnn"
    log -q "\t6. ytn"
    log -q "\t7. Top selling movies"
    read entity_index

    re='^[0-9]+$'
    # check is number?
    if ! [[ $entity_index =~ $re ]]; then
        send_custom_request $intent_text $intent_index
    else
        case $entity_index in
        1)
            send_custom_request $intent_text "1"
            ;;
        2)
            send_custom_request $intent_text "one"
            ;;
        3)
            send_custom_request $intent_text "2"
            ;;
        4)
            send_custom_request $intent_text "three"
            ;;
        5)
            send_custom_request $intent_text "cnn"
            ;;
        6)
            send_custom_request $intent_text "ytn"
            ;;
        7)
            send_custom_request $intent_text "Top selling movies"
            ;;
        esac
    fi

}
function show_entity_menu_arrow() {
    log -q "\t1. up"
    log -q "\t2. down"
    log -q "\t3. left"
    log -q "\t4. right"
    log -q "\t5. back"
    log -q "\t6. previous"
    log -q "\t7. exit"
    read entity_index

    re='^[0-9]+$'
    # check is number?
    if ! [[ $entity_index =~ $re ]]; then
        send_custom_request $intent_text $intent_index
    else
        case $entity_index in
        1)
            send_custom_request $intent_text "up"
            ;;
        2)
            send_custom_request $intent_text "down"
            ;;
        3)
            send_custom_request $intent_text "left"
            ;;
        4)
            send_custom_request $intent_text "right"
            ;;
        5)
            send_custom_request $intent_text "back"
            ;;
        6)
            send_custom_request $intent_text "previous"
            ;;
        7)
            send_custom_request $intent_text "exit"
            ;;

        esac
    fi

}
function show_entity_menu_play() {
    log -q "\t1. start"
    log -q "\t2. stop"
    log -q "\t3. pause"
    log -q "\t4. next"
    log -q "\t5. back"
    log -q "\t6. previous"
    log -q "\t7. fast forward"
    log -q "\t8. rewind"

    log -q "\t9. forward"
    log -q "\t10. backward"
    read entity_index

    re='^[0-9]+$'
    # check is number?
    if ! [[ $entity_index =~ $re ]]; then
        send_custom_request $intent_text $intent_index
    else
        case $entity_index in
        1)
            send_custom_request $intent_text "start"
            ;;
        2)
            send_custom_request $intent_text "stop"
            ;;
        3)
            send_custom_request $intent_text "pause"
            ;;
        4)
            send_custom_request $intent_text "next"
            ;;
        5)
            send_custom_request $intent_text "back"
            ;;
        6)
            send_custom_request $intent_text "previous"
            ;;
        7)
            send_custom_request $intent_text "fast forward"
            ;;
        8)
            send_custom_request $intent_text "rewind"
            ;;
        9)
            send_custom_request $intent_text "forward"
            ;;
        10)
            send_custom_request $intent_text "backward"
            ;;

        esac
    fi
}

function show_entity_menu_iot() {
    local light_on="light on"
    local light_off="light off"
    local gas_valve_lock="gas valve lock"
    local door_lock="door lock"
    local door_unlock="door unlock"
    log -q "\t1. $light_on"
    log -q "\t2. $light_off"
    log -q "\t3. $gas_valve_lock"
    log -q "\t4. $door_lock"
    log -q "\t5. $door_unlock"
    read entity_index

    re='^[0-9]+$'

    if ! [[ $entity_index =~ $re ]]; then
        send_iot_command $intent_text
    else
        case $entity_index in
        1)
            send_iot_command "$light_on"
            ;;
        2)
            send_iot_command "$light_off"
            ;;
        3)
            send_iot_command "$gas_valve_lock"
            ;;
        4)
            send_iot_command "$door_lock"
            ;;
        5)
            send_iot_command "$door_unlock"
            ;;
        esac
    fi

}

########################################################

while true; do
    if ! $demoMode; then
        show_intent_menu
    else
        show_demo_mode
    fi
done
