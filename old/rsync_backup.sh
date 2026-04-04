#!/usr/bin/env bash

#### STEP 1 : Declare variables ########################################################################################
DEBUG=false;

#RSYNCOPT=(--rsh="ssh -p 10022 -c des" --rsync-path=\"/opt/bin/rsync\" --inplace --progress -a -vv)
#...
#printf "%q " ${SCREEN} ${SCREENOPT} ${SCREEN_TITLE}
#echo
#
#printf "%q " ${RSYNC} "${RSYNCOPT[@]}" ${SOURCE} ${REMOTE_USER}${REMOTE_HOST}${REMOTE_BASE}${REMOTE_TARGET}
#echo
#${RSYNC} "${RSYNCOPT[@]}" ${SOURCE} ${REMOTE_USER}${REMOTE_HOST}${REMOTE_BASE}${REMOTE_TARGET}


source common_bash.sh;
source common_menu.sh;
declare -a selected_items=();
declare -a dir_array=();
index=0;

ssh_command="ssh"
rsync_command="rsync"
rsync_option+=(-avzh)
rsync_option+=(--progress)
rsync_option+=('--rsh=ssh -p 10022')

#rsync_option="-avzh --progress --rsh \\\"ssh -p 10022\\\""

source_path="";

dest_host="saraluis.iptime.org"
dest_path="~/workspace/"
dest_command="$dest_host:$dest_path"

command="";

#### STEP 2 : check whether command exist ##############################################################################
case "$OSTYPE" in
darwin*)  echo "OSX" ;; 
linux*)
    type -P $RRDTOOL &>/dev/null || { echo "$RRDTOOL not found. Set \$RRDTOOL in $0"; exit 1; }
    ;;
esac

if ! type "$rsync_command" > /dev/null && ! type "$ssh_command" > /dev/null ; then
  log -w "need install some packages";
  do_execute -i sudo apt-get update;
  do_execute -i suto apt-get install -y $rsync_command $ssh_command
fi


if [ ! -d $WORKSPACE_HOME ]; then
    log -e "WORKSPACE_HOME is not exist";
    exit 1;
fi


function buildByMenu() {
    local temp_path item;
    cd $WORKSPACE_HOME;
    for dir in */; do
        dir_array[item++]="${dir%/}"
    done

    ## show menu list
    selected_items=($(show_menu -d ${dir_array[@]}));
    debug $FUNCNAME select_values=${selected_items[@]}

    for item in ${selected_items[@]}; do

        debug $FUNCNAME: direcoty=$item
        temp_path="$temp_path $WORKSPACE_HOME/$item"
    done

    debug "$FUNCNAME, selected path:$temp_path"
    echo $temp_path;
}

function buildByArgs() {
    local args directory temp_path;
    args=( "$@" );

    for directory in "${args[@]}";
    do
        debug $FUNCNAME: directory=\"$directory\";
        temp_path="$temp_path $directory"
    done;

    debug "$FUNCNAME, selected path:$temp_path"
    echo $temp_path;

}
#### STEP 3 : check whether arguments exist ############################################################################
if [ $# -eq 0 ]; then
    source_path=$(buildByMenu);
else
    source_path=$(buildByArgs "$@");
fi

########################################################################################################################
print -i "\t option  : " ${rsync_option[@]}
print -i "\t source  : " $source_path
print -i "\t dest    : " $dest_command
$rsync_command "${rsync_option[@]}" $source_path $dest_command;

#rsync -avzh --progress -e "ssh -p 10022" $WORKSPACE_HOME/1.Project $WORKSPACE_HOME/5.Docker $WORKSPACE_HOME/bin saraluis.iptime.org:~/workspace/