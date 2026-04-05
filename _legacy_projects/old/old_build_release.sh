#!/usr/bin/env bash

# STEP 1 : Declare variables and help ##############################################################################
DEBUG=true;
MODEL="CT1107"
MANUFACTURER="kaonmedia"
PDK_ROOT="$PWD"
PDK_OUT="$PDK_ROOT/out/target/product/$MODEL"
BUILD_OUT="$PDK_ROOT/kaon_release_out"
CT1107="$PDK_ROOT/vendor/kaon/$MODEL"
DPP_TOOLS="$CT1107/tools/dpp_tools"
PREBUILT_BOOTIMAGE="$CT1107/prebuilts/boot"
PREBUILT_BOOTLOADER="$CT1107/prebuilts/bootloader"
PREBUILT_FIRSTBFW="$CT1107/prebuilts/firstBFW"
PREBUILT_RECOVERY="$CT1107/prebuilts/recovery"
SELF_SIGNING="$CT1107/tools/self-signing"
REPO_MANIFEST="$PDK_ROOT/.repo/manifests/ct1107.xml"

VARIANT_TYPE="user"
BUILD_TYPE="dev"
MAKE_OPTION=""
CP='cp'

CORE_COUNT=$( cat /proc/cpuinfo | grep processor | wc -l )

TAG=""
IS_TAGGING=false;
IS_CLEAR=false;
IS_REPO_SYNC=false;
IS_GIT_TAG_PUSH=false;
HAS_CHANGED_VERSION=false;
IS_PRINT_LOG=false;
IS_QUITE_MODE=false;
OTA_BUILD=true;
DPP_BUILD=true;

step_index=0;
red_color="\033[0;31;49m";
green_color="\033[0;32;49m";
yellow_color="\033[0;93;49m";
blink_color="\033[5;33;49m";
reset_color="\033[0m";

if [ ! -f $REPO_MANIFEST ]; then
    echo -e "$red_color This script must execute in PDK root directory $reset_color"
    exit
fi

# -- help function
help() {
    echo "$(basename "$0") [-b {user|userdebug}] [-v {1.1.0100 1.1.0101 15.1.0100 ....}] [-o {OUT_PATH} ] [-c] [-r] [--type={MODE}] [--tag={TAG}] [--push] [--log={BASE_TAG_NAME}] --quite --only={dpp|ota}"
    echo ""
    echo "This script is just a tool to release version"
    echo "  1. image build [make -j$CORE_COUNT]"
    echo "  2. copy file for need release to output directory"
    echo "  3. git tagging and push"
    echo "  4. git graph log from tag name"
    echo "options:"
    echo "      -b      build type (default : $VARIANT_TYPE)"
    echo "      -v      firmware for a version or list (default : $( cat $CT1107/version.txt ))"
    echo "      -o      out path (default : $BUILD_OUT)"
    echo "      -c      make clobber, rm -rf out ~/.ccache"
    echo "      -r      repo sync --force-sync -j$CORE_COUNT"
    echo "      --type  build type [commercial, commercial-dev, dev] (default: dev)"
    echo "      --only  DPP_to_DPP only is dpp and OTA Package only is ota"
    echo "      --tag   git tagging"
    echo "      --push  git push the commits and tag to remote gitlab"
    echo "      --log   git graph log from args tag (default : lastest tag)"
    echo "      --quite quite mode for build message"
    echo ""
    echo "example :"
    echo "        ./$(basename $0) --type=commercial-dev -v \"1.1.0250 15.1.0250\" -c -r -t 20181218_relase -p --quite"
    echo "        ./$(basename $0) --type=commercial -o ~/sftp --only=ota --quite"
}

