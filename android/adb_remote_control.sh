#!/bin/bash
echo "Press any key to continue"
escape_char=$(printf "\u1b")
while [ true ] ; do
    read -rsn1 mode # get 1 character
    if [[ $mode == $escape_char ]]; then
        read -rsn4 -t 0.001 mode # read 2 more chars
    fi
    keyevent="";
    case $mode in
        '')     keyevent=KEYCODE_DPAD_CENTER ;;
        '[a')   keyevent=KEYCODE_DPAD_UP ;;
        '[b')   keyevent=KEYCODE_DPAD_DOWN ;;
        '[d')   keyevent=KEYCODE_DPAD_LEFT ;;
        '[c')   keyevent=KEYCODE_DPAD_RIGHT ;;
        '[A')   keyevent=KEYCODE_DPAD_UP ;;
        '[B')   keyevent=KEYCODE_DPAD_DOWN ;;
        '[D')   keyevent=KEYCODE_DPAD_LEFT ;;
        '[C')   keyevent=KEYCODE_DPAD_RIGHT ;;
        '[5~')  keyevent=KEYCODE_CHANNEL_UP ;;
        '[6~')  keyevent=KEYCODE_CHANNEL_DOWN ;;
        '[7~')  keyevent=KEYCODE_HOME ;;
        '[H')   keyevent=KEYCODE_HOME ;;
        '\')    keyevent=KEYCODE_BACK ;;
        '0')    keyevent=KEYCODE_0 ;;
        '1')    keyevent=KEYCODE_1 ;;
        '2')    keyevent=KEYCODE_2 ;;
        '3')    keyevent=KEYCODE_3 ;;
        '4')    keyevent=KEYCODE_4 ;;
        '5')    keyevent=KEYCODE_5 ;;
        '6')    keyevent=KEYCODE_6 ;;
        '7')    keyevent=KEYCODE_7 ;;
        '8')    keyevent=KEYCODE_8 ;;
        '9')    keyevent=KEYCODE_9 ;;
        '[2~')  keyevent=KEYCODE_MEDIA_RECORD ;;
        '[7$')  echo HOME ;;
        '[8~')  echo end ;;
        '[8$')  echo END ;;
        '[3~')  echo delete ;;
        '[3$')  echo DELETE ;;
        '[11~') echo F1 ;;
        '[12~') echo F2 ;;
        '[13~') echo F3 ;;
        '[14~') echo F4 ;;
        '[15~') echo F5 ;;
        '[16~') echo Fx ;;
        '[17~') echo F6 ;;
        '[18~') echo F7 ;;
        '[19~') echo F8 ;;
        '[20~') echo F9 ;;
        '[21~') echo F10 ;;
        '[22~') echo Fy ;;
        '[23~') echo F11 ;;
        '[24~') keyevent="82 8 82 9 82 10" ;;

        *) echo $mode;;
    esac
    if [ -n "${keyevent}" ]; then
        echo "keyevent=${keyevent}"
        adb -s ${ANDROID_SERIAL} shell input keyevent ${keyevent} &
    fi
done