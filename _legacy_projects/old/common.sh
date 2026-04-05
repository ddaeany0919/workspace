#!/usr/bin/env bash

source common_log.sh

DEBUG=false

LOG_PREFIX="=======LOG "
CMD_LOG_PREFIX="=======CMD "
PRINT_PREFIX="=== RESULT :	"
mCommandCnt=1

COMMON_DEBUG=false

CUR_DIR=$PWD

RESULT_FILE="$HOME/bin/result"

MENU_LIST=("")

function option_picked() {
	COLOR='\033[01;31m' # bold red
	RESET='\033[00;00m' # normal white
	MESSAGE=${@:-"${RESET}Error: No message passed"}
	echo -e "${COLOR}${MESSAGE}${RESET}"
}

show_menu() {
	NORMAL=$(echo "\033[m")
	MENU=$(echo "\033[36m")   #Blue
	NUMBER=$(echo "\033[33m") #yellow
	FGRED=$(echo "\033[41m")
	RED_TEXT=$(echo "\033[31m")
	ENTER_LINE=$(echo "\033[33m")
	echo -e "\t${MENU}*********************************************${NORMAL}"
	count=1
	for menu in "${MENU_LIST[@]}"; do
		CMD_OPTION="${MENU}**${NUMBER} $count) $menu ${NORMAL}"
		echo -e "\t$CMD_OPTION"
		count=$(expr $count + 1)
	done
	echo -e "\t${MENU}*********************************************${NORMAL}"
	echo -e "\t${ENTER_LINE}Please enter a menu option and enter or ${RED_TEXT}enter to exit. ${NORMAL}"

	if [[ ! -z $* ]]; then
		opt=$*
	else
		read opt
	fi
}

PRINT() {
	log "$LOG_PREFIX $*"
}

RESULT_PRINT() {
	output=$1
	type=$2
	if [ "$output" != "" ]; then
		case $type in
		"-i")
			log -i "$output"
			;;
		"-e")
			log -e "$output"
			;;
		esac
	fi
}

EXCUTE_CMD() {
	command=""
	isPrint=""
	output=""
	result=""
	for args in "$@"; do
		case $args in
		"-h")
			isPrint=$args
			;;
		"-i")
			type=$args
			;;
		"-e")
			type=$args
			;;
		"-w")
			type=$args
			;;
		*)
			type=""
			command="$command $args"
			;;
		esac
	done

	log $type"$mCommandCnt. #)$command"
	mCommandCnt=$(expr $mCommandCnt + 1)

	if [ "$isPrint" != "-h" ] && [ -x $type]; then
		local output=$($command 2>&1 >/dev/tty)
		#local output=$($command 3>&2 2>&1 1>&3-)
		result=$?

		if [ "$COMMON_DEBUG" = true ]; then
			var_out=${output#*-------------$}
			printf "EXCUTE_CMD(), var_out=$var_out\n"
		fi

	else
		output=$($command)
		result=$?
	fi

	if [ "$COMMON_DEBUG" = true ]; then
		printf "EXCUTE_CMD(), result=$result\n"
	fi

	return $result
}

EXCUTE_CMD_CHECK() {
	EXCUTE_CMD $*
	if [ $result -gt 0 ]; then
		echo "result = $result"
		exit $result
	fi
	return $result
}
