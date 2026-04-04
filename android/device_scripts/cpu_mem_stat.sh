#!/system/bin/sh
 
NAME="none"
LOOP_MAX=1
SLEEP=1
DISABLE_AVERAGE_PRINT=
COUNT=0
SUM_CPU_IDLE=0
SUM_MEM_FREE=0
 
# check cpu idle and meminfo
UT_CPU=
UT_MEM=
 
CURRENT_DATE=$(/system/bin/date +%Y%m%d)
IT_TEST= # Integration Testing
UT_TEST= # Unit Testing
 
# default path
RESULT_PATH=/data
# result file
# SSC (System Stability Checker)
RESULT_PREFIX=SSC
CPU_MEM_FILE=cpu_mem_stat
DUMPSYS_FILE=dumpsys_meminfo
IT_CPU_MEM_STAT_FILE=
IT_DUMPSYS_FILE_FILE=
UT_CPU_MEM_STAT_FILE=
UT_DUMPSYS_FILE_FILE=
 
print_help() {
    echo '============================================================================='
    echo 'Usage: '
    echo './cpu_mem_stat.sh [-u | -i date] [-p project_name] [-n name] [-l loop_count] [-s sleep_count] [-cm] [-d disable_average_print]'
    echo '  -[u|i] : set Unit Testing or Integration Testing mode'
    echo "         : if you set the IT mode, then the date argument is needed for created file name such as '20211025'."
    echo '  -p     : set project name'
    echo '  -n     : set name such as livetv, home, youtube, netflix and others'
    echo '  -l     : set loop count'
    echo '  -s     : set sleep(delay) seconds for each check'
    echo "  -cm    : [option] set only to check cpu or mem such as -c, -m or -cm"
    echo "           if '-cm' is not set, then cpu and mem check are set by default. "
    echo "  -d     : [option] if '-d' is set, then the average values for cpu idle and free memory are not calculated."
    echo ''
    echo 'ex > ./cpu_mem_stat.sh -u -p UCW4046MEG -n livetv -l 100 -s 10     // cpu and mem'
    echo '     ./cpu_mem_stat.sh -u -p UCW4046MEG -n livetv -l 100 -s 10 -c  // only cpu'
    echo '     ./cpu_mem_stat.sh -u -p UCW4046MEG -n livetv -l 100 -s 10 -m  // only mem'
    echo ''
    echo 'If the usb stick is plugged in, it is in the usb root or in the /data folder.'
    echo ' - SSC_<UT|IT>_${project_name}_${name}_cpu_mem_stat_<$date>.csv'
    echo ' - SSC_<UT|IT>_${project_name}_${name}_dumpsys_meminfo_<$date>.txt'
    echo '============================================================================='
    exit 1;
}
 
if [ $# -ne "$NO_ARGS" ]; then
    while getopts ":p:n:l:s:i:cmdu" Option
    do
        case $Option in
            p )
                PROJECT_NAME=$OPTARG;;
            n )
                NAME=$OPTARG;;
            l )
                LOOP_MAX=$OPTARG;;
            s )
                SLEEP=$OPTARG;;
            d )
                DISABLE_AVERAGE_PRINT=1;;
            i )
                IT_TEST=1
                CURRENT_DATE=$OPTARG;;
            u )
                UT_TEST=1;;
            c )
                UT_CPU=1;;
            m )
                UT_MEM=1;;
            \? )
                echo "ERR : Invalid option: -$OPTARG"
                print_help
                ;;
            : )
                echo "ERR : Option -$OPTARG requires an argument."
                print_help
                ;;
            * )
                print_help
                ;;
        esac
    done
fi
 
 
if [ -z "$UT_CPU" ] && [ -z "$UT_MEM" ]; then
    UT_CPU=1
    UT_MEM=1   
fi
 
if [ -z "$IT_TEST" ] && [ -z "$UT_TEST" ]; then
    print_help
elif [ -z "$PROJECT_NAME" ] || [ -z "$NAME" ] || [ -z "$LOOP_MAX" ] || [ -z "$SLEEP" ]; then
    print_help
fi
 
#=============================================================================================================
# USB detect
#=============================================================================================================
count=0
/system/bin/df | /system/bin/grep media_rw | /system/bin/grep -v block | /system/bin/cut -d ' ' -f 1  > /data/usbname.txt
USBNAME=("" "")
while read USBNAME[$count]; do
    ((count=count+1))
    usleep 1
done < /data/usbname.txt
rm /data/usbname.txt
 
if [ -n "${USBNAME[0]}" ]; then
    RESULT_PATH="${USBNAME[0]}"
fi
#=============================================================================================================
 
# make SSC output file name
if [ -n "$IT_TEST" ]; then
    IT_CPU_MEM_STAT_FILE="$RESULT_PATH/${RESULT_PREFIX}_${PROJECT_NAME}_IT_${CPU_MEM_FILE}_${CURRENT_DATE}.csv"
    IT_DUMPSYS_FILE_FILE="$RESULT_PATH/${RESULT_PREFIX}_${PROJECT_NAME}_IT_${DUMPSYS_FILE}_${CURRENT_DATE}.txt"
fi
UT_CPU_MEM_STAT_FILE="$RESULT_PATH/${RESULT_PREFIX}_${PROJECT_NAME}_UT_${NAME}_${CPU_MEM_FILE}_${CURRENT_DATE}.csv"
UT_DUMPSYS_FILE_FILE="$RESULT_PATH/${RESULT_PREFIX}_${PROJECT_NAME}_UT_${NAME}_${DUMPSYS_FILE}_${CURRENT_DATE}.txt"
 
