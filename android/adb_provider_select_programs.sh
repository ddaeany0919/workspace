#!/usr/bin/env bash

source common_menu.sh;
DEBUG_COMMON_BASH=false;
DEBUG=true;
TV_DB="/data/data/com.android.providers.tv/databases/tv.db"
QUERY_COMMAND="adb shell sqlite3 ${TV_DB}\""

PKG="${WORKSPACE_DTVINPUT_PACKAGE}";
TV_DB="/data/data/com.android.providers.tv/databases/tv.db"
SQL_OPT="-header -column"

LIMIT_RECORDS=10000;

function query_program_by_channels() {
    local projections="programs._id as programs_id, channels._id as channels_id, channels.display_number, channels.transport_stream_id as TP, channels.display_name, programs.title, programs.content_rating"
    projections="${projections}, strftime(\"%Y-%m-%d %H:%M:%S\",datetime(programs.start_time_utc_millis/1000, \"unixepoch\", \"localtime\")) as start"
    projections="${projections}, strftime(\"%Y-%m-%d %H:%M:%S\",datetime(programs.end_time_utc_millis/1000, \"unixepoch\", \"localtime\")) as end"
    projections="${projections}, end_time_utc_millis - start_time_utc_millis AS duration"

    local tables="programs INNER join channels on channels._id=programs.channel_id"
    local where="where channels.browsable=1";
    local order="order by channels.display_number, start_time_utc_millis"

    if [ $# -gt 0 ]; then
        where="${where} and channels.display_number in ($(echo $@ | tr ' ' ',' ))"
        log -d "where=${where}"
    fi

    # "select channels.display_number, channels.display_name, programs.title, end_time_utc_millis - start_time_utc_millis AS duration from programs INNER join channels on channels._id=programs.channel_id where channels.browsable=1 and channels.display_number in "901" limit 10"

    command="sqlite3 ${TV_DB} ${SQL_OPT} 'select ${projections} from ${tables} ${where} ${order}'"
    log -i "adb shell \"${command}\""
    local resultSet=$(adb shell "${command}")

    # log -d "$resultSet"
    oIFS="$IFS"
    IFS=$'\n'
    for line in $resultSet; do
        log "${line}"
        # IFS='|'
        # arr=($line)
        # log -d "${arr[0]} ${arr[5]} ~ ${arr[6]} (${arr[7]}) ${arr[2]} / ${arr[4]}" 
    done
    
    IFS="$oIFS"   
}

query_program_by_channels $@
