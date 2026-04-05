#!/usr/bin/env bash

source common_dtv.sh

function deleteUpdatedPrograms() {
    log -w "delete all programs these were updated by manually (${UPDATED_VERSION})"
    do_execute "adb shell 'content delete --uri content://android.media.tv/program --where \"${UPDATED_VERSION} and package_name=\\\"${PKG}\\\"\"'"
}

function updateStartEndTime() {

    # delete updated programs by manually
    # deleteUpdatedPrograms;

    local currTime=$(adb shell date +%s)
    currTime=$((currTime * 1000))

    local count=$(adb shell "sqlite3 ${TV_DB} 'select count(_id) from programs where package_name=\"${PKG}\" and end_time_utc_millis<=${currTime}'");
    log "updateable program count is ${count}"

    local minTime=$(adb shell "sqlite3 ${TV_DB} 'select start_time_utc_millis from programs where package_name=\"${PKG}\" order by start_time_utc_millis limit 1'")
    local diffTime=$((currTime - minTime))
    log -d "diffTime=${diffTime}"
    local fields="start_time_utc_millis=start_time_utc_millis+${diffTime}, end_time_utc_millis=end_time_utc_millis+${diffTime}, ${UPDATED_VERSION}"
    local where="select _id from programs where package_name=\\\"${PKG}\\\" and end_time_utc_millis<=${currTime} LIMIT ${LIMIT_RECORDS}"
    do_execute -i "adb shell \"sqlite3 ${TV_DB} 'update programs set ${fields} where package_name=\\\"${PKG}\\\" and end_time_utc_millis<=${currTime}'\""

    return 0

}

function updateChannelSubtype() {
    local maxSubType=$(adb shell "sqlite3 ${TV_DB} 'select max(subtype) from channels where package_name=\"${PKG}\"'")
    maxSubType=$((maxSubType + 1))
    log -d "max SubType=${maxSubType}"
#   usage: adb shell content update --uri <URI> [--user <USER_ID>] [--where <WHERE>] [--extra <BINDING>...]
#     <WHERE> is a SQL style where clause in quotes (You have to escape single quotes - see example below).
#     Example:
#     # Change "new_setting" secure setting to "newer_value".
#     adb shell content update --uri content://settings/secure --bind value:s:newer_value --where "name='new_setting'"
    # update channels set subtype=(select max(subtype) from channels where package_name='com.technicolor.android.dtvinput') + 1 where package_name='com.technicolor.android.dtvinput'
    do_execute -i "adb shell content update --uri content://android.media.tv/channel --bind subtype:i:${maxSubType} --where \"package_name=\'${PKG}\'\""
}

adb_provider_update_channel_browsable.sh

updateStartEndTime;

updateChannelSubtype;
