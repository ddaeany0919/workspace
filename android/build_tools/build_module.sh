#!/usr/bin/env bash

source common_bash.sh
DEBUG_COMMON_BASH=false;
DEBUG=false;
ADB_PUSH="adb push --sync"

WORKSPACE_ENV_PS1=true;


SSH_COMMAND="ssh -tqC ${WORKSPACE_BUILD_SERVER}"
CMD_PREPARE="export WORKSPACE_ENV_PS1=\"${WORKSPACE_BUILD_SERVER}-module_build.sh\" ; source ~/workspace/bin/.bashrc_luis"

ONLY_APPLY=false;

trap exited SIGINT
function exited() {
  log -w "error occurred"
  exit 1
}

#### STEP 1 : Declare variables ########################################################################################
declare -A action00=([name]="image"              [cmd]="image")
declare -A action01=([name]="frameworks"         [cmd]="frameworks")
declare -A action02=([name]="services"           [cmd]="services" )
declare -A action03=([name]="sepolicy"           [cmd]="sepolicy" )
# declare -A action04=([name]="DtvInput"           [cmd]="dtvinput")
# declare -A action05=([name]="DtvProvider"        [cmd]="dtvprovider")
# declare -A action06=([name]="DTVFS"              [cmd]="dtvfs")
# declare -A action07=([name]="AtlLiveTv"          [cmd]="atllivetv")
# declare -A action07=([name]="DtvBackupService"   [cmd]="dtvbackupservice")


declare -a menu_items=( ${!action@} )
#### STEP 2 : Declare variables ########################################################################################
function finishBuild() {
  local _message=$1;
  exit 1;
}

function makeCmdPrepare() {
  CMD_PREPARE="export WORKSPACE_ENV_TERMINAL_TITLE='build_$1' ; source ~/workspace/bin/.bashrc_luis"
}

function cleanBuild() {
  if ! ${ONLY_APPLY}; then
    local _moduleName=$1;
    if ! do_execute -i ${SSH_COMMAND} "${CMD_PREPARE} && make clean-${_moduleName} && make ${_moduleName} -j10"; then
      finishBuild "build failed!"
      return 1;
    fi
  fi
  return 0;
}

# function build_ampsdk() {
#     local _moduleName=$1;
#     # cd ampsdk
#     # source build/envsetup.sh
#     # make
#     if ! do_execute -i "${SSH_COMMAND} \"${CMD_PREPARE} && cd vendor/synaptics-sdk/ampsdk && source build/envsetup.sh && make ${_moduleName} -j10\""; then
#       finishBuild "build failed!"
#       return 1;
#     fi
#     return 0;
# }

# path, binary name, process name
function deployOutputs() {
    adb remount
    local _path="$1"
    local _dest_path="$1"
    local _process="$2"
    local _files="$3"
    if [ -z ${_files} ]; then
      _dest_path=`dirname ${_path}`
    fi
    local executeOpt="-i"
    if $VIRTUAL_MODE; then
      executeOpt="-v"
    fi

    if do_execute $executeOpt "$ADB_PUSH ${ANDROID_OUTPUT}/${_path}/${_files} /${_dest_path}/"; then
      do_execute $executeOpt "adb shell sync"
        if [ ! -z ${_process} ]; then
          local pid=$(adb shell pidof ${_process})
          if [ ! -z ${pid} ]; then
            do_execute $executeOpt "adb shell kill -9 ${pid}"
          fi
          do_execute  $executeOpt "adb shell pm force-dex-opt ${_process}"
        fi
      return 0;
    else
      finishBuild "deploy failed!!"
      return 1;
    fi
}


#### STEP 3 : Declair build functions ########################################################################################

function image() {
    build_image.sh
}

function frameworks() {
    if ! ${ONLY_APPLY}; then
      makeCmdPrepare "frameworks"
      cleanBuild "framework"
    fi
    deployOutputs "system/framework" 
    do_execute -i "adb reboot"
    do_execute -i "adb_connect -r"
}

function services() {
    if ! ${ONLY_APPLY}; then
      makeCmdPrepare "services"
      cleanBuild "services"
    fi
    deployOutputs "system/framework"
    do_execute -i "adb reboot"
    do_execute -i "adb_connect -r"
}

