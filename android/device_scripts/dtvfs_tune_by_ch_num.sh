#!/bin/sh

URI_PROGRAM="--uri content://android.media.tv/program"
URI_CHANNEL="--uri content://android.media.tv/channel"
PKG="${WORKSPACE_DTVINPUT_PACKAGE}";

watch_pid="";
trap exited SIGINT
function exited() {
  echo "stopped monitoring"
  if [ ${watch_pid} -gt 0 ]; then
    echo "kill watch process (${watch_pid})"
    kill ${watch_pid}
fi
  exit 1
}

function queryUriForChannelNum() {
    local result;
    local chNum="901"
    if [ ! -z $1 ]; then
        chNum=$(echo $@ | sed "s/ /,/g");
    fi
    
    local where="display_number in (${chNum}) and package_name='${PKG}'"
    while IFS= read -r line ; do 
        local uri=$(echo ${line} | grep -o 'uri":"dvb:\\/\\/[a-zA-Z0-9.+-]*' | toybox rev | cut -d\/ -f1 | toybox rev)
        # echo "uri=${uri}"
        result="${result} ${uri}"
    done <<< $(content query ${URI_CHANNEL} --projection internal_provider_data --where "${where}")
    echo ${result}
}

function tuneByChannelUri() {
    # 785 : ac.d.2f19
    # 833 : ac.d.34ec
    # 888 : ac.d.361d
    watch_pid="";
    local media_ts;
    for uri in "$@"; do
        media_ts="/mnt/dtvfs/live/dvb:$uri/media.ts"
        if [ -f ${media_ts} ]; then
            tail -f ${media_ts} > /dev/null & 
            watch_pid="${watch_pid} $$"
        fi
    done

    echo "If want to close tuned media, then press enter key"
    read
    kill -9 $(pidof tail)
}

function tuneByChannelNum() {
    local uris="$(queryUriForChannelNum $@)"
    if [ ! -z "${uris}" ]; then
        tuneByChannelUri ${uris}
    else 
        echo "uri not found"
    fi
}

tuneByChannelNum $@;

# tuneByChannelUri ac.d.34ec ac.d.361d

# queryUriForChannelNum $@
