#!/bin/bash

PROFILE="Work"
WORK_MODE="skylife"

# start roxterm and make sure it's the dbus provider (in case roxterm is already running)
roxterm --profile $PROFILE -n "STB" &

case $WORK_MODE in
    skylife )
    TITLE_LIST=( "LOG" "SM" "TVAPP" "CMD" );
    ;;
esac

sleep 1

CMD_OPTION=""
for title in "${TITLE_LIST[@]}"
do
   CMD_OPTION=" --tab --profile $PROFILE -n $title";
   roxterm $CMD_OPTION;
   CMD_OPTION="";
done

#gnome-terminal $CMD_OPTION;	
# roxterm $CMD_OPTION;
	
