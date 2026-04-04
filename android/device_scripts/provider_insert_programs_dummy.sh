#!/bin/sh
ME=$(dirname "$0")
source ${ME}/common_bash.sh;
DEBUG=true;

URI_PROGRAM="--uri content://android.media.tv/program"
URI_CHANNEL="--uri content://android.media.tv/channel"
PKG="${WORKSPACE_DTVINPUT_PACKAGE}";
DEFAULT_FIELDS="package_name, channel_id, season_display_number, season_title, episode_display_number, episode_title, \
                broadcast_genre, canonical_genre, short_description, long_description, video_width, video_height, audio_language, \
                content_rating, poster_art_uri, thumbnail_uri, searchable, recording_prohibited, internal_provider_data, \
                internal_provider_flag1, internal_provider_flag2, internal_provider_flag3, internal_provider_flag4, review_rating_style, review_rating"
CUSTOM_FIELDS="title, version_number, start_time_utc_millis, end_time_utc_millis"

LIMIT_RECORDS=10000;
versionNumber=999999;
CURR_TIME=$(date +%s)
UPDATED_VERSION="version_number=${versionNumber}"

FINISH_END_DAY=2
TITLE_ARRAY=("Dummy_Program" "Vativa" "Recording_test" "Aritel_program" "Yellow" "Hello" "Soccer" "Baseball")
BROADCAST_GENRE_ARRAY=( "Children's/Youth"
                "Education/Science/Factual"
                "Leisure"
                "Movie/Drama-movie/drama"
                "Music/Ballet/Dance-music/ballet/dance"
                "News/Current"
                "Show/Game"
                "Sports-sports")
CANONICAL_GENRE_ARRAY=( "MOVIES" "FAMILY_KIDS" "EDUCATION" "LIFE_STYLE" "DRAMA" "MUSIC" "NEWS" "GAMING" "SPORTS")
RATING_ARRAY=("com.android.tv/IN_TV/TV_A" "com.android.tv/IN_TV/TV_U" "com.android.tv/IN_TV/TV_UA")
SHORT_DESCRIPTION_ARRAY=( "Short_description"
                            # "Learn about the concept of Mirror image and dotted line."
                            # "Public onion currunt issues."
                            # "Starring: Frankie Muniz, Hilary Duff, Angie Harmon, Keith David. A nerdy teen is drafted by the government to be a special agent to get close to a cute classmate to learn about an evil plan hatched by her father."
                            # "Talk Fr.Ajomon"
                            # "This program features a priests as he delivers speeches on various topics."
                            # "Viviliya Parvaiyil Mariya-Arul Nirai Mariye."
                            # "WAKE-UP TO THE BEST PUNJABI MUSIC."
                            # "Khabran Punjab Toh/Top News"
                        )
LONG_DESCRIPTION_ARRAY=( 
                            "Long_description"
                            # "Best of India Short Film Festival (BOISFF) was established by ShortsTV to honor & recognize the exceptional work of Indian filmmakers from across the globe. This year BOISFF will be exclusively broadcasted on Shor"    
                            # "Inspired by the real events that took place in the Pilibhit Tiger Reserve where people used to leave their elderly family members for tigers to prey on, and then claim compensation from the administration."
                            # "As Kristoff, Sven & Bulda relax around the campfire, one of Bulda's crystals begins to flicker & fade! Can Kristoff and his friends harness the power of the Northern Lights & recharge Bulda's crystal?"
                            # "Divakar is a poet who adores his wife, Jamuna, and soon begins to see her as his muse in his imagination and even names her Mohini. But his obsession with Mohini begins to destroy his home and career."
                            # "Elma & Ramish like each other. When his parents reject Elma, her father gets her married to Zarbab. She soon finds out about Zarbab's extra-marital relationship. Will she be able to handle his deceit?"
                            # "Agent Agni, a highly trained & deadly field agent is entrusted with the mission to gather Intel & eliminate Rudraveer, an international human & arms trafficker who has been off the radar for 10 years."
                            # "Marinette has a secret other teenagers don't have; she lives a double life as a crime-fighting superhero ladybug. she uses her superpowers to help protect her native paris from supervillain hawk moth."
                            # "While George's first love turns out to be a disappointment, Malar, a college lecturer, rekindles his love interest. His romantic journey takes him through several stages, helping him find his purpose."
                        )
