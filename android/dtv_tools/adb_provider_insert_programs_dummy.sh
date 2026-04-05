#!/usr/bin/env bash

source common_dtv.sh

function deleteCurrentProgramsByChannelId() {
    if [  -z $1 ]; then
        log -w "deleteCurrentProgramsByChannelId, must need channel's id"
        exit 1;
    fi
    # local currTime=$(adb shell date +%s)
    local currTime=$((${CURR_TIME} * 1000))
    local where="channel_id in ($(echo $@ | sed "s/ /,/g")) and end_time_utc_millis >= ${currTime}"
    log -i "delete current programs _id in ${1}"
    do_execute "adb shell content delete ${URI_PROGRAM} --where '${where}'"
}


# function selecIntoPrograms() {
    # deleteUpdatedPrograms;

    # local currTime=$(adb shell date +%s)
    # currTime=$((currTime * 1000))
    # echo "adb shell content query ${URI_PROGRAM} --projection start_time_utc_millis \
    #                 --where \"package_name='${PKG}' and end_time_utc_millis <= ${currTime}\" --sort \"start_time_utc_millis limit 1"
    # local minTime=$(adb shell "content query ${URI_PROGRAM} --projection start_time_utc_millis \
    #                 --where \"package_name='${PKG}' and end_time_utc_millis <= ${currTime}\" --sort \"start_time_utc_millis limit 1\" | cut -d= -f2")
    # log -d "minTime=${minTime}"
    # local diffTime=$((currTime - minTime))
    # log -d "diffTime=${diffTime}"
    # do_execute -i "adb shell sqlite3 /data/data/com.android.providers.tv/databases/tv.db \
    #                 \"insert into programs (${DEFAULT_FIELDS}, \
    #                         ${CUSTOM_FIELDS}) \
    #                     select \
    #                         ${DEFAULT_FIELDS}, \
    #                         \\\"dummy_\\\" || title as title , ${versionNumber} as version_number, \
    #                         start_time_utc_millis +${diffTime} as start_time_utc_millis, end_time_utc_millis +${diffTime} as end_time_utc_millis \
    #                     from programs\""

    # return 0
# }


function getChannelId() {
    #local where="package_name='${PKG}' and browsable=1"
    local where="package_name='${PKG}'"
    if [ ! -z $1 ]; then
        where="${where} and display_number in ($(echo $@ | sed "s/ /,/g")));"
    fi
    # log -d "query : adb shell \"content query ${URI_CHANNEL} --projection _id --where \\\"${where}\\\"\""
    local resultSet=$(adb shell "content query ${URI_CHANNEL} --projection _id --where \"${where}\"")
    local result=""
    oIFS="$IFS"
    IFS=$'\n'
    for row in ${resultSet}; do
        result="${result} $(echo ${row} | cut -d= -f2)"
    done
    
    IFS="$oIFS"  
    # log "$result"
    echo ${result}
}

function getLastEndTime() {
    if [  -z $1 ]; then
        log -w "getLastEndTime, must need channel's id"
        exit 1;
    fi
    local where="channel_id='$1'"
    local order="end_time_utc_millis desc limit 1"
    # adb shell content delete ${URI_PROGRAM} --where \"channel_id=$1 and end_time_utc_millis >= ${currTime}\
    local endTime=$(adb shell "content query ${URI_PROGRAM} --projection end_time_utc_millis --where \"${where}\" --sort \"${order}\"")
    echo ${endTime} | cut -d= -f2
}

