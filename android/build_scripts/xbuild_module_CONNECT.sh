#!/usr/bin/env bash

source common_menu.sh
source common_android.sh
DEBUG_COMMON_BASH=false
DEBUG=false
ADB_PUSH="adb push --sync"
ADB_INSTALL="adb install -r -d"

WORKSPACE_ENV_PS1=true

SSH_COMMAND="ssh -tqC ${WORKSPACE_BUILD_SERVER}"
COMMAND_PREFIX="tmux_request.sh"
# NINJA_COMMAND_PREFIX="prebuilts/build-tools/linux-x86/bin/ninja -f out/combined-connect_s.ninja"
NINJA_COMMAND_PREFIX="qb"
GRADLE_FLAVOR=$(if [ "${WORKSPACE_PRODUCT_NAME}" = "connect_l" ]; then echo "Clite"; else echo "Cstd"; fi)

ONLY_APPLY=false
NINJA_BUILD=true

ANDROID_BUILD_TOP=${ANDROID_BUILD_TOP:-"lagvm/LINUX/android"}
BUILD_ROOT=${ANDROID_SOONG_HOST_OUT:-"${WORKSPACE_REMOTE_HOME}/${ANDROID_BUILD_TOP}"}

trap exited SIGINT
function exited() {
    log -w "error occurred"
    exit 1
}

#### STEP 1 : Declare variables ########################################################################################
declare -A action01=([name]="freamework_all" [cmd]="framework_all")
declare -A action02=([name]="image" [cmd]="image")
declare -A action03=([name]="common.android.isp-service-nextchip"        [cmd]="common.android.isp-service-nextchip")
declare -A action04=([name]="services" [cmd]="services")
declare -A action05=([name]="sepolicy" [cmd]="sepolicy")
declare -A action06=([name]="mobis.framework" [cmd]="mobis_framework")
declare -A action07=([name]="HmgCarService" [cmd]="HmgCarService")
declare -A action08=([name]="hmg.car" [cmd]="hmg.car")

declare -A action09=([name]="android.hardware.automotive.vehicle" [cmd]="android.hardware.automotive.vehicle")
# declare -A action08=([name]="GlobalSearchService" [cmd]="GlobalSearchService")
# declare -A action08=([name]="CarFramework" [cmd]="CarFramework")
declare -A action10=([name]="ExtCamera" [cmd]="ExtCamera")
declare -A action11=([name]="HmgEvsCameraPreviewApp" [cmd]="HmgEvsCameraPreviewApp")
declare -A action12=([name]="HmgEvsCameraPreviewApp2" [cmd]="HmgEvsCameraPreviewApp2")
declare -A action13=([name]="MobisEvsCameraPreviewApp" [cmd]="MobisEvsCameraPreviewApp")
declare -A action14=([name]="MobisEvsRvmCameraPreviewApp" [cmd]="MobisEvsRvmCameraPreviewApp")
declare -A action15=([name]="mobis_evs_qcx_aidl_app" [cmd]="mobis_evs_qcx_aidl_app")
declare -A action16=([name]="android.hardware.automotive.evs-qcx" [cmd]="android.hardware.automotive.evs-qcx")

declare -A action21=([name]="vendor.mobis.fingerprint-hal-service" [cmd]="vendor.mobis.fingerprint-hal-service")
declare -A action22=([name]="vendor.mobis.hardware.interfaces.automotive.micomcommunication@V1-default-service" [cmd]="vendor.mobis.hardware.interfaces.automotive.micomcommunication@V1-default-service")
declare -A action23=([name]="mobis-api-stubs-update-current-api" [cmd]="mobis-api-stubs-update-current-api")

declare -A action30=([name]="libqcxclient" [cmd]="libqcxclient")
declare -A action31=([name]="vendor.mobis.audiohal-service-connect" [cmd]="vendor.mobis.audiohal-service-connect")

declare -A action90=([name]="build_la" [cmd]="build_la")