DURATION_ARRAY=(600 900 1200 1800 2400 3600)


function deleteUpdatedPrograms() {
    # local currTime=$(date +%s)
    local currTime=$((${CURR_TIME} * 1000))
    log -i "delete all programs these were updated by manually (${UPDATED_VERSION})"
    do_execute "content delete ${URI_PROGRAM} --where \"${UPDATED_VERSION} and \
                    package_name='${PKG}' and end_time_utc_millis >= ${currTime}\""
}

function deleteCurrentProgramsByChannelId() {
    if [  -z $1 ]; then
        log -w "deleteCurrentProgramsByChannelId, must need channel's id"
        exit 1;
    fi
    # local currTime=$(date +%s)
    local currTime=$((${CURR_TIME} * 1000))
    local where="channel_id in ($(echo $@ | sed "s/ /,/g")) and end_time_utc_millis >= ${currTime}"
    # log -i "delete current programs _id in ${1}"
    do_execute "content delete ${URI_PROGRAM} --where \"${where}\""
}


function selecIntoPrograms() {
    deleteUpdatedPrograms;

    local currTime=$(date +%s)
    currTime=$((currTime * 1000))
    echo "content query ${URI_PROGRAM} --projection start_time_utc_millis \
                    --where \"package_name='${PKG}' and end_time_utc_millis <= ${currTime}\" --sort \"start_time_utc_millis limit 1"
    local minTime=$("content query ${URI_PROGRAM} --projection start_time_utc_millis \
                    --where \"package_name='${PKG}' and end_time_utc_millis <= ${currTime}\" --sort \"start_time_utc_millis limit 1\" | cut -d= -f2")
    log -d "minTime=${minTime}"
    local diffTime=$((currTime - minTime))
    log -d "diffTime=${diffTime}"
    do_execute -i "sqlite3 /data/data/com.android.providers.tv/databases/tv.db \
                    \"insert into programs (${DEFAULT_FIELDS}, \
                            ${CUSTOM_FIELDS}) \
                        select \
                            ${DEFAULT_FIELDS}, \
                            \\\"dummy_\\\" || title as title , ${versionNumber} as version_number, \
                            start_time_utc_millis +${diffTime} as start_time_utc_millis, end_time_utc_millis +${diffTime} as end_time_utc_millis \
                        from programs\""

    return 0
}
function getChannelId() {
    local where="package_name='${PKG}' and browsable=1"
    if [ $# -gt 0 ]; then
        where="${where} and display_number in ($(echo "${@}" | sed "s/ /,/g")));"
    fi
    local result;

    while IFS= read -r line ; do 
        result="${result} $(echo ${line} | cut -d= -f2)"
    done <<< $(content query ${URI_CHANNEL} --projection _id --where "${where}")
    echo ${result}
}

function getLastEndTime() {
    if [  -z $1 ]; then
        log -w "getLastEndTime, must need channel's id"
        exit 1;
    fi
    local where="channel_id='$1'"
    local order="end_time_utc_millis desc limit 1"
    # content delete ${URI_PROGRAM} --where \"channel_id=$1 and end_time_utc_millis >= ${currTime}\
    local endTime=$("content query ${URI_PROGRAM} --projection end_time_utc_millis --where \"${where}\" --sort \"${order}\"")
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
    # getopts "dtbcrsl" option
    # log -d "getRandom: option=${option}"
    case $1 in
        "-d")
            rand=$(($RANDOM % ${#DURATION_ARRAY[@]}))
            result=${DURATION_ARRAY[$rand]}
        ;;
        "-t")
            rand=$(($RANDOM % ${#TITLE_ARRAY[@]}))
            result=${TITLE_ARRAY[$rand]}  
        ;;
        "-b")
            rand=$(($RANDOM % ${#BROADCAST_GENRE_ARRAY[@]}))
            result=${BROADCAST_GENRE_ARRAY[$rand]}
        ;;
        "-c")
            rand=$(($RANDOM % ${#CANONICAL_GENRE_ARRAY[@]}))
            result=${CANONICAL_GENRE_ARRAY[$rand]}
        ;;
        "-r")
            rand=$(($RANDOM % ${#RATING_ARRAY[@]}))
            result=${RATING_ARRAY[$rand]}
        ;;
        "-s")
            rand=$(($RANDOM % ${#SHORT_DESCRIPTION_ARRAY[@]}))
            result=${SHORT_DESCRIPTION_ARRAY[$rand]}
        ;;
        "-l")
            rand=$(($RANDOM % ${#LONG_DESCRIPTION_ARRAY[@]}))
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
    log -i "=> ${channel_num}(${channel_id}), $(date +"%D %T" -d @${start_time}) ~ $(date +"%D %T" -d @${end_time})"
    channel_id="--bind channel_id:s:${channel_id}"
    start_time="--bind start_time_utc_millis:l:$((${start_time} * 1000))"
    end_time="--bind end_time_utc_millis:l:$((${end_time} * 1000))"

    local package_name="--bind package_name:s:${PKG}"
    local title="--bind title:s:\"$(getRandom -t)\""
    local broadcast_genre="--bind broadcast_genre:s:\"$(getRandom -b)\""
    local canonical_genre="--bind canonical_genre:s:\"$(getRandom -c)\""
    local rating="--bind content_rating:s:\"$(getRandom -r)\""
    local short_desc="--bind short_description:s:\"$(getRandom -s)\""
    local long_desc="--bind long_description:s:\"$(getRandom -l)\""
    local recording_prohibited="--bind recording_prohibited:i:1"
    # command="content insert ${URI_PROGRAM} ${channel_id} ${start_time} ${end_time} ${package_name} ${title} ${broadcast_genre} ${canonical_genre} ${rating} ${long_desc} ${short_desc} ${recording_prohibited}"
    # echo "${title} ${broadcast_genre} ${canonical_genre} ${rating} ${long_desc} ${short_desc}"
    content insert ${URI_PROGRAM} ${channel_id} ${start_time} ${end_time} ${package_name} ${title} ${broadcast_genre} ${canonical_genre} ${rating} ${long_desc} ${short_desc} ${recording_prohibited}
    # exec $command
}

function makeDummuyPrograms() {
    # getChannelId $@
    local channelNums="$(echo ${@})"
    local channelNum;
    local channelIds="$(getChannelId ${channelNums})"
    deleteCurrentProgramsByChannelId ${channelIds[@]}
    local channelIndex=0

       
    local beginProgramTime=$((${CURR_TIME} - 300));
    # 86400 = 1 day
    local finishProgramTime=$((${CURR_TIME} + (86400 * 1)));
    local totalProgramCount=0;
    for _id in ${channelIds[@]}; do
        
        # log -d "channel_id=${_id}"
        # log -d "beginProgramTime=$(date +"%D %T" -d @${beginProgramTime})"
        # log -d "finishProgramTime=$(date +"%D %T" -d @${finishProgramTime})"
        # lastEndTime=$(getLastEndTime $_id)
        # log -d "lastEndTime=$(date +"%D %T" -d @$((${lastEndTime} / 1000)))"
        local startTime=${beginProgramTime};
        # adjust offset
        local endTime=$((300 - (${CURR_TIME} % 300) + ${CURR_TIME} ));
        channelNum=${channelNums[${channelIndex}]}
        insertDummyProgram $_id $startTime $endTime ${channelNum}
        local programCount=1
        startTime=${endTime}
    
        channelIndex=$((channelIndex + 1))
        while [ ${startTime} -lt ${finishProgramTime} ]; do
            # duration=$(getRandom -d);
            endTime=$(( ${startTime} + $(getRandom -d) ))
            insertDummyProgram $_id $startTime $endTime ${channelNum}
            startTime=${endTime};
            programCount=$((programCount + 1))
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
