#!/bin/bash
EXCLUDE_WORD="/private"
DISK_LIST=($(diskutil info -all | grep "Mount Point" | cut -d ":" -f2));

for mount in ${DISK_LIST[@]}; do
  echo "mount=$mount"
done
#
# for (( i = 0 ; i < ${#DISK_LIST[@]} ; i++ )) ; do
# 	#j=$(($i+2))
# 	#echo "j = $j"
#     echo "[$(($i+2))] : ${DISK_LIST[$i]}"
# done
