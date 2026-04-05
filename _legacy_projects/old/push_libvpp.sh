#!/usr/bin/env bash

source common_bash.sh;
source common_android.sh

DEST="/vendor/firmware/ta/libvpp.ta"

function usage {
    log -d "$0 libvpp_version.ta"
    exit 1;
}

if [ -z $1 ]; then
    log -e "Must need target file"
    usage;
elif [ ! -f $1 ]; then
    log -e "$1 is not exist!"
    exit 1
else
    do_execute -i "adb push $1 $DEST" && 
    do_execute -i "adb shell sync" && 
    do_execute -i "md5sum $1 && adb shell md5sum $DEST" &&
    do_execute -i "adb reboot"
fi