function getRandom() {
    local result;
    local array;
    local rand=0;

    # BROADCAST_GENRE_ARRAY
    # CANONICAL_GENRE_ARRAY
    # RATING_ARRAY
    # SHORT_DESCRIPTION_ARRAY
    # LONG_DESCRIPTION_ARRAY

    # getopts dtbcrsl opt $@;
    opt=$1

    case ${opt} in
        -d)
            rand=$[$RANDOM % ${#DURATION_ARRAY[@]}]
            result=${DURATION_ARRAY[$rand]}
        ;;
        -t)
            rand=$[$RANDOM % ${#TITLE_ARRAY[@]}]
            result=${TITLE_ARRAY[$rand]}  
        ;;
        -b)
            rand=$[$RANDOM % ${#BROADCAST_GENRE_ARRAY[@]}]
            result=${BROADCAST_GENRE_ARRAY[$rand]}
        ;;
        -c)
            rand=$[$RANDOM % ${#CANONICAL_GENRE_ARRAY[@]}]
            result=${CANONICAL_GENRE_ARRAY[$rand]}
        ;;
        -r)
            rand=$[$RANDOM % ${#RATING_ARRAY[@]}]
            result=${RATING_ARRAY[$rand]}
        ;;
        -s)
            rand=$[$RANDOM % ${#SHORT_DESCRIPTION_ARRAY[@]}]
            result=${SHORT_DESCRIPTION_ARRAY[$rand]}
        ;;
        -l)
            rand=$[$RANDOM % ${#LONG_DESCRIPTION_ARRAY[@]}]
            result=${LONG_DESCRIPTION_ARRAY[$rand]}
        ;;
        *)
            result="not support"
        ;;
    esac
    # rand=$[$RANDOM % ${#array[@]}]
    # echo ${arr[$rand]}
    echo ${result}
    
}

function insertDummyProgram() {
    local channel_id=${1}
    local start_time=${2};
    local end_time=${3};
    local channel_num=${4}
    local programIndex=${5}
    # local title=$(getRandom -t)
    local title="dummy_${channel_num}_${programIndex}"
    log -i "=> ${channel_num}(${channel_id}): ${title}  $(date +"%D %T" -d @${start_time}) ~ $(date +"%D %T" -d @${end_time})"
    channel_id="--bind channel_id:s:${channel_id}"
    start_time="--bind start_time_utc_millis:l:$((${start_time} * 1000))"
    end_time="--bind end_time_utc_millis:l:$((${end_time} * 1000))"

    local package_name="--bind package_name:s:\"${PKG}\""
    local title="--bind title:s:\"${title}\""
    local broadcast_genre="--bind broadcast_genre:s:\"$(getRandom -b)\""
    local canonical_genre="--bind canonical_genre:s:\"$(getRandom -c)\""
    local rating="--bind content_rating:s:\"$(getRandom -r)\""
    local short_desc="--bind short_description:s:\"$(getRandom -s)\""
    local long_desc="--bind long_description:s:\"$(getRandom -l)\""
    local recording_prohibited="--bind recording_prohibited:i:1"
    do_execute -q "adb shell content insert ${URI_PROGRAM} ${channel_id} ${start_time} ${end_time} ${package_name} ${title} ${broadcast_genre} ${canonical_genre} ${rating} ${long_desc} ${short_desc}"
}

function makeDummuyPrograms() {
    # getChannelId $@
    local channelNums=( "$@" )
    local channelIds=($(getChannelId $@))
    deleteCurrentProgramsByChannelId ${channelIds[@]}
    local channelIndex=0
       
    local beginProgramTime=$((${CURR_TIME} - 600));

    # 86400 = 1 day
    # 3600 = 1h, 7200 = 2h, 14400 = 4h
    # local finishProgramTime=$((${CURR_TIME} + 14400));
    
    local totalProgramCount=0;
    
    for _id in ${channelIds[@]}; do
        
        # log -d "channel_id=${_id}"
        log -d "current time     =$(date +"%D %T" -d @${CURR_TIME})"
        log -d "beginProgramTime =$(date +"%D %T" -d @${beginProgramTime})"
        log -d "finishProgramTime=$(date +"%D %T" -d @${finishProgramTime})"
        log -d "beginProgramTime =${beginProgramTime}"
        log -d "finishProgramTime=${finishProgramTime}"
        # lastEndTime=$(getLastEndTime $_id)
        # log -d "lastEndTime=$(date +"%D %T" -d @$((${lastEndTime} / 1000)))"
        local startTime=${beginProgramTime};
        # adjust offset
        local endTime=$((60 - (${CURR_TIME} % 60) + ${CURR_TIME} ));
        channelNum=${channelNums[${channelIndex}]}
        local programCount=0
        insertDummyProgram $_id $startTime $endTime ${channelNum} ${programCount}
        
        startTime=${endTime}
    
        channelIndex=$((channelIndex + 1))
        while [ ${startTime} -lt ${finishProgramTime} ]; do
            programCount=$((programCount + 1))
            # duration=$(getRandom -d);
            if ${randomDuration}; then
                duration=$(getRandom -d);
            fi
            endTime=$((${startTime} + ${duration}))

            insertDummyProgram $_id $startTime $endTime ${channelNum} ${programCount}
            startTime=${endTime};
            
        done
        totalProgramCount=$((${totalProgramCount} + ${programCount}))
        log -i "index ${channelIndex}, inserted count = ${programCount}"
        # while
    done
    log -i "total count=${totalProgramCount}"

}

# adb_provider_update_channel_browsable.sh

# selecIntoPrograms $@;

makeDummuyPrograms $@
