#!/bin/bash
source common_android.sh;



# # 명령 실행 결과를 배열에 저장
# mapfile -t keywords < <(adb shell cmd mobisvariant get-variant-keys)

# # 하나씩 꺼내서 실행
# for key in "${keywords[@]}"; do
#     echo "실행중: $key"
#     # 여기에 원하는 명령 실행
#     adb shell cmd mobisvariant get-variant-value "$key"
# done

function usage() {
    echo "Usage: $0 [keyword1 keyword2 ...]"
    echo "If no keywords are provided, all variant keys will be fetched."
    echo "--list : List all available variant keys"
    
}

function get_var() {
    local keywords=("$@")
    if [ ${#keywords[@]} -eq 0 ]; then
        mapfile -t keywords < <(adb shell cmd mobisvariant get-variant-keys)
    fi

    for key in "${keywords[@]}"; do
        # echo -e "\n$key:"
        # trim whitespace
        key=$(echo "$key" | xargs)
        cmd="adb shell cmd mobisvariant get-variant-value \"$key\""
        log -i "${cmd}"
        value=$(eval $cmd)
        log -i "${key} : ${value}"
    done
}

function main() {
    # check arguments
    if [ "$#" -eq 0 ]; then
        get_var
    fi

    local args=("$@")
    getopts=$(getopt -o l --long list -- "$@")
    eval set -- "$getopts"
    while true; do
        case "$1" in
            -l|--list)
                echo "Available variant keys:"
                for key in "${keywords[@]}"; do
                    get_var "$key"
                done
                shift
                ;;
            --)
                shift
                break
                ;;
            *)
                echo "Invalid option: $1"
                usage
                exit 1
                ;;
        esac
    done
    

}

main "$@"