dump_result_to_it_file() {
    if [ -n "$UT_CPU" ]; then
        # dump cpu, mem info
        echo $CSV_PRINT >> $IT_CPU_MEM_STAT_FILE
    fi
    if [ -n "$UT_MEM" ]; then
        # dump dumpsys meminfo
        echo "==================================================================" >> $IT_DUMPSYS_FILE_FILE
        echo "$NAME, $S_TIME" >> $IT_DUMPSYS_FILE_FILE
        echo "==================================================================" >> $IT_DUMPSYS_FILE_FILE
        cat /data/dumpsys_meminfo.txt >> $IT_DUMPSYS_FILE_FILE
    fi 
}
 
dump_result_to_ut_file() {
    if [ -n "$UT_CPU" ]; then
        # dump cpu, mem info
        echo $CSV_PRINT >> $UT_CPU_MEM_STAT_FILE
    fi
    if [ -n "$UT_MEM" ]; then
        # dump dumpsys meminfo
        echo "==================================================================" >> $UT_DUMPSYS_FILE_FILE
        echo "$NAME, $S_TIME" >> $UT_DUMPSYS_FILE_FILE
        echo "==================================================================" >> $UT_DUMPSYS_FILE_FILE
        cat /data/dumpsys_meminfo.txt >> $UT_DUMPSYS_FILE_FILE
        rm -rf /data/dumpsys_meminfo.txt
    fi
}
 
# set 0 for printk level
echo 0 > /proc/sys/kernel/printk
 
while [ $COUNT -lt $LOOP_MAX ]; do                    
    S_TIME=$(/system/bin/date +%Y-%m-%d' '%H:%M:%S)
 
    IDLE_USAGE=0
    if [ -n "$UT_CPU" ]; then
        # check cpu idle
        vmstat 1 2 > /data/vmstat.txt
        VM_INFO=(`cat /data/vmstat.txt | sed -n '4p'`)
        IDLE_USAGE="${VM_INFO[14]}"
        rm -rf /data/vmstat.txt
    fi 
 
    TOTAL_MEM=0
    USED_MEM=0
    FREE_MEM=0
    if [ -n "$UT_MEM" ]; then
        # execute dumpsys meminfo
        /system/bin/dumpsys -t 60 meminfo > /data/dumpsys_meminfo.txt
        MEM=(`cat /data/dumpsys_meminfo.txt | grep 'Total RAM'`)
        TOTAL_MEM=$(echo ${MEM[2]} | sed -e 's/,//g' -e 's/K//g')
        MEM=(`cat /data/dumpsys_meminfo.txt | grep 'Used RAM'`)
        USED_MEM=$(echo ${MEM[2]} | sed -e 's/,//g' -e 's/K//g')
        MEM=(`cat /data/dumpsys_meminfo.txt | grep 'Free RAM'`)
        FREE_MEM=$(echo ${MEM[2]} | sed -e 's/,//g' -e 's/K//g')
    fi
     
    if [ -n "$FREE_MEM" ]; then
        echo "$S_TIME CPU Load idle: $IDLE_USAGE %, Mem total: $TOTAL_MEM KB, used: $USED_MEM KB, free: $FREE_MEM KB, Temperature: `cat /sys/class/thermal/thermal_zone0/temp|cut -c 1-2` on $NAME"
        CSV_PRINT="$S_TIME, $NAME, CPU Load idle, $IDLE_USAGE, Mem total, $TOTAL_MEM, KB, used, $USED_MEM, KB, free, $FREE_MEM, KB, Temperature, `cat /sys/class/thermal/thermal_zone0/temp|cut -c 1-2`"
        let COUNT++
        let "SUM_CPU_IDLE=$SUM_CPU_IDLE+$IDLE_USAGE"
        let "SUM_MEM_FREE=$SUM_MEM_FREE+$FREE_MEM"
        if [ -n "$IT_TEST" ]; then
            dump_result_to_it_file;
        fi
        dump_result_to_ut_file;
    fi 
 
    sleep $SLEEP
done
 
if [ -z "$DISABLE_AVERAGE_PRINT" ]; then
    let "AVERAGE_CPU_IDLE=$SUM_CPU_IDLE/$COUNT"
    let "AVERAGE_MEM_FREE=$SUM_MEM_FREE/$COUNT"
    echo "======================================================================"        | tee -a $UT_CPU_MEM_STAT_FILE
    if [ -n "$UT_CPU" ] && [ -n "$UT_MEM" ]; then
        echo "Average CPU Load idle: $AVERAGE_CPU_IDLE %, freeMem: $AVERAGE_MEM_FREE KB" | tee -a $UT_CPU_MEM_STAT_FILE
    elif [ -n "$UT_CPU" ]; then
        echo "Average CPU Load idle: $AVERAGE_CPU_IDLE %"                                | tee -a $UT_CPU_MEM_STAT_FILE
    elif [ -n "$UT_MEM" ]; then
        echo "Average freeMem: $AVERAGE_MEM_FREE KB"                                     | tee -a $UT_CPU_MEM_STAT_FILE
    fi
    echo "======================================================================"        | tee -a $UT_CPU_MEM_STAT_FILE
fi