# declare -A action12=([name]="Radio" [cmd]="Radio")
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

    if pushModules "${pushModules}"; then
        if makeCleanBuild ${modules}; then
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
function mobis_evs_qcx_aidl_app() {
    local modules="mobis_evs_qcx_aidl_app libmobisevscamerajni libevsservicejni native_evs_app_aidl_interface librvm2"
    prepareMakeCmd "${modules}"
    local outputs=(
        "/system/etc/init/mobis_evs_qcx_aidl_app.rc"
        "/system/bin/mobis_evs_qcx_aidl_app"
        "/system/lib64/libmobisevscamerajni.so"
        "/system/lib64/libevsservicejni.so"
        "/system/lib64/librvm2.so"
    )

    if makeCleanBuild ${modules}; then
      if pushModules "${outputs[@]}"; then
            adb_kill "mobis_evs_qcx_aidl_app"
            return 0
        else
            log -e "push failed!"
        fi
    else
        log -e "build failed!"
    fi
    
    
    return 1
}

function mobis_framework() {
    prepareMakeCmd "mobis_framework"
    local modules="mobis.framework.services mobis.framework mobis.framework.core mobis.framework-res"
    local pushModules="/system/framework/mobis.framework*"

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

function hmg.car() {
    prepareMakeCmd "hmg.car"
    local modules="hmg.car.plugin.camera hmg.car"
    local pushModules="/system/framework/hmg.car.jar"

    if makeCleanBuild ${modules}; then
        if pushModules "${pushModules}"; then
            
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

function vendor.mobis.audiohal-service-connect() {
    local modules="vendor.mobis.audiohal-service-connect"
    prepareMakeCmd "${modules}"
    local outputs=(
        "/vendor/bin/hw/vendor.mobis.audiohal-service-connect"
        "/vendor/etc/init/audiohal.rc"
        "/vendor/etc/vintf/manifest/audiohal.xml"
        # "/vendor/lib64/libDspInterface.so"
        # "/vendor/lib64/vendor.mobis.audiohal-V1-ndk.so"
        # "/vendor/lib64/vendor.mobis.hardware.interfaces.automotive.micomcommunication-V1-ndk.so"
    )
    if makeCleanBuild ${modules}; then 
        if pushModules "${outputs[@]}"; then
            adb_kill "${modules}"
            return 0
        else
            log -e "push failed!"
        fi
    else
        log -e "build failed!"
    fi
    
    return 1
}

function android.hardware.automotive.evs-qcx() {
     local modules="android.hardware.automotive.evs-qcx"
    prepareMakeCmd "${modules}"
    local outputs=(
        "/vendor/bin/android.hardware.automotive.evs-qcx"
    )
    if makeCleanBuild ${modules}; then 
        if pushModules "${outputs[@]}"; then
            adb_kill "${modules}"
            return 0
        else
            log -e "push failed!"
        fi
    else
        log -e "build failed!"
    fi
    
    return 1
}


function android.hardware.automotive.vehicle() {
    local modules="android.hardware.automotive.vehicle@V1-connect-service"
    prepareMakeCmd "${modules}"
    local outputs=(
        "/vendor/bin/hw/android.hardware.automotive.vehicle@V1-connect-service"
        "/vendor/etc/init/vhal-connect-service.rc"
        "/vendor/etc/vintf/manifest/vhal-connect-service.xml"
    )
    if makeCleanBuild ${modules}; then 
        if pushModules "${outputs[@]}"; then
            adb_kill "${modules}"
            return 0
        else
            log -e "push failed!"
        fi
    else
        log -e "build failed!"
    fi
    
    return 1
    
}

function HmgCarService() {
    prepareMakeCmd "HmgCarService"
    local modules="HmgCarService"
    local pushModules="/system_ext/priv-app/HmgCarService"

    if makeCleanBuild ${modules}; then
        if pushModules "${pushModules}"; then
            adb_kill "com.hmg.car"
            adb_kill "hmg.hardware.interfaces.hmgvariantd@V1-default-service"
            return 0
        else
            log -e "push failed!"
        fi
    else
        log -e "build failed!"
    fi
    
    return 1
}


function common.android.isp-service-nextchip() {
    prepareMakeCmd "common.android.isp-service-nextchip"
    local modules="common.android.isp-service-nextchip"
    local pushModules="/vendor/bin/hw/${modules}"

    if makeCleanBuild ${modules}; then
        if pushModules "${pushModules}"; then
            # libqcxclient
            adb_kill "${modules}"
            return 0
        else
            log -e "push failed!"
        fi
    else
        log -e "build failed!"
    fi
    
    return 1
}

function libqcxclient() {
    prepareMakeCmd "libqcxclient"
    local modules="libqcxclient libqcxosal"
    # local pushModules="/vendor/lib64/libqcxclient.so"

    if makeCleanBuild ${modules}; then
        if pushModules "/vendor/lib64/libqcxclient.so" && pushModules "/vendor/lib64/libqcxosal.so"; then
            return 0
        else
            log -e "push failed!"
        fi
    else
        log -e "build failed!"
    fi
    
    return 1
}

function libqcxosal() {
    prepareMakeCmd "libqcxosal"
    local modules="libqcxosal"
    local pushModules="/vendor/lib64/libqcxosal.so"

    if makeCleanBuild ${modules}; then
        if pushModules "${pushModules}"; then
            
            return 0
        else
            log -e "push failed!"
        fi
    else
        log -e "build failed!"
    fi
    
    return 1
}

function qcarcam_test() {
    prepareMakeCmd "qcarcam_test"
    local modules="qcarcam_test"
    local pushModules="/vendor/bin/qcarcam_test"

    if makeCleanBuild ${modules}; then
        if pushModules "${pushModules}"; then
            adb_kill "qcarcam_test"
            adb shell /vendor/bin/qcarcam_test
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
    do_execute "adb push $ANDROID_OUTPUT/vendor/etc/selinux/precompiled_sepolicy /data/precompilie_sepolicy"
    do_execute "adb shell load_policy /data/precompilie_sepolicy"
}



function ExtCamera() {
    local moduleName=$(if [ "${GRADLE_FLAVOR}" = "Clite" ]; then echo "Connect-L_ExtCamera"; else echo "Connect_ExtCamera"; fi)
    local packageName="com.mobis.app.extcamera"
    makeGradleModule "${moduleName}" "vendor/mobis/packages/apps/ExtCamera" "/system_ext/app" ${packageName}
    do_execute -i am start -n ${packageName}/.feature.features.ConnectCameraActivity
}

function HmgEvsCameraPreviewApp() {
    local moduleName="HmgEvsCameraPreviewApp"
    local packageName="com.android.hmg.evs"
    local outmod="/system/app/${moduleName}"
    prepareMakeCmd "${moduleName}"

    if makeCleanBuild ${moduleName}; then
        if installApk ${outmod} ${moduleName}; then
            do_execute -i am start -n ${packageName}/.MainActivity
            return 0
        else
            log -e "install failed!"
        fi

    else
        log -e "build failed!"
    fi
    return 1
}

function HmgEvsCameraPreviewApp2() {
    local moduleName="HmgEvsCameraPreviewApp_2"
    local packageName="com.android.hmg.evs2"
    local outmod="/system/app/${moduleName}"
    prepareMakeCmd "${moduleName}"

    if makeCleanBuild ${moduleName}; then
        if installApk ${outmod} ${moduleName}; then
            do_execute -i am start -n ${packageName}/.MainActivity
            return 0
        else
            log -e "install failed!"
        fi

    else
        log -e "build failed!"
    fi
    return 1
}

function MobisEvsCameraPreviewApp() {
    local moduleName="MobisEvsCameraPreviewApp"
    local packageName="com.mobis.test.camera.evs"
    local pushModules="/system/app/${moduleName}"
    prepareMakeCmd "${moduleName}"

    if makeCleanBuild ${moduleName}; then
        if pushModules "${pushModules}"; then
            # adb_kill "${packageName}"
            do_execute -i pm compile -f "${packageName}"
            # adb shell /vendor/bin/qcarcam_test
            return 0
        else
            log -e "push failed!"
        fi
    else
        log -e "build failed!"
    fi
    return 1
}

function MobisEvsRvmCameraPreviewApp() {
    local moduleName="MobisEvsRvmCameraPreviewApp"
    local packageName="com.android.mobis.evs.rvm"
    local pushModules="/system/app/${moduleName}"
    prepareMakeCmd "${moduleName}"

    if makeCleanBuild ${moduleName}; then
        if pushModules "${pushModules}"; then
            # adb_kill "${packageName}"
            do_execute -i pm compile -f "${packageName}"
            # adb shell /vendor/bin/qcarcam_test
            return 0
        else
            log -e "push failed!"
        fi
    else
        log -e "build failed!"
    fi
    return 1
}

function MiniPlayer() {
    makeGradleModule "MiniPlayer" "vendor/mobis/packages/apps/MiniPlayer" "/system_ext/app" "com.mobis.miniplayer.app"
}

function Radio() {
    makeGradleModule "PBVIVI_RadioApp" "vendor/mobis/packages/apps/radio" "/system_ext/app" "com.mobis.app.radio"
}

function vendor.mobis.hardware.interfaces.automotive.micomcommunication@V1-default-service(){
    # prepareMakeCmd "vendor.mobis.hardware.interfaces.automotive.micomcommunication@V1-default-service"
     local modules="vendor.mobis.hardware.interfaces.automotive.micomcommunication@V1-default-service"
    prepareMakeCmd "${modules}"

    #/vendor/bin/hw/vendor.mobis.fingerprint-hal-service
    #/vendor/etc/init/fingerprint-hal-default.rc
    #/vendor/etc/vintf/manifest/fingerprint-hal-default.xml
    local pushModules=(
        "/vendor/bin/hw/vendor.mobis.hardware.interfaces.automotive.micomcommunication@V1-default-service"
        "/vendor/etc/init/vendor.mobis.hardware.interfaces.automotive.micomcommunication-service.rc"
        "/vendor/etc/vintf/manifest/vendor.mobis.hardware.interfaces.automotive.micomcommunication-service.xml"

    )

    if makeCleanBuild ${modules}; then
      if pushModules "${pushModules[@]}"; then
            adb_kill "${modules}"
            return 0
        else
            log -e "push failed!"
        fi
    else
        log -e "build failed!"
    fi
    
    return 1
}

function mobis-api-stubs-update-current-api() {
    local remote_command="export WORKSPACE_ENV_TERMINAL_TITLE='build' ; source ~/workspace/bin/.bashrc_luis ; cd \\\${WORKSPACE_ANDROID_HOME};"
    local envsetup_command="source build/envsetup.sh ; lunch ${WORKSPACE_PRODUCT_NAME}-${WORKSPACE_BUILD_VARIANT};"
    local build_command="m mobis-api-stubs-update-current-api && make mobis.framework.core mobis.framework.services mobis.framework"
    if $NINJA_BUILD; then
        build_command="${NINJA_COMMAND_PREFIX} mobis-api-stubs-update-current-api && make mobis.framework.core mobis.framework.services mobis.framework"
    fi

    prepareMakeCmd "mobis-api-stubs-update-current-api"
    # local build_command="export WORKSPACE_ENV_TERMINAL_TITLE='build' ; source ~/workspace/bin/.bashrc_luis ; cd release; source build.sh ; build_la skip_gradle && cpimg 2"
    log -i "remote_command   = ${remote_command}"
    log -i "envsetup_command = ${envsetup_command}"
    log -i "build_command    = ${build_command}"
    log -i "command    = ${SSH_COMMAND} \"${remote_command} ${envsetup_command} ${build_command}\""


    if ! eval ${SSH_COMMAND} "\"${remote_command} ${envsetup_command} ${build_command}\""; then
        log -w "build failed!"
        return 1
    else 
        log -i "??build success!!"
        local pushModules="/system/framework/mobis.framework*"
   
        if pushModules "${pushModules}"; then
            reboot
            return 0
        else
            log -e "push failed!"
        fi
        
    fi
}


function build_la() {
    prepareMakeCmd "build_la"
    local build_command="export WORKSPACE_ENV_TERMINAL_TITLE='build_$1' ; source ~/workspace/bin/.bashrc_luis ; cd release; source build.sh ; build_la skip_gradle && cpimg 2"
    log -i "build_la() build_command=${build_command}"


    if ! eval ${SSH_COMMAND} "\"${build_command}\""; then
        log -w "build failed!"
        return 1
    else 
        log -i "??build success!!"
        log -w "TODO: request cpimg"
        # for module in "$@"; do
        # log -i "?“¦ $module"
        # done
        
    fi

    # log -i "command=${command}"
}


#### STEP 3 : Declair build functions ########################################################################################

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
    -m)
        NINJA_BUILD=false
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
