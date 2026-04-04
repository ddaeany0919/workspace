#!/usr/bin/env bash
source common_bash.sh
#### STEP 1 : Declare variables ########################################################################################
DEBUG=false;

CONFIG_USE_SSH=true
PRODUCT_NAME=ute7057lgu

#REMOTE="sskim@localhost"
REMOTE="build"
REMOTE_BASE="~/UTE7057LGU"
REMOTE_OUT_FILES=""
REMOTE_OUT="$REMOTE_BASE/out/target/product/$PRODUCT_NAME"

HOST_PATH="$PWD/9.etc/fastboot_binaries"
#FASTBOOT="$ANDROID_PLATFORM_TOOLS/fastboot";
FASTBOOT="fastboot";
FASTBOOT_OPTS="";
INT_OPTIONS="yht:p:dbir-:";

sync_images=false;
execute_build=false;
execute_reboot=true;
transport_tcp=false;

TARGET_IP=$(/bin/cat $WORKSPACE/bin/.TARGET_IP);

############ DEFAULT_CONFIG ############
HOST_PATH="0.android/q-amlogic-20200507-gtvs/out/target/product/TBBTV01"

declare -A flash_01=([name]="product"             [cmd]="flash"   [bin]="product.img"       )
declare -A flash_02=([name]="dtbo"             [cmd]="flash"   [bin]="dtbo.img"       )
declare -A flash_03=([name]="vbmeta"             [cmd]="flash"   [bin]="vbmeta.img"       )
#declare -A flash_04=([name]="logo"             [cmd]="flash"   [bin]="logo.img"       )
declare -A flash_05=([name]="boot"             [cmd]="flash"   [bin]="boot.img"       )
declare -A flash_06=([name]="super"             [cmd]="flash"   [bin]="super.img"       )
declare -A flash_07=([name]="recovery"             [cmd]="flash"   [bin]="recovery.img"       )
declare -A flash_99=([name]=""                     [cmd]="reboot"                             )

if $CONFIG_USE_SSH; then
  SOURCE_PATH="$REMOTE:$REMOTE_OUT/{$REMOTE_OUT_FILES}"
else
  SOURCE_PATH="$REMOTE_OUT/{$REMOTE_OUT_FILES}"
fi

SAMPLE_COMMAND="ifconfig eth1 -addr=$TARGET_IP mask=255.255.255.0 -gw=192.168.50.1;boot -elf -noclose -bsu flash0.BSU1; android fastboot -transport=tcp -device=flash0"

function usage() {
    log -i "Enter the command : \n\t$SAMPLE_COMMAND\n\n"
    log -v "ARGS are \"$INT_OPTIONS\""
    log -v "\t-h \t usage"
    log -v "\t--debug \t turn on debug flag"
    log -v "\t-b \t execute build"
    log -v "\t-i \t ignore reboot"
    log -v "\t-y \t sync images from output directory [$SOURCE_PATH]"
    log -v "\t-t \t Ip address of target device [$TARGET_IP]"
    log -v "\t-p \t Set path of images"
    log -v "SYNOPSYS"
    log -v "\t./fashboot.sh -s"
    log -v "\t./fashboot.sh -t $TARGET_IP"
    log -v "===================================================================================================="
    local cmd=""
    declare -n item
    for item in ${!flash@}; do
      cmd=${item[cmd]}

      if [ ! -z "${cmd}" ]; then
        if [ "flash" == ${cmd} ]; then
          log -v "\t$FASTBOOT $FASTBOOT_OPTS ${item[cmd]} ${item[name]} $HOST_PATH/${item[bin]}"
        elif [ "" != ${item[cmd]} ]; then
          log -v "\t$FASTBOOT $FASTBOOT_OPTS ${item[cmd]} ${item[name]}";
        fi
      fi
    done;
}
########################################################################################################################
while getopts "$INT_OPTIONS" opt; do
    if $DEBUG ; then
        log -d "opt=$opt"
    fi
    case "${opt}" in
        -)
            case "${OPTARG}" in
                debug)
                    DEBUG=true;
                ;;
                *)
                    help
                    exit 2
                ;;
            esac
            ;;
    	  r)
    		    transport_tcp=true;
    		    ;;
        b)
            execute_build=true;
    	      ;;
        y)
            sync_images=true;
            ;;
        i)
            execute_reboot=false;
            ;;
        h)
            usage;
            exit 0;
            ;;
        t)
            TARGET_IP=$OPTARG
            ;;
        p)
            HOST_PATH=$OPTARG
            ;;
        \?)
            log -e "Invalid option: -$OPTARG"
            exit 1
            ;;
        :)
            log -e "Option -$OPTARG requires an argument."
            exit 1
            ;;
    esac
done
shift $(($OPTIND - 1))

ARGS=( "$@" )

########################################################################################################################

