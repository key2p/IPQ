#!/bin/sh

ROOT_DIR=$PWD
OPENWRT_DIR=${ROOT_DIR}/openwrt
WORK_DIR=${ROOT_DIR}/iso/src
ISO=${ROOT_DIR}/iso/wrt-dd-x64.iso

BOOT_DIR=${OPENWRT_DIR}/staging_dir/target-x86_64_musl/image/grub2
KERNEL_PATH=${OPENWRT_DIR}/build_dir/target-x86_64_musl/linux-x86_64/bzImage

ROOTFS_PATH=/dev/shm/minirootfs.tar.gz
ROOTFS_URL=https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/x86_64/alpine-minirootfs-3.20.3-x86_64.tar.gz
[ -e $ROOTFS_PATH ] || curl -L ${ROOTFS_URL} -o /dev/shm/minirootfs.tar.gz

rm -rf $WORK_DIR
mkdir -p $WORK_DIR
cd $WORK_DIR

mkdir -p $WORK_DIR/.boot/boot/grub
mkdir -p $WORK_DIR/root/usr/lib

tar -zxf $ROOTFS_PATH -C $WORK_DIR/root

rm -f $WORK_DIR/root/sbin/init
cp ${ROOT_DIR}/iso/init $WORK_DIR/root/sbin/init
chmod +x $WORK_DIR/root/sbin/init

rm $WORK_DIR/root/lib/libcrypt*

cp ${ROOT_DIR}/iso/iso_grub.cfg $WORK_DIR/.boot/boot/grub/grub.cfg
cp ${KERNEL_PATH} $WORK_DIR/.boot/boot/vmlinuz

cat ${BOOT_DIR}/cdboot.img ${BOOT_DIR}/eltorito.img > .boot/boot/grub/eltorito.img
mkfs.fat -C $WORK_DIR/.boot/boot/grub/isoboot.img -S 512 1440
mmd -i $WORK_DIR/.boot/boot/grub/isoboot.img ::/efi ::/efi/boot
mcopy -i $WORK_DIR/.boot/boot/grub/isoboot.img ${BOOT_DIR}/iso-bootx64.efi ::/efi/boot/bootx64.efi

cp -fa ${OPENWRT_DIR}/build_dir/target-x86_64_musl/root-x86/lib/{libgcc_s.so.1,libubox.so.20240329,libubus.so.20241020} $WORK_DIR/root/lib/
cp -fa ${OPENWRT_DIR}/build_dir/target-x86_64_musl/root-x86/usr/lib/{libparted*,libblk*,libncu*,libread*,libcom_err*,libe2p*,libf2fs*,libext2fs*,libuuid*} $WORK_DIR/root/usr/lib/
cp -fa ${OPENWRT_DIR}/build_dir/target-x86_64_musl/root-x86/sbin/parted $WORK_DIR/root/sbin
cp -fa ${OPENWRT_DIR}/build_dir/target-x86_64_musl/root-x86/usr/sbin/resize2fs $WORK_DIR/root/sbin

gunzip -dc ${OPENWRT_DIR}/bin/targets/x86/64/*ext4-combined-efi.img.gz | xz -zc9v > $WORK_DIR/root/dd.img.xz
#cp -fa ${OPENWRT_DIR}/bin/targets/x86/64/*ext4-combined-efi.img.gz $WORK_DIR/root/dd.img.gz

#xorriso -as mkisofs -R -b boot/grub/eltorito.img -no-emul-boot -boot-info-table -boot-load-size 4 -c boot.cat -eltorito-alt-boot -b boot/grub/isoboot.img -efi-boot-part --efi-boot-image -e boot/grub/iso-bootx64.efi -o ${ISO} ${WORK_DIR}/.boot ${WORK_DIR}/root

xorriso -as mkisofs -R -b boot/grub/eltorito.img -no-emul-boot -boot-info-table -boot-load-size 4 -c boot.cat -eltorito-alt-boot -b boot/grub/isoboot.img -o ${ISO} ${WORK_DIR}/.boot ${WORK_DIR}/root

cd ${ROOT_DIR}