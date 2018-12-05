#! /bin/bash
####
NDK=r18b
#### true|false
LOG=true
####
APP=true
####
UPX=false
####
LIBUSB=false
####
PCSC=false
####
CONF="/data/local"
###########################################
UPX_VERSION="3.95"
OPENSSL_VERSION="1.1.1a"
LIBUSB_VERSION="1.0.22"
PCSC_LITE_VERSION="1.8.23"
CCID_VERSION="1.4.29"
SOURCEDIR="sources"
###########################################
menu_api(){
[ -e $dir/patches/stapi/libwi.a ] && [ -e $dir/patches/stapi/stapi.patch ] && stapi="stapi "'Openbox_Xcruiser(experimental)'" off";
cmd=(dialog --separate-output --no-cancel --checklist "OSCam${TYPE} Rev:$FILE_REV" 16 60 10)
options=(16	"4.1 Jelly Bean" off
	17	"4.2 Jelly Bean" off
	18	"4.3 Jelly Bean" off
	19	"4.4 KitKat" off
	21	"5.0 Lollipop" off
	22	"5.1 Lollipop" off
	23	"6.0 Marshmallow" off
	24	"7.0 Nougat" off
	26	"8.0 Oreo" off
	27	"8.1 Oreo" off
	28	"9.0 Pie" off
	Ax	"Amiko" off
	WP2	"WeTek Play 2" off
	$stapi)

choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
for choice in $choices
do
    case $choice in
	Ax)
	BOX="Amiko"
	API="19"
	ABI="armeabi-v7a"
	CONF="/var/tuxbox/config"
	APP=false
	BUILD
	;;
	WP2)
	BOX="WeTek_Play_2"
	API="21"
	ABI="armeabi-v7a"
	CONF="/data/local"
	APP=true
	BUILD
	;;
	stapi)
	BOX="Openbox_Xcruiser"
	API="21"
	ABI="armeabi-v7a"
	CONF="/data/plugin/oscam"
	APP=false
	BUILD
	rm -rf $sources/$cam
	;;
	14|15|16|17|18|19|21|22|23|24|26|27|28)
	API=$choice
	menu_abi
	;;
	esac
	done
clear
}
######
menu_abi(){
cmd=(dialog --separate-output --no-cancel --checklist "OSCam${TYPE} Rev:$FILE_REV (android-$API)" 11 60 10)
options=(armeabi-v7a "arm-linux-android" off
	 x86 "i686-linux-android" off
	 arm64 "aarch64-linux-android" off
	 x86_64 "x86_64-linux-android" off)
choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
for choice in $choices
do
    case $choice in
	armeabi-v7a)
	ABI="armeabi-v7a"
	BUILD
	;;
	x86)
	ABI="x86"
	BUILD
	;;
	arm64)
	ABI="arm64-v8a"
	[ "$API" -lt "21" ] && API="21"
	BUILD
	;;
	x86_64)
	ABI="x86_64"
	[ "$API" -lt "21" ] && API="21"
	BUILD
	;;
	esac
	done
