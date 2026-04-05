#!/usr/bin/env bash

source common_bash.sh

log -i "Press any key to control (Arrows, Numbers, Enter, Backspace...)"
escape_char=$(printf "\u1b")

while true; do
    read -rsn1 mode
    if [[ "$mode" == "$escape_char" ]]; then
        read -rsn4 -t 0.001 mode
    fi

    keyevent=""
    case "$mode" in
        '')     keyevent=KEYCODE_DPAD_CENTER ;;
        '[A'|'[a') keyevent=KEYCODE_DPAD_UP ;;
        '[B'|'[b') keyevent=KEYCODE_DPAD_DOWN ;;
        '[D'|'[d') keyevent=KEYCODE_DPAD_LEFT ;;
        '[C'|'[c') keyevent=KEYCODE_DPAD_RIGHT ;;
        '[5~')  keyevent=KEYCODE_CHANNEL_UP ;;
        '[6~')  keyevent=KEYCODE_CHANNEL_DOWN ;;
        '[H'|'[7~') keyevent=KEYCODE_HOME ;;
        '\'|'[3~')  keyevent=KEYCODE_BACK ;;
        [0-9])  keyevent="KEYCODE_$mode" ;;
        *)      log -d "Unknown key: $mode" ;;
    esac

    if [[ -n "$keyevent" ]]; then
        echo "keyevent=${keyevent}"
        adb ${ANDROID_SERIAL:+-s $ANDROID_SERIAL} shell input keyevent "${keyevent}" &
    fi
done
