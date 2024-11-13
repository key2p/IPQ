#!/bin/bash
set -ex

sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

./scripts/feeds update -a

rm -rf feeds/packages/net/{alist,adguardhome,mosdns,xray*,v2ray*,v2ray*,sing*,smartdns}
rm -rf feeds/packages/multimedia/{ffmpeg*, fswebcam}

# TTYD 免登录
sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config

# apk version 兼容
sed -i 's/PKG_VERSION/PKG_SRC_VERSION/g' feeds/packages/net/vlmcsd/Makefile
sed -i '/svn1113/i\\PKG_VERSION:=1.1.13' feeds/packages/net/vlmcsd/Makefile
sed -i '/PKG_SOURCE_URL/i\\PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_SRC_VERSION)' feeds/packages/net/vlmcsd/Makefile

sed -i '/PKG_VERSION/d' feeds/luci/themes/luci-theme-argon/Makefile
sed -i '/PKG_RELEASE/d' feeds/luci/themes/luci-theme-argon/Makefile

sed -i '/PKG_VERSION/d' feeds/luci/applications/luci-app-arpbind/Makefile
sed -i '/PKG_RELEASE/d' feeds/luci/applications/luci-app-arpbind/Makefile

sed -i '/PKG_VERSION/d' feeds/luci/applications/luci-app-autoreboot/Makefile
sed -i '/PKG_RELEASE/d' feeds/luci/applications/luci-app-autoreboot/Makefile

sed -i '/PKG_VERSION/d' feeds/luci/applications/luci-app-*/Makefile
sed -i '/PKG_RELEASE/d' feeds/luci/applications/luci-app-*/Makefile

# nftables 最新的patch不兼容
# rm package/network/utils/nftables/patches/*

# 移除要替换的包
rm -rf feeds/packages/net/mosdns
rm -rf feeds/packages/net/msd_lite
rm -rf feeds/packages/net/smartdns
rm -rf feeds/luci/themes/luci-theme-netgear
rm -rf feeds/luci/themes/luci-theme-bootstrap*
rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf feeds/luci/applications/luci-app-netdata
rm -rf feeds/luci/applications/luci-app-serverchan
rm -rf feeds/luci/applications/luci-theme-bootstrap*
rm -rf feeds/luci/applications/luci-app-openclash
rm -rf feeds/luci/applications/luci-app-passwall
rm -rf feeds/luci/applications/luci-app-homeproxy

# 移除不需要的包
rm -rf feeds/smpackage/{adguardhome,base-files,dnsmasq,firewall*,fullconenat,libnftnl,nftables,ppp,opkg,ucl,upx,vsftpd-alt,miniupnpd-iptables,wireless-regdb}
rm -rf feeds/packages/{adguardhome,alist,frp,nps}

#修改默认主题, 更改 Argon 主题背景
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
#cp -f $GITHUB_WORKSPACE/images/bg1.jpg package/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg
rm feeds/luci/themes/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg || true

# msd_lite
git clone --depth=1 https://github.com/ximiTech/luci-app-msd_lite package/luci-app-msd_lite
git clone --depth=1 https://github.com/ximiTech/msd_lite package/msd_lite

sed -i '/PKG_VERSION/d' package/luci-app-*/Makefile
sed -i '/PKG_RELEASE/d' package/luci-app-*/Makefile

# 修复 hostapd 报错
cp -f $GITHUB_WORKSPACE/scripts/011-fix-mbo-modules-build.patch package/network/services/hostapd/patches/011-fix-mbo-modules-build.patch

# 修复 armv8 设备 xfsprogs 报错
sed -i 's/TARGET_CFLAGS.*/TARGET_CFLAGS += -DHAVE_MAP_SYNC -D_LARGEFILE64_SOURCE/g' feeds/packages/utils/xfsprogs/Makefile
#sed -i '$a src-git smpackage https://github.com/kenzok8/small-package' feeds.conf.default

#./scripts/feeds update

rm -rf feeds/packages/net/{alist,adguardhome,mosdns,xray*,v2ray*,v2ray*,sing*,smartdns}
rm -rf feeds/packages/multimedia/{ffmpeg*, fswebcam}
rm -rf feeds/smpackage/{base-files,dnsmasq,firewall*,fullconenat,libnftnl,nftables,ppp,opkg,ucl,upx,vsftpd-alt,miniupnpd-iptables,wireless-regdb}
rm -rf feeds/packages/lang/golang
#git clone https://github.com/sbwml/packages_lang_golang -b 22.x feeds/packages/lang/golang

./scripts/feeds install -a  


# Configure startup scripts auto resize rootfs
# https://openwrt.org/docs/guide-user/advanced/expand_root

mkdir -p ./package/base-files/files/etc/uci-defaults || true

cat << "EOF" > ./package/base-files/files/etc/uci-defaults/70-rootpt-resize
uname -a | grep -v x86_64 && exit 2

if [ ! -e /etc/rootpt-resize ] && type parted > /dev/null && lock -n /var/lock/root-resize then
  ROOT_BLK="$(readlink -f /sys/dev/block/"$(awk -e '$9=="/dev/root"{print $3}' /proc/self/mountinfo)")"
  ROOT_DISK="/dev/$(basename "${ROOT_BLK%/*}")"
  ROOT_PART="${ROOT_BLK##*[^0-9]}"

  echo $ROOT_DISK | grep mmc && exit 2

  parted -f -s "${ROOT_DISK}" resizepart "${ROOT_PART}" 100%
  mount_root done
  touch /etc/rootpt-resize
  sync && reboot
fi

exit 1
EOF

cat << "EOF" > ./package/base-files/files/etc/uci-defaults/80-rootfs-resize
uname -a | grep -v x86_64 && exit 2

if [ ! -e /etc/rootfs-resize ] && [ -e /etc/rootpt-resize ] && type losetup > /dev/null && type resize2fs > /dev/null && lock -n /var/lock/root-resize then
  ROOT_BLK="$(readlink -f /sys/dev/block/"$(awk -e '$9=="/dev/root"{print $3}' /proc/self/mountinfo)")"
  ROOT_DEV="/dev/${ROOT_BLK##*/}"
  LOOP_DEV="$(awk -e '$5=="/overlay"{print $9}' /proc/self/mountinfo)"

  echo $ROOT_DEV | grep mmc && exit 2

  if [ -z "${LOOP_DEV}" ] then
    LOOP_DEV="$(losetup -f)"
    losetup "${LOOP_DEV}" "${ROOT_DEV}"
  fi

  resize2fs -f "${LOOP_DEV}"
  mount_root done
  touch /etc/rootfs-resize
  sync && reboot
fi

exit 1
EOF

cat << "EOF" >> ./package/base-files/files/etc/sysupgrade.conf
/etc/uci-defaults/70-rootpt-resize
/etc/uci-defaults/80-rootfs-resize
EOF