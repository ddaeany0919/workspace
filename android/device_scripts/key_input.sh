#!/bin/sh

echo "Press any key to continue"
escape_char=$(printf "\u1b")
isSpecial=false;
while [ true ] ; do
    read -rsn4 -a keys # get 1 character
    # if [[ $mode == $escape_char ]]; then
    #     read -rsn4 -t 0.001 mode # read 2 more chars
    # fi
    isSpecial=false;
    echo "key size= ${#keys[@]}"
      for key in ${keys[@]}; do
        echo "key=${key}"
    done
    if [ ${#keys[@]} -eq 1 ]; then
        if [ ${keys[0]} == 27 ]; then
            echo "ignore"
            continue;
        else
            mode=${keys[0]};
        fi
    elif [ ${#keys[@]} -gt 1 ]; then
        isSpecial=true
        if [ ${keys[0]} == 91 ]; then
            mode=${keys[1]}
        else
            echo "ignore"
            continue;
        fi
    fi
    # case ${#keys[@]} in
    #     1) mode=${keys[0]};;
    #     2) mode=${keys[0]};;
    # echo "key count=${#mode[@]}"
    # for key in ${mode[@]}; do
    #     echo "key=${key}"
    # done
    # echo "array=${mode[-1]}"
    # keyevent="";
    case $mode in
        10)     keyevent=KEYCODE_DPAD_CENTER ;;
        65)   keyevent=KEYCODE_DPAD_UP ;;
        66)   keyevent=KEYCODE_DPAD_DOWN ;;
        68)   keyevent=KEYCODE_DPAD_LEFT ;;
        67)   keyevent=KEYCODE_DPAD_RIGHT ;;
        # '[A*')   keyevent=KEYCODE_DPAD_UP ;;
        # '[B*')   keyevent=KEYCODE_DPAD_DOWN ;;
        # '[D*')   keyevent=KEYCODE_DPAD_LEFT ;;
        # '[C*')   keyevent=KEYCODE_DPAD_RIGHT ;;
        72)  keyevent=KEYCODE_HOME ;;
        127)    keyevent=KEYCODE_BACK ;;
        48)    keyevent=KEYCODE_0 ;;
        49)    keyevent=KEYCODE_1 ;;
        50)    if $isSpecial; then 
                    keyevent=KEYCODE_MEDIA_RECORD 
               else 
                    keyevent=KEYCODE_2 
                fi
                ;;
        51)    keyevent=KEYCODE_3 ;;
        52)    keyevent=KEYCODE_4 ;;
        53)    if $isSpecial; then 
                    keyevent=KEYCODE_CHANNEL_UP 
               else 
                    keyevent=KEYCODE_5
                fi
                ;;
        54)    
                 if $isSpecial; then 
                    keyevent=KEYCODE_CHANNEL_DOWN 
               else 
                    keyevent=KEYCODE_5
                fi
                ;;
        55)    keyevent=KEYCODE_7 ;;
        56)    keyevent=KEYCODE_8 ;;
        57)    keyevent=KEYCODE_9 ;;
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

        # *) echo "not support=$mode";;
    esac
    if [ -n "${keyevent}" ]; then
        echo "keyevent=${keyevent}"
        # adb -s ${ANDROID_SERIAL} shell input keyevent ${keyevent} &
        input keyevent ${keyevent} 
    fi
done