#!/usr/bin/env bash

source common_bash.sh

target_device="${ANDROID_SERIAL:+-s ${ANDROID_SERIAL}}"

function adb_wait-for-device() {
    if ! adb_is_connected; then
        if ! do_execute "adb wait-for-device"; then
            return 0
        fi
    fi
    return 1

}

function adb_is_connected() {
    # echo "adb ${target_device} get-state"
    # Check if the device is connected
    if [ "$(adb ${target_device} get-state 2>/dev/null)" != "device" ]; then
        return 1
    fi
    return 0
}

function adb_is_rooted() {
    # Check if the device is rooted
    if [ "$(adb ${target_device} shell whoami)" != "root" ]; then
        return 1
    fi
    return 0
}

function adb_root() {
    # Check if the device is rooted
    if adb_is_rooted; then
        return 0
    fi

    # Attempt to root the device
    if ! do_execute -i "adb ${target_device} root"; then
        log -e "adb ${target_device} root failed"
        return 1
    fi
}

function adb_permissive() {
    # Check if the device is in permissive mode
    if [ "$(adb ${target_device} shell getenforce)" == "Permissive" ]; then
        log -i "device is already in permissive mode"
        return 0
    fi

    # Attempt to set the device to permissive mode
    if ! do_execute -i "adb ${target_device} shell setenforce 0"; then
        log -e "adb ${target_device} setenforce 0 failed"
        return 1
    fi
}


function adb_enforce() {
    # Check if the device is in enforcing mode
    if [ "$(adb ${target_device} shell getenforce)" == "Enforcing" ]; then
        log -i "device is already in enforcing mode"
        return 0
    fi

    # Attempt to set the device to enforcing mode
    if ! do_execute -i "adb ${target_device} shell setenforce 1"; then
        log -e "adb ${target_device} setenforce 1 failed"
        return 1
    fi
}


function adb_remount() {
    # Check if the device is mounted
    if adb ${target_device} shell 'touch /system/test_remount' >/dev/null 2>&1; then
        return 0
    fi

    # Attempt to remount the device
    if ! do_execute -i "adb ${target_device} remount"; then
        log -e "adb ${target_device} remount failed"
        return 1
    fi
}

function adb_connect() {
    if [[ -z ${ANDROID_SERIAL} ]]; then
        log -w "ANDROID_SERIAL is empty"
        return 1
    fi

    # Check if the device is connected    
    # 최대 30초 동안 device 연결 대기
    local timeout=30
    local waited=0
    local needRooting=true
    local needPermissive=true
    local needRemount=true
    local opt=${1:-"default"}
    for arg in "$@"; do
        if [[ "$arg" == "root" ]]; then
            needPermissive=false
            needRemount=false
        elif [[ "$arg" == "permissive" ]]; then\
            needRemount=false
        fi
    done
    

    # Wait for device to be connected
    while ! adb_is_connected; do
        if (( waited >= timeout )); then
            log -e "${ANDROID_SERIAL} device not connected after ${timeout}s"
            return 1
        fi
        log "🔄 Waiting for ${ANDROID_SERIAL} to be connected... (${waited}s)"
        # local result=$(adb wait-for-device)
        # log "adb wait-for-device result: $result"
        ((waited++))
    done

    # Check if the device is rooted
    if ! $needRooting; then
        log -d "needRooting is false"
        return 0
    elif ! adb_is_rooted; then
        if ! adb_root; then
            log -e "adb ${target_device} root failed"
            return 1
        fi
        adb_wait-for-device
        adb_time_set
    fi

    if $WORKSPACE_ADB_PERMISSIVE; then
        # Check if SELinux is enforcing
        if ! $needPermissive; then
            log -d "needPermissive is false"
            return 0
        elif [ "$(adb ${target_device} shell getenforce)" == "Enforcing" ]; then
            adb_permissive
        fi
    else 
        log -d "WORKSPACE_ADB_PERMISSIVE is false"
        if [ "$(adb ${target_device} shell getenforce)" != "Enforcing" ]; then
            adb_enforce
        fi

    fi

    # Check if the device is mounted
    if ! $needRemount; then
        log -d "needRemount is false"
        return 0
    elif ! adb ${target_device} shell 'touch /system/test_remount' >/dev/null 2>&1; then
        adb_remount
    fi

    return 0;
}

