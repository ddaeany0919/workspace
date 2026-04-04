#!/bin/sh
DEBUG=true;
# path
ME_PATH="$PWD"
LOGCAT_PID=0;
REPORT_OUTPUT="report.txt"
DEF_SLEEP=15;

########################################################################################################################
usb_dir=`mount | grep vfat | cut -d " " -f 3 | cut -d "/" -f 4`
am_exoplayer="${am_exoplayer}"
 # resolutions
resolutions=(
        "480p@60|8" 
        "720p@60|14" 
        "720p@50|15" 
        "1080p@60|24"
        "1080p@5994|25"
        "1080p@50|26"
        "1080p@30|19"
        "1080p@2997|20"
        "1080p@25|21"
        "1080p@24|23"
        "1080i@60|16"
        "1080i@5994|17"
        "1080i@50|18"
        "2160p@5994|63"
        "2160p@60|64"
        "2160p@50|62"
        "2160p@30|61"
        "2160p@2997|60"
        "2160p@25|59"
        "2160p@24|57"
        )
bit_depth=("12bit|0" "10bit|1" "8bit|2")
color_fmt=("RGB888|0" "YUV444|1" "YUV422|2" "YUV420|3")
aspect_ratio=("16x9|2")
actions=(
    "GFX|input keyevent KEYCODE_HOME"
    "LIVE|input keyevent KEYCODE_TV"
    "SDR|${am_exoplayer} file:///storage/$usb_dir/Stream/test_SDR.mp4"
    "HDR|${am_exoplayer} file:///storage/$usb_dir/Stream/test_HDR.mp4"
    "HLG|${am_exoplayer} file:///storage/$usb_dir/Stream/test_HLG.mp4"
    "DV|${am_exoplayer} http://media.developer.dolby.com/DolbyVision_Atmos/mp4/P81_GlassBlowing2_3840x2160%4059.94fps_15200kbps_fmp4.mp4"
    )

trap cleanup 1 2 3 6
step_index=0;
red_color="\033[0;31;49m";
green_color="\033[0;32;49m";
yellow_color="\033[0;93;49m";
blink_color="\033[5;33;49m";
reset_color="\033[0m";


function log() {
    # _log=$2;
    # message="${_log/$PDK_ROOT"/"/""}" ;
    message=$2;
    case "$1" in
        -i)
            echo -e "$green_color"$message"$reset_color"
        ;;
        -e)
            echo -e "$red_color"$message"$reset_color"
        ;;
        -b)
            echo -e "$blink_color"$message"$reset_color" 
        ;;
        -d)
            if $DEBUG ; then
                echo -e "$yellow_color\tDEBUG :"$message"$reset_color"
            fi
        ;;
        *)
            echo " $message";
    esac
}

function cleanup() {
    if [ $# -gt 0 ]; then
        if [ $1 -gt 0 ]; then
            log -e "INTERRUPTED!!"
        fi
    fi

    if [ $LOGCAT_PID -gt 0 ]; then
        log -d "Kill the LOCAT_PID=$LOGCAT_PID"
        kill -9 $LOGCAT_PID;
    fi
    exit 1
}
########################################################################################################################

if [ $# -gt 0 ]; then
    MODEL_NAME="$1"
else
    log -e "need a model name"
    exit 1;
fi
echo "" > $REPORT_OUTPUT
########################################################################################################################
log -d "$ME_PATH"
mkdir $ME_PATH/$MODEL_NAME;
cd $ME_PATH/$MODEL_NAME;

# disable print of kernel
echo "0" > /proc/sys/kernel/printk

# test_disp
test_disp hdcp version > hdcp_version
test_disp hdcp state   > hdcp_state
test_disp edid infor   > edid_infor
manufacture=`test_disp edid infor | grep "Manufacturer Name" | cut -d":" -f2 | xargs`
product_code=`test_disp edid infor | grep "Product Code" | cut -d":" -f2 | xargs`
serial_number=`test_disp edid infor | grep "Serial Number" | cut -d":" -f2 | xargs`
week_of_manu=`test_disp edid infor | grep "Week of Manufacture" | cut -d":" -f2 | xargs`
year_of_manu=`test_disp edid infor | grep "Year of Manufacture" | cut -d":" -f2 | xargs`
log -i "Display Info"
log -i "\tManufacture=$manufacture, Product Code=$product_code, SerialNumber=$serial_number, Week/Year=$week_of_manu/$year_of_manu"

# run logcat
logcat > logcat.log &
LOGCAT_PID=$!

function getResult() {
    read -t $DEF_SLEEP result;
    result=`echo $result | tr '[:upper:]' '[:lower:]'`
    if [ "$result" == "y" ] || [ -z "$result" ]; then
        echo "OK!!"
        exit 0;
    fi
    
    select sub_index in "HDCP state" "HDCP disable" "HDCP enable" "Display black" "No Sound" "Crazy screen" "Direct report" "Next step"; do
        case $sub_index in
            "HDCP state")
                test_disp hdcp state
                continue;
            ;;
            "HDCP disable")
                test_disp hdcp disable
                continue;
            ;;
            "HDCP enable")
                test_disp hdcp enable
                continue;
            ;;
            "Direct report")
                echo "enter problem status"
                read  temp_result;
                result="$result, $temp_result"
                # echo "$result";
                continue
            ;;
            "Display black" | "No Sound" | "Crazy screen")
                result="$result, $sub_index"
                # echo "$result";
                continue
            ;;
            *)
                break;
            ;;
            
        esac
    done

    echo "$result";
    exit 0;
}

