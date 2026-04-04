#!/bin/bash

source common.sh

timestamp() {
	temp_time=0
	if [[ -z $1 ]]; then
		temp_time=$(date +%s)
		echo "timestamp value is '$temp_time'"
		return 0
	else
		temp_time=$1
	fi

	EXCUTE_CMD -i "date -d @$temp_time "
}
