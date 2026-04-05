https://confluence.mobis.co.kr/display/MAOSP/M.AOS+Platform+Home

adb wait-for-device && adb root && logcat -c -p system_server -v " window| activity| display| task|wm_"

* activate adbd
setprop persist.vendor.usb.config adb
setprop sys.usb.config adb

* layout bounds
adb shell setprop debug.layout true
adb shell service call activity 1599295570

* cpu load
tc_count=20 && tc_item=0 && while [[ ${tc_count} -gt ${tc_item} ]]; do tc_item=$((tc_item+1)); dd if=/dev/zero of=/dev/null& done;

* apply framework binaries
find /mnt/w/PBVIVI_out/system/ -newermt "$(date -d '10 minutes ago' '+%Y-%m-%d %H:%M:%S')" | while read file; do
    if [ -f $file ]; then
        _target_file=$(echo $file | sed -E 's|^/mnt/w/PBVIVI_out||')
        adb push $file ${_target_file}
    fi
done

* animation for window transition
adb shell settings put global window_animation_scale 0
adb shell settings put global transition_animation_scale 0
adb shell settings put global animator_duration_scale 0



* reboot command
 * reboot && adb wait-for-device && adb root && adb shell setenforce 0 && adb remount && adb shell date -s \"$(date +'%Y-%m-%d %H:%M:%S')\"
* update service
 * adb root ; adb remount ; adb push /mnt/w/PBVIVI_out/system/framework/services.* /system/framework/ && reboot ;adb wait-for-device && adb root && adb shell setenforce 0 && adb remount && adb shell date -s \"$(date +'%Y-%m-%d %H:%M:%S')\"
* update DMB
 * adb root ; adb remount ; adb push /mnt/w/PBVIVI/1.Sources/apps/LINUX/qssi/vendor/mobis/packages/apps/DMB/app/build/outputs/apk/pbvivi/debug/app-pbvivi-debug.apk  /system_ext/app/PBVIVI_DMB/PBVIVI_DMB.apk && adb_kill com.mobis.app.dmb
* App black
 * am start -n "com.mobis.app.extcamera/.feature.features.CameraActivity" && sleep 1 && adb shell input tap 551 369 && adb shell input tap 551 369 && sleep 0.5 && adb shell input tap 1797 881 && sleep 0.5 && adb shell input tap 912 42


* mobis command
    * power on/off
    * adb shell cmd mobispower set-oem-powerstate-test [0|5]


adb push /mnt/w/PBVIVI_out/system_ext/priv-app/PBV_CarUiPortraitSystemUI/PBV_CarUiPortraitSystemUI.apk /system_ext/priv-app/PBV_CarUiPortraitSystemUI/ && adb shell sync && adb_kill com.android.systemui
adb push /mnt/w/PBVIVI_out/system/framework/mobis.framework.jar /system/framework/ && adb shell sync && reboot && adb_connect
adb push /mnt/w/PBVIVI/1.Sources/apps/LINUX/qssi/vendor/mobis/packages/apps/Phone/app/build/outputs/apk/pbvivi/debug/app-pbvivi-debug.apk /system_ext/app/PBVIVI_Phone/PBVIVI_Phone.apk && adb_kill com.mobis.app.phone
adb push /mnt/w/PBVIVI/1.Sources/apps/LINUX/qssi/vendor/mobis/packages/apps/Settings/app/build/outputs/apk/pbvivi/debug/app-pbvivi-debug.apk /system_ext/app/NewSettings/NewSettings.apk && adb_kill com.mobis.settings
