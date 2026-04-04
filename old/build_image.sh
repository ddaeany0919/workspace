#!/usr/bin/env bash
source common_bash.sh
source .bashrc_functions

DEBUG=true

ONLY_ANDROID=false;
USB_PATH="";
OTA_FILE_NAME="";
IMAGE_NAME_PREFIX="$(echo ${WORKSPACE_PROJECT} | tr '[:upper:]' '[:lower:]')-ota";

trap cleanup EXIT
function cleanup() {
    exit 0
}

function usage() {
    log -i "usage:"
    log  "You must only use the option"
    log  "-o [--only_android]   build only for android (default : build with SoC)"
    log  "--usb                 USB mount path (ex: E)"
}

optspec="o-:"
while getopts "${optspec}}" option; do
    case ${option} in
        -)
            case "${OPTARG}" in
                only_android)
                    ONLY_ANDROID=true;
                    ;;
                usb)
                    USB_PATH=$2
                    # USB_PATH=$(echo ${OPTARG} | cut -d\"=\" -f 2);
                    shift 2;
                    ;;
                *)
                    usage;
                    exit 0;
            esac
        ;;
        o)
            ONLY_ANDROID=true
        ;;
        *)
            usage;
            exit 0;
    esac
done

shift $((OPTIND -1))

DEST=$1
log -i "${WORKSPACE_PROJECT} build start! (ONLY_ANDROID=${ONLY_ANDROID})"

ssh svr -C "rm -f ~/${ANDROID_OUTPUT}}/${IMAGE_NAME_PREFIX}*.zip"
if $ONLY_ANDROID; then
    ssh svr -C "cd ${BUILD_HOME} && source env.sh && make installclean && make -j10 && make otapackage"
else
    ssh svr -C "cd ${BUILD_HOME} && ./androidtv_build.bash"
fi

TARGET_FILE=$(ls -t ${ANDROID_OUTPUT}/${IMAGE_NAME_PREFIX}*.zip | head -1);
if [ ! -z ${USB_PATH} ]; then
    log -d "USB_PATH=${USB_PATH}"
    # DEST=$1;
    # if [ ! $(readlink -e ${DEST}) ]; then
    #     log -d "window path"
    # else 
    #     log -d "linux path"    
    # fi
    DEST=${USB_PATH}
    
    cmd_copy "${TARGET_FILE}" ${USB_PATH}
elif [ -d ${DEST} ]; then 
    log -i "copy ota image (${TARGET_FILE})"
    cp -n ${TARGET_FILE} ${DEST}
fi;

