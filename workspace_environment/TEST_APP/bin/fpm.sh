#!/bin/bash

source common_bash.sh
DEBUG=true
# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

declare -A FPM_PROPERTIES
# vendor/hmg/packages/services/Car/property/car-lib/src/hmg/car/hardware/property/VehicleConnectPropertyIds.java
FPM_PROPERTIES["START_PROFILE_ID"]=557877980
FPM_PROPERTIES["ENGINE_START_FAILED_POPUP"]=557877014
FPM_PROPERTIES["CLUSTER_BRIGHTNESS"]=557877016

FPM_PROPERTIES["ENGINE_START_DISABLE"]=557877015
FPM_PROPERTIES["ENGINE_START_ENABLE"]=557877015
FPM_PROPERTIES["ENGINE_START_DEFAULT"]=557877015
FPM_PROPERTIES["ENGINE_START_INVAILD"]=557877015
FPM_PROPERTIES["AUTH_RESULT"]=557877889
FPM_PROPERTIES["ENROLL_PROCESS_STATUS"]=557877879
FPM_PROPERTIES["ENROLL_PROCESS_PROGRESS"]=557877880
FPM_PROPERTIES["USER_01_ENABLED_SLOT"]=557943417
FPM_PROPERTIES["USER_02_ENABLED_SLOT"]=557943418
FPM_PROPERTIES["USER_03_ENABLED_SLOT"]=557943432
FPM_PROPERTIES["DELETE_PROCESS_STATUS"]=557877883
FPM_PROPERTIES["PROCESS_START"]=557877884
FPM_PROPERTIES["PROCESS_STOP"]=557877885
FPM_PROPERTIES["RANDOM_NUMBER"]=558926464
FPM_PROPERTIES["READY_TO_SEND"]=557877890
FPM_PROPERTIES["ISK_LEARNING_REQUEST"]=557877981
FPM_PROPERTIES["ISK_LEARNING_FEEDBACK"]=557877891
FPM_PROPERTIES["ISK_LEARNING_STATE"]=557877011
FPM_PROPERTIES["ENCRYPTED_DATA"]=558992007
FPM_PROPERTIES["H2PV_VALUE"]=557877983
FPM_PROPERTIES["LAMP_COLOR_PATTERN"]=557942572
FPM_PROPERTIES["LAMP_PATTERN"]=557877013
FPM_PROPERTIES["OPTION"]=557877878
FPM_PROPERTIES["ENCRYPTION_DATA_C"]=561000459
FPM_PROPERTIES["ENROLL_START"]=561000459
FPM_PROPERTIES["ENROLL_STOP"]=561000459
FPM_PROPERTIES["LEARN_NEUTRALIZE_START_C"]=561000457
FPM_PROPERTIES["ISK_LEARNING"]=561000457
FPM_PROPERTIES["ISK_NEUTRALIZING"]=561000457
FPM_PROPERTIES["AUTHENTICATE_START"]=557877884
FPM_PROPERTIES["AUTHENTICATE_STOP"]=557877885

keys=("${!FPM_PROPERTIES[@]}")
values=("${FPM_PROPERTIES[@]}")

adb_command="adb shell dumpsys android.hardware.automotive.vehicle.IVehicle/default"

function callMicom() {
    local adb_cmd="adb shell dumpsys vendor.mobis.hardware.interfaces.automotive.micomcommunication.IMicomCommunication/default"
    local option=("$@")
    log -d "Calling Micom with command: ${adb_cmd} ${option[*]}"
    do_execute -i "${adb_cmd} ${option[*]}"
}

function CLUSTER_BRIGHTNESS() {
    local action="--set"
    local brightness="${1:-200}"
    local propId=${FPM_PROPERTIES["CLUSTER_BRIGHTNESS"]}
    local option="-i ${brightness}"
    do_execute -i "${adb_command} ${action} ${propId} ${option}"
}

function ENGINE_START_FPM() {
    local action="--set"
    local propId=${FPM_PROPERTIES["ENGINE_START_ENABLE"]}
    local option="-i ${1:-2}"
    do_execute -i "${adb_command} ${action} ${propId} ${option}"
}

