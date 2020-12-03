#!/sbin/sh
#
# ThundeRStormS - Flash script 1.1
#
# Credit also goes to @djb77
# @lyapota, @Tkkg1994, @osm0sis
# @dwander for bits of code
# @MoRoGoKu


# Functions
BB=/data/tmp/ts/busybox

ui_print() { echo -n -e "ui_print $1\n"; }

file_getprop() { grep "^$2" "$1" | cut -d= -f2; }

show_progress() { echo "progress $1 $2"; }

set_progress() { echo "set_progress $1"; }

set_perm() {
  chown $1.$2 $4
  chown $1:$2 $4
  chmod $3 $4
  chcon $5 $4
}

clean_magisk() {
	rm -rf /cache/*magisk* /cache/unblock /data/*magisk* /data/cache/*magisk* /data/property/*magisk* \
        /data/Magisk.apk /data/busybox /data/custom_ramdisk_patch.sh /data/app/com.topjohnwu.magisk* \
        /data/user*/*/magisk.db /data/user*/*/com.topjohnwu.magisk /data/user*/*/.tmp.magisk.config \
        /data/adb/*magisk* /data/adb/post-fs-data.d /data/adb/service.d /data/adb/modules* 2>/dev/null
        
        if [ -f /system/addon.d/99-magisk.sh ]; then
	  mount -o rw,remount /system
	  rm -f /system/addon.d/99-magisk.sh
	fi
}

abort() {
	ui_print "$*";
	echo "abort=1" > /tmp/aroma/abort.prop
	exit 1;
}

unmount_system() {
	umount -l /system_root 2>/dev/null
	umount -l /system 2>/dev/null
}

# Mount system
export SYSTEM_ROOT=false

block=/dev/block/platform/13d60000.ufs/by-name/system
SYSTEM_MOUNT=/system
SYSTEM=$SYSTEM_MOUNT

# Try to detect system-as-root through $SYSTEM_MOUNT/init.rc like Magisk does
# Mount whatever $SYSTEM_MOUNT is, sometimes remount is necessary if mounted read-only

grep -q "$SYSTEM_MOUNT.*\sro[\s,]" /proc/mounts && mount -o remount,rw $SYSTEM_MOUNT || mount -o rw "$block" $SYSTEM_MOUNT

# Remount /system to /system_root if we have system-as-root and bind /system to /system_root/system (like Magisk does)
# For reference, check https://github.com/topjohnwu/Magisk/blob/master/scripts/util_functions.sh
if [ -f /system/init.rc ]; then
  mkdir /system_root
  mount --move /system /system_root
  mount -o bind /system_root/system /system
  export SYSTEM_ROOT=true
fi

# Initialice TSkernel folder
mkdir -p -m 777 /data/.tskernel 2>/dev/null

#======================================
# AROMA INIT
#======================================

set_progress 0.01

ui_print "@ThundeRStormS - Mount partitions"
ui_print "-- Mount /system RW"
if [ $SYSTEM_ROOT == true ]; then
	ui_print "-- Device is system-as-root"
	ui_print "-- Remounting /system as /system_root"
fi

set_progress 0.10
show_progress 0.40 -2000

## VARIABLES
SDK="$(file_getprop /system/build.prop ro.build.version.sdk)"
BL=`getprop ro.bootloader`
MODEL=${BL:0:5}
MODEL1=G975F
MODEL1_DESC="G975F"
MODEL2=G975N
MODEL2_DESC="G975N"
MODEL3=G973F
MODEL3_DESC="G973F"
MODEL4=G970F
MODEL4_DESC="G970F"
MODEL5=G970N
MODEL5_DESC="G970N"
MODEL6=G977B
MODEL6_DESC="G977B"
MODEL7=G977N
MODEL7_DESC="G977N"
MODEL8=N970F
MODEL8_DESC="N970F"
MODEL9=N975N
MODEL9_DESC="N975N"
MODEL10=N976N
MODEL10_DESC="N976N"
MODEL11=N971N
MODEL11_DESC="N971N"
MODEL12=N976B
MODEL12_DESC="N976B"
MODEL13=G973N
MODEL13_DESC="G973N"
if [ $MODEL == $MODEL1 ]; then MODEL_DESC=$MODEL1_DESC; fi
if [ $MODEL == $MODEL2 ]; then MODEL_DESC=$MODEL2_DESC; fi
if [ $MODEL == $MODEL3 ]; then MODEL_DESC=$MODEL3_DESC; fi
if [ $MODEL == $MODEL4 ]; then MODEL_DESC=$MODEL4_DESC; fi
if [ $MODEL == $MODEL5 ]; then MODEL_DESC=$MODEL5_DESC; fi
if [ $MODEL == $MODEL6 ]; then MODEL_DESC=$MODEL6_DESC; fi
if [ $MODEL == $MODEL7 ]; then MODEL_DESC=$MODEL7_DESC; fi
if [ $MODEL == $MODEL8 ]; then MODEL_DESC=$MODEL8_DESC; fi
if [ $MODEL == $MODEL9 ]; then MODEL_DESC=$MODEL9_DESC; fi
if [ $MODEL == $MODEL10 ]; then MODEL_DESC=$MODEL10_DESC; fi
if [ $MODEL == $MODEL11 ]; then MODEL_DESC=$MODEL11_DESC; fi
if [ $MODEL == $MODEL12 ]; then MODEL_DESC=$MODEL12_DESC; fi
if [ $MODEL == $MODEL13 ]; then MODEL_DESC=$MODEL13_DESC; fi
BASE="DTJA"
VERSION="v1.3"

## FLASH KERNEL
ui_print " "
ui_print "@ThundeRStormS - Flashing the kernel"
ui_print "-- Extracting ThundeRStormS kernel"
cd /data/tmp/ts
$BB tar -Jxf kernel.tar.xz ThundeRStormS-Kernel-$BASE-OneUI-Q-$MODEL_DESC-$VERSION.img
# $BB tar -xvf kernel.tar.xz ThundeRStormS-Kernel-$BASE-OneUI-Q-$MODEL_DESC-$VERSION.img
dd of=/dev/block/platform/13d60000.ufs/by-name/boot if=/data/tmp/ts/ThundeRStormS-Kernel-$BASE-OneUI-Q-$MODEL_DESC-$VERSION.img

## RUN INITIAL SCRIPT IMPLEMENTATOR
sh /data/tmp/ts/initial_settings.sh
	
set_progress 0.40

#======================================
# OPTIONS
#======================================

## THUNDERTWEAKS
if [ "$(file_getprop /tmp/aroma/menu.prop chk3)" == 1 ]; then
	ui_print " "
	ui_print "@ThundeRStormS - Installing ThunderTweaks App..."
	sh /data/tmp/ts/ts_clean.sh com.moro.mtweaks -as
    sh /data/tmp/ts/ts_clean.sh com.thunder.thundertweaks -as
    sh /data/tmp/ts/ts_clean.sh com.hades.hKtweaks -as

	mkdir -p /data/media/0/ThunderTweaks
	mkdir -p /sdcard/ThunderTweaks

# DELETE OLDER APPS
	rm -f /sdcard/ThunderTweaks/*.*
##	rm -rf /sdcard/ThunderTweaks/*.*

# COPY NEW APP
	cp -rf /data/tmp/ts/ttweaks/*.apk /data/media/0/ThunderTweaks
	cp -rf /data/tmp/ts/ttweaks/*.apk /sdcard/ThunderTweaks
fi

## THUNDERTWEAKS PROFILES
if [ "$(file_getprop /tmp/aroma/menu.prop chk4)" == 1 ]; then
	ui_print " "
	ui_print "@ThundeRStormS - Install ThunderTweaks Profiles..."
	mkdir -p /data/media/0/ThunderTweaks/profiles 2>/dev/null;
	mkdir -p /sdcard/ThunderTweaks/profiles 2>/dev/null;
	cp -rf /data/tmp/ts/ttweaks-profiles/. /data/media/0/ThunderTweaks/profiles/
	cp -rf /data/tmp/ts/ttweaks-profiles/. /sdcard/ThunderTweaks/profiles/
fi

set_progress 0.50

