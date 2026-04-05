#!/bin/sh
#No need to update always
#cp ./u400_develop/vendor/taurus/taurus_setting.mk ./
#cp ./u400_develop/vendor/taurus/etc/library_xml/vendor/*.xml ./etc/xml/

#cd release

source="/home/sskim/tbroad_dev";
dest="/home/sskim/workspace/1.Projects/TBROAD_U400/1.release/vendor/taurus"
rm -rf u400_makeimage
mkdir u400_makeimage
cd u400_makeimage
mkdir -v ./jar
mkdir -v ./lib
mkdir -v ./app
mkdir -v ./bin
cp -rv ../etc/ .
cp -v $source/out/target/common/obj/JAVA_LIBRARIES/taurus-rop_intermediates/classes.jar ./jar/libtaurus-rop.jar
cp -v $source/out/target/common/obj/JAVA_LIBRARIES/taurus-cl_intermediates/classes.jar ./jar/libtaurus-cl.jar
cp -v $source/out/target/common/obj/JAVA_LIBRARIES/taurus-cl-prj_intermediates/classes.jar ./jar/libtaurus-cl-prj.jar
cp -v $source/out/target/product/tmau400/vendor/bin/smbootloader ./bin/
cp -v $source/out/target/product/tmau400/vendor/lib/libpl.so ./lib/
cp -v $source/out/target/product/tmau400/vendor/lib/libdcas.so ./lib/
cp -v $source/out/target/product/tmau400/vendor/lib/libtv*.so ./lib/
cp -v $source/out/target/product/tmau400/product/lib/libtv*.so ./lib/
cp -v $source/out/target/product/tmau400/product/priv-app/CABSystemApp/CABSystemApp.apk ./app/
cp -v $source/out/target/product/tmau400/product/priv-app/XcasApp/XcasApp.apk ./app/
cp -v $source/out/target/product/tmau400/system/priv-app/CABCustomizer/CABCustomizer.apk ./app/
cp -v $source/vendor/taurus/app_cable/prebuilts/*.apk ./app/

../make_android_mk.sh
cd ..
cp -rv u400_makeimage/* $dest
