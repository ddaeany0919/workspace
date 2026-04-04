#!/bin/bash

source common.sh;

SRC_ROOT="/home/sskim/DEV/01.Project/Linknet/SH940C"
SRC_OUT="$SRC_ROOT/out/target/product/SH940C-LN"
SRC_MMF="$SRC_ROOT/vendor/tvstorm/mmf"
DEST_ROOT="/home/sskim/workspace/OhPlayer/OhPlayer_LinkNet_Temp"
#DEST_BRANCH="$DEST_ROOT/branches/LinkNetMMF_Rev_690"
DEST_BRANCH="$DEST_ROOT/branches/LinkNetMMF_CAS_MERGE"
DEST_TRUNK="$DEST_ROOT/trunk"
DEST_OUT="$DEST_ROOT/out/target/product/SH940C-LN"
DEST_MMF="$DEST_ROOT/vendor/tvstorm/mmf"
BUILD_SVR="$USER@lkn-build-server2"
SYNC_OPTION="--exclude *svn* -e ssh -l sskim"

BUILD_TYPE=$1;

IGNORE="/home/sskim/bin/get_linknet_source.ignore"

BUILD_PRODUCT="sh940c_ln-user"

export RSYNC_RSH="ssh -l sskim -p 22"

log -i "1. Sync source"
EXCUTE_CMD "rsync -avrc --exclude-from=$IGNORE $BUILD_SVR:$DEST_BRANCH/ $SRC_MMF/"


#log -i "5. Pushing libraries"
#EXCUTE_CMD "sh $SRC_MMF/push_mmf.sh; cd $CUR_DIR"

