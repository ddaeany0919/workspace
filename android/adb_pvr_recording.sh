#!/usr/bin/env bash

source common_bash.sh
DEBUG_COMMON_BASH=false;
DEBUG=true;

PKG="${WORKSPACE_DTVINPUT_PACKAGE}";
MODE_MONITORING=true;
last_segment="";
curr_segment="";

optspec="o"
while getopts "${optspec}}" option; do
    case ${option} in
        
        o)
            MODE_MONITORING=false
            ;;
        
    esac
done

shift $((OPTIND -1))

function pvr_info() {
    local tv_db="/data/data/com.android.providers.tv/databases/tv.db"
    local projections="recorded_programs._id, channels.display_name, channels.display_number"
    projections="${projections}, strftime(\"%H:%M:%S\",datetime(start_time_utc_millis/1000, \"unixepoch\", \"localtime\")) as start"
    projections="${projections}, strftime(\"%H:%M:%S\",datetime(end_time_utc_millis/1000, \"unixepoch\", \"localtime\")) as end"
    projections="${projections}, end_time_utc_millis - start_time_utc_millis AS duration, recording_data_uri, start_time_utc_millis, end_time_utc_millis"

    local tables="recorded_programs INNER join channels on recorded_programs.channel_id = channels._id"
    local index=$1;
    
    if [ -z $1 ]; then
        index=0;
    fi;

    index=$((index+1));
    local result=`adb shell "sqlite3 ${tv_db} 'select _id, recording_data_uri from recorded_programs ORDER by recorded_programs._id DESC limit ${index}'"`
    
    local _id=`echo ${result} | cut -d" " -f ${index} | cut -d"|" -f1`
    log -d "pvr_info result=${result}, rec_id=${_id}"

    local result=`adb shell "sqlite3 ${tv_db} 'select ${projections} from ${tables} where recorded_programs._id=${_id}'"`
    local _id ch_name ch_num start_time end_time duration path segment start_time_millis end_time_millis;
    oIFS="$IFS"
    IFS=$'\n'
    for _result in $result; do
        IFS='|'
        record=($_result)
        _id=${record[0]}
        ch_name=${record[1]}
        ch_num=${record[2]}
        start_time=${record[3]}
        end_time=${record[4]}
        duration=${record[5]}
        path=${record[6]}
        segment=`echo ${path} | cut -d"/" -f5`
        log -d "${_id}, ${ch_num}/${ch_name}, ${start_time} ~ ${end_time}, ${path}, segment=${segment}"
    done
    IFS="$oIFS"   
    
    result="${result}|${segment}"
    echo ${result}
}

