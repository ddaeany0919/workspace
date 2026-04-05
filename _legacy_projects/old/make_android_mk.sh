#!/bin/bash

rm Android.mk
echo "LOCAL_PATH := \$(call my-dir)" > Android.mk
echo "" >> Android.mk

echo "# PUBLIC LIBRARY" > taurus_setting.mk
echo "PRODUCT_COPY_FILES += vendor/taurus/etc/xml/af.android.taurus_cl_library.xml:product/etc/permissions/af.android.taurus_cl_library.xml" >> taurus_setting.mk
echo "PRODUCT_COPY_FILES += vendor/taurus/etc/xml/af.android.taurus_cl_prj_library.xml:product/etc/permissions/af.android.taurus_cl_prj_library.xml" >> taurus_setting.mk
echo "PRODUCT_COPY_FILES += vendor/taurus/etc/xml/com.alticast.rop_library.xml:vendor/etc/permissions/com.alticast.rop_library.xml" >> taurus_setting.mk

echo "" >> taurus_setting.mk
echo "# PRODUCT_PACKAGE" >> taurus_setting.mk
echo "PRODUCT_PACKAGES += com.alticast.rop_library.xml" >> taurus_setting.mk
echo "PRODUCT_PACKAGES += af.android.taurus_cl_library.xml" >> taurus_setting.mk
echo "PRODUCT_PACKAGES += af.android.taurus_cl_prj_library.xml" >> taurus_setting.mk

for FILE in `ls lib`
do
    NAME=$(echo "$FILE" | sed 's/\.[^\.]*$//')

    echo "include \$(CLEAR_VARS)" >> Android.mk
    echo "LOCAL_MODULE := $NAME" >> Android.mk
    echo "LOCAL_MODULE_CLASS := SHARED_LIBRARIES" >> Android.mk
    echo "LOCAL_MODULE_SUFFIX := .so" >> Android.mk
    echo "LOCAL_SRC_FILES := lib/$FILE" >> Android.mk

    if [ $NAME = "libtvclmediaplayer_jni" ]
    then
        echo "LOCAL_PRODUCT_MODULE := true" >> Android.mk
        echo "LOCAL_SHARED_LIBRARIES := bcm.hardware.dspsvcext@1.0 bcm.hardware.sdbhak@1.0" >> Android.mk
    elif [ $NAME = "libtvclbcmaudiocapture-jni" ]
    then
        echo "LOCAL_PRODUCT_MODULE := true" >> Android.mk
    else
        echo "LOCAL_PROPRIETARY_MODULE := true" >> Android.mk
    fi
    echo -e "include \$(BUILD_PREBUILT)\n" >> Android.mk

    if [ $NAME != "libtvcore" ]
    then
        echo "PRODUCT_PACKAGES += $NAME" >> taurus_setting.mk
    fi
done

for FILE in `ls app`
do
    NAME=$(echo "$FILE" | sed 's/\.[^\.]*$//')
    echo "include \$(CLEAR_VARS)" >> Android.mk
    echo "LOCAL_MODULE := $NAME" >> Android.mk
    echo "LOCAL_MODULE_TAG := optional" >> Android.mk
    echo "LOCAL_MODULE_CLASS := APPS" >> Android.mk
    echo "LOCAL_SRC_FILES := app/\$(LOCAL_MODULE).apk" >> Android.mk
    echo "LOCAL_MODULE_SUFFIX := \$(COMMON_ANDROID_PACKAGE_SUFFIX)" >> Android.mk

    if [ $NAME = "CABSystemApp" ] || [ $NAME = "XcasApp" ]
    then
        echo "LOCAL_CERTIFICATE := platform" >> Android.mk
    else
        echo "LOCAL_CERTIFICATE := PRESIGNED" >> Android.mk
    fi

    echo "LOCAL_PRIVILEGED_MODULE := true" >> Android.mk
    echo "LOCAL_PRODUCT_MODULE := true" >> Android.mk
    echo -e "include \$(BUILD_PREBUILT)\n" >> Android.mk
    echo "PRODUCT_PACKAGES += $NAME" >> taurus_setting.mk
done

for FILE in `ls jar`
do
    NAME=$(echo "$FILE" | sed 's/\.[^\.]*$//')
    MODULE_NAME=${NAME:3}
    echo "include \$(CLEAR_VARS)" >> Android.mk
    echo "LOCAL_MODULE := $MODULE_NAME" >> Android.mk
    echo "LOCAL_MODULE_TAG := optional" >> Android.mk
    echo "LOCAL_MODULE_CLASS := JAVA_LIBRARIES" >> Android.mk
    echo "LOCAL_DEX_PREOPT := false" >> Android.mk

    if [ $MODULE_NAME = "taurus-rop" ]
    then
        echo "LOCAL_PROPRIETARY_MODULE := true" >> Android.mk
    else
        echo "LOCAL_PRODUCT_MODULE := true" >> Android.mk
    fi

    echo "LOCAL_PRIVATE_PLATFORM_APIS := true" >> Android.mk
    echo "LOCAL_STATIC_JAVA_LIBRARIES := $NAME" >> Android.mk
    echo -e "include \$(BUILD_JAVA_LIBRARY)\n" >> Android.mk
    echo "PRODUCT_PACKAGES += $MODULE_NAME" >> taurus_setting.mk
done

for FILE in `ls bin`
do
    echo "include \$(CLEAR_VARS)" >> Android.mk
    echo "LOCAL_MODULE := $FILE" >> Android.mk
    echo "LOCAL_MODULE_CLASS := EXECUTABLES" >> Android.mk
    echo "LOCAL_PROPRIETARY_MODULE := true" >> Android.mk
    echo "LOCAL_SRC_FILES := bin/$FILE" >> Android.mk
    echo "PRODUCT_PACKAGES += $FILE" >> taurus_setting.mk
    echo -e "include \$(BUILD_PREBUILT)\n" >> Android.mk
done

echo "include \$(CLEAR_VARS)" >> Android.mk
echo "LOCAL_PREBUILT_STATIC_JAVA_LIBRARIES := \\" >> Android.mk
JAR_COUNT=$(ls -Rl jar | grep ^- | wc -l)
COUNT=1
for FILE in `ls jar`
do
    NAME=$(echo "$FILE" | sed 's/\.[^\.]*$//')
    if [ "$COUNT" -eq "$JAR_COUNT" ]
    then
        echo -e "\t$NAME:jar/$FILE" >> Android.mk
    else
        echo -e "\t$NAME:jar/$FILE \\" >> Android.mk
    fi
    COUNT=$(($COUNT+1))
done
echo -e "include \$(BUILD_MULTI_PREBUILT)\n" >> Android.mk

