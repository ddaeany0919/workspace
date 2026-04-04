export logcat_opt="-v threadtime -b all -r 500000 -n 50"
export USB_DIR=`mount | grep vfat | cut -d" " -f3`
export date_day=`date "+%Y%m%d"`
export date="${date_day}`date "+_%H%M%S"`"
export dir="$USB_DIR/hdmi_aging_${date_day}"
export log_file="${dir}/${date}.log "
mkdir $dir
echo "ps -ef | grep \"${dir}\" | grep -v \"grep\" | cut -d\" \" -f10"
export logcat_pid=`ps -ef | grep "${dir}" | grep -v "grep" | cut -d" " -f10`
echo "logcat pid=(${logcat_pid})"
if [ "${logcat_pid}" != "" ]; then
    echo "######## kill previous commands (${logcat_pid})"
    kill -9 ${logcat_pid}
fi

logcat ${logcat_opt} -f ${log_file} &
cp /dev/tzlogger ${dir}/${date}_tzlogger.txt &