## INTENT
function app_comp() {
    do_execute adb ${target_device} shell am start -n $@
}

function app_main() {
    do_execute adb ${target_device} shell am start -n $1 -a android.intent.action.MAIN
}

function app_action() {
    do_execute adb ${target_device} shell am start -a $@
}

function broadcast() {
    do_execute adb ${target_device} shell am broadcast --receiver-include-background -a $*
}

# SETTINGS
function settings() {
    local target=""
    local intent=""
    
    if [[ ! -z $1 ]]; then
        case $1 in
        main) app_action android.settings.SETTINGS ;;
        bluetooth) app_comp com.android.tv.settings/.accessories.BluetoothDevicePickerActivity ;;
        bluetooth_accessories) app_action com.google.android.intent.action.CONNECT_INPUT ;;
        developer) app_comp com.android.tv.settings/.system.development.DevelopmentActivity ;;
        restric) app_comp com.android.tv.settings/.system.SecurityActivity ;;
        storage) app_action android.intent.action.MANAGE_PACKAGE_STORAGE ;;
        esac
    else
        app_action android.settings.SETTINGS
    fi
}
complete -W "main bluetooth bluetooth_accessories developer restric storage" settings

# DEVICE
function bluetooth_on() {
    do_execute adb ${target_device} shell service call bluetooth_manager 6
}

function bluetooth_off() {
    do_execute adb ${target_device} shell service call bluetooth_manager 8
}

function bluetooth_restart() {
    do_execute bluetooth_off && bluetooth_on
}

function reboot() {
    log "🔄 reboot"
    do_execute "adb ${target_device} reboot $@"
}

function restart() {
    do_execute "adb ${target_device} shell pkill logd && am restart"
}

# Key Injeting
function keyevent() {
    do_execute adb ${target_device} shell input keyevent KEYCODE_$1
}

function power() {
    keyevent POWER
}

function home() {
    adb ${target_device} shell am start -a android.intent.action.MAIN -c android.intent.category.HOME -f 0x1400000
}

function ch_up() {
    keyevent CHANNEL_UP
}

function ch_down() {
    keyevent CHANNEL_DOWN
}

function dpad_center() {
    keyevent DPAD_CENTER
}

function dpad_left() {
    keyevent DPAD_LEFT
}

function dpad_right() {
    keyevent DPAD_RIGHT
}

function dpad_top() {
    keyevent DPAD_TOP
}

function dpad_down() {
    keyevent DPAD_DOWN
}

function dumpsys() {
    adb ${target_device} shell dumpsys $@
}

