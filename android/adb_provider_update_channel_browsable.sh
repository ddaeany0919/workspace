#!/usr/bin/env bash

source common_menu.sh
DEBUG_COMMON_BASH=false
DEBUG=false
TV_DB="/data/data/com.android.providers.tv/databases/tv.db"

PKG="${WORKSPACE_DTVINPUT_PACKAGE}";
URI_CHANNEL="content://android.media.tv/channel"

LIMIT_RECORDS=10000

function updateBrowsableByTP() {
    local TP

    if [ ! -z $1 ]; then
        TP=$(echo $@ | sed "s/ /,/g")
        do_execute -i "adb shell content update --uri ${URI_CHANNEL} --bind browsable:i:1 --where \"package_name='${PKG}' and transport_stream_id in (${TP})\""
        do_execute -i "adb shell content update --uri ${URI_CHANNEL} --bind browsable:i:0 --where \"package_name='${PKG}' and transport_stream_id not in (${TP})\""
    else
        do_execute -i "adb shell content update --uri ${URI_CHANNEL} --bind browsable:i:1 --where \"package_name='${PKG}'\""
    fi

    return 0
}

function updateChannelSubtype() {
    # local maxSubType=$(adb shell "sqlite3 ${TV_DB} 'select max(subtype) from channels where package_name=\"${PKG}\"'")

    # local maxSubType=$(adb shell "content query --uri ${URI_CHANNEL} --projection \"subtype\" --where \"package_name='${PKG}'\" --sort \"subtype desc limit 1\" | cut -d= -f2")
    maxSubType=$(date +%s)
    log -d "max SubType=${maxSubType}"
    do_execute -i "adb shell content update --uri ${URI_CHANNEL} --bind subtype:i:${maxSubType} --where \"package_name='${PKG}'\""
}

updateBrowsableByTP $@

updateChannelSubtype
