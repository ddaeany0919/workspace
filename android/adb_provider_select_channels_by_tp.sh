#!/usr/bin/env bash

source common_menu.sh;
DEBUG_COMMON_BASH=false;
DEBUG=true;
TV_DB="/data/data/com.android.providers.tv/databases/tv.db"

PKG="${WORKSPACE_DTVINPUT_PACKAGE}";
URI_CHANNEL="--uri content://android.media.tv/channel"

LIMIT_RECORDS=10000;
DEFAULT_TP=13

function selectChannelListByTP() {
    # local fields="_id, display_number, display_name, transport_stream_id"
    local fields="display_number:display_name:transport_stream_id:service_id:_id"
    local where="package_name=\\\"${PKG}\\\""
    local sort="--sort display_number"

    local TP;

    if [ ! -z $1 ]; then
        TP=$(echo $@ | sed "s/ /,/g");
        where="${where} and transport_stream_id in (${TP})"
    fi

    do_execute -i "adb shell content query ${URI_CHANNEL} --projection ${fields} --where \"${where}\" ${sort}"
   
   return 0
}

selectChannelListByTP $@;