complete -W "DockObserver
  SurfaceFlinger
  accessibility
  account
  activity
  activity_task
  adb
  alarm
  android.frameworks.stats.IStats/default
  android.hardware.light.ILights/default
  android.hardware.memtrack.IMemtrack/default
  android.hardware.oemlock.IOemLock/default
  android.hardware.power.IPower/default
  android.hardware.security.keymint.IKeyMintDevice/default
  android.hardware.security.secureclock.ISecureClock/default
  android.hardware.security.sharedsecret.ISharedSecret/default
  android.os.UpdateEngineService
  android.os.UpdateEngineStableService
  android.security.apc
  android.security.authorization
  android.security.compat
  android.security.identity
  android.security.legacykeystore
  android.security.maintenance
  android.security.metrics
  android.service.gatekeeper.IGateKeeperService
  android.system.keystore2.IKeystoreService/default
  app_binding
  app_hibernation
  app_integrity
  app_search
  appops
  appwidget
  audio
  auth
  autofill
  backup
  battery
  batteryproperties
  batterystats
  binder_calls_stats
  biometric
  blob_store
  bluetooth_manager
  bugreport
  cacheinfo
  clipboard
  color_display
  connectivity
  connmetrics
  consumer_ir
  content
  country_detector
  cpuinfo
  crossprofileapps
  dataloader_manager
  dbinfo
  device_config
  device_identifiers
  device_policy
  device_state
  deviceidle
  devicestoragemonitor
  diskstats
  display
  dnsresolver
  domain_verification
  dreams
  drm.drmManager
  dropbox
  dynamic_system
  emergency_affordance
  ethernet
  external_vibrator_service
  file_integrity
  font
  game
  gfxinfo
  gpu
  graphicsstats
  hardware_properties
  hdmi_control
  imms
  incident
  incidentcompanion
  incremental
  input
  input_method
  inputflinger
  installd
  ipsec
  jobscheduler
  launcherapps
  led
  legacy_permission
  lights
  location
  lock_settings
  looper_stats
  manager
  media.aaudio
  media.audio_flinger
  media.audio_policy
  media.camera
  media.camera.proxy
  media.extractor
  media.metrics
  media.player
  media.resource_manager
  media.resource_observer
  media.tuner
  media_communication
  media_metrics
  media_projection
  media_resource_monitor
  media_router
  media_session
  meminfo
  memtrack.proxy
  mount
  netd
  netd_listener
  netpolicy
  netstats
  network_management
  network_score
  network_stack
  network_time_update_service
  network_watchlist
  notification
  oem_lock
  otadexopt
  overlay
  pac_proxy
  package
  package_native
  people
  performance_hint
  permission
  permission_checker
  permissionmgr
  persistent_data_block
  pinner
  platform_compat
  platform_compat_native
  power
  powerstats
  processinfo
  procstats
  reboot_readiness
  recovery
  restrictions
  role
  rollback
  runtime
  scheduling_policy
  search
  search_ui
  sec_key_att_app_id_provider
  secure_element
  sensor_privacy
  sensorservice
  serial
  servicediscovery
  settings
  shortcut
  slice
  smartspace
  soundtrigger
  soundtrigger_middleware
  speech_recognition
  stats
  statscompanion
  statsmanager
  statusbar
  storaged
  storaged_pri
  storagestats
  suspend_control
  suspend_control_internal
  system_config
  system_server_dumper
  system_update
  telephony.registry
  testharness
  tethering
  textclassification
  textservices
  texttospeech
  thermalservice
  time_detector
  time_zone_detector
  tracing.proxy
  trust
  tv_input
  tv_tuner_resource_mgr
  uimode
  updatelock
  uri_grants
  usagestats
  usb
  user
  vcn_management
  vibrator_manager
  voiceinteraction
  vold
  vpn_management
  wallpaper
  webviewupdate
  wifi
  wifinl80211
  wifip2p
  wifiscanner
  window" dumpsys

function pm() {
    adb ${target_device} shell pm $@
}

function am() {
    adb ${target_device} shell am $@
}

function content() {
    adb ${target_device} shell content $@
}

function getprop() {
    adb ${target_device} shell getprop $@
}

function setprop() {
    adb ${target_device} shell setprop $@
}


# ETC
function adb_pull_tv_provider() {
    adb ${target_device} pull /data/data/com.android.providers.tv/databases/tv.db $1
}

function clear_tv_provider() {
    adb ${target_device} shell pm clear com.android.providers.tv
}

# LAUNCH APP
function youtube() {
    # while getopts "lh" option; do
    #     log "opt=${option}"
    # done

    # shift $(($OPTIND - 1))
    if [ -z $1 ]; then
        app_comp com.google.android.youtube.tv/com.google.android.apps.youtube.tv.activity.ShellActivity
    else
        case "${1}" in
        "http"*)
            app_action android.media.action.MEDIA_PLAY_FROM_SEARCH -d $1
            ;;
        "-l")
            log "Youtube test URL list"
            log "   - https://youtu.be/wzE2nsjsHhg : 30min 1080p 50fps 25fps Audio Video Sync Test and Video Frame Align Grid"
            log "   - https://youtu.be/YRSIvFOzRBs : Audio-Video Sync & Latency Test (60 FPS & MP4)"
            log "   - https://youtu.be/XXYlFuWEuKI : The Weeknd - Save Your Tears (Official Music Video)"
            log "   - https://youtu.be/kTJczUoc26U : The Kid LAROI, Justin Bieber - STAY (Official Video)"
            log "   - https://youtu.be/yWHrYNP6j4k : The Kid LAROI, Justin Bieber - Stay (Lyrics)"
            return 0
            ;;
        "-h")
            log "with no option : launch main activity"
            log " opt -l : example list"
            log " opt http---- : launch with the url"
            return 0
            ;;
        esac

    fi
}

