#!/bin/bash

usb_adb_support=false
adb_root_support=true
max_trial_cnt=20000

if [ "$usb_adb_support" = "true" ]; then
    device=$1
    adb_session_cmd="adb -s $device"
    logcat_log_dir=$HOME/logs/uie4057lgu/factory_reset/$device
else
    ip=$1
    adb_session_cmd="adb -s $ip:5555"
    #logcat_log_dir=$HOME/logs/uie4057lgu/factory_reset/$ip
    logcat_log_dir=$HOME/temp/uie4057lgu/factory_reset/$ip
fi
trial=1
elapsed_time="0d 00h 00m 00s"
script_start_timestamp=$(date +"%s")
log_file_script_start_time_postfix=$(date -d@$script_start_timestamp +"%Y%m%d_%H%M%S")
me=`basename "$0"`

# Rebooting timeout: 50 seconds
booting_timeout_sec=30
factory_reset_timeout_sec=80

# Font color settings
SET_RED_FONT='\033[1;31m'
SET_GREEN_FONT='\033[1;32m'
CLR_FONT_SET='\033[0m'

# usage
if [ "$#" -eq 0 ]; then
    if [ "$usb_adb_support" = "true" ]; then
        echo "Error: Required argument : [Device ID]"
        echo "Example) $me 680000000000005a"
    else
        echo "Error: Required argument : [IP Address]"

        echo "Example) $me 192.168.0.2"
    fi
    exit -1;
fi

#trap '{ kill $logcat_pid; echo ""; echo "logcat pid [$logcat_pid] has been killed."; echo "The script is stopped at [$(date)]."; exit 1; }' INT
trap exit_script INT

# Post processes:
# 1. Kill background logcat process.
# 2. Disconnect adb connection.
function exit_script() {
    echo ""
    stop_logcat_process
    echo "The script is stopped at [$(date)]."
    update_elapsed_time
    echo "Total elapsed time: $elapsed_time"

    if [ "$usb_adb_support" != "true" ]; then
        adb disconnect $ip:5555
    fi
    exit 1
}

# Reconnect adb
function reconnect_adb() {
    if [ "$usb_adb_support" != "true" ]; then
        # Reconnect adb
        echo "Reconnect adb..."
        #adb disconnect $ip:5555
        #sleep 1
        adb connect $ip:5555
        sleep 1

        # Check adb connection and retry
        retry_cnt=1
        while [ 1 ] ; do
            adb_device=$(adb devices | grep -wo $ip)
            if [ -z "$adb_device" ]; then
                echo "ERROR: adb connection failed. Retry #$retry_cnt - Please wait..."
                adb connect $ip:5555
                sleep 2
            else
                break
            fi

            retry_cnt=$((retry_cnt + 1))
        done
    fi
    if [ "$adb_root_support" = "true" ]; then
        # Get adb root permission
        $adb_session_cmd root
        sleep 1
        $adb_session_cmd root
        if [ "$usb_adb_support" != "true" ]; then
            adb connect $ip:5555
        fi
        sleep 1
    fi
}

# Update elapsed time string in "0d 00h 00m 00s" format
function update_elapsed_time() {
    cur_timestamp=$(date +"%s")
    time_diff_sec=$((cur_timestamp - script_start_timestamp))
    elapsed_day=$(date -d@$time_diff_sec -u +"%d")
    elapsed_day=$((elapsed_day - 1))
    if [ "$elapsed_day" -gt 0 ]; then
        elapsed_time="${elapsed_day}d $(date -d@$time_diff_sec -u +"%Hh %Mm %Ss")"
    else
        elapsed_time=$(date -d@$time_diff_sec -u +"%Hh %Mm %Ss")
    fi
}

function stop_logcat_process() {
    printf "\n\n"
    if [ -n "$logcat_pid" ]; then
        logcat_process=$(ps | grep -c $logcat_pid)
        if ((logcat_process > 0)); then
            kill $logcat_pid
            echo "logcat pid [$logcat_pid] has been killed."
        else
            echo "logcat pid [$logcat_pid] is already completed."
        fi
        logcat_pid=
    fi
}

# Capture logcat log
function capture_logcat_logs() {
    # Add comment on logcat logs file
    mkdir -p $logcat_log_dir
    logcat_file_name=${logcat_log_dir}/factory_reset_trial${trial}.txt
    printf "============================================================\n\n" > $logcat_file_name
    printf "  FACTORY RESET TRIAL #$trial: $booting_start_local_time\n" >> $logcat_file_name
    printf "\n============================================================\n\n" >> $logcat_file_name

    # Start logcat
    $adb_session_cmd logcat -b all | egrep -v "disp_is_gfx_bd|AMPBuf_BDTag_GetWithType" >> $logcat_file_name &
    logcat_pid=$!
    echo "logcat capturing has been started (pid: $logcat_pid)."
}

# Infinite rebooting test: Start from active (powered-on) status

echo "The script is started at [$(date -d@$script_start_timestamp)]."

# Connect adb and retry if needed.
adb start-server

echo "Do 1st factory reset!"

while [ 1 ]; do
    booting_start_timestamp=$(date +"%s")
    booting_start_local_time=$(date -d@$booting_start_timestamp)
    printf "\n============================================================\n"
    printf "  FACTORY RESET TRIAL #$trial: $booting_start_local_time\n"
    printf "============================================================\n"

    # Reconnect adb
    reconnect_adb

    # Do factory reset
    $adb_session_cmd shell "echo 'boot-recovery' > /cache/recovery/command"
    $adb_session_cmd shell "echo '--wipe_data' >> /cache/recovery/command"
    $adb_session_cmd shell reboot recovery

    # factory reset & following reboot waiting
    for (( i=factory_reset_timeout_sec; i>0; i-- )) ; do
        if [ $i -gt 1 ] ; then
            printf "\r[Factory reset & reboot waiting timeout] $i seconds left..."
        else
            printf "\r[Factory reset & reboot waiting timeout] $i second left..."
        fi
        sleep 1
        printf "\r                                                                "
    done
    printf "\rFactory reset & reboot waiting timeout! ($factory_reset_timeout_sec seconds)\n"

    # Reconnect adb
    reconnect_adb

    # Capture logcat log file
    capture_logcat_logs
    sleep 2

    # Rebooting
    $adb_session_cmd shell reboot
    sleep 3
    stop_logcat_process

    # Boot-up waiting
    for ((i=booting_timeout_sec; i>0; i--)); do
        if [ "$i" -gt 1 ]; then
            printf "\r[Boot-up waiting timeout] $i seconds left..."
        else
            printf "\r[Boot-up waiting timeout] $i second left..."
        fi
        sleep 1
        printf "\r                                               "
    done
    printf "\rBoot-up waiting timeout! ($booting_timeout_sec seconds)\n"

    if [ $trial -ge $max_trial_cnt ]; then
        exit_script
    fi

    update_elapsed_time
    printf "\n\n"
    echo "Do next factory reset! (Total elapsed time: $elapsed_time)"

    # Increase trial count
    trial=$((trial + 1))
done