function sepolicy() {
    makeCmdPrepare "precompiled_sepolicy"
    cleanBuild "precompiled_sepolicy"
    # do_execute "adb push $ANDROID_OUTPUT/odm/etc/selinux/precompiled_sepolicy /data/precompilie_sepolicy"
    # do_execute "adb shell load_policy /data/precompilie_sepolicy"
}

function dtvinput() {
    local moduleName="${WORKSPACE_DTVINPUT_APK}"
    local outputPath="vendor/app/${moduleName}"
    local processName="${WORKSPACE_DTVINPUT_PACKAGE}"
    if ! ${ONLY_APPLY}; then
      makeCmdPrepare "dtvinput"
      local prepare='cd ${WORKSPACE_DTVSTACK_OUT} && ./gradlew -x lint prepareSdk preparePrebuilts'
      if ! do_execute -i "${SSH_COMMAND} ${CMD_PREPARE} && ${prepare} && apk_sign.sh ${moduleName}"; then
        finishBuild "build failed!"
        return 1;
      fi
    fi
    if [ ${WORKSPACE_DTVINPUT_PACKAGE} == "com.technicolor.android.dtvinput" ]; then
      deployOutputs "${outputPath}" "${processName}" 
    else
      do_execute -i "adb install -r ${ANDROID_OUTPUT}/${outputPath}/${moduleName}.apk"
    fi
    
    # cleanBuild $moduleName
    # deployOutputs "${outputPath}" "${processName}" 

}

function dtvprovider() {
    local moduleName="${WORKSPACE_DTVPROVIDER_APK}"
    local outputPath="vendor/app/${moduleName}"
    local processName="${WORKSPACE_DTVPROVIDER_PACKAGE}"
    if ! ${ONLY_APPLY}; then
      makeCmdPrepare "${WORKSPACE_DTVPROVIDER_APK}"
      local prepare='cd ${WORKSPACE_DTVSTACK_OUT} && ./gradlew -x lint prepareSdk preparePrebuilts'
      if ! do_execute -i "${SSH_COMMAND} ${CMD_PREPARE} && ${prepare} && apk_sign.sh ${moduleName}"; then
        finishBuild "build failed!"
        return 1;
      fi
    fi
    
    # cleanBuild $moduleName
    # deployOutputs "${outputPath}" "${processName}" 
    if ! do_execute -i "adb install -r -d  ${ANDROID_OUTPUT}/${outputPath}/${moduleName}.apk"; then
      finishBuild "build failed!"
      return 1;
    fi

}

function dtvfs() {
    makeCmdPrepare "dtvfs"
    cleanBuild "dtvfs"
    do_execute "adb shell stop dtvfs"
    deployOutputs "vendor/bin" "dtvfs" "dtvfs" 
    do_execute "adb shell start dtvfs"
    # do_execute -i "adb reboot"
    # do_execute -i "adb_connect -r"
}

function atllivetv() {
    local moduleName="AtlLiveTv"
    local outputPath="system/priv-app/${moduleName}"
    local processName="com.android.tv"
    if ! ${ONLY_APPLY}; then

      cleanBuild $moduleName
    fi
    # deployOutputs "${outputPath}" "${processName}"
    
    # do_execute -i "adb push --sync  ${ANDROID_OUTPUT}/system/etc/permissions/{com.android.tattv.xml,privapp-permissions-com.technicolor.tatlivetv.xml} /system/etc/permissions/"

    if ! do_execute -i "adb install -r -d ${ANDROID_OUTPUT}/${outputPath}/${moduleName}.apk"; then
      finishBuild "build failed!"
      return 1;
    fi
}

function dtvbackupservice() {
    local moduleName="dtvbackup_service"
    local outputPath="vendor/priv-app/${moduleName}"
    local processName="com.technicolor.android.dtvbackupservice"
    if ! ${ONLY_APPLY}; then

      cleanBuild $moduleName
    fi
    deployOutputs "${outputPath}" "${processName}"
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

buildModuleItems=("");
args=( "$@" )
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
        exit 0;
      ;;
      *)
        buildModuleItems+=("${arg}")
    esac
done

if [ ${#buildModuleItems[@]} -gt 1 ]; then
    for module in "${buildModuleItems[@]}"; do
        eval ${module}
    done
else
    while true; do
        if ! showMenu; then
            exit 0;
        fi

    done
fi