function ENGINE_START_VHAL() {

     action="--receive"
    
    #ff 40 95 02 c0 03 00 2d 49 01 08 ff 04 4d 10 01 02 0a 75 10 01 02 5a
    #ff 40 95 02 c0 03 00 2d 49 01 08 ff 
    local rawHeader="ff 40 95 02 c0 03 00 0a 49 01 08 ff"
    
    #04 4d 10 01 
    local id="04 4d 10 01 "
    # $ARG 
    local value="$1"
    #0a 75 10 01 02 5a
    local unknown="0a 75 10 01 02 5a"
    local rawValue="${rawRed} ${id} ${value} ${unknown}"
    
    local bytesValue=$(echo ${rawHeader} ${rawValue} | sed 's/ / 0x/g; s/^/0x/')

    callMicom ${action} ${bytesValue}

    # local action="--set"
    # local propId="0x00000095 0x00000040 0x00000002"
    # local option="0x00000040 0x00000005 0x00000000 0x00000002 0x00000004 0x000000$(printf '%02x' ${1:-2})"
    # do_execute -i "adb shell dumpsys vendor.mobis.hardware.interfaces.automotive.micomcommunication.IMicomCommunication/default ${action} ${propId} ${option}"
}

function ENGINE_START() {

    local directVhal=false
    if [ "$directVhal" = true ]; then
        ENGINE_START_VHAL "$1"
    else
        ENGINE_START_FPM "$1"
    fi
   
}

function ENGINE_START_DEFAULT() {
    ENGINE_START "-2"
}

function ENGINE_START_DISABLE() {
    ENGINE_START "0"
}

function ENGINE_START_ENABLE() {
    ENGINE_START "1"
}

function ENGINE_START_INVALID() {
    ENGINE_START "-1"
}

# function ISK_LEARNING() {
#     local action="--send"
#     local propId=${FPM_PROPERTIES["LEARN_NEUTRALIZE_START_C"]}

#     local req="${1:-1}"

#     local option="-i ${req}"

#     do_execute -i "${adb_command} ${action} ${propId} ${option}"
# }

function AUTHENTICATE_START() {
    PROCESS_START 1
}

function AUTHENTICATE_STOP() {
    PROCESS_STOP 1
}

function LAMP_PATTERN() {
    local propId=${FPM_PROPERTIES["LAMP_PATTERN"]}
    local pattern="${1:-2}"
    local action="--send"
    local option="-i ${pattern}"
    do_execute -i "${adb_command} ${action} ${propId} ${option}"
}

function LAMP_COLOR_PATTERN() {
    # LAMP_PATTERN 0
    local propId=${FPM_PROPERTIES["LAMP_COLOR_PATTERN"]}
    # default color=random (0~255)
    local red="${1:-$((RANDOM % 256))}"
    local green="${2:-$((RANDOM % 256))}"
    local blue="${3:-$((RANDOM % 256))}"
    local alpha="${4:-255}"
    local pattern="${5:-2}"
    local action="--send"
    local option="-i ${red} ${green} ${blue} ${pattern}"
    
    local directVhal=false
    if [ "$directVhal" = true ]; then
        # 95 40 02 40 05 00 02 04 ff
        local rawHeader="ff 95 40 02 40 05 00 02 04 ff"
        # local propColorId="04 ff"
        local rawPrefix="00 00 00"
        local rawRed="03 7c ${rawPrefix} $(printf '%02x' ${red})"
        local rawGreen="03 7f ${rawPrefix} $(printf '%02x' ${green})"
        local rawBlue="03 7d ${rawPrefix} $(printf '%02x' ${blue})"
        local rawPattern="03 7e ${rawPrefix} $(printf '%02x' ${pattern})"
        local rawValue="${rawRed} ${rawGreen} ${rawBlue} ${rawPattern}"
        # local length=$(echo -n "${rawValue}" | wc -w)
        local length=4
        local rawLength=$(printf '%02x' ${length})
        local bytesValue=$(echo ${rawHeader} ${rawValue} | sed 's/ / 0x/g; s/^/0x/')
        callMicom ${action} "${bytesValue}"
        # do_execute -i "adb shell dumpsys vendor.mobis.hardware.interfaces.automotive.m"
    else
        do_execute -i "${adb_command} ${action} ${propId} ${option}"
    fi
    # LAMP_PATTERN 2
}

