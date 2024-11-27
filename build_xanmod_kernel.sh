#!/bin/bash
set -ex

export KERNEL_BASE_VER=linux-${KERNEL_BASE_VER}
export XANMOD_CONFIG=config_x86-64-v2

# define outer
#export WORK_DIR=/dev/shm/linux
#export KERNEL_BASE_URL=https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.12.tar.xz
#export XANMOD_PATCH=https://sourceforge.net/projects/xanmod/files/releases/edge/6.12.1-xanmod1/patch-6.12.1-xanmod1.xz/download

rm -rf ${WORK_DIR} || true
mkdir -p ${WORK_DIR} || true

## https://blobfolio.com/2024/building-a-custom-xanmod-kernel-on-ubuntu-23-10/
# if not exist llvm19 then build it
[ ! -e /opt/llvm19_krl ] && build_xanmod_docker.sh


# download source
curl -L ${KERNEL_BASE_URL}  -o /dev/shm/linux.tar.xz
curl -L ${XANMOD_PATCH}  -o /dev/shm/patch.xz

# Unpack the kernel sources and patches
cd ${WORK_DIR} && tar -xJf /dev/shm/linux.tar.xz && unxz -k /dev/shm/patch.xz
cd ${WORK_DIR}/${KERNEL_BASE_VER}
patch -Np1 -i /dev/shm/patch
rm /dev/shm/linux.tar.xz && rm /dev/shm/patch*

## https://github.com/graysky2/openwrt/commit/0628c0a4673ad349d517b579e72d88de9c3924a5#diff-d5daeb65b3fa0ba33c79958bd89ca5122a6211baa492081ed752652a9a1bbdd1R20
## CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE  boost build
sed -i "s/KBUILD_CFLAGS += -O2/KBUILD_CFLAGS += -O3/g" arch/x86/Makefile 
cat arch/x86/Makefile | grep KBUILD_CFLAGS

# build kernel
cp -a CONFIGS/xanmod/gcc/${XANMOD_CONFIG} .config
export MAIN_KCONFIG_FILE=.config

