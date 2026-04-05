#!/usr/bin/env bash

source common_dtv.sh

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
