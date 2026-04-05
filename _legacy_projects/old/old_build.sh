#!/usr/bin/env bash

# STEP 1 : Declare variables and help ############################################################################### STEP 1 : Declare variables and help ##############################################################################
DEBUG=true;
PDK_ROOT="$PWD"
PDK_OUT="$PDK_ROOT/out/target/product/$MODEL"
BUILD_OUT="$PDK_ROOT/alti_release_out"
REPO_MANIFEST="$PDK_ROOT/.repo/manifests/default.xml"

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
    echo "$(basename "$0") [-v {1.1.0100 1.1.0101 15.1.0100 ....}] [-o {OUT_PATH} ] [-c] [-r] [--tag={TAG}] [--push] [--log={BASE_TAG_NAME}] --quite "
    echo ""
    echo "This script is just a tool to release version"
    echo "  1. image build [make -j$CORE_COUNT]"
    echo "  2. copy file for need release to output directory"
    echo "  3. git tagging and push"
    echo "  4. git graph log from tag name"
    echo "options:"
    echo "      -v      firmware for a version or list (default : $( cat $CT1107/version.txt ))"
    echo "      -o      out path (default : $BUILD_OUT)"
    echo "      -c      make clobber, rm -rf out ~/.ccache"
    echo "      -r      repo sync --force-sync -j$CORE_COUNT"
    echo "      --tag   git tagging"
    echo "      --push  git push the commits and tag to remote gitlab"
    echo "      --log   git graph log from args tag (default : lastest tag)"
    echo "      --quite quite mode for build message"
    echo ""
    echo "example :"
    echo "        ./$(basename $0) -v \"0.2.12 0.2.13\" -c -r --tag 20190716_relase -p --quite"
    echo "        ./$(basename $0) --type=commercial -o ~/sftp"
}

# STEP 2 : Declare global function ############################################################################
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

# STEP 3 : check arguments(options) ##############################################################################
optspec="b:v:l:o:hcr-:"
while getopts "v:o:hcr-:" option; do
    case ${option} in
        -)
            case "${OPTARG}" in
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

# STEP 4 : ##############################################################################
function getVersion() {
    echo "cat core_cable/cabinit/config.xml | grep \"AF_CF_TAURUS_VERSION\" | grep jconfig | cut -d\" -f6"
}
function prepare() {
    if [ ! -f $REPO_MANIFEST ]; then
        log -e "This script must execute on PDK root directory"
        cleanup    
    fi

    if [ "$VERSIONS" == "" ]; then
        VERSIONS=getVersion();
    fi
    BUILD_VARIANT="$MODEL-$VARIANT_TYPE"
    declare -a GIT_DIR_ARR=($(cat $REPO_MANIFEST | grep path | cut -d "\"" -f4))
    version_array=("$VERSIONS")
}


prepare;