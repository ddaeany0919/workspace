#!/system/bin/sh

#input keyevent 3; 		#HOME
#input keyevent 4; 		#BACK
#input keyevent 19; 	#UP
#input keyevent 20; 	#DOWN
#input keyevent 21; 	#LEFT
#input keyevent 22; 	#RIGHT
#input keyevent 23; 	#OK
#input keyevent 166; 	#CHANNEL UP
#input keyevent 167; 	#CHANNEL DOWN

#input keyevent 168; 	#PREV, RED
#input keyevent 166; 	#STOP, GREEN
#input keyevent 164; 	#PLAY, YELLOW
#input keyevent 208; 	#NEXT, BLUE

SLEEP() {
	if [[ ! -z $1 ]]; then
		sleep $1
	fi
}

KEY_INPUT() {
	# $1 : key code
	# $2 : Sleep time
	echo "KEY $1"
	key=$1
	case $key in
	HO* | ho*)
		input keyevent KEYCODE_HOME
		;;
	BA* | ba*)
		input keyevent KEYCODE_BACK
		;;
	U* | u*)
		input keyevent KEYCODE_DPAD_UP
		;;
	D* | d*)
		input keyevent KEYCODE_DPAD_DOWN
		;;
	L* | l*)
		input keyevent KEYCODE_DPAD_LEFT
		;;
	RIGHT* | right*)
		input keyevent KEYCODE_DPAD_RIGHT
		;;
	OK* | ok*)
		input keyevent KEYCODE_DPAD_CENTER
		;;
	CH-U* | ch-u*)
		input keyevent KEYCODE_CHANNEL_UP
		;;
	CH-D* | ch-d*)
		input keyevent KEYCODE_CHANNEL_DOWN
		;;
	PREV | prev | RED | red)
		input keyevent KEYCODE_MEDIA_REWIND
		;;
	STOP | stop | GREEN | green)
		input keyevent KEYCODE_MEDIA_STOP
		;;
	PLAY | play | YELLOW | yellow)
		input keyevent KEYCODE_MEDIA_PLAY_PAUSE
		;;
	NEXT | next | BLUE | blue)
		input keyevent KEYCODE_MEDIA_FAST_FORWARD
		;;
	esac

	SLEEP $2
}

key_input() {
	KEY_INPUT $1 $2
}

keyinput() {
	KEY_INPUT $1 $2
}

key() {
	KEY_INPUT $1 $2
}

GOTO_HOME() {
	KEY_INPUT home
	if [[ ! -z $1 ]]; then
		sleep $1
	else
		sleep 2
	fi
}

GOTO_APPS() {
	KEY_INPUT right 1
	KEY_INPUT right 1
	KEY_INPUT right 1
	KEY_INPUT ok 1
}

RESET_LOGCAT() {
	logcat -c
	logcat -v time &

}

GOTO_CHANNEL_BY_TVPLAYER() {
	CH_NAME=$1
	CH_NUM=$2

	am start -a android.intent.action.VIEW -d tv://channel/$CH_NAME?channelNumber=$CH_NUM -n com.google.tv.player/.PlayerActivity

	SLEEP $3
}

DO_TVS_STATE() {

	RESULT_FILE="/data/state"
	TEMP_TOP="/data/_top"
	TEMP_VMSTATE="/data/_vmstat"

	let_count=0
	count=0

	if [[ ! -z $1 ]]; then
		let_count=$1
	fi

	while [ $count -lt $let_count ]; do
		count=$count+1
		date="$(date)"
		var="$(cat /proc/sys/fs/file-nr)"

		top -n 1 >$TEMP_TOP
		vmstat -n 1 >$TEMP_VMSTATE

		ampservice="$(cat $TEMP_TOP | grep ampservice)"
		tvs_media="$(cat $TEMP_TOP | grep tvs_media)"
		skb_home="$(cat $TEMP_TOP | grep com.skb.google.tv)"
		si_service="$(cat $TEMP_TOP | grep com.tvstorm.tv.siservice)"

		result="\n\n==============================================================\n"
		result="$result FILE NR  \t|==TVS : $date =========| $var\n"
		result="$result AMP    \t\t|==TVS : $date =========| $ampservice\n"
		result="$result TVS_MEDIA\t|==TVS : $date =========| $tvs_media\n"
		result="$result SKB_HOME \t|==TVS : $date =========| $skb_home\n"
		result="$result TVS_SIS  \t|==TVS : $date =========| $si_service"

		echo $result
		echo $result >>$RESULT_FILE

		cat $TEMP_VMSTATE
		cat $TEMP_VMSTATE >>$RESULT_FILE

		date=""
		result=""
		ampservice=""
		tvs_media=""
		skb_home=""
		si_service=""

		if [[ ! -z $2 ]]; then
			sleep $2
		else
			sleep 30
		fi
	done
}