function netflix() {
    app_comp com.netflix.ninja/.MainActivity
}

function live() {
    local channelNum=$1
    local QUERY_TV_DB="sqlite3 /data/data/com.android.providers.tv/databases/tv.db"

    local PKG="${WORKSPACE_DTVINPUT_PACKAGE}"
    local URI_CHANNEL="--uri content://android.media.tv/channel"
    if [ -z ${1} ]; then
        app_comp com.android.tv/.MainActivity
        return 0
    fi

    local num=${1}
    local where="package_name='${PKG}' and display_number=${num}"

    log -i "adb ${target_device} shell content query ${URI_CHANNEL} --projection _id:display_name --where \"${where}\""
    local ch_info=$(adb ${target_device} "content query ${URI_CHANNEL} --projection _id:display_name --where \"${where}\"")

    if [ -z "${ch_info}" ]; then
        log -w "channel is empty"
        return 1
    else
        id=$(echo ${ch_info} | cut -d= -f2 | cut -d, -f1)
        log -i "channel informaiton=${ch_info}"
        name=$(echo ${ch_info} | cut -d= -f3 | cut -d, -f1)
        log -i "tune to ${num} (${id}) - ${name}"
        do_execute -i adb ${target_device} am start-activity -n com.android.tv/.MainActivity content://android.media.tv/channel/${id}
    fi
}

# SETTINGS

function adb_target() {
    #echo "$@"
    local save=false
    local serial=$1

    OPTIND=1
    while getopts "s:" option; do
        case "${option}" in
        s)
            save=true
            serial="$OPTARG"
            ;;
        esac
    done
    shift $(($OPTIND - 1))

    if echo "$serial" | grep -E -q '^([0-9]{1,3}\.){3}[0-9]{1,3}$'; then
        IFS='.' read -r -a octets <<<"$serial"
        for octet in "${octets[@]}"; do
            if ((octet < 0 || octet > 255)); then
                log -w "Invalid IP format"
                return 1
            fi
        done
        local ip_addr=$(echo "$serial" | cut -d : -f 1)
        local port=5555
        if [ $(echo "$serial" | grep ":") ]; then
            port=$(echo "$serial" | cut -d : -f 2)
        fi
        serial="$ip_addr:$port"
    fi

    log -i "changed the ANDROID_SERIAL: ${serial}"
    if $save; then
        local path=$WORKSPACE_ROOT/bin
        if [[ ! -z ${WORKSPACE_PROJECT} ]]; then
            path=${WORKSPACE_HOME}/.workspace_env/
        fi
        log -i "save the ANDROID_SERIAL to path=${path}"
        echo "$serial" >${path}/TARGET_IP
    fi
    export ANDROID_SERIAL="$serial"
}

function adb_screen_capture() {
    DATE=$(date "+%y%m%d_%H%M%S")

    adb ${target_device} shell screencap -p >adb_screen_capture_${DATE}.png
    log -i "captured to adb_screen_capture_${DATE}.png"
}

function adb_kill {
    local processName=$@
    if [[ -z ${processName} ]]; then
        log -w "process name is empty"
        return 1
    fi

    if ! adb_is_connected ; then
        log -w "device is not connected"
        return 1
    elif ! adb_is_rooted ; then
        log -w "device is not rooted"
        adb_root
    fi

    for process in $processName; do
        local _pid=$(adb ${target_device} shell pidof $process)
        if [[ -z ${_pid} ]]; then
            log -w "${process} is not running"
        else
            do_execute -i adb ${target_device} shell kill $_pid
        fi
    done
}

function selinux_check() {
    local tempDir="~/temp"
    local device=""
    if [ ! -z ${WORKSPACE_HOME} ]; then
        tempDir=${WORKSPACE_HOME}/temp

    fi

    if [ ! -d ${tempDir} ]; then
        mkdir "${tempDir}"
    fi

    do_execute "adb ${target_device} pull /sys/fs/selinux/policy ${tempDir}"
    do_execute "adb ${target_device} logcat -b events -d | grep avc | audit2allow -p ${tempDir}/policy"
}

