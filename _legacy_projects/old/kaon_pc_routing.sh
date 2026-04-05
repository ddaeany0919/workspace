#!/usr/bin/env bash

#### STEP 1 : Declare variables ########################################################################################
source common_bash.sh;

GW_KAON_PC="172.30.0.1"
GW_INNER="192.168.20.1"
DEF_GW=$GW_KAON_PC;

DEBUG=false;
OPT="add";
SET_DEFAULT=false;

#### STEP 2 : check whether command exist ##############################################################################

 while getopts hd option; do
        case ${option} in
            h)
                help;
            ;;
            d)
                OPT="del"
            ;;
            D)
                SET_DEFAULT=true;
            ;;

            
        esac
done

#### STEP 3 : check whether arguments exist ############################################################################

########################################################################################################################
if ! [ $(id -u) = 0 ]; then
   log -e "The script need to be run as root." >&2
   log -h "sudo ${0##*/} (d)" 
   exit 1
fi

do_execute -i sudo ip route $OPT 172.16.4.0/24 via $DEF_GW
do_execute -i sudo ip route $OPT 172.16.7.0/24 via $DEF_GW
do_execute -i sudo ip route $OPT 10.1.1.0/24 via $DEF_GW
do_execute -i sudo ip route $OPT 10.1.2.0/24 via $DEF_GW 
