#!/usr/bin/env bash

source common_dtv.sh

function deleteRecordedPrograms() {

    do_execute -q "adb shell content delete --uri content://android.media.tv/recorded_program/$1"
}

deleteRecordedPrograms $@