# make file list to get from remote server
declare -n item
for item in ${!flash@}; do
    if $DEBUG ; then
      log -d "name: ${item[name]}"
    fi

    if [ ! -z "${item[bin]}" ]; then
        if [[ $REMOTE_OUT_FILES != *"${item[bin]}"* ]]; then
            if [[ -z "$REMOTE_OUT_FILES" ]]; then
              REMOTE_OUT_FILES="${item[bin]}"
            else
              REMOTE_OUT_FILES+=",${item[bin]}"
            fi
        fi
    fi
done

if $DEBUG ; then
  log -d "REMOTE_OUT_FILES: $REMOTE_OUT_FILES"
fi

if [ -z "$TARGET_IP" ]; then
    log -w "TARGET_IP is empty!!"
    usage;
    exit 1;
fi

if $DEBUG ; then
    log -d "#####  ARGS= \t$ARGS"
    log -d "#####  TARGET_IP= \t$TARGET_IP"
    log -d "#####  FILES= \t\t$REMOTE_OUT_FILES"
    if $transport_tcp; then
        log -d "#####  TRANSPORT= \tUSB"
    else
        log -d "#####  TRANSPORT= \tDEVICE"
    fi
fi

log -i "Enter the command : $SAMPLE_COMMAND\n\n"

if $transport_tcp; then
    FASTBOOT_OPTS="-s tcp:$TARGET_IP"
    SAMPLE_COMMAND="ifconfig eth0 -addr=$TARGET_IP mask=255.255.255.0 -gw=192.168.50.1;boot -elf -noclose -bsu flash0.BSU1; android fastboot -transport=tcp -device=flash0"
fi

# if $execute_build; then
#     command="cd $REMOTE_BASE/vendor/taurus/build/ &&\
#                    source prepare_taurus.sh tbroad && \
#                    cd ../../../ && \
#                    make installclean && \
#                    make -j20"
#     if $CONFIG_USE_SSH; then
#       ssh $REMOTE "$command"
#     else
#       eval $command
#     fi
# fi

if $sync_images; then
	if [ ! -d $HOST_PATH ]; then
		mkdir -p $HOST_PATH
	fi
  if $CONFIG_USE_SSH; then
    do_execute -i "/usr/bin/scp $REMOTE:$REMOTE_OUT/{$REMOTE_OUT_FILES} $HOST_PATH "
  else
    do_execute -i "cp $REMOTE:$REMOTE_OUT/{$REMOTE_OUT_FILES} $HOST_PATH "
  fi
fi

declare -n item
for item in ${!flash@}; do
  item_name=${item[name]}
    if [ ! -z "${item[cmd]}" ]; then
      if [ "$#" -eq 0 ]; then
        if [ "flash" == ${item[cmd]} ]; then
          do_execute -i "$FASTBOOT $FASTBOOT_OPTS ${item[cmd]} ${item[name]} $HOST_PATH/${item[bin]}"
        fi
      elif [ "$#" -eq 1 ]; then
        if [[ "${item[name]}" == *"$ARGS"* ]]; then
          if [ ! -z "${item[bin]}" ]; then
            bin=$HOST_PATH/${item[bin]};
          else
            bin=""
          fi
          do_execute -i "$FASTBOOT $FASTBOOT_OPTS ${item[cmd]} ${item[name]} $bin"
        fi
      else
        for arg in "${ARGS[@]}"; do
          if [[ "${item[name]}" == *"$arg"* ]]; then
            if [ ! -z "${item[bin]}" ]; then
              bin=$HOST_PATH/${item[bin]};
            else
              bin=""
            fi
            do_execute -i "$FASTBOOT $FASTBOOT_OPTS ${item[cmd]} ${item[name]} $bin"
          fi
        done
      fi
    fi
done

do_execute -i "$FASTBOOT $FASTBOOT_OPTS reboot";

# do_execute -i "$FASTBOOT $FASTBOOT_OPTS flash boot_i $HOST_PATH/boot.img"
# do_execute -i "$FASTBOOT $FASTBOOT_OPTS flash boot_e $HOST_PATH/boot.img"
# do_execute -i "$FASTBOOT $FASTBOOT_OPTS flash vendor_i $HOST_PATH/vendor.img"
# do_execute -i "$FASTBOOT $FASTBOOT_OPTS flash vendor_e $HOST_PATH/vendor.img"
# do_execute -i "$FASTBOOT $FASTBOOT_OPTS flash system_i $HOST_PATH/system.img"
# do_execute -i "$FASTBOOT $FASTBOOT_OPTS flash system_e $HOST_PATH/system.img"
# do_execute -i "$FASTBOOT $FASTBOOT_OPTS flash cache $HOST_PATH/cache.img"
# do_execute -i "$FASTBOOT $FASTBOOT_OPTS flash userdata $HOST_PATH/userdata.img"
# do_execute -i "$FASTBOOT $FASTBOOT_OPTS reboot"
