#!/usr/bin/env bash

source common_menu.sh;
DEBUG_COMMON_BASH=false;
DEBUG=false;
# BUILD_HOME="~/UTE7057LGU"
# ANDROID_OUTPUT="/mnt/x/UTE7057LGU_out"
ADB_PUSH="adb push --sync"

trap exited SIGINT
function exited() {
  log -w "error occurred"
  exit 1
}

#### STEP 1 : Declare variables ########################################################################################
declare -A action00=([name]="frameworks"         [cmd]="build_frameworks")
declare -A action01=([name]="services"           [cmd]="build_services" )
declare -A action02=([name]="NetflixReceiver "   [cmd]="build_netflix_receiver" )
declare -A action03=([name]="IptvShmService "    [cmd]="build_iptv_shm_service")
declare -A action04=([name]="libstbapp"          [cmd]="build_libstbapp")
declare -A action05=([name]="hdmi_cec.vs680"     [cmd]="build_hdmi_cec.vs680")
declare -A action06=([name]="display handler"    [cmd]="build_display_handler")
declare -A action07=([name]="fps client"         [cmd]="build_fps_client")
declare -A action08=([name]="ampsdk_libdispsrv"  [cmd]="build_ampsdk_libdispsvr")
declare -A action09=([name]="SynaTvSettings"     [cmd]="build_syna_tvsettings")
declare -A action10=([name]="WriteLog"           [cmd]="build_write_log")
declare -A action11=([name]="kmsglogd"           [cmd]="build_kmsglogd")

declare -a menu_items=( ${!action@} )
#### STEP 2 : Declare variables ########################################################################################
function finishBuild() {
  local _message=$1;
  exit 1;
}

function cleanBuild() {
    local _moduleName=$1;
    if ! do_execute -i "ssh svr -C \"cd ${BUILD_HOME} && source env.sh && make clean-${_moduleName} && make ${_moduleName} -j10\""; then
      finishBuild "build failed!"
      return 1;
    fi
    return 0;
}

function build_ampsdk() {
    local _moduleName=$1;
    # cd ampsdk
    # source build/envsetup.sh
    # make
    if ! do_execute -i "ssh svr -C \"cd ${BUILD_HOME} && source env.sh && cd vendor/synaptics-sdk/ampsdk && source build/envsetup.sh && make ${_moduleName} -j10\""; then
      finishBuild "build failed!"
      return 1;
    fi
    return 0;
}

# path, binary name, process name
function deployOutputs() {
    adb remount
    local _path="$1"
    local _dest_path="$1"
    local _files="$2"
    if [ -z ${_files} ]; then
      _dest_path=`dirname ${_path}`
    fi
    local _process="$3"

    if do_execute -i "$ADB_PUSH ${ANDROID_OUTPUT}/${_path}/${_files} /${_dest_path}/"; then
      do_execute -i "adb shell sync"
        if [ ! -z ${_process} ]; then
        local pid=`adb shell pidof ${_process}`
          if [ ! -z ${pid} ]; then
            do_execute -i "adb shell kill -9 ${pid}"
          fi
        fi
      return 0;
    else
      finishBuild "deploy failed!!"
      return 1;
    fi
}
function deployAmpsdkOutputs() {
    local _files="$1"
    if do_execute -i "$ADB_PUSH ${WORKSPACE_SERVER_MOUNT_PATH}/vendor/synaptics-sdk/out/vs680_a0_android_igarnet/target/ampsdk/lib/${_files} /vendor/lib/"; then
        log -i "success"
    fi
}

function build_frameworks() {
    cleanBuild "framework"
    # deployOutputs "system/framework" "{framework.jar,boot*,arm,services.*}"
    # deployOutputs "system/framework/oat/arm/" "services.*"
    deployOutputs "system/framework" 
    do_execute -i "adb reboot"
    do_execute -i "adb_connect -r"
}

function build_services() {
    cleanBuild "services"
    # deployOutputs "system/framework" "services.*"
    # deployOutputs "system/framework/oat/arm/" "services.*"
    deployOutputs "system/framework"
    do_execute -i "adb reboot"
    do_execute -i "adb_connect -r"
}

function build_netflix_receiver() {
    local moduleName="NetflixReceiver"
    local outputPath="product/app/${moduleName}"
    local processName="com.marvell.tv.netflix"

    cleanBuild $moduleName
    deployOutputs "${outputPath}" "${moduleName}.*" "${processName}"
}

function build_iptv_shm_service() {
    local moduleName="IptvShmService"
    local outputPath="system/priv-app/${moduleName}"
    local processName="com.lge.sys"
    
    cleanBuild $moduleName
    deployOutputs "${outputPath}" "${moduleName}.*" "${processName}"
}

function build_libstbapp() {
    cleanBuild "libstbapp"
    deployOutputs "vendor/lib" "libstbapp.*" "com.technicolor.iptv.iptvserver@1.0-service"
}

function build_hdmi_cec.vs680() {
    cleanBuild "hdmi_cec.vs680"
    deployOutputs "vendor/lib/hw" "hdmi_cec.vs680.*" "android.hardware.tv.cec@1.0-service"
    do_execute -i "adb reboot"
    do_execute -i "adb_connect -r"
}

function build_display_handler() {
    cleanBuild "libdisplayhandler"
    deployOutputs "vendor/lib" "libdisplayhandler.so" "com.synaptics.display@2.1-service"
    do_execute -i "adb reboot"
    do_execute -i "adb_connect -r"
}

function build_fps_client() {
    cleanBuild "fpsclient"
    deployOutputs "system/bin" "fpsclient" "fpsclient"
    do_execute -i "adb reboot"
    do_execute -i "adb_connect -r"
}

function build_syna_tvsettings() {
    local moduleName="SynaTvSettings2"
    local outputPath="product/app/${moduleName}"
    local processName="com.synaptics.tv.settings"
    cleanBuild $moduleName
    deployOutputs "${outputPath}" "${moduleName}.*" "${processName}"
}

function build_write_log() {
  cleanBuild "wl"
  deployOutputs "system/bin" "wl" "wl"
}

function build_kmsglogd() {
  cleanBuild "kmsglogd"
  deployOutputs "vendor/bin" "kmsglogd" "kmsglogd"
}

function build_ampsdk_libdispsvr() {
    build_ampsdk "libdispsrv"
    deployAmpsdkOutputs "libdispsrv.so"
    do_execute -i "adb reboot"
    do_execute -i "adb_connect -r"
}

function build_ampsdk() {
    build_ampsdk 
    deployAmpsdkOutputs "*"
    do_execute -i "adb reboot"
    do_execute -i "adb_connect -r"
}

function showMenu() {
  select_items=($(show_actions_menu ${!action@} ))

  log -d "select_items=$select_items"
  log -d "count=${#select_items[@]}"

  if [ ${#select_items[@]} -eq 0 ]; then
    return 1;
  else
    for index in ${select_items[@]}; do
      if [ $(isNumber $index) == 1 ]; then
        if [ $index -gt ${#menu_items[@]} ]; then
          continue;
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

if [ ! -z $1 ]; then
    eval "$1"
else
    while true; do
    if ! showMenu; then
        exit 0;
    fi

    done
fi