function doProcessAction() {
    local _command;
    local result="";
    for action in "${actions[@]}"
    do
        label=`echo $action | cut -d\| -f1`
        _command=`echo $action | cut -d\| -f2`
        echo "doProcessAction, label=$label, command=$_command"
        $_command
        sleep 1;

        # check the result
        echo -n "Continue (Y/y/N/n) ";
        result=`getResult`;
        result="$label:\t $result"
        log -d "result = $result"
        echo "\t\tinfo=$info, config=$config : $result" >> $REPORT_OUTPUT
    done
}

function test_by_command {
    local _command="test_disp setformat 0"
    input keyevent KEYCODE_HOME
   
    info="";
    config=""
    # resolution
    for resolution in "${resolutions[@]}"
    do
        log -b "================================= `echo $resolution | cut -d\| -f1` ================================="
        curr_res=`echo $resolution | cut -d\| -f1`
        # bit_depth
        for bit in "${bit_depth[@]}"
        do
            curr_bit=`echo $bit | cut -d\| -f1`
            
            # color_fmt
            for color in "${color_fmt[@]}"
            do
                curr_color=`echo $color | cut -d\| -f1`
                if [[ "$curr_res" != "2160"* ]] && [[ $curr_color == "YUV420"* ]]; then
                    log -d "not support color($curr_color) in $curr_res"
                    continue;
                fi

                # aspect_ratio
                for aspect in "${aspect_ratio[@]}"
                do
                    # make infomation
                    info="$curr_res $curr_bit $curr_color"
                    info="$info `echo $aspect | cut -d\| -f1`"
                    
                    # make config to be use to param
                    config=`echo $resolution | cut -d\| -f2`
                    config="$config `echo $bit | cut -d\| -f2`"
                    config="$config `echo $color | cut -d\| -f2`"
                    config="$config `echo $aspect | cut -d\| -f2`"
                    log -d "info=$info, command=$_command $config"
                    
                    log -i "set resolution : $info"
                    echo "===========================================" >> $REPORT_OUTPUT
                    echo "info=$info, config=$config" >> $REPORT_OUTPUT

                    $_command $config > /dev/null
                    
                    sleep 3

                    # check the result
                    # echo -n "Continue (Y/y/N/n) ";
                    # result=`getResult`;
                    # log -d "result = $result"
                    # echo "\t\tinfo=$info, config=$config : $result" >> $REPORT_OUTPUT

                    test_disp getformat | grep ResID
                    test_disp hdcp state | grep HDCP
                    
                    #am start -a android.settings.SETTINGS

                    doProcessAction;
                    # for aspect in "${aspect_ratio[@]}"
                    
                    # sleep 1

                    # $_command $config > /dev/null
                    
                    # sleep 1
                    # input keyevent KEYCODE_HOME

                    # # check the result
                    # echo -n "Continue (Y/y/N/n) ";
                    # result=`getResult`;
                    # log -d "result = $result"
                    # echo "\t\tinfo=$info, config=$config : $result" >> $REPORT_OUTPUT

                    # test_disp getformat | grep ResID
                    # test_disp hdcp state | grep HDCP
                done
            done
        done    
    done
}



########################################################################################################################

display_pid=`pidof com.synaptics.tv.settings`

if [ "$display_pid" != "" ]; then
    kill -9 $display_pid
fi


#test_keyinput

test_by_command

# revert to auto
# am start -n com.synaptics.tv.settings/.DisplayActivity
# sleep 1
# input keyevent DPAD_CENTER
# input keyevent DPAD_CENTER
# sleep 5;
# input keyevent DPAD_DOWN
# input keyevent DPAD_CENTER

cleanup 0;


