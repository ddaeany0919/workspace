#!/usr/bin/env bash

source common_bash.sh
ME=$(dirname "$0")

#
# fpm_startKeyExchangeProcess.sh
#  - 전달한 PIN, VIN 값으로 Vehicle HAL (BYTES property) 설정
#

set -e

function usage() {
    echo "Usage: ${ME} [--dry-run] [PIN] [VIN]"
    echo
    echo "Arguments:"
    echo "  PIN       6-digit hex string (default: 012345)"
    echo "            - Split into 3 parts: PIN1, PIN2, PIN3 (two hex digits each)"
    echo "            - Example: 012345 -> PIN1=0x01, PIN2=0x23, PIN3=0x45"
    echo "  VIN       Vehicle Identification Number (default: 1GCARVIN12345)"
    echo
    echo "Options:"
    echo "  --help    Show this help message"
    echo "  --dry-run Print the generated JSON and adb command without executing"
    echo
    echo "Examples:"
    echo "  ${ME}"
    echo "  ${ME} 012345 1GCARVIN12345"
    echo "  ${ME} A1B2C3 5YJ3E1EA7KF317000"
    echo "  ${ME} --dry-run 012345 1GCARVIN12345"
    exit 0
}

send_vehicle_cmd() {

      # 옵션 체크
    if [[ "$1" == "--help" ]]; then
      usage
      return 0
    fi

     if [[ "$1" == "--dry-run" ]]; then
        dry_run=1
        shift
    fi

    
    local prop_id=561000457  # PRTC_VEHICLE_FPM_KEY_LEARN_NEUTRALIZE_START_C
    # 기본값
    local pin="${1:-012345}"
    local vin="${2:-1GCARVIN12345}"

    # pin → 두 자리씩 잘라서 10진수로 변환
    local p1=$((16#${pin:0:2}))
    local p2=$((16#${pin:2:2}))
    local p3=$((16#${pin:4:2}))

    # pin → 두 자리씩 잘라서 10진수로 변환
    local p1=$((16#${pin:0:2}))
    local p2=$((16#${pin:2:2}))
    local p3=$((16#${pin:4:2}))

    # JSON 생성
    local json="{\"mode\":0,\"PIN1\":$p1,\"PIN2\":$p2,\"PIN3\":$p3,\"VIN\":\"$vin\"}"

    log "Generated JSON: $json"

    # JSON → hex 변환
    local hex=$(echo -n "$json" | xxd -p -c256)

    # 최종 adb 명령어
    local adb_cmd="adb shell dumpsys android.hardware.automotive.vehicle.IVehicle/default --send $prop_id -b 0x$hex"

    if [[ "$dry_run" == "1" ]]; then
        echo "command: $adb_cmd"
    else
        do_execute -i "$adb_cmd"
    fi
    
}

send_vehicle_cmd "$@"