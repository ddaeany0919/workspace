#!/bin/bash

source common.sh

DEV_HOME="$PWD"

if [ ! -f project.properties ]; then
	log -e "project.properties file is not exist. \n \t\tThis path is not project diretory!!!"
	exit 1
fi

find_version_str="target=android-"
string_count=${#find_version_str}
string_count=$(expr $string_count + 1)
project_version=$(cat project.properties | grep $find_version_str | cut -c $string_count-)

log -i "Removing generated java classes."
EXCUTE_CMD_CHECK "rm -rf gen bin"
EXCUTE_CMD_CHECK "find ./ -name *.class -exec rm {} \;"

log -i "Generating BuildConfig.java..."

for find_result in $(find ./ -name *.aidl); do
	aidl_file=$(echo $find_result | cut -c 3-)

	file=$(echo $aidl_file | rev | cut -d/ -f1 | cut -c 6- | rev)
	src_dir=$(echo $aidl_file | rev | cut -d/ -f2- | rev)
	gen_dir="gen$(echo $aidl_file | rev | cut -d/ -f2- | rev | cut -c 4-)"
	log -i "AIDL : $src_dir/$file"
	EXCUTE_CMD_CHECK "$ANDROID_SDK/build-tools/20.0.0/aidl -p$ANDROID_SDK/platforms/android-$project_version/framework.aidl -I$DEV_HOME/src -I$DEV_HOME/gen $DEV_HOME/$src_dir/$file.aidl $DEV_HOME/$gen_dir/$file.java"
done

log -i "Preparing generated java files for update/creation."
EXCUTE_CMD_CHECK "$ANDROID_SDK/build-tools/20.0.0/aapt package -m -v -J /$DEV_HOME/gen -M /$DEV_HOME/AndroidManifest.xml -S /$DEV_HOME/res -I /$ANDROID_SDK/platforms/android-$project_version/android.jar"

ant release