function reserveRecordingNow() {
    local tv_ch_fields="_id, display_name, input_id"
    local tv_db="/data/data/com.android.providers.tv/databases/tv.db"
    local needProgramId=true

    local table_programs_channel="programs INNER JOIN channels on programs.channel_id=channels._id"

    local where_for_dtvinput="programs.package_name=\"${PKG}\""

    local dvr_fields="input_id, channel_id, start_time_utc_millis, end_time_utc_millis, type, state, priority"
    local dvr_db="/data/data/com.android.tv/databases/dvr.db"
    local schedule_table="schedules"
    # needProgramId=false
    # local dvr_fields="input_id, channel_id, program_id, start_time_in_millis, end_time_in_millis, type, state, priority"
    # dvr_fields="${dvr_fields}, series_recording_id, recorded_program_id, locked, isSelected"
    # local dvr_db="/data/data/com.airtel.tv/databases/schedules.db"
    local schedule_table="Schedules"

    local num=901;
    local duration=120;
    local needKillLiveTv=true;

    if [ ! -z $1 ]; then
        num=$1;
    fi

    if [ ! -z $2 ]; then
        duration=$2;
    fi

    # 1. getting last pvr info
    local last_pvr_info=`pvr_info`
    
    log "reserveRecordingNow last_pvr_info=${last_pvr_info}"
    last_segment=`echo $last_pvr_info | cut -d\| -f8`
    local last_endtime=$(echo $last_pvr_info | cut -d\| -f9)
    last_endtime=$((last_endtime / 1000))

    # 2. getting channel id in tv.db
    local ch_info=`adb shell "sqlite3 ${tv_db} \"select ${tv_ch_fields} from channels where display_number=${num} limit 1\""`
    log -d "reserveRecordingNow channel id=${ch_info}"
    local ch_id=`echo ${ch_info} | cut -d\| -f1`
    local ch_name=`echo ${ch_info} | cut -d\| -f2`
    local ch_input=`echo ${ch_info} | cut -d\| -f3`

    # 3. make start and end time for the newer request to recording
    local start_time=`adb shell date +%s`
    
    if [ $start_time -lt $last_endtime ]; then
        start_time=$last_endtime;
        start_time=$((start_time + 1))
        needKillLiveTv=false;
    else
        start_time=$((start_time + 5))
    fi
    local end_time=$((start_time + ${duration}))

    start_time=$((start_time * 1000))
    end_time=$((end_time * 1000))

    

    log -i "reserveRecordingNow reserve a recording request for ${num} (${ch_id}) - ${ch_name}"
    local top_priority=`adb shell "sqlite3 ${dvr_db} \"select priority from ${schedule_table} order by priority desc limit 1\""`;
    log -d "reserveRecordingNow top_priority=${top_priority}"
    top_priority=$((top_priority + 1000))

    # 4. delete gabage records in the dvr.dv
    # local deletableRows=$(adb shell "sqlite3 ${dvr_db} \"select failed_reason from schedules where failed_reason NOT NULL\"")
    # if [ "${deletableRows}" != "" ];then
        # do_execute -i "adb shell \"sqlite3 ${dvr_db} 'delete from ${schedule_table} where state like \\\"%FAILED\\\"'\"";
    # fi

    # 5. make sure the recording request to dvr.dv
    local dvr_def_value="\\\"TYPE_TIMED\\\", \\\"STATE_RECORDING_NOT_STARTED\\\", ${top_priority}";
    local dvr_ch_input="\\\"${ch_input}\\\""

    if ${needProgramId}; then
        local where="where ${where_for_dtvinput}"
        where="${where} and channels._id=${ch_id} and programs.start_time_utc_millis <= ${start_time} and ${start_time} <= programs.end_time_utc_millis"
        local program_id=$(adb shell "sqlite3 ${tv_db} 'select programs._id from ${table_programs_channel} ${where}'")
        if [ ! -z ${program_id} ]; then 
            do_execute -i "adb shell \"sqlite3 ${dvr_db} 'INSERT INTO ${schedule_table} (${dvr_fields}) VALUES \
            (${dvr_ch_input}, ${ch_id}, ${program_id}, ${start_time}, ${end_time}, ${dvr_def_value}, 0, 0, 0, 0)'\"";    
        else
            log -w "program is not matched"
            exit 1
        fi

    else
        do_execute -i "adb shell \"sqlite3 ${dvr_db} 'INSERT INTO ${schedule_table} (${dvr_fields}) \
        VALUES (${dvr_ch_input}, ${ch_id}, ${start_time}, ${end_time}, ${dvr_def_value})'\"";
    fi

    if $needKillLiveTv; then
        # 6. kill the live tv app and restart it
        # do_execute -i "adb_kill com.android.tv";
        # do_execute -i "adb shell am stop-service -n com.android.tv/.dvr.recorder.DvrRecordingService"
        # do_execute -i "adb shell am stop-service -n com.android.tv/.dvr.recorder.DvrRecordingService"
        # do_execute -i "adb shell am broadcast --receiver-include-background -n com.android.tv/.dvr.recorder.DvrStartRecordingReceiver";
        # do_execute -i "adb_kill com.airtel.tv";
        do_execute -i "adb shell am broadcast --receiver-include-background -a com.airtel.algorithm.scheduling.RECEIVE";
    fi

}

reserveRecordingNow $@

if $MODE_MONITORING; then
    try_count=0;
    while
        curr_segment=`adb shell ls -tu /storage/emulated/0/Android/media/${PKG}/Records | head -1`
        log -d "last=${last_segment}, curr=${curr_segment}"
        [ "${last_segment}" == "${curr_segment}" ]
    do
        if [ ${try_count} -gt 5 ]; then
            log -e "failed creating the segment directory"
            exit 1       
        fi
        sleep 0.5

        # adb_pvr_check_meta.sh ${curr_segment}
    done
    watch -d adb shell /data/pvr_info.sh
fi


