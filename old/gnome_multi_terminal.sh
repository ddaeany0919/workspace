#!/bin/bash

PROFILE="Work"
#TITLE_LIST=( "STB" "LOG" "BUILD" "CMD" "SVR" );
#TITLE_LIST=( "STB" "LOG" "SM" "UI" "MDC" "CSP" "IME" );
#TITLE_LIST=( "STB" "LOG" "SM" "APP" "BT" "SVR" "CMD" );
TITLE_LIST=( "STB" "LOG" "IME" "BT" "SVR" "CMD" );

CMD_OPTION=""
for title in "${TITLE_LIST[@]}"
do
   CMD_OPTION=$CMD_OPTION" --tab-with-profile=$PROFILE --title=$title";
done

gnome-terminal $CMD_OPTION;	
	