function selinux_apply() {
    local tempDir="~/temp"
    local device=""
    if [ ! -z ${WORKSPACE_HOME} ]; then
        tempDir=${WORKSPACE_HOME}/temp

    fi

    if [ ! -d ${tempDir} ]; then
        mkdir "${tempDir}"
    fi

    do_execute "adb ${target_device} root && adb ${target_device} remount && adb ${target_device} push ${ANDROID_OUTPUT}/vendor/etc/selinux/precompiled_sepolicy /data/"
    do_execute "adb ${target_device} shell load_policy /data/precompiled_sepolicy"
}

function adb_time_set() {
    DATE_STR=$(date +'%Y-%m-%d %H:%M:%S')
    do_execute adb ${target_device} shell \"date -s \'$DATE_STR\'\"
}

function adb_restart_app(){
    local packageName="$1"

    if [ -z "$local packageName" ]; then
        echo "Usage: $0 <package.name>"
        return 1
    fi

    # 1. main activity component name 추출
    COMPONENT=$(adb shell cmd package resolve-activity --brief "$local packageName" | tail -n 1)

    if [[ "$COMPONENT" != *"/"* ]]; then
        echo "Failed to resolve main activity for $local packageName"
        return 1
    fi

    echo "Resolved component: $COMPONENT"

    # 2. taskId 조회
    TASK_ID=$(adb shell "am stack list" | grep -A 1 "$local packageName" | grep taskId | sed -n 's/.*taskId=\([0-9]*\):.*/\1/p')

    if [ -n "$TASK_ID" ]; then
        echo "Removing existing taskId=$TASK_ID"
        adb shell "am stack remove $TASK_ID"
    fi

    # 3. main activity 실행
    adb shell "am start -n $COMPONENT -f 0x10008000"
}

function adb_device_monitoring(){
    local serial="${1:-$ANDROID_SERIAL}"
    while true; do
        draw_line_with_title "Waiting for device" "-" ${COLOR_RED}
        adb_wait-for-device 
        adb_connect
        draw_line_with_title "Device is running" "-" ${COLOR_GREEN}
        adb wait-for-disconnect
    done
}

################################### Incubating functions ###################################
function adb_dumpsys_activities() {
    local packageName="$1"
    local filter="rootOfTask|^ACTIVITY\s+MANAGER\s+ACTIVITIES.*$|^Display|\* Task|ActivityRecord|ProcessRecord|Intent|packageName\=|processName\=|launchedFromPackage\=|state\=|mActivityComponent\=|nowVisible\=|^\s*Resumed:|^ActivityTaskSupervisor state:$|DisplayPolicy|WindowInsetsStateController|KeyguardController|TaskDisplayArea|PinnedTaskController|  bounds="
    # local filter="ActivityRecord|ProcessRecord|Intent|DisplayPolicy|WindowInsetsStateController|KeyguardController|TaskDisplayArea|PinnedTaskController"

    # log "filter=$filter"
    # local result=$(adb ${target_device} shell dumpsys activity activities | egrep "$filter")
    # log "result=$result"
    # do_execute "adb ${target_device} shell dumpsys activity activities | egrep \"$filter\" | grcat ~/workspace/bin/etc/grc/dumpsys_activity.conf"

    log "adb ${target_device} shell dumpsys activity activities | egrep \"$filter\" | grcat ~/workspace/bin/etc/grc/dumpsys_activity.conf"
    adb ${target_device} shell dumpsys activity activities | egrep "$filter" | grcat ~/workspace/bin/etc/grc/dumpsys_activity.conf
}


function log_convert_from_nano_to_milli() {
    local fileName=$1
    if [ -z $fileName ]; then
        log -w "file is empty"
        return 1
    elif [ ! -f $fileName ]; then
        log -e "file is not exist"
        return 1
    fi
    log -i "sed -i.bak -E -e 's/(\.[0-9]{3})[0-9]{3}/\1/g; /^-{9}\s.{0,}/d' $fileName"
    sed -i.bak -E -e 's/(\.[0-9]{3})[0-9]{3}/\1/g; /^-{9}\s.{0,}/d' $fileName

}