# STEP 2 : check arguments(options) ##############################################################################
optspec="b:v:l:o:hcr-:"
while getopts "b:v:l:o:hcr-:" option; do
    case ${option} in
        -)
            case "${OPTARG}" in
                type=*)
                    _type=${OPTARG#*=};
                    if [ "$_type" == "dev" ] || [ "$_type" == "commercial" ] || [ "$_type" == "commercial-dev" ]; then
                        BUILD_TYPE="$_type"
                    else
                        help
                        exit 1
                    fi
                ;;
                tag=*)
                    TAG=${OPTARG#*=}
                    echo "## tag=$TAG"
                ;;
                push)
                    IS_GIT_TAG_PUSH=true
                ;;
                quite)
                    IS_QUITE_MODE=true
                ;;
                only=*)
                    if [ "${OPTARG#*=}" == "dpp" ]; then
                        OTA_BUILD=false;
                    elif [ "${OPTARG#*=}" == "ota" ]; then
                        DPP_BUILD=false;
                    fi
                ;;
                log=*)
                    IS_PRINT_LOG=true
                    BASE_TAG=${OPTARG#*=}
                    opt=${OPTARG%=$TAG}
                    echo "## log base=$BASE_TAG"
                ;;
                *)
                    if [ "$OPTERR" = 1 ] && [ "${optspec:0:1}" != ":" ]; then
                        help
                        exit 2
                    fi
                ;;
            esac
        ;;
        b)
            _variant="$OPTARG"
            if [ "$_variant" == "user" ] || [ "$_variant" == "userdebug" ]; then
                VARIANT_TYPE="$_variant"
            else
                help
                exit 1
            fi
        ;;
        v)
            _ver=$OPTARG
            if [ "$VERSIONS" != "$_ver" ]; then
                HAS_CHANGED_VERSION=true
            fi
            VERSIONS=$OPTARG
        ;;
        o)
            _out_path=$OPTARG
            if [ ! -d "$_out_path" ]; then
                echo "check output path : $_out_path"
            fi
            BUILD_OUT=$_out_path
        ;;
        r)
            IS_REPO_SYNC=true;
            echo "## ! do repo sync"
        ;;
        c)
            IS_CLEAR=true;
            echo "## ! do clear"
        ;;
        h)
            help
            exit 0
        ;;
    esac
done


# STEP 3 : Declare global function ############################################################################
trap cleanup 1 2 3 6

function log() {
    _log=$2;
    message="${_log/$PDK_ROOT"/"/""}" ;
    #message=$2;
    case "$1" in
        -i)
            echo -e "$green_color" $message "$reset_color"
        ;;
        -e)
            echo -e "$red_color" $message "$reset_color"
        ;;
        -b)
            
            echo -e "$blink_color" $message "$reset_color"
            
        ;;
        -d)
            if $DEBUG ; then
                echo -e "$yellow_color\tDEBUG :" $message "$reset_color"
            fi
        ;;
        *)
            echo " $message";
    esac
}

function cleanup() {
    log -e "Caught error, STEP : $STEP"
    log -b "$step_index. kaon >>>> $STEP"  
    exit 1
}

function build_step() {
    STEP=$*
    step_index=`expr ${step_index} + 1`
    log -i "[$step_index] $BUILD_TYPE, $version, $BUILD_VARIANT >>>> $STEP"  
}

function init_global_variables() {

    if [ ! "$BUILD_TYPE" == "dev" ] && [ "$VARIANT_TYPE" == "userdebug" ]; then
        log -e "$BUILD_TYPE type can build in user only"
        log -i "ex) ./$(basename "$0") --type=$BUILD_TYPE"
        echo " "
        help
        
    elif [ ! -f $REPO_MANIFEST ]; then
        log -e "This script must execute on PDK root directory"
        cleanup    
    fi

    if [ "$VERSIONS" == "" ]; then
        VERSIONS=$( cat $CT1107/version.txt )
    fi
    BUILD_VARIANT="$MODEL-$VARIANT_TYPE"
    declare -a GIT_DIR_ARR=($(cat $REPO_MANIFEST | grep path | cut -d "\"" -f4))
    version_array=("$VERSIONS")
}

