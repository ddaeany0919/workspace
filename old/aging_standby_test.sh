common_file="aging_common.sh"
if [ ! -f "${common_file}" ]; then
    echo "###### Must necessary common file (${common_dir})"
    exit 1
fi
source ${common_file}

function prepare{
    ampdiag setmodl DISPSRV 255
}

function run{
    while true; do 
        input keyevent KEYCODE_POWER;
        sleep 5;
    done
}

prepare
run