function PROCESS_START() {
    local action="--send"
    local propId=${FPM_PROPERTIES["PROCESS_START"]}
    
    local req="${1:-1}"
    
    local option="-i ${req}"
    
    do_execute -i "${adb_command} ${action} ${propId} ${option}"
}

function PROCESS_STOP() {
    local action="--send"
    local propId=${FPM_PROPERTIES["PROCESS_STOP"]}
    
    local req="${1:-1}"
    
    local option="-i ${req}"
    
    do_execute -i "${adb_command} ${action} ${propId} ${option}"
    
}

function ENROLL_START() {
    local action="--send"
    local valueType="-b"
    local propId=${FPM_PROPERTIES["ENCRYPTION_DATA_C"]}
    
    local user="${1:2}"
    local finger="${2:0}"
    
    # if [ "$user" -gt 1 ]; then
    #     finger=$((finger + 3))
    # fi
    # zero padding prefix 8 digits
    local value=$(printf "0x%016x" "$finger")
    
    do_execute -i "${adb_command} ${action} ${propId} ${valueType} ${value}"
    # do_execute -i "adb shell dumpsys vendor.mobis.hardware.interfaces.automotive.micomcommunication.IMicomCommunication/default --send 0xff 0x94 0x03 0x01 0x03 0x14 0x00 0x09 0x01 0x00 0x00 0x00 0x00 0x00 0x00 0x00"
    READY_TO_SEND 1
    sleep 0.1
    READY_TO_SEND 0
}

function ENROLL_STOP() {
    READY_TO_SEND 0
}

function READY_TO_SEND() {
    
    local propId=${FPM_PROPERTIES["READY_TO_SEND"]}
    local option="${1:-0}"
    # option 이 0 이면 --set, 0이 아니면 --send
    local action="--send"
    local valueType="-i"
    if [ "$option" -ne 0 ]; then
        action="--send"
    fi
    
    
    
    # log -d "FPM_READY_TO_SEND - action : $action"
    # log -d "FPM_READY_TO_SEND - command: $adb_command  ${action} ${propId} ${option}"
    do_execute -i "${adb_command} ${action} ${propId} ${valueType} ${option}"
    
}

function main() {
    local executeFunc=("")
    local args=("$@")
    for arg in "${args[@]}"; do
        case "$arg" in
            -h)
                echo "Usage: $0 [options]"
                echo "Options:"
                echo "  -h        Show this help message"
                exit 0
            ;;
            -l)
                for key in "${!FPM_PROPERTIES[@]}"; do
                    echo "$key"
                done
                exit 0
            ;;
            *)
                # 만일 opt 이름의 function 이 존재하면 해당 function 이름 추가
                if declare -f $arg > /dev/null; then
                    log -d "Scheduling function: $arg"
                    executeFunc+=("$arg")
                    continue
                    # elif [
                    # if FPM_PROPERTIES["$arg"] ]; then
                    #     log -i "Scheduling function: $arg"
                    #     executeFunc+=("$arg")
                    #     continue
                    # 이전에 function이 executeFunc 배열에 추가되었다면 해당 function의 arguements 로 추가
                    elif [[ ${#executeFunc[@]} -gt 0 ]]; then
                    log -d "Adding argument to function: $arg"
                    lastIndex=$((${#executeFunc[@]} - 1))
                    executeFunc[$lastIndex]="${executeFunc[$lastIndex]} $arg"
                    continue
                else
                    log -e "No such function: $arg"
                    exit 1
                fi
                
            ;;
            
        esac
    done
    
    if [ ${#executeFunc[@]} -gt 1 ]; then
        for func in "${executeFunc[@]}"; do
            eval ${func}
        done
    fi
}

main $@
