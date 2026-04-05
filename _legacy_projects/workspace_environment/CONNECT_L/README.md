https://confluence.mobis.co.kr/display/MAOSP/M.AOS+Platform+Home

//c-std
repo init -u ssh://git@bitbucket.mobis.co.kr:7999/connect/manifest -b master -m avn2_0.xml 

//c-lite
repo init -u ssh://git@bitbucket.mobis.co.kr:7999/connect/manifest -b master -m avn2_0_l.xml


* AAOS build
 * cd release ; source build.sh && build_la
 * source build/envsetup.sh && lunch connect_s-userdebug
 * make -j28 dist ENABLE_AB=true SYSTEMEXT_SEPARATE_PARTITION_ENABLE=true BOARD_DYNAMIC_PARTITION_ENABLE=true ENABLE_VIRTUAL_AB=true SHIPPING_API_LEVEL=34 SKIP_ABI_CHECKS=true

* vendor app build
 * source $RELEASE_DIR/build_gradle_cd.sh "$RELEASE_DIR" "assembleRelease" "$VENDOR_PATH"

* Intellij module build
 1. Shell Script configuration 생성
 2. Name 지정 (ex: frameworks)
 3. 상단 "Script text" 선택
 4. Script text에 wsl 명령어 입력
  * wsl -u luis -- bash -ic 'source ~/workspace/bin/.bashrc_luis && cd ~ && workspace CONNECT && xbuild_module.sh mobis_framework' 
 5. Execute in the terminal 선택
 
 
* Gradle build
 * ./gradlew assembleRelease -x lint -x ktlintCheck -x test

* QNX > LA 접속
  * ssh root@192.168.63.3 (PW:root)

* QFIL
  * https://confluence.mobis.co.kr/display/~DT060230/QFIL


* change adb mode
  * setprop persist.vendor.usb.config adb
  * setprop sys.usb.config adb

<!-- * Nativa camera test
	slay qcxserver
	slay qcx_be_server
	qcxserver &
	qcx_be_server &

	adb shell /vendor/bin/android.hardware.automotive.evs-qcx &
	adb shell setprop evs.qcom.camera.pos front
	adb shell evs_qcx_aidl_app --test -->

* Ignition 1
  * adb shell dumpsys android.hardware.automotive.vehicle.IVehicle/default --set 557891584 -i 1
* MCU update
  * https://confluence.mobis.co.kr/pages/viewpage.action?pageId=976031238 
  * 관련명령어
    * adb push SlimVC_23_08_02_v003_WS.bin /data/SlimVC_23_08_02_v003_WS.bin
    * adb shell
    * micom_update -f /data/SlimVC_23_08_02_v003_WS.bin
      * 업데이트 됨 (4분 전후 소요됨)
      * 로그에 [UpdateMonitor] Unit: micom, Stage: FUSING_STAGE, Percent: 1, Status: installing, ErrCode: NoErr 문구들 계속 표시됨, Percent 숫자는 증가함)
    * micom_update -w
    * sync

<!-- 1. Provision
	configuration
		provision 체크
	Select port
		elf
		default
	reboot
	configuration
		provision 체크 비활성
	select port
	slect programmer
		elf
	seleft flat build
	load xml
		rawprgram 0~7
		patch 0~7
	Download -->


adb shell cmd mobisfingerprintservice randomNumber
adb shell cmd mobisfingerprintservice randomNumber
adb shell cmd mobisfingerprintservice randomNumber
adb shell cmd mobisfingerprintservice enroll
adb shell cmd mobisfingerprintservice key_reset --vin 1GCARVIN12345  --pin 560996378
adb shell cmd mobisfingerprintservice key_learning --vin 1GCARVIN12345  --pin 012345

adb shell cmd hmg_car_service --service HmgCar.FINGERPRINT_SERVICE user_info

* enroll
adb shell dumpsys android.hardware.automotive.vehicle.IVehicle/default --send 561000459 -b 0x01000000
adb shell dumpsys android.hardware.automotive.vehicle.IVehicle/default --set 557877890 -i 1
adb shell dumpsys android.hardware.automotive.vehicle.IVehicle/default --set 557877890 -i 0
adb shell cmd mobisfingerprintservice isk neutralizing  --pin 012345

 <pre>worklogAuthor in (DT102426) AND worklogDate >= startOfWeek()  AND worklogDate <= now()</pre>


* FPM dev repo info
	/device/hmg/common
		Project: device.hmg.common
		Manifest revision: hmgcp_common_14
	/device/mobis/common
		Project: device.mobis.common
		Manifest revision: m_aos4_release
	/vendor/mobis/proprietary/frameworks
		Project: platform.vendor.mobis.proprietary.frameworks
		Manifest revision: m_aos4_release
	/vendor/hmg/packages/services/Car/plugins/fingerprint
		Project: platform.vendor.hmg.packages.services.Car.plugins.fingerprint
		Manifest revision: hmgcp_common_mobis_14

1. HMG Car service
 - HmgCarService 의 plugin active config.xml
  - /device/hmg/common/product_files/overlay/vendor/hmg/packages/services/Car/service/res/values/config.xml


* llvm-readobj 또는 readelf 도구 사용
  * prebuilts/clang/host/linux-x86/clang-r487747c/bin/llvm-readelf --dynamic-table  [librvm2.so 경로]
