#!/usr/bin/env bash

#### STEP 1 : Declare variables ########################################################################################
source common_bash.sh

DEBUG=false
build_tools_version="28.0.0"
tool_path="$ANDROID_HOME/build-tools/$build_tools_version"
zipalign="$tool_path/zipalign"
apksigner="$tool_path/apksigner"

#### STEP 2 : check whether command exist ##############################################################################
debug $zipalign
if ! [ -x "$(command -v $zipalign)" ]; then
    log -e 'Error: $zipalign is not installed.' >&2
    exit 1
fi

if ! [ -x "$(command -v $apksigner)" ]; then
    log -e 'Error: $apksigner is not installed.' >&2
    exit 1
fi

#### STEP 3 : check whether arguments exist ############################################################################
function help() {
}
    log -i "$(basename $0) jks_file target.apk"

if [ $# -lt 2 ]; then
    log -e "Check arguments"
    help
    exit 1
fi

jks=$1

file=$2
fileName=${file%%.*}
fileExt=${file#*.}

debug "file = " $file
debug "file name = " $fileName
debug "file ext = " $fileExt
case $(file --mime-type -b "$file") in
application/zip)
    if [ ! $fileExt == "apk" ]; then
        log -e "Only handle apk file"
        help
        exit 1
    fi

    ;;
*) log -e "check file type!!, need file type is 'application/zip'" ;;
esac

########################################################################################################################

do_execute -i $zipalign -v -p 4 $file $fileName-align.apk
do_execute -i $apksigner sign --ks $jks --out $fileName-release.apk $fileName-align.apk
do_execute -i jarsigner -verify -verbose -certs $fileName-release.apk
do_execute -i rm -f $fileName-align.apk
