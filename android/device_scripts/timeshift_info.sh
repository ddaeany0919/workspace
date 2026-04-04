#!/bin/sh

# source common_menu.sh;
DEBUG_COMMON_BASH=false;
DEBUG=true;

DTVINPUT_PACKAGE="com.technicolor.android.dtvinput"
DTVINPUT_PACKAGE_DIR="/storage/emulated/0/Android/media/${DTVINPUT_PACKAGE}"
if [ ! -d "${DTVINPUT_PACKAGE_DIR}" ]; then
    DTVINPUT_PACKAGE="com.google.android.tv.dtvinput"
    DTVINPUT_PACKAGE_DIR="/storage/emulated/0/Android/media/${DTVINPUT_PACKAGE}"
    if [ ! -d "${DTVINPUT_PACKAGE_DIR}" ]; then
        echo "package dir is not exist"
        exit 1;
    fi
fi

REC_PATH="${DTVINPUT_PACKAGE_DIR}/Timeshift"
TV_DB="/data/data/com.android.providers.tv/databases/tv.db"
DVR_DB="/data/data/com.android.tv/databases/dvr.db"
projections="recorded_programs._id, channels.display_name, channels.display_number"
projections="${projections}, strftime(\"%H:%M:%S\",datetime(start_time_utc_millis/1000, \"unixepoch\", \"localtime\")) as start"
projections="${projections}, strftime(\"%H:%M:%S\",datetime(end_time_utc_millis/1000, \"unixepoch\", \"localtime\")) as end"
projections="${projections}, start_time_utc_millis, end_time_utc_millis"
projections="${projections}, end_time_utc_millis - start_time_utc_millis AS duration, recording_data_uri"
segment="";

optspec="o-:s:"
while getopts "${optspec}}" option; do
    case ${option} in
        -)
            case "${OPTARG}" in
                no-monitoring)
                    MODE_MONITORING=false;
                    ;;
                *)
                    usage;
                    exit 0;
            esac
        ;;
        o)
            MODE_MONITORING=false
            ;;
        s)
            segment=${OPTARG}
            ;;
    esac
done

shift $((OPTIND -1))


function getTimeshiftInfo() {
    # log "getPvrInfo args=$@"
    # local last_rec_info="$(print_pvr_info)"
    
    # local _id="`echo ${last_rec_info} | cut -d\| -f1`"
    # local ch_name="`echo ${last_rec_info} | cut -d\| -f2`"
    # local ch_num="`echo ${last_rec_info} | cut -d\| -f3`"
    # local start_time="`echo ${last_rec_info} | cut -d\| -f4`"
    # local end_time="`echo ${last_rec_info} | cut -d\| -f5`"
    # local duration="`echo ${last_rec_info} | cut -d\| -f8`"
    # local path="`echo ${last_rec_info} | cut -d\| -f9`"

    # segment=`echo "${last_rec_info}" | cut -d\| -f10`
    # local state=`echo "${last_rec_info}" | cut -d\| -f11`
    # if [  "${segment}" == "" ]; then
    #     echo "segment is not searched"
    #     exit 1;
    # fi
    # local result="=> time: $(date +%T)\t\t\t\t\t\t\t\t\t\t\tdate: $(date +%y-%m-%d)"
    # result="${result}\r\n  ${start_time} ~ ${end_time}, [${duration}]"
    # result="${result}\r\n  _id: ${_id}, channel: ${ch_num}(${ch_name})"
    # result="${result}\r\n  segment: ${segment} (${state})"
    
    # print media
    # files=(`ls -q ${REC_PATH}/${segment}/*.ts*`)
    files=(`ls -q ${REC_PATH}/${segment}/*.ts*`)
    local raw;
    local fileName;
    for file in "${files[@]}";
    do
        raw=`du -h -x ${file} | cut -f1`
        fileName="$(echo ${file} | cut -f2 | cut -d\/ -f10)"
        result="${result} $(printf '\n%15s : %s\n' ${fileName} ${raw})"
    done

    # print info
    if [ -f ${REC_PATH}/${segment}/infos.txt_0 ]; then
        files=(`ls -q ${REC_PATH}/${segment}/infos.*`)
        local raw;
        for file in "${files[@]}";
        do
            raw=`cat ${file}`
            fileName="$(echo ${file} | cut -d\/ -f10)"
            result="${result} $(printf '\n%15s : %s\n' ${fileName} ${raw})"
        done
    fi

    # print meta
    if [ -f ${REC_PATH}/${segment}/meta.dat_0 ]; then
        files=(`ls -q ${REC_PATH}/${segment}/meta.*`)
        local raw;
        for file in "${files[@]}";
        do
            raw=`cat ${file}`
            fileName="$(echo ${file} | cut -d\/ -f10)"
            result="${result} $(printf '\n%15s : %.20s...\n' ${fileName} ${raw})"
        done
    fi

    # print weak.meta
    if [ -f ${REC_PATH}/${segment}/weak.meta.* ]; then
        files=(`ls -q ${REC_PATH}/${segment}/weak.meta.*`)
        local raw;
        for file in "${files[@]}";
        do
            raw=`cat ${file}`
            fileName="$(echo ${file} | cut -d\/ -f10)"
            result="${result} $(printf '\n%15s : %s\n' ${fileName} ${raw})"
        done
    fi
    echo "$result";
}

index=$1;
if [ -z $1 ]; then
    index=0;
fi;  

index=$((index+1));
# print_pvr_info
result=$(getTimeshiftInfo)
echo -e "${result}"
