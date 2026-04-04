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

function finishBuild() {
    local _message=$1
    exit 1
}

function prepareMakeCmd() {
    CMD_PREPARE="export WORKSPACE_ENV_TERMINAL_TITLE='build_$1' ; source ~/workspace/bin/.bashrc_luis && cd ${ANDROID_BUILD_TOP}"
}

function makeCleanBuild() {
    if ! ${ONLY_APPLY}; then
        local command="${CMD_PREPARE}"
        local cleanModules="make "
        local buildModules=""
        for module in "$@"; do
            if [ -z "${cleanModules}" ]; then
                cleanModules="make clean-${module}"
            else
                cleanModules="${cleanModules} clean-${module}"
            fi
            if [ -z "${buildModules}" ]; then
                buildModules="make ${module}"
            else
                buildModules="${buildModules} ${module}"
            fi
        done

        if [ ! -z "${cleanModules}" ]; then
            command="${command} && ${cleanModules}"
        fi
        if [ ! -z "${buildModules}" ]; then
            command="${command} && ${buildModules} -j100"
        fi

        if ! eval ${SSH_COMMAND} "\"${command}\""; then
            log -w "build failed!"
            return 1
        else 
            log -i "✅ build success!!"
            for module in "$@"; do
            log -i "📦 $module"
            done
            
        fi
    fi

    return 0
}

# path, binary name, process name
function pushModules() {
    local source_path="$1"
    local dest_path="${source_path%/*}/"
    local executeOpt="-i"
    if $VIRTUAL_MODE; then
        executeOpt="-v"
    fi

    eval "source=${ANDROID_OUTPUT}${source_path}"
    if adb_connect && do_execute $executeOpt "$ADB_PUSH ${source} ${dest_path}"; then
        do_execute $executeOpt "adb shell sync"
        return 0
    else
        finishBuild "deploy failed!!"
        return 1
    fi
}

function makeApkModule(){
    local moduleName=$1
    local outputPath="$2/${moduleName}"
    local processName=$3

    prepareMakeCmd "${moduleName}"
    if makeCleanBuild "${moduleName}"; then 
        if pushModules "${outputPath}"; then
            adb_kill "${processName}"
        fi
    fi
}

function makeGradleModule(){
    local moduleName=$1
    local modulePath=$2
    local outputPath="${BUILD_ROOT}/${modulePath}/app/build/outputs/apk/${WORKSPACE_PRODUCT_NAME}/release"
    local deployPath="$3/${moduleName}"
    local processName=$4

    prepareMakeCmd "${moduleName}"

    local taskTarget="${WORKSPACE_PRODUCT_NAME^}"
    local command="${CMD_PREPARE}/$modulePath && ./gradlew -x lint assemble${taskTarget}Release"

    log "command=${command}"
    

    if ! do_execute -i ${SSH_COMMAND} "\"${command}\""; then
        log -w "build failed!"
        return 1
    else 
        log -i "✅ build success!! ${moduleName}"
    fi

    local apk_file="$(find ${outputPath} -name "*.apk" -type f | head -n 1)"
    if [ -z "${apk_file}" ]; then
        log -e "APK file not found in ${outputPath}"
        return 1
    fi

    log "outputPath=${outputPath}"
    log "deployPath=${deployPath}"

    eval "source=${apk_file}"
    log "source=${source}"
    if adb_connect && do_execute $executeOpt "$ADB_PUSH ${source} ${deployPath}/${moduleName}.apk"; then
        do_execute $executeOpt "adb shell sync"
        adb_kill "${processName}"
        return 0
    else
        finishBuild "deploy failed!!"
        return 1
    fi

    # fi
}

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
