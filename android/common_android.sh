#!/usr/bin/env bash

# 핵심 엔진 로드
source common_bash.sh

# 타겟 디바이스 옵션을 반환하는 함수 (고정 변수 대신 사용)
function get_adb_target() {
    [[ -n "${ANDROID_SERIAL}" ]] && echo "-s ${ANDROID_SERIAL}" || echo ""
}

function adb_wait-for-device() {
    if ! adb_is_connected; then
        do_execute "adb $(get_adb_target) wait-for-device"
    fi
}

function adb_is_connected() {
    [[ "$(adb $(get_adb_target) get-state 2>/dev/null)" == "device" ]]
}

function adb_is_rooted() {
    [[ "$(adb $(get_adb_target) shell whoami 2>/dev/null)" == "root" ]]
}

function adb_root() {
    adb_is_rooted && return 0
    if ! do_execute -i "adb $(get_adb_target) root"; then
        log -e "adb $(get_adb_target) root failed"
        return 1
    fi
}

function adb_permissive() {
    if [[ "$(adb $(get_adb_target) shell getenforce)" == "Permissive" ]]; then
        log -i "device is already in permissive mode"
        return 0
    fi
    do_execute -i "adb $(get_adb_target) shell setenforce 0"
}

function adb_enforce() {
    if [[ "$(adb $(get_adb_target) shell getenforce)" == "Enforcing" ]]; then
        log -i "device is already in enforcing mode"
        return 0
    fi
    do_execute -i "adb $(get_adb_target) shell setenforce 1"
}

function adb_remount() {
    if adb $(get_adb_target) shell 'touch /system/test_remount' >/dev/null 2>&1; then
        return 0
    fi
    do_execute -i "adb $(get_adb_target) remount"
}

function adb_connect() {
    [[ -z "${ANDROID_SERIAL}" ]] && { log -w "ANDROID_SERIAL is empty"; return 1; }

    local timeout=30 waited=0
    local needRooting=true needPermissive=true needRemount=true
    
    for arg in "$@"; do
        case "$arg" in
            root) needPermissive=false; needRemount=false ;;
            permissive) needRemount=false ;;
        esac
    done

    while ! adb_is_connected; do
        if (( waited >= timeout )); then
            log -e "${ANDROID_SERIAL} not connected after ${timeout}s"
            return 1
        fi
        log "🔄 Waiting for ${ANDROID_SERIAL}... (${waited}s)"
        sleep 1
        ((waited++))
    done

    if $needRooting && ! adb_is_rooted; then
        adb_root || return 1
        adb_wait-for-device
        adb_time_set
    fi

    if [[ "$WORKSPACE_ADB_PERMISSIVE" == "true" ]]; then
        $needPermissive && adb_permissive
    else 
        adb_enforce
    fi

    $needRemount && adb_remount
    return 0
}

# --- Shortcuts ---
function app_comp() { do_execute adb $(get_adb_target) shell am start -n "$@"; }
function app_main() { do_execute adb $(get_adb_target) shell am start -n "$1" -a android.intent.action.MAIN; }
function app_action() { do_execute adb $(get_adb_target) shell am start -a "$@"; }
function broadcast() { do_execute adb $(get_adb_target) shell am broadcast --receiver-include-background -a "$@"; }

function keyevent() { do_execute adb $(get_adb_target) shell input keyevent "KEYCODE_$1"; }
function power() { keyevent POWER; }
function home() { adb $(get_adb_target) shell am start -a android.intent.action.MAIN -c android.intent.category.HOME -f 0x1400000; }

function dumpsys() { adb $(get_adb_target) shell dumpsys "$@"; }
function pm() { adb $(get_adb_target) shell pm "$@"; }
function am() { adb $(get_adb_target) shell am "$@"; }
function getprop() { adb $(get_adb_target) shell getprop "$@"; }
function setprop() { adb $(get_adb_target) shell setprop "$@"; }

function adb_time_set() {
    local DATE_STR
    printf -v DATE_STR '%(%Y-%m-%d %H:%M:%S)T' -1
    do_execute adb $(get_adb_target) shell "date -s '$DATE_STR'"
}

function adb_screen_capture() {
    local DATE
    printf -v DATE '%(%y%m%d_%H%M%S)T' -1
    adb $(get_adb_target) shell screencap -p > "adb_screen_capture_${DATE}.png"
    log -i "captured to adb_screen_capture_${DATE}.png"
}

function adb_target() {
    # 전역 설정 로드
    local env_path="${WORKSPACE_ROOT}/config/.default_env"
    [[ -f "$env_path" ]] && source "$env_path"

    local save=false
    local serial="$1"

    OPTIND=1
    while getopts "s:" option; do
        case "${option}" in
        s) save=true; serial="$OPTARG" ;;
        esac
    done
    shift $((OPTIND - 1))

    # IP 포맷 검사 및 포트 자동 보완
    if [[ "$serial" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}(:[0-9]+)?$ ]]; then
        local ip_addr="${serial%%:*}"
        local port="${serial#*:}"
        [[ "$port" == "$ip_addr" ]] && port="${DEFAULT_ADB_PORT:-5555}" 

        # 전역 설정된 PING_OPTS 사용 (OS 자동 대응)
        log -i "🌐 Testing connectivity to ${ip_addr}..."
        if ! ping ${PING_OPTS} "${ip_addr}" >/dev/null 2>&1; then
            log -w "⚠️  ${ip_addr} is not reachable. (OS: ${WORKSPACE_OS})"
        fi
        serial="${ip_addr}:${port}"
    fi

    log -i "🎯 Target device set to: ${serial}"
    
    if $save; then
        local path="${WORKSPACE_ROOT}/bin"
        [[ -n "${WORKSPACE_PROJECT}" ]] && path="${WORKSPACE_HOME}/.workspace_env/"
        log -d "Saving target to: ${path}/TARGET_IP"
        echo "$serial" > "${path}/TARGET_IP"
    fi
    export ANDROID_SERIAL="$serial"
}