# enable kvm and disable xen
sed -i 's/CONFIG_XEN=[mny]/CONFIG_XEN=n/g'  			${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_HAVE_KVM=[mny]/CONFIG_HAVE_KVM=y/g'		${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_MODULE_COMPRESS_ZSTD=[mny]/CONFIG_MODULE_COMPRESS_ZSTD=y/g'  		${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_MODULE_DECOMPRESS=[mny]/CONFIG_MODULE_DECOMPRESS=y/g'  		${MAIN_KCONFIG_FILE}

# disable gpu
sed -i 's/CONFIG_DRM_AMDGPU=[mny]/CONFIG_DRM_AMDGPU=n/g'  	${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_DRM_RADEON=[mny]/CONFIG_DRM_RADEON=n/g'  	${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_DRM_NOUVEAU=[mny]/CONFIG_DRM_NOUVEAU=n/g'  	${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_DRM_XE=[mny]/CONFIG_DRM_XE=n/g'  		${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_INPUT_TOUCHSCREEN=[mny]/CONFIG_INPUT_TOUCHSCREEN=n/g'  ${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_SURFACE_PLATFORMS=[mny]/CONFIG_SURFACE_PLATFORMS=n/g'  ${MAIN_KCONFIG_FILE}

sed -i 's/CONFIG_HAVE_KERNEL_BZIP2=[mny]/CONFIG_HAVE_KERNEL_BZIP2=n/g'  ${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_HAVE_KERNEL_LZO=[mny]/CONFIG_HAVE_KERNEL_LZO=n/g'  	${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_HYPERV=[mny]/CONFIG_HYPERV=y/g'  			${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_VMXNET3=[mny]/CONFIG_VMXNET3=y/g' 			${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_TLS=[mny]/CONFIG_TLS=y/g' 				${MAIN_KCONFIG_FILE}

sed -i 's/CONFIG_WIRELESS=[mny]/CONFIG_WIRELESS=n/g' 			${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_WIRELESS_HOTKEY=[mny]/CONFIG_WIRELESS_HOTKEY=n/g'  	${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_SFC=[mny]/CONFIG_SFC=n/g'  				${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_SFC_FALCON=[mny]/CONFIG_SFC_FALCON=n/g'  			${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_SFC_SIENA=[mny]/CONFIG_SFC_SIENA=n/g'  			${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_NET_VENDOR_MARVELL=[mny]/CONFIG_NET_VENDOR_MARVELL=n/g'  	${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_NET_VENDOR_CAVIUM=[mny]/CONFIG_NET_VENDOR_CAVIUM=n/g'  	${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_NET_VENDOR_NETRONOME=[mny]/CONFIG_NET_VENDOR_NETRONOME=n/g'  	${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_NET_DSA_MV88E6060=[mny]/CONFIG_NET_DSA_MV88E6060=n/g'  	${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_NET_DSA_MV88E6XXX=[mny]/CONFIG_NET_DSA_MV88E6XXX=n/g'  	${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_NET_DSA_SJA1105=[mny]/CONFIG_NET_DSA_SJA1105=n/g' 	 	${MAIN_KCONFIG_FILE}

sed -i 's/CONFIG_BT=[mny]/CONFIG_BT=n/g'  			${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_WLAN=[mny]/CONFIG_WLAN=n/g' 			${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_ISDN=[mny]/CONFIG_ISDN=n/g'  			${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_NEW_LEDS=[mny]/CONFIG_NEW_LEDS=n/g'  		${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_NFC=[mny]/CONFIG_NFC=n/g'  			${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_INFINIBAND=[mny]/CONFIG_INFINIBAND=n/g'  	${MAIN_KCONFIG_FILE}

sed -i 's/CONFIG_SOUND=[mny]/CONFIG_SOUND=n/g' 		${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_SOUNDWIRE=[ymn]/CONFIG_SOUNDWIRE=n/g'  	${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_MEDIA_SUPPORT=[mny]/CONFIG_MEDIA_SUPPORT=n/g' ${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_VIDEO_DEV=[mny]/CONFIG_VIDEO_DEV=n/g' 	${MAIN_KCONFIG_FILE}

sed -i 's/CONFIG_BCACHEFS_FS=[mny]/CONFIG_BCACHEFS_FS=n/g' 	${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_BCACHE=[mny]/CONFIG_BCACHE=n/g' 		${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_BTRFS_FS=[mny]/CONFIG_BTRFS_FS=n/g' 		${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_OCFS2_FS=[mny]/CONFIG_OCFS2_FS=n/g' 		${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_F2FS_FS=[mny]/CONFIG_F2FS_FS=n/g' 		${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_GFS2_FS=[mny]/CONFIG_GFS2_FS=n/g' 		${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_JFFS2_FS=[mny]/CONFIG_JFFS2_FS=n/g' 		${MAIN_KCONFIG_FILE}

sed -i '/CONFIG_GPIO_BT8XX/e' ${MAIN_KCONFIG_FILE}
echo 'CONFIG_GPIO_BT8XX=n' >> ${MAIN_KCONFIG_FILE}

echo 'CONFIG_DEBUG_INFO_NONE=y' >> ${MAIN_KCONFIG_FILE}
echo 'CONFIG_DEBUG_INFO_DWARF4=n' >> ${MAIN_KCONFIG_FILE}
echo 'CONFIG_DEBUG_INFO_DWARF5=n' >> ${MAIN_KCONFIG_FILE}
echo 'CONFIG_DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT=n' >> ${MAIN_KCONFIG_FILE}

# for xdp https://pulsar.sh/docs/faq/kernel-requirements
sed -i 's/CONFIG_TEST_/# CONFIG_TEST_/g' 			${MAIN_KCONFIG_FILE}

echo 'CONFIG_TEST_BPF=n' >> ${MAIN_KCONFIG_FILE}
echo 'CONFIG_DEBUG_INFO=y' >> ${MAIN_KCONFIG_FILE}
echo 'CONFIG_DEBUG_INFO_BTF=y' >> ${MAIN_KCONFIG_FILE}
echo 'CONFIG_SECURITY=y' >> ${MAIN_KCONFIG_FILE}
echo 'CONFIG_SECURITYFS=y' >> ${MAIN_KCONFIG_FILE}
echo 'CONFIG_SECURITY_NETWORK=y' >> ${MAIN_KCONFIG_FILE}
echo 'CONFIG_FUNCTION_TRACER=y' >> ${MAIN_KCONFIG_FILE}
echo 'CONFIG_FTRACE_SYSCALLS=y' >> ${MAIN_KCONFIG_FILE}
echo 'CONFIG_BPF_LSM=y' >> ${MAIN_KCONFIG_FILE}

##### cloud 
sed -i 's/CONFIG_HW_CONSOLE=[mny]/CONFIG_HW_CONSOLE=n/g'		${MAIN_KCONFIG_FILE}

sed -i 's/CONFIG_UBSAN=[mny]/CONFIG_UBSAN=n/g' 		${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_FONTS=[mny]/CONFIG_FONTS=n/g' 		${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_AS3935=[mny]/CONFIG_AS3935=n/g' 	${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_THINKPAD_ACPI=[mny]/CONFIG_THINKPAD_ACPI=n/g' 		${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_VME_USER=[mny]/CONFIG_VME_USER=n/g' 	${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_LTE_GDM724X=[mny]/CONFIG_LTE_GDM724X=n/g' 		${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_GREYBUS=[mny]/CONFIG_GREYBUS=n/g' 	${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_COMEDI=[mny]/CONFIG_COMEDI=n/g' 	${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_LEDS_CLASS=[mny]/CONFIG_LEDS_CLASS=n/g' 		${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_MMC=[mny]/CONFIG_MMC=n/g' 		${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_TYPEC=[mny]/CONFIG_TYPEC=n/g' 		${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_USB_NET_DRIVERS=[mny]/CONFIG_USB_NET_DRIVERS=n/g'	${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_USB_USBNET=[mny]/CONFIG_USB_USBNET=n/g' 		${MAIN_KCONFIG_FILE}

sed -i 's/CONFIG_MTD=[mny]/CONFIG_MTD=n/g'  			${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_BNX2X=[mny]/CONFIG_BNX2X=n/g'  		${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_QED=[mny]/CONFIG_QED=n/g'  			${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_QLCNIC=[mny]/CONFIG_QLCNIC=n/g'  		${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_NET_VENDOR_CHELSIO=[mny]/CONFIG_NET_VENDOR_CHELSIO=n/g'  	${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_NET_VENDOR_META=[mny]/CONFIG_NET_VENDOR_META=n/g'  		${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_NET_VENDOR_MICREL=[mny]/CONFIG_NET_VENDOR_MICREL=n/g'  	${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_NET_VENDOR_MYRI=[mny]/CONFIG_NET_VENDOR_MYRI=n/g'  		${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_NET_VENDOR_NATSEMI=[mny]/CONFIG_NET_VENDOR_NATSEMI=n/g'  	${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_NET_VENDOR_NVIDIA=[mny]/CONFIG_NET_VENDOR_NVIDIA=n/g'  	${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_NET_VENDOR_OKI=[mny]/CONFIG_NET_VENDOR_OKI=n/g'  		${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_NET_VENDOR_QLOGIC=[mny]/CONFIG_NET_VENDOR_QLOGIC=n/g'  	${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_NET_VENDOR_QUALCOMM=[mny]/CONFIG_NET_VENDOR_QUALCOMM=n/g'	${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_NET_VENDOR_RDC=[mny]/CONFIG_NET_VENDOR_RDC=n/g'		${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_NET_VENDOR_RENESAS=[mny]/CONFIG_NET_VENDOR_RENESAS=n/g'	${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_NET_VENDOR_SMSC=[mny]/CONFIG_NET_VENDOR_SMSC=n/g'	${MAIN_KCONFIG_FILE}

sed -i 's/CONFIG_TABLET/# CONFIG_TABLET/g' 			${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_CHARGER_/# CONFIG_CHARGER_/g' 			${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_BATTERY/# CONFIG_BATTERY/g' 			${MAIN_KCONFIG_FILE}
sed -i 's/CONFIG_LEDS/# CONFIG_LEDS/g' 				${MAIN_KCONFIG_FILE}

#sed -i 's/CONFIG_IIO=[mny]/CONFIG_IIO=n/g' 			${MAIN_KCONFIG_FILE}
#sed -i 's/CONFIG_PMBUS=[mny]/CONFIG_PMBUS=n/g' 		${MAIN_KCONFIG_FILE}
#sed -i 's/CONFIG_SENSORS/# CONFIG_SENSORS/g' 			${MAIN_KCONFIG_FILE}
#sed -i 's/CONFIG_KGDB=[mny]/CONFIG_KGDB=n/g' 			${MAIN_KCONFIG_FILE}
#sed -i 's/CONFIG_PHYLIB=[mny]/CONFIG_PHYLIB=n/g' 		${MAIN_KCONFIG_FILE}
#sed -i 's/CONFIG_DRM_I915=[mny]/CONFIG_DRM_I915=n/g'  		${MAIN_KCONFIG_FILE}
#sed -i 's/CONFIG_I40E=[mny]/CONFIG_I40E=n/g'  			${MAIN_KCONFIG_FILE}
#sed -i 's/CONFIG_ICE=[mny]/CONFIG_ICE=n/g'  			${MAIN_KCONFIG_FILE}
#sed -i 's/CONFIG_MLX5_/# CONFIG_MLX5_/g' 			${MAIN_KCONFIG_FILE}

#### cloud end

# build opt
echo 'CONFIG_LTO_CLANG_THIN=y' 			>> ${MAIN_KCONFIG_FILE}
echo 'CONFIG_DEBUG_INFO_COMPRESSED_ZLIB=y' 	>> ${MAIN_KCONFIG_FILE}
echo 'CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE=y' 	>> ${MAIN_KCONFIG_FILE}
   
# Append a timestamp or something to the localversion to make it unique:
echo "$( cat localversion )-$( date +%s )" > localversion
export DEBFULLNAME="Alexandre Frade"
export DEBEMAIL="kernel@xanmod.org"
export KDEB_CHANGELOG_DIST="bookworm"
#export KCONFIG_CONFIG="CONFIGS/xanmod/gcc/config_$psabi"

export lv=$(make -s kernelversion)
export xv=$(cat localversion)
export rv=0

PAREL_BUILD=$(nproc)
if [ "$PAREL_BUILD" -ge '8' ]; then
  PAREL_BUILD=8
fi
		
date; make olddefconfig LLVM=1 LLVM_IAS=1
date; make KDEB_COMPRESS=xz bindeb-pkg -j${PAREL_BUILD} LLVM=1 LLVM_IAS=1
date

# build perf
create_package() {
	local pname="$1" pdir="$2"
	local dpkg_deb_opts

	mkdir -m 755 -p "$pdir/DEBIAN"
	mkdir -p "$pdir/usr/share/doc/$pname"
	cp debian/copyright "$pdir/usr/share/doc/$pname/"
	cp debian/changelog "$pdir/usr/share/doc/$pname/changelog.Debian"
	gzip -n -9 "$pdir/usr/share/doc/$pname/changelog.Debian"
	sh -c "cd '$pdir'; find . -type f ! -path './DEBIAN/*' -printf '%P\\0' | xargs -r0 md5sum > DEBIAN/md5sums"

	# Fix ownership and permissions
	if [ "$DEB_RULES_REQUIRES_ROOT" = "no" ]; then
		dpkg_deb_opts="--root-owner-group"
	else
		chown -R root:root "$pdir"
	fi
	# a+rX in case we are in a restrictive umask environment like 0077
	# ug-s in case we build in a setuid/setgid directory
	chmod -R go-w,a+rX,ug-s "$pdir"

	# Create the package
	#dpkg-gencontrol -p$pname -P"$pdir"
    	cp ./debian/control "$pdir/DEBIAN/"
	dpkg-deb $dpkg_deb_opts ${KDEB_COMPRESS:+-Z$KDEB_COMPRESS} --build "$pdir" ..
}

tools_version=$lv$pv$xv
tools_packagename=linux-tools
tools_destdir=./linux-tools-tmp
tools_destdir=`readlink -f $tools_destdir`
rm -rf $tools_destdir

make -C ./tools/perf prefix=/usr DESTDIR=$tools_destdir install  NO_LIBZSTD=1 NO_LIBPERL=1  NO_LIBBABELTRACE=1
make -C ./tools/power/cpupower DESTDIR=$tools_destdir prefix=/usr install  NO_LIBZSTD=1 NO_LIBPERL=1 NO_LIBBABELTRACE=1

cat <<DEOF > debian/control   
Package: $tools_packagename
Architecture: amd64
Replaces: linux-base, linux-tools-common
Depends: libc6, libcap2, libdw1, libelf1, liblzma5, libnuma1, libpci3, libudev1, libunwind8, zlib1g
Description: Performance analysis tools for Linux $tools_version
 This package contains the 'perf' performance analysis tools for Linux
 kernel version $tools_version .
Maintainer: linux
Version: $tools_version

DEOF

# create perf deb
KDEB_COMPRESS=xz create_package \"$tools_packagename\" $tools_destdir

# build x64v3
cp ${MAIN_KCONFIG_FILE} ${MAIN_KCONFIG_FILE}.v2
if [[ $XANMOD_CONFIG =~ "-v2" ]]; then
  sed -i 's/x64v2/x64v3/g'  						${MAIN_KCONFIG_FILE}
  sed -i 's/CONFIG_X86_64_VERSION=2/CONFIG_X86_64_VERSION=3/g'  	${MAIN_KCONFIG_FILE}
  make olddefconfig LLVM=1 LLVM_IAS=1
  make KDEB_COMPRESS=xz bindeb-pkg -j${PAREL_BUILD} LLVM=1 LLVM_IAS=1
fi


# build cloud image
#rm ${MAIN_KCONFIG_FILE} || true
#cp -f ${MAIN_KCONFIG_FILE}.v2 ${MAIN_KCONFIG_FILE}