clear
}
######
[ ! -d $SOURCEDIR ] && mkdir -p $SOURCEDIR
dir=`pwd`
cd $SOURCEDIR
sources=`pwd`
######
export NCURSES_NO_UTF8_ACS=1
#export LOCALE=UTF-8
progressbox="dialog --stdout ""$1"" --progressbox 15 70";
######
BUILD(){
ndk
make -C $sources/$cam config
CONF=$(dialog --no-cancel --title "Oscam config dir:" --inputbox $CONF 8 30 $CONF 3>&1 1>&2 2>&3)
[ -e $sources/config.mk ] && rm -rf $sources/config.mk
[ "$TYPE" = "-emu" ] && TYPE="-emu"$(grep -a "Version:" $sources/emu/VERSION | cut -d ' ' -f 2);
PLATFORM=android-$API
case $choice in A*|W*)PLATFORM=$BOX;;esac
if [ "$choice" = "stapi" ] ; then
PLATFORM=$BOX
patch -d $sources/$cam -p0 < $dir/patches/stapi/stapi.patch | $progressbox
rej=($sources/$cam/*.rej)
[ -e "${rej[0]}" ] && dialog --title "ERROR!" --msgbox '                PATCH ERROR! '$cam'' 5 60 && exit;
fi
echo "DIR := $sources" >> $sources/config.mk
echo "CAM := $cam" >> $sources/config.mk
echo "PLATFORM := $PLATFORM" >> $sources/config.mk
echo "CONFDIR := $CONF" >> $sources/config.mk
echo "REV := ${FILE_REV}${TYPE}" >> $sources/config.mk
echo "OPENSSL := openssl-${OPENSSL_VERSION}" >> $sources/config.mk
ssl
if $LIBUSB || $PCSC ; then
echo "LIBUSB := libusb-${LIBUSB_VERSION}" >> $sources/config.mk
usb
fi
if $LIBUSB ; then
echo "usb := true" >> $sources/config.mk
else
echo "usb := false" >> $sources/config.mk
fi
if $PCSC && $APP ; then
echo "PCSC_LITE := pcsc-lite-${PCSC_LITE_VERSION}" >> $sources/config.mk
echo "CCID := ccid-${CCID_VERSION}" >> $sources/config.mk
echo "pcsc := true" >> $sources/config.mk
pcsc
ccid
else
echo "pcsc := false" >> $sources/config.mk
fi
if [ "$cam" = "OSCam" ] ; then
echo "emu := false" >> $sources/config.mk
else
echo "emu := true" >> $sources/config.mk
fi
if [ "$choice" = "stapi" ] ; then
echo "stapi := true" >> $sources/config.mk
else
echo "stapi := false" >> $sources/config.mk
fi
[ ! -e $dir/packages/oscam.mk ] && wget -q -P $dir/packages -c https://raw.githubusercontent.com/su-mak/osebuild/master/packages/oscam.mk;
if $LOG ; then
rm -rf $sources/build.log
$sources/android-ndk-$NDK/ndk-build APP_ABI=$ABI APP_PLATFORM=android-$API NDK_PROJECT_PATH=$sources NDK_LOG=1 APP_BUILD_SCRIPT=$dir/packages/oscam.mk 2>&1 | tee -a "$sources/build.log" | $progressbox
else
$sources/android-ndk-$NDK/ndk-build APP_ABI=$ABI APP_PLATFORM=android-$API NDK_PROJECT_PATH=$sources APP_BUILD_SCRIPT=$dir/packages/oscam.mk 2>&1 | $progressbox
fi
if [ ! -e $sources/libs/$ABI/oscam ] ; then
dialog --title "WARNING!" --msgbox "\n                     BUILD ERROR!" 7 60
else
$UPX && UPX_ && $sources/upx-${UPX_VERSION}-amd64_linux/upx --brute $sources/libs/$ABI/oscam;
name="oscam-1.20-unstable_svn-${FILE_REV}${TYPE}-$PLATFORM"
ZIP | $progressbox
dialog --title "$ABI" --msgbox "\n $name" 7 60
fi
}
######
ZIP(){
if $APP && [ -e $dir/application/cam.apk ] ; then
apkdir="$dir/application/storage/OSEbuild/installation"
mkdir -p $apkdir
zip -j $apkdir/oscam-$ABI.zip -xi $sources/libs/$ABI/oscam
if $PCSC ; then
zip -j $apkdir/pcscd-${ABI}.zip -xi $sources/usr/sbin/android-$API/$ABI/pcscd
zip -j $apkdir/libccid-${ABI}.zip -xi $sources/usr/lib/android-$API/$ABI/libccid.so
zip -j $apkdir/libccidtwin-${ABI}.zip -xi $sources/usr/lib/android-$API/$ABI/libccidtwin.so
zip -j $apkdir/Info.plist.zip -xi $dir/packages/ccid/Info.plist
fi
cd $dir
zip -r $dir/$name-$ABI.zip -xi application
rm -rf $dir/application/storage
fi
zip -j $dir/$name-$ABI.zip -xi $sources/libs/$ABI/oscam
zip -j $dir/$name-$ABI.zip -xi $sources/$cam/README
$LOG && zip -j $dir/$name-$ABI.zip -xi $sources/build.log;
[ "$choice" = "stapi" ] && [ -e $dir/patches/stapi/plugin.sh ] && . $dir/patches/stapi/plugin.sh;
rm -rf $sources/*obj* $sources/libs
}
######
ndk(){
FILE="android-ndk-$NDK-linux-x86_64.zip"
URL="https://dl.google.com/android/repository/$FILE"
if [ ! -d $sources/android-ndk-$NDK ] ; then
[ ! -e $sources/$FILE ] && SOURCE;
unzip $sources/$FILE | $progressbox
fi
clear
}
######
ssl(){
if [ ! -e $sources/usr/lib/android-$API/$ABI/libcrypto_static.a ] ; then
lssl="openssl-${OPENSSL_VERSION}"
FILE="$lssl.tar.gz"
URL="http://www.openssl.org/source/$FILE"
SOURCE
[ ! -d $sources/$lssl ] && tar -xf $sources/$FILE;
case $ABI in
armeabi-v7a)
CONFIG="android-arm"
TOOLCHAINS="arm-linux-androideabi"
;;
arm64-v8a)
CONFIG="android-arm64"
TOOLCHAINS="aarch64-linux-android"
;;
x86)
CONFIG="android-x86"
TOOLCHAINS="x86"
;;
x86_64)
CONFIG="android-x86_64"
TOOLCHAINS="x86_64"
;;
esac
export ANDROID_NDK=$sources/android-ndk-$NDK
export PATH=$ANDROID_NDK/toolchains/$TOOLCHAINS-4.9/prebuilt/linux-x86_64/bin:$PATH
cd $sources/$lssl && ./Configure $CONFIG -D__ANDROID_API__=$API no-afalgeng no-aria no-asan no-asm no-async no-autoalginit no-autoerrinit no-autoload-config no-bf no-blake2 no-camellia no-capieng no-cast no-chacha no-cmac no-cms no-comp no-crypto-mdebug no-crypto-mdebug-backtrace no-ct no-deprecated no-devcryptoeng no-dgram no-dh no-dsa no-dso no-dtls no-dynamic-engine no-ec no-ec2m no-ecdh no-ecdsa no-ec_nistp_64_gcc_128 no-egd no-engine no-err no-external-tests no-filenames no-fuzz-libfuzzer no-fuzz-afl no-gost no-heartbeats no-idea no-makedepend no-md2 no-md4 no-msan no-multiblock no-nextprotoneg no-ocb no-ocsp no-pic no-poly1305 no-posix-io no-psk no-rc2 no-rc4 no-rc5 no-rdrand no-rfc3779 no-rmd160 no-scrypt no-sctp no-seed no-shared no-siphash no-sm2 no-sm3 no-sm4 no-sock no-srp no-srtp no-sse2 no-ssl no-ssl-trace no-stdio no-tests no-threads no-tls no-ts no-ubsan no-ui-console no-unit-test no-whirlpool no-weak-ssl-ciphers no-zlib no-zlib-dynamic no-ssl3 no-ssl3-method no-tls1 no-tls1-method no-tls1_1 no-tls1_1-method no-tls1_2 no-tls1_2-method no-tls1_3 no-dtls1 no-dtls1-method no-dtls1_2 no-dtls1_2-method > /dev/null && cd $sources
make -C $sources/$lssl crypto/include/internal/bn_conf.h > /dev/null
make -C $sources/$lssl crypto/include/internal/dso_conf.h > /dev/null
make -C $sources/$lssl crypto/buildinf.h > /dev/null
make -C $sources/$lssl include/openssl/opensslconf.h > /dev/null
[ ! -e $dir/packages/openssl.mk ] && wget -q -P $dir/packages -c https://raw.githubusercontent.com/su-mak/osebuild/master/packages/openssl.mk;
$sources/android-ndk-$NDK/ndk-build APP_ABI=$ABI APP_PLATFORM=android-$API NDK_PROJECT_PATH=$sources APP_BUILD_SCRIPT=$dir/packages/openssl.mk 2>&1 | $progressbox
[ ! -d $sources/usr/lib/android-$API/$ABI ] && mkdir -p $sources/usr/lib/android-$API/$ABI;
mv $sources/obj/local/$ABI/libcrypto_static.a $sources/usr/lib/android-$API/$ABI/libcrypto_static.a
[ ! -d $sources/usr/include/android-$API/$ABI/openssl ] && mkdir -p $sources/usr/include/android-$API/$ABI/openssl;
mv -f $sources/$lssl/include/openssl/opensslconf.h $sources/usr/include/android-$API/$ABI/openssl/opensslconf.h
cp -r $sources/$lssl/include/openssl $sources/usr/include
rm -rf $sources/$lssl $sources/*obj*
if [ ! -e $sources/usr/lib/android-$API/$ABI/libcrypto_static.a ] ; then
dialog --title "EXIT" --yesno "BUILD ERROR: $lssl" 5 60
case $? in
   0) clear && exit ;;
esac
fi
fi
}
######
usb(){
if [ ! -e $sources/usr/lib/android-$API/$ABI/libusb1.0_static.a ] ; then
lusb="libusb-${LIBUSB_VERSION}"
FILE="$lusb.tar.bz2"
URL="https://github.com/libusb/libusb/releases/download/v${LIBUSB_VERSION}/$FILE"
SOURCE
[ ! -d $sources/$lusb ] && tar -jxf $sources/$FILE;
[ ! -e $dir/packages/libusb.mk ] && wget -q -P $dir/packages -c https://raw.githubusercontent.com/su-mak/osebuild/master/packages/libusb.mk;
$sources/android-ndk-$NDK/ndk-build APP_ABI=$ABI APP_PLATFORM=android-$API NDK_PROJECT_PATH=$sources APP_BUILD_SCRIPT=$dir/packages/libusb.mk 2>&1 | $progressbox
[ ! -d $sources/usr/lib/android-$API/$ABI ] && mkdir -p $sources/usr/lib/android-$API/$ABI;
mv $sources/obj/local/$ABI/libusb1.0_static.a $sources/usr/lib/android-$API/$ABI/libusb1.0_static.a
[ ! -d $sources/usr/include/libusb-1.0 ] && mkdir -p $sources/usr/include/libusb-1.0;
cp $sources/$lusb/libusb/libusb.h $sources/usr/include/libusb-1.0/
rm -rf $sources/$lusb $sources/*obj*
if [ ! -e $sources/usr/lib/android-$API/$ABI/libusb1.0_static.a ] ; then
dialog --title "EXIT" --yesno "BUILD ERROR: $lusb" 5 60
case $? in
   0) clear && exit ;;
esac
fi
fi
}
######
pcsc(){
if [ ! -e $sources/usr/lib/android-$API/$ABI/libpcsclite_static.a ] || [ ! -e $sources/usr/sbin/android-$API/$ABI/pcscd ] ; then
pcscd="pcsc-lite-${PCSC_LITE_VERSION}"
FILE="$pcscd.tar.bz2"
URL="https://pcsclite.apdu.fr/files/$FILE"
SOURCE
[ ! -d $sources/$pcscd ] && tar -jxf $sources/$FILE;
for i in pcsc.mk config.h pcscd.h pcsclite.h
do
[ ! -e $dir/packages/pcsc/$i ] && wget -q -P $dir/packages/pcsc -c https://raw.githubusercontent.com/su-mak/osebuild/master/packages/pcsc/$i;
done
cp $dir/packages/pcsc/config.h $sources/$pcscd/
cp $dir/packages/pcsc/pcscd.h $sources/$pcscd/src/
cp $dir/packages/pcsc/pcsclite.h $sources/$pcscd/src/PCSC/
$sources/android-ndk-$NDK/ndk-build APP_ABI=$ABI APP_PLATFORM=android-$API NDK_PROJECT_PATH=$sources APP_BUILD_SCRIPT=$dir/packages/pcsc/pcsc.mk 2>&1 | $progressbox
[ ! -d $sources/usr/sbin/android-$API/$ABI ] && mkdir -p $sources/usr/sbin/android-$API/$ABI;
mv $sources/libs/$ABI/pcscd $sources/usr/sbin/android-$API/$ABI/
mv $sources/obj/local/$ABI/libpcsclite_static.a $sources/usr/lib/android-$API/$ABI/libpcsclite_static.a
[ ! -d $sources/usr/include/PCSC ] && mkdir -p $sources/usr/include/PCSC;
cp $sources/$pcscd/src/PCSC/*.h $sources/usr/include/PCSC
rm -rf $pcscd $sources/*obj* $sources/libs
if [ ! -e $sources/usr/lib/android-$API/$ABI/libpcsclite_static.a ] || [ ! -e $sources/usr/sbin/android-$API/$ABI/pcscd ] ; then
dialog --title "EXIT" --yesno "BUILD ERROR: $pcscd" 5 60
case $? in
   0) clear && exit ;;
esac
fi
fi
}
######
ccid(){
if [ ! -e $sources/usr/lib/android-$API/$ABI/libccid.so ] || [ ! -e $sources/usr/lib/android-$API/$ABI/libccidtwin.so ] ; then
lccid="ccid-${CCID_VERSION}"
FILE="$lccid.tar.bz2"
URL="https://ccid.apdu.fr/files/$FILE"
SOURCE
[ ! -d $sources/$lccid ] && tar -jxf $sources/$FILE;
for i in ccid.mk config.h Info.plist
do
[ ! -e $dir/packages/ccid/$i ] && wget -q -P $dir/packages/ccid -c https://raw.githubusercontent.com/su-mak/osebuild/master/packages/ccid/$i;
done
cp $dir/packages/ccid/config.h $sources/$lccid/
$sources/android-ndk-$NDK/ndk-build APP_ABI=$ABI APP_PLATFORM=android-$API NDK_PROJECT_PATH=$sources APP_BUILD_SCRIPT=$dir/packages/ccid/ccid.mk 2>&1 | $progressbox
[ ! -d $sources/usr/lib/android-$API/$ABI ] && mkdir -p $sources/usr/lib/android-$API/$ABI;
mv $sources/libs/$ABI/libccid*.so $sources/usr/lib/android-$API/$ABI/
rm -rf $lccid $sources/*obj* $sources/libs
if [ ! -e $sources/usr/lib/android-$API/$ABI/libccid.so ] || [ ! -e $sources/usr/lib/android-$API/$ABI/libccidtwin.so ] ; then
dialog --title "EXIT" --yesno "BUILD ERROR: $lccid" 5 60
case $? in
   0) clear && exit ;;
esac
fi
fi
}
######
UPX_(){
if [ ! -d $sources/upx-${UPX_VERSION}-amd64_linux/upx ] && $UPX ; then
FILE="upx-${UPX_VERSION}-amd64_linux.tar.xz"
URL="https://github.com/upx/upx/releases/download/v${UPX_VERSION}/$FILE"
SOURCE
tar -xf $sources/$FILE
fi
clear
}
######
SOURCE(){
[ ! -e $sources/$FILE ] && wget -P $sources -c --progress=bar:force "$URL" 2>&1 | while read -d "%" X; do sed 's:^.*[^0-9]\([0-9]*\)$:\1:' <<< "$X"; done | dialog --title "" --clear --stdout --gauge "$FILE" 6 50;
[ ! -e $sources/$FILE ] && dialog --title "ERROR!" --msgbox '                 DOWNLOAD ERROR! \n '$URL'' 7 50 && clear && exit;
}
######
rev() {
if [ ! -e $sources/$cam ] ; then
REV=$(dialog --no-cancel --title " OSCam$TYPE ($SVN_MIN to $REV_EMU)" --inputbox "" 7 35 "$REV_EMU" 3>&1 1>&2 2>&3)
SVN
else
dialog --title "OSCam$TYPE UPDATE" --backtitle "" --yesno "Online SVN ('$REV_EMU') = Local SVN ('$FILE_REV')" 7 50
response=$?
case $response in
   0)REV=$(dialog  --no-cancel --title " Local svn:$FILE_REV ($SVN_MIN to $REV_EMU)" --inputbox "" 8 35 "$REV_EMU" 3>&1 1>&2 2>&3) && SVN;;
esac
fi
FILE_REV=$(svn info $sources/$cam | grep Revision | cut -d ' ' -f 2)
menu_api
}
######
SVN(){
if [ "$REV" -ge $SVN_MIN ] && [ "$REV" -le "$REV_EMU" ] ; then
null="null"
else
rev
fi
if [ "$cam" = "OSCam_Emu" ] ; then
[ -e $sources/$cam ] && rm -rf $sources/$cam;
svn co -r $REV $SVN_EMU emu | $progressbox
REV=$(grep -a " Makefile" emu/oscam-emu.patch | grep -a "revision" | cut -c24-28)
svn co -r $REV $SVN_SOURCE $sources/$cam | $progressbox
patch -d $sources/$cam -p0 < $sources/emu/oscam-emu.patch | $progressbox
else
svn co -r $REV $SVN_SOURCE $sources/$cam | $progressbox
REV=$(svn info $sources/$cam | grep Revision | cut -d ' ' -f 2)
fi
}
####
OSCAM() {
SVN_SOURCE="http://www.streamboard.tv/svn/oscam/trunk"
REV_EMU=$(svn info $SVN_SOURCE | grep Revision | cut -d ' ' -f 2)
REV=$REV_EMU
SVN_MIN="11438"
TYPE=""
cam="OSCam"
[ -e $sources/$cam ] && FILE_REV=$(svn info $sources/$cam | grep Revision | cut -d ' ' -f 2);
rev
}
####
OSCAM_EMU() {
SVN_EMU="https://github.com/oscam-emu/oscam-emu/trunk"
SVN_SOURCE="http://www.streamboard.tv/svn/oscam/trunk"
REV_EMU=$(svn info $SVN_EMU | grep Revision | cut -d ' ' -f 2)
REV=$REV_EMU
SVN_MIN="1867"
TYPE="-emu"
cam="OSCam_Emu"
[ -e $sources/emu ] && FILE_REV=$(svn info $sources/emu | grep Revision | cut -d ' ' -f 2);
rev
}
####
OSCAM_PATCHED() {
SVN_SOURCE="https://github.com/oscam-emu/oscam-patched/trunk"
REV_EMU=$(svn info $SVN_SOURCE | grep Revision | cut -d ' ' -f 2)
REV=$REV_EMU
SVN_MIN="1595"
TYPE="-patched"
cam="OSCam_patched"
[ -e $sources/$cam ] && FILE_REV=$(svn info $sources/$cam | grep Revision | cut -d ' ' -f 2);
rev
}
######
menu(){
selected=$(dialog --stdout --clear --colors --backtitle $0 --title "" --menu "" 9 60 8 \
	1	"Oscam" \
	2	"Oscam-emu" \
	4	"Oscam-patched");
case $selected in
	1) OSCAM ;;
	2) OSCAM_EMU ;;
	4) OSCAM_PATCHED ;;
	esac
clear
}
##############
case $1 in
h|-h|--h|help|-help|--help|Help|HELP)
MACHINE=`uname -o`
MACHINE_TYPE=`uname -m`
if [ $MACHINE_TYPE = 'x86_64' ] ; then
case "$MACHINE" in
GNU/Linux*)
echo "-----------------------------"
echo "Build:     "
echo "	OSCam"
echo "	OSCam Emu"
echo "	Oscam-patched"
echo "-----------------------------"
echo "PLATFORM:"
echo "	ANDROID:arm,arm64,x86,x86_64"
echo "-----------------------------"
echo "Packages required:"
echo "		dialog subversion gcc make zip"
echo "-----------------------------"
echo "   $0"
echo "-----------------------------"
;;
*)
echo "this is not linux operating system"
;;
esac
else
echo "this is not linux x86_64 operating system"
fi
exit 0;
;;
esac
##############
menu
##############
exit;

