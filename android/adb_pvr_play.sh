#!/usr/bin/env bash

source common_bash.sh
DEBUG_COMMON_BASH=false;
DEBUG=false;


function get_pvr_info() {
    local tv_db="/data/data/com.android.providers.tv/databases/tv.db"
    local projections="recorded_programs._id, channels.display_name, channels.display_number"
    projections="${projections}, strftime(\"%H:%M:%S\",datetime(start_time_utc_millis/1000, \"unixepoch\", \"localtime\")) as start"
    projections="${projections}, strftime(\"%H:%M:%S\",datetime(end_time_utc_millis/1000, \"unixepoch\", \"localtime\")) as end"
    projections="${projections}, end_time_utc_millis - start_time_utc_millis AS duration, recording_data_uri"

    local tables="recorded_programs INNER join channels on recorded_programs.channel_id = channels._id"
    local index=$1;
    
    if [ -z $1 ]; then
        index=0;
    fi;

    index=$((index+1));
    local result=`adb shell "sqlite3 ${tv_db} 'select _id, recording_data_uri from recorded_programs ORDER by recorded_programs._id DESC limit ${index}'"`
    
    local _id=`echo ${result} | cut -d" " -f ${index} | cut -d"|" -f1`
    log -d "result=${result}, rec_id=${_id}"

    local result=`adb shell "sqlite3 ${tv_db} 'select ${projections} from ${tables} where recorded_programs._id=${_id}'"`
    
    log -d "result=${result}"
    local _id=`echo ${result} | cut -d"|" -f1`
    local ch_name=`echo ${result} | cut -d"|" -f2`
    local ch_num=`echo ${result} | cut -d"|" -f3`
    local start_time=`echo ${result} | cut -d"|" -f4`
    local end_time=`echo ${result} | cut -d"|" -f5`
    local duration=`echo ${result} | cut -d"|" -f6`
    local path=`echo ${result} | cut -d"|" -f7`
    local segment=`echo ${path} | cut -d"/" -f5`

    result="${result}|${segment}"

    log -d "${_id}, ${ch_num}/${ch_name}"
    log -d "\t${start_time} - ${end_time} (${duration})"
    log -d "\t${segment}"
    
    # log -i "${result}"
    echo ${result}
}

last_pvr_info=`get_pvr_info $1`
log "last_pvr_info=${last_pvr_info}"
rec_id=`echo $last_pvr_info | cut -d\| -f1`

do_execute -i "adb shell am start-activity -a \"android.intent.action.VIEW\" content://android.media.tv/recorded_program/${rec_id}"   


