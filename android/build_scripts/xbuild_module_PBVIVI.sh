#!/usr/bin/env bash

source common_menu.sh
source common_android.sh
DEBUG_COMMON_BASH=false
DEBUG=false
ADB_PUSH="adb push --sync"

WORKSPACE_ENV_PS1=true

SSH_COMMAND="ssh -tqC ${WORKSPACE_BUILD_SERVER}"

ONLY_APPLY=false

ANDROID_BUILD_TOP=${ANDROID_BUILD_TOP:-"1.Sources/apps/LINUX/qssi"}
BUILD_ROOT=${ANDROID_SOONG_HOST_OUT:-"${WORKSPACE_REMOTE_HOME}/${ANDROID_BUILD_TOP}"}

trap exited SIGINT
function exited() {
    log -w "error occurred"
    exit 1
}

#### STEP 1 : Declare variables ########################################################################################
declare -A action01=([name]="freamework_all" [cmd]="framework_all")
declare -A action02=([name]="image" [cmd]="image")
declare -A action03=([name]="mobis-framework"        [cmd]="mobis_ramework")
declare -A action04=([name]="services" [cmd]="services")
declare -A action05=([name]="sepolicy" [cmd]="sepolicy")
declare -A action06=([name]="PBV_CarLauncher" [cmd]="PBV_CarLauncher")
declare -A action07=([name]="PBV_CarUiPortraitSystemUI" [cmd]="PBV_CarUiPortraitSystemUI")
declare -A action08=([name]="GlobalSearchService" [cmd]="GlobalSearchService")
declare -A action08=([name]="CarFramework" [cmd]="CarFramework")
declare -A action10=([name]="ExtCamera" [cmd]="ExtCamera")
declare -A action11=([name]="MiniPlayer" [cmd]="MiniPlayer")
declare -A action12=([name]="Radio" [cmd]="Radio")
# declare -A action04=([name]="DtvInput"           [cmd]="dtvinput")
# declare -A action05=([name]="DtvProvider"        [cmd]="dtvprovider")
# declare -A action06=([name]="DTVFS"              [cmd]="dtvfs")
# declare -A action07=([name]="AtlLiveTv"          [cmd]="atllivetv")
# declare -A action07=([name]="DtvBackupService"   [cmd]="dtvbackupservice")

declare -a menu_items=(${!action@})
#### STEP 2 : Declare variables ########################################################################################

source common_build.sh
#### STEP 3 : Declair build functions ########################################################################################

function framework_all() {
    prepareMakeCmd "frameworks all"
    local modules="framework services mobis.framework.core mobis.framework mobis.framework.services"
    local pushModules="/system/framework/{services*,mobis.framework*,framework*}"

    if makeCleanBuild ${modules}; then
        if pushModules "${pushModules}"; then
            reboot
            return 0
        else
            log -e "push failed!"
        fi
    else
        log -e "build failed!"
    fi
    
    return 1
}

function mobis_ramework() {
    prepareMakeCmd "mobis_framework"
    local modules="mobis.framework.core mobis.framework mobis.framework.services"
    local pushModules="/system/framework/{mobis.framework*}"

    if makeCleanBuild ${modules}; then
        if pushModules "${pushModules}"; then
            reboot
            return 0
        else
            log -e "push failed!"
        fi
    else
        log -e "build failed!"
    fi
    
    return 1
}

function services() {
    # if ! ${ONLY_APPLY}; then
    prepareMakeCmd "services"
    if makeCleanBuild "services"; then
        if pushModules "/system/framework/services*"; then
            reboot
            return 0
        else
            log -e "push failed!"
        fi
    else
        log -e "build failed!"
    fi
    return 1
}

function CarFramework() {
    local modules="car-frameworks-service-module"
    local car_frameworks_service_module="/system/framework/car-frameworks-service-module*"
    local car_frameworks_apex="/system/apex/com.android.car.framework"

    # log -i "car_frameworks_service_module=${car_frameworks_service_module}"
    # log -i "car_frameworks_apex=${car_frameworks_apex}"
    prepareMakeCmd "CarFramework"
    if makeCleanBuild ${modules}; then
        if pushModules ${car_frameworks_service_module} && pushModules ${car_frameworks_apex}; then
            reboot
            return 0
        else
            log -e "push failed!"
        fi
    else
        log -e "build failed!"
    fi
    return 1
}

function sepolicy() {
    prepareMakeCmd "precompiled_sepolicy"
    makeCleanBuild "precompiled_sepolicy"
    # do_execute "adb push $ANDROID_OUTPUT/odm/etc/selinux/precompiled_sepolicy /data/precompilie_sepolicy"
    # do_execute "adb shell load_policy /data/precompilie_sepolicy"
}

function PBV_CarLauncher() {
    makeApkModule "PBV_CarLauncher" "/system/priv-app" "com.android.car.carlauncher"
}

function GlobalSearchService() {
    makeApkModule "GlobalSearchService" "/system/priv-app" "com.mobis.service.globalsearchservice"
}

function PBV_CarUiPortraitSystemUI() {
    makeApkModule "PBV_CarUiPortraitSystemUI" "/system_ext/priv-app" "com.android.systemui"
}

function ExtCamera() {
    makeGradleModule "PBVIVI_ExtCamera" "vendor/mobis/packages/apps/ExtCamera" "/system_ext/app" "com.mobis.app.extcamera"
}

function MiniPlayer() {
    makeGradleModule "MiniPlayer" "vendor/mobis/packages/apps/MiniPlayer" "/system_ext/app" "com.mobis.miniplayer.app"
}

function Radio() {
    makeGradleModule "PBVIVI_RadioApp" "vendor/mobis/packages/apps/radio" "/system_ext/app" "com.mobis.app.radio"
}

function showMenu() {
    select_items=($(show_actions_menu ${!action@}))

    log -d "select_items=$select_items"
    log -d "count=${#select_items[@]}"

    if [ ${#select_items[@]} -eq 0 ]; then
        return 1
    else
        for index in ${select_items[@]}; do
            if [ $(isNumber $index) == 1 ]; then
                if [ $index -gt ${#menu_items[@]} ]; then
                    continue
                fi
                index=$(($index - 1))
                declare -n item=${menu_items[$index]}
                #log -i ${item[name]}
                eval "${item[cmd]}"
            fi
        done
        return 0
    fi
}

buildModuleItems=("")
args=("$@")
for arg in "${args[@]}"; do
    case ${arg} in
    -a)
        ONLY_APPLY=true
        ;;
    -d)
        VIRTUAL_MODE=true
        ;;
    -l)
        for key in "${!menu_items[@]}"; do
            declare -n item=${menu_items[$key]}
            echo "${item[cmd]}"
        done
        exit 0
        ;;
    *)
        buildModuleItems+=("${arg}")
        ;;
    esac
done

if [ ${#buildModuleItems[@]} -gt 1 ]; then
    for module in "${buildModuleItems[@]}"; do
        eval ${module}
    done
else
    while true; do
        if ! showMenu; then
            exit 0
        fi

    done
fi
