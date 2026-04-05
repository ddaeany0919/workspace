#!/usr/bin/env bash
source common_android.sh
DEBUG_COMMON_BASH=$false
DEBUG=$true

AUTHORITY="com.technicolor.android.dtvprovider"
if [ ! -z $WORKSPACE_DTVPROVIDER_AUTHOR ]; then
    AUTHORITY=$WORKSPACE_DTVPROVIDER_AUTHOR
fi

TV_DB="/data/data/com.android.providers.tv/databases/tv.db"
PKG=$WORKSPACE_DTVINPUT_PACKAGE
URI_CHANNEL="--uri content://android.media.tv/channel"
