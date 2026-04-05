#!/usr/bin/env bash
source common_bash.sh

if [ -z ${ANDROID_BUILD_TOP} ]; then
    log -e "ANDROID_BUILD_TOP is not defined"
    exit 1
fi

CERT="platform"
SIGN_PRE_OPT="-Djava.library.path=${ANDROID_BUILD_TOP}/out/host/linux-x86/lib64 "
SIGN_JAR="-jar ${ANDROID_BUILD_TOP}/out/host/linux-x86/framework/signapk.jar"
KEY_PATH="${ANDROID_BUILD_TOP}/build/make/target/product/security"
# KEY_PATH="${ANDROID_BUILD_TOP}/vendor/broadcom/bcm_platform/signing"
# APK_BUILD_OUT_PATH="${ANDROID_BUILD_TOP}/vendor/technicolor/projects/${WORKSPACE_PRODUCT_NAME}/dtvmodules/build/prebuilts/"
APK="tch_dtvinput_service"

if [ ! -z $1 ]; then
    APK=$1
fi

INPUT_APK="${WORKSPACE_DTVSTACK_OUT}/build/prebuilts/${APK}.apk"
# TODO: need more others apk
OUTPUT_APK="${ANDROID_PRODUCT_OUT}/vendor/app/${APK}/${APK}.apk"

do_execute -i "java ${SIGN_PRE_OPT} ${SIGN_JAR} ${KEY_PATH}/${CERT}.x509.pem ${KEY_PATH}/${CERT}.pk8 ${INPUT_APK} ${OUTPUT_APK}"
