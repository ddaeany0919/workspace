#!/usr/bin/env bash

source common_menu.sh;
DEBUG_COMMON_BASH=false;
DEBUG=false;

URI_PROGRAM="--uri content://android.media.tv/program"
URI_CHANNEL="--uri content://android.media.tv/channel"
TV_DB="/data/data/com.android.providers.tv/databases/tv.db"
QUERY_COMMAND="adb shell sqlite3 ${TV_DB}\""

CURR_TIME=$(adb shell date +%s)
UPDATED_VERSION="version_number=${versionNumber}"



while getopts "cd:e:" option; do
    case "${option}" in
    c)
        needPrevProgramsClear=true
        ;;
    d)
        randomDuration=false;
        duration="${OPTARG}"
        ;;
    e)
        finishProgramTime=$((${CURR_TIME} + $((${OPTARG} * 60))));
        ;;
    esac
done
shift $(($OPTIND - 1))

function deleteRecordedPrograms() {

    do_execute -q "adb shell content delete --uri content://android.media.tv/recorded_program/$1"
}

deleteRecordedPrograms $@