function repo_sync() {
    build_step "repo sync"

    echo "repo sync --force-sync -j$CORE_COUNT"
    repo sync --force-sync -j$CORE_COUNT
    if [ $? -ne 0 ]; then
        cleanup
    fi
}

function init_variables() {
    version=$1
    step_index=0;

    if [ "$TAG" == "" ]; then 
        _out=$BUILD_OUT/v$version\_$BUILD_TYPE\_$VARIANT_TYPE
    else
        _out=$BUILD_OUT/$TAG/v$version\_$BUILD_TYPE\_$VARIANT_TYPE
    fi
    
    if $IS_QUITE_MODE ; then
        touch makelog.txt
        echo "" > makelog.txt
        MAKE_OPTION=" > makelog.txt 2>&1"
        # MAKE_OPTION="2>&1 | tee makelog.txt"
    fi
    DPP_OUT="$_out/DPP_to_DPP"
    OTAPACKAGE_OUT="$_out/USB_OTA/KAON"
    SYSTEM_RAW_OUT="$DPP_OUT/images"
    
    log -i "## build variant \t $BUILD_VARIANT"
    log -i "## build version \t $version"
    log -b "## build type \t\t $BUILD_TYPE"
    log -d "DPP_OUT=\t\t$DPP_OUT"
    log -d "SYSTEM_RAW_OUT=\t$SYSTEM_RAW_OUT"
}

function prepare_build() {
    # apply firmware version to version.txt
    build_step "Apply $version version to $CT1107/version.txt"
    echo "$version" > $CT1107/version.txt 
    
    build_step "prepare build enviroment"
    source build/envsetup.sh $MAKE_OPTION
    lunch $BUILD_VARIANT $MAKE_OPTION
    if [ $? -ne 0 ]; then
        cleanup
    fi
    

    # clean cache files and execute 'make clobber'
    if $IS_CLEAR ; then
        build_step "make clobber and rm -rf out ~/.ccache"   
        make clobber $MAKE_OPTION
        rm -rf out ~/.ccache
    fi

    # delete previous output images
    build_step "Delete previous files "
    rm -rf $_out
}

function make_system_build() {
    # execute image build
    build_step "Make Build"
    
    if [[ $version == 1.* ]] && [ "$VARIANT_TYPE" == "user" ] ; then    
        build_step "Make clean-adbd"
        make clean-adbd -j$CORE_COUNT $MAKE_OPTION
    fi
    
    make -j$CORE_COUNT $MAKE_OPTION
    if [ $? -ne 0 ]; then
        cleanup
    fi
}

function make_self_signing() {
     build_step "Make boot image and apply to prebuilt directory"
    _var="";
    if [ "$VARIANT_TYPE" == "userdebug" ]; then
        _var="-debug";
    fi
    
    bsu_path="$CT1107/prebuilts/bsu/CT1107_BSU_DEV_v1.BIN"

    cat $bsu_path $PDK_OUT/boot.img      > $SELF_SIGNING/self_signing_tool/CT1107_APP.BIN
    #cat $bsu_path $PDK_OUT/recovery.img  > $SELF_SIGNING/CT1107_RECOVERY.BIN

    cd $SELF_SIGNING
    #make app recovery
    make clean app
    if [ $? -ne 0 ]; then
        cleanup
    fi
    $CP $SELF_SIGNING/CT1107_GANG_BOOTIMAGE.ENC     $PREBUILT_BOOTIMAGE/dev/CT1107_GANG_BOOTIMAGE$_var.ENC 
    #$CP $_ptools/CT1107_GANG_RECOVERYIMAGE.ENC $PREBUILT_RECOVERY/dev/CT1107_GANG_RECOVERYIMAGE$_var.ENC   
    cd $PDK_ROOT
}