function log_summury() {
    local fileName=$1
    if [ -z $fileName ]; then
        log -w "file is empty"
        return 1
    elif [ ! -f $fileName ]; then
        log -e "file is not exist"
        return 1
    fi
    cat $fileName |
        awk 'BEGIN {
        # 우선순위가 높은 TAG 목록 (필요에 따라 추가)
        high["ActivityManager"] = 1;
        high["system_server"]    = 1;
        high["Binder"]           = 1;
        high["Watchdog"]         = 1;
        high["InputDispatcher"]  = 1;
        high["SurfaceFlinger"]   = 1;
        }
        {
        # 6번째 필드(TAG)에서 콜론(:) 제거
        gsub(":", "", $6);
        pid   = $3 + 0;      # PID를 숫자로 처리
        tag   = $6;
        level = $5;
        
        # PID와 TAG의 조합을 고유 키로 사용
        key = pid SUBSEP tag;
        count[key, level]++;  # 각 로그 레벨별 카운트 누적
        keys[key] = 1;
        }
        END {
        for (k in keys) {
            split(k, parts, SUBSEP);
            pid = parts[1] + 0;
            tag = parts[2];
            E = count[k, "E"] + 0;
            W = count[k, "W"] + 0;
            I = count[k, "I"] + 0;
            D = count[k, "D"] + 0;
            V = count[k, "V"] + 0;
            # 우선순위 지정: high 배열에 있으면 0 (우선), 없으면 1 (일반)
            prio = (tag in high) ? 0 : 1;
            # /* 
            # 정렬을 위한 키로는 prio(낮은 숫자가 우선), 
            # 그 다음 E 건수 내림차순, 그리고 PID 숫자 오름차순을 사용합니다.
            # 출력 시 앞에 이 정렬 키들을 붙인 후, 
            # 후속 처리에서 제거하여 최종 형식( PID TAG E=... )으로 만듭니다.
            # */
            printf "%d %d %d %s E=%d W=%d I=%d D=%d V=%d\n", prio, E, pid, tag, E, W, I, D, V;
        }
        }' | sort -k1,1n -k2,2nr -k3,3n |
        awk '{
        # 첫 번째(prio)와 두 번째(E 정렬용) 필드를 제거하여 최종 출력 형식을 맞춤
        $1 = ""; $2 = "";
        sub(/^  /, "");
        print
        }'

}

alias serial="python -m serial.tools.miniterm --filter direct --eol LF --encoding utf-8 /dev/ttyS5 115200"

alias adb_push_device_scripts="adb ${target_device} push --sync ${WORKSPACE_ROOT}/bin/android/device_scripts /data/local/tmp/"

function adb_cpu_stress_test() {
    local count=${1:-4}
    local duration=${2:-0}
    do_execute -i "adb ${target_device} shell sh /data/local/tmp/device_scripts/cpu_stress.sh $count $duration"
}
# alias adb_cpu_stress_test="adb ${target_device} shell /data/local/tmp/device_scripts/cpu_stress_test.sh"
# alias adb_pvr_info="adb ${target_device} shell /data/device_scripts/pvr_info.sh"
# alias adb_monitoring_pvr="watch -d adb ${target_device} /data/device_scripts/pvr_info.sh"
# alias adb_monitoring_timeshift="watch -d adb ${target_device} /data/device_scripts/timeshift_info.sh"
# alias adb_dtvfs_tune_by_ch_num="adb ${target_device} /data/device_scripts/dtvfs_tune_by_ch_num.sh"

# complete -W "$(${WORKSPACE_ROOT}/bin/android/build.sh -l)" build.sh
# complete -W "${WORKSPACE_DTVINPUT_PACKAGE} com.android.tv dtvfs" adb_kill

#TODO : remove variable name
# if [[ -z ${WORKSPACE_DTVSTACK_OUT} ]]; then
#     export WORKSPACE_DTVSTACK_OUT="${WORKSPACE_HOME}/vendor/technicolor/projects/${WORKSPACE_PRODUCT_NAME}/dtvmodules"
# fi
# if [[ -z ${WORKSPACE_DTVINPUT_PACKAGE} ]]; then
#     export WORKSPACE_DTVINPUT_PACKAGE="com.technicolor.android.dtvinput"
# fi
# if [[ -z ${WORKSPACE_DTVINPUT_APK} ]]; then
#     export WORKSPACE_DTVINPUT_APK="tch_dtvinput_service"
# fi
