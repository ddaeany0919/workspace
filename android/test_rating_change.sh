#!/usr/bin/env bash

source common_bash.sh;
source common_android.sh;
DEBUG_COMMON_BASH=false;
DEBUG=true;
TC_NAME="2.3.3 Parental rating"
TC_SUB_ITEM="Program rating change test"
RATING_PREFIX="com.android.tv/IN_TV"
AUTHORITY="com.technicolor.android.dtvprovider"
if [ ! -z ${WORKSPACE_DTVPROVIDER_AUTHOR} ]; then
    AUTHORITY=${WORKSPACE_DTVPROVIDER_AUTHOR}
fi

URI="--uri content://android.media.tv/program"

currTime=$(date +%s)
currTime=$((currTime * 1000))

function intro() {
    log -i " # $TC_NAME"
    log -i " - $TC_SUB_ITEM"
     while read -r line; do  
        # _time=$(echo $line | cut -d"=" -f4)
        log -i "$line"
        
    done <<< $(adb shell cat /data/system/users/0/tv-input-manager-state.xml | grep com.android)
    log -d " • ${RATING_PREFIX}/TV_U ( ~ 11)"
	log -d "	○ U – Unrestricted public exhibition."
	log -d " • ${RATING_PREFIX}/TV_UA (12 ~ 17)"
	log -d "	○ U/A – Unrestricted public exhibition, but with parental guidance for children below the age of 12 years."
	# log -d " • ${RATING_PREFIX}/TV_ADULT_REMOVE_ADULT_ONCE"
    log -d " • ${RATING_PREFIX}/TV_A"
	log -d "	○ A – Restricted to adults. (18~21)"
	log -d " • ${RATING_PREFIX}/TV_S"
    log -d "	○ S – Restricted to any special class of persons."
    log -d "  + monitoring : watch -d -n 1 'adb shell cat /data/system/users/0/tv-input-manager-state.xml'"
}

function summery() {
    local zapping_time=0 
    local count=0 
    local _time=0;
    # adb shell "content query --uri content://android.media.tv/program --projection title:_id --where \"start_time_utc_millis <= 1665037800000 and 1665037800000 <= end_time_utc_millis\""
    while read -r line; do  
        # _time=$(echo $line | cut -d"=" -f4)
        log -i "$line"
    done <<< $(adb shell "content query ${URI} --projection _id:title:channel_id --where \"start_time_utc_millis <= ${currTime} and ${currTime} <= end_time_utc_millis\"")
}

function changeChannel() {
    do_execute -q "adb shell input keyevent KEYCODE_CHANNEL_UP && sleep 2 && adb shell content query --uri content://${AUTHORITY}/players >> ${WORKSPACE_HOME}/zapping_time"
}

function verify() {
    
#     usage: adb shell content update --uri <URI> [--user <USER_ID>] [--where <WHERE>] [--extra <BINDING>...]
#   <WHERE> is a SQL style where clause in quotes (You have to escape single quotes - see example below).
#   Example:
#   # Change "new_setting" secure setting to "newer_value".
#   adb shell content update --uri content://settings/secure --bind value:s:newer_value --where "name='new_setting'"

##  adb shell "content update --uri content://android.media.tv/program \
## --bind content_rating:s:com.android.tv/IN_TV/TV_ADULT_REMOVE_ADULT_ONCE \
## --where \"start_time_utc_millis <= ${currTime} and ${currTime} <= end_time_utc_millis\""


    do_execute adb shell "content update ${URI} \
        --bind content_rating:s:${RATING_PREFIX}/DVB_${1}\
        --where \"start_time_utc_millis <= ${currTime} and ${currTime} <= end_time_utc_millis\""
}

intro

if [ -z $1 ];then
    log -w "need argument"
    log -w " TV_U"
    log -w " TV_UA "
    log -w " TV_A"
fi

verify $1

summery;