function save_dpp_image() {
    if [ "$BUILD_TYPE" == "dev" ]; then
        make_self_signing
    fi
    
    # make system raw image
    build_step "Make DPP_TO_DPP to $DPP_OUT/"
    mkdir -p $SYSTEM_RAW_OUT/
    gpt=$CT1107/prebuilts/gpt/CT1107_GPT_v1.05.bin
    
    if [ "$BUILD_TYPE" == "dev" ]; then
        # dev mode
        bootloader=$PREBUILT_BOOTLOADER/CT1107_BOOTLOADER_v1_34_07.BIN
        firstBFW=$PREBUILT_FIRSTBFW/CT1107_FIRST_BFW_IMAGES_DEV_V02.BIN
        bootimage=$PREBUILT_BOOTIMAGE/dev/CT1107_GANG_BOOTIMAGE$_var.ENC
        recovery=$PREBUILT_RECOVERY/dev/CT1107_GANG_RECOVERYIMAGE$_var.ENC
    else
        # commercial mode
        if [ "$VARIANT_TYPE" == "userdebug" ]; then
            log -e "Can not support for $VARIANT_TYPE in $BUILD_TYPE"
            cleanup
        fi

        firstBFW=$PREBUILT_FIRSTBFW/CT1107_FIRST_BFW_IMAGES_PROD_V01.BIN
        recovery=$PREBUILT_RECOVERY/CT1107_GANG_RECOVERYIMAGE.ENC
        
        if [ "$BUILD_TYPE" == "commercial" ]; then
            bootloader=$PREBUILT_BOOTLOADER/CT1107_BOOTLOADER_PROD_v7.BIN
            bootimage=$PREBUILT_BOOTIMAGE/CT1107_GANG_BOOTIMAGE-prod.ENC
        else
            # commercial dev mode
            bootloader=$PREBUILT_BOOTLOADER/CT1107_BOOTLOADER_PROD_v7_LOG.BIN
            if [[ $version == 15.* ]]; then
                bootimage=$PREBUILT_BOOTIMAGE/CT1107_GANG_BOOTIMAGE-prod_dev.ENC
            else
                bootimage=$PREBUILT_BOOTIMAGE/CT1107_GANG_BOOTIMAGE-prod.ENC
            fi
        fi
    fi
    
    out/host/linux-x86/bin/simg2img $PDK_OUT/system.img $PDK_OUT/system.raw.img
    
    for file in $gpt $firstBFW $bootloader $bootimage $recovery
    do
        filename=$(basename $file)
        if [ ! -f $file ]; then log -e "File not found, $file"; cleanup; fi
    done
    log -d "bootimage : \t$bootimage"
    log -d "bootloader : \t$bootloader"
    log -d "recovery : \t$recovery"
    log -d "gpt : \t\t$gpt"
    log -d "firstBFW : \t$firstBFW"
    
    $CP -r $DPP_TOOLS/* $DPP_OUT/
    
    sed -i -e "s/__BOOT_LOADER__/$(basename $bootloader)/g" $DPP_OUT/DoIt.sh
    sed -i -e "s/__FIRST_BFW__/$(basename $firstBFW)/g" $DPP_OUT/DoIt.sh
    sed -i -e "s/__RECOVERY__/$(basename $recovery)/g" $DPP_OUT/DoIt.sh
    sed -i -e "s/__BOOT_IMAGE__/$(basename $bootimage)/g" $DPP_OUT/DoIt.sh
    sed -i -e "s/__SYSTEM_RAW__/$(basename $PDK_OUT/system.raw.img)/g" $DPP_OUT/DoIt.sh
    
    mkdir $DPP_OUT/lpackage
    
    $CP $gpt $DPP_OUT/lpackage/
    $CP $firstBFW $DPP_OUT/lpackage/
    $CP $bootloader $DPP_OUT/lpackage/
    
    $CP $bootimage $SYSTEM_RAW_OUT
    $CP $recovery $SYSTEM_RAW_OUT
    $CP $PDK_OUT/system.raw.img $SYSTEM_RAW_OUT
    
}

function make_otapackage() {
    # make otapackage
    build_step "Make otapackage for $BUILD_TYPE"
    if [ "$BUILD_TYPE" != "dev" ]; then
        make otapackage-commercial -j$CORE_COUNT $MAKE_OPTION
    else
        make otapackage -j$CORE_COUNT $MAKE_OPTION
    fi
    if [ $? -ne 0 ]; then
        cleanup
    fi
}


function save_otapacakge() {
    # make fwinfo.txt and copy otapackage file
    build_step "Copy OTA package file to $OTAPACKAGE_OUT"
    mkdir -p $OTAPACKAGE_OUT/
    echo "ct1107=KAON/"$MANUFACTURER"_$MODEL"_"$version.bin" > $OTAPACKAGE_OUT/fwinfo.txt
    _otapackage=$PDK_OUT/$MANUFACTURER\_$MODEL\_$version.bin
    
    log -d "otapackage file : $_otapackage"
    $CP $_otapackage $OTAPACKAGE_OUT/$MANUFACTURER\_$MODEL\_$version.bin
}

function git_tagging() {
    version=$1;
    version=$1;
    if $IS_GIT_TAG_PUSH; then
        build_step "git commit for release $version"
        cd $CT1107
        git commit -a -m "kaon> release version for $version. [release by $(basename "$0")]"
        git pull
        git push
        cd $PDK_ROOT
    fi
    
    build_step "git tagging, tag name : $TAG"
    for dir in "${GIT_DIR_ARR[@]}"
    do
        #echo -e "\n# $dir"
        git -C $dir tag -d $TAG
        git -C $dir tag $TAG
        if $IS_GIT_TAG_PUSH; then
            echo "# git -C $dir push gitlab $TAG"
            git -C $dir push gitlab $TAG
            sleep 5
        fi
    done

}

function print_commit_list() {
    build_step "commit list"
    if [ "$BASE_TAG" == "" ]; then
        BASE_TAG=$(git -C $CT1107 for-each-ref --format='%(refname)' --sort=-creatordate --count=1 refs/tags| cut -d "/" -f3)
        echo "BASE_TAG=$BASE_TAG"
    fi

    for dir in "${GIT_DIR_ARR[@]}"
    do
        commit_count=$(git -C $dir log --oneline $BASE_TAG... | wc -l)
        if [ $commit_count != "0" ]; then
            echo -e "\n# $dir"
            #git -C $dir --no-pager log --graph --abbrev-commit --decorate --date=format:'%Y-%m-%d %H:%M:%S' --
            git -C $dir log --graph --abbrev-commit --decorate --date=format:'%Y-%m-%d %H:%M:%S' --pretty=tformat:"%C(yellow)%h%Creset}%Cgreen(%ad)%Creset}%C(bold blue)<%an>%Creset}%C(bold red)%d%Creset %s" $BASE_TAG... |  column -s '}' -t        
        fi
    done
}


function build() {
    
    prepare_build;
    
    if $DPP_BUILD; then
        make_system_build;
        save_dpp_image;
    fi
    
    if $OTA_BUILD; then
        make_otapackage;
        save_otapacakge;
    fi
    
    if ! type tree > /dev/null; then
        echo "need install 'tree', sudo [apt-get install || pacman -Sy] tree" 
    else
        tree $_out -s
    fi
}

# STEP 4 : Run script ############################################################################
   
init_global_variables;

if $IS_REPO_SYNC ; then repo_sync; fi

for version in ${version_array[@]}
do 
    init_variables $version;
    build;
done

# git tagging and push
if $IS_TAGGING; then git_tagging ${version_array[0]}; fi

# printing git graph log from lastest tag
if $IS_PRINT_LOG; then print_commit_list; fi;

# list files of output files and directories in a tree-like format
# if ! type tree > /dev/null; then
#     echo "need install 'tree', sudo [apt-get install || pacman -Sy] tree" 
# else
#     tree $_out
# fi


# build_release.sh -v 0.2.14
