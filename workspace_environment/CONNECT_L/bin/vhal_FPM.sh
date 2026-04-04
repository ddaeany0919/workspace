#!/bin/bash


# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

declare -A FPM_PROPERTIES
# vendor/hmg/packages/services/Car/property/car-lib/src/hmg/car/hardware/property/VehicleConnectPropertyIds.java
FPM_PROPERTIES["FPM_START_PROFILE_ID"]=557877980
FPM_PROPERTIES["FPM_ENGINE_START_FAILED_POPUP"]=557877014
FPM_PROPERTIES["FPM_ENGINE_START_ENABLE"]=557877015
FPM_PROPERTIES["FPM_AUTH_RESULT"]=557877889
FPM_PROPERTIES["FPM_ENROLL_PROCESS_STATUS"]=557877879
FPM_PROPERTIES["FPM_ENROLL_PROCESS_PROGRESS"]=557877880
FPM_PROPERTIES["FPM_USER_01_ENABLED_SLOT"]=557943417
FPM_PROPERTIES["FPM_USER_02_ENABLED_SLOT"]=557943418
FPM_PROPERTIES["FPM_DELETE_PROCESS_STATUS"]=557877883
FPM_PROPERTIES["FPM_PROCESS_START"]=557877884
FPM_PROPERTIES["FPM_PROCESS_STOP"]=557877885
FPM_PROPERTIES["FPM_RANDOM_NUMBER"]=558926464
FPM_PROPERTIES["FPM_READY_TO_SEND"]=557877890
FPM_PROPERTIES["FPM_ISK_LEARNING_REQUEST"]=557877981
FPM_PROPERTIES["FPM_ISK_LEARNING_FEEDBACK"]=557877891
FPM_PROPERTIES["FPM_ISK_LEARNING_STATE"]=557877011
FPM_PROPERTIES["FPM_ENCRYPTED_DATA"]=558992007
FPM_PROPERTIES["FPM_H2PV_VALUE"]=557877983
FPM_PROPERTIES["FPM_LAMP_COLOR"]=557942548
FPM_PROPERTIES["FPM_LAMP_PATTERN"]=557877013
FPM_PROPERTIES["FPM_OPTION"]=557877878

keys=("${!FPM_PROPERTIES[@]}")
values=("${FPM_PROPERTIES[@]}")

adb_command="adb shell dumpsys android.hardware.automotive.vehicle.IVehicle/default"

function parse_vehicle_output() {
    printf "%-35s | %-12s | %s\n" "Property Name" "Prop ID" "Value"
    printf -- "------------------------------------+--------------+-------------------------\n"

    while IFS= read -r line; do
        if [[ $line =~ prop:\ ([0-9]+) ]]; then
            prop_id="${BASH_REMATCH[1]}"
            key=""
            for k in "${!FPM_PROPERTIES[@]}"; do
                if [[ "${FPM_PROPERTIES[$k]}" == "$prop_id" ]]; then
                    key="$k"
                    break
                fi
            done

            # 값 추출
            if [[ $line =~ int32Values:\ \[([^]]*)\] ]]; then
                value="${BASH_REMATCH[1]}"
            elif [[ $line =~ int64Values:\ \[([^]]*)\] ]]; then
                value="${BASH_REMATCH[1]}"
            elif [[ $line =~ stringValue:\ (.*)\} ]]; then
                value="${BASH_REMATCH[1]}"
            else
                value="(no value)"
            fi

            # 색상 선택
            color=$GREEN
            [[ "$value" == *"-2"* ]] && color=$YELLOW

            printf "%-35s | %-12s | ${color}%s${NC}\n" "${key:-UNKNOWN_PROP}" "$prop_id" "$value"

        elif [[ $line =~ failed\ to\ read\ property\ value:\ ([0-9]+) ]]; then
            prop_id="${BASH_REMATCH[1]}"
            key=""
            for k in "${!FPM_PROPERTIES[@]}"; do
                if [[ "${FPM_PROPERTIES[$k]}" == "$prop_id" ]]; then
                    key="$k"
                    break
                fi
            done
            printf "%-35s | %-12s | ${RED}ERROR: NOT_AVAILABLE${NC}\n" "${key:-UNKNOWN_PROP}" "$prop_id"
        fi
    done
}


function dump_properties() {
    local propKeys=("$@")
    if [ ${#propKeys[@]} -eq 0 ]; then
        propKeys=("${keys[@]}")
    fi

    # make a list to gether values
    local propValues=()
    for key in "${propKeys[@]}"; do
        propValues+=("${FPM_PROPERTIES[$key]}")
    done
    # echo -e "\nFPM Properties:"
    # echo "Key : Value"
    # echo "---------------------"
    # paste <(printf '%s\n' "${propKeys[@]}") <(printf '%s\n' "${propValues[@]}") | column -t -s $'\t'
    # echo -e "\nValues:"
    # get values from adb command
    ${adb_command} --get ${propValues[*]} | parse_vehicle_output
    
}

function main() {

    # check arguments
    if [ $# -eq 0 ]; then
        dump_properties FPM_OPTION FPM_ENGINE_START_ENABLE FPM_START_PROFILE_ID FPM_AUTH_RESULT FPM_ENROLL_PROCESS_STATUS FPM_ENROLL_PROCESS_PROGRESS FPM_USER_01_ENABLED_SLOT FPM_USER_02_ENABLED_SLOT FPM_DELETE_PROCESS_STATUS FPM_PROCESS_START FPM_PROCESS_STOP FPM_RANDOM_NUMBER FPM_READY_TO_SEND FPM_ISK_LEARNING_REQUEST FPM_ISK_LEARNING_FEEDBACK FPM_ISK_LEARNING_STATE FPM_ENCRYPTED_DATA FPM_H2PV_VALUE FPM_LAMP_COLOR FPM_LAMP_PATTERN
        exit 0
    fi

    
    getopts "hg:" opt
    case $opt in
        h)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  -h        Show this help message"
            exit 0
            ;;
        g)
            ;;
        *)
            dump_properties $(echo $OPTARG | tr ',' ' ')
            exit 0
            ;;
    esac
    
    
}

main $@
