#!/bin/bash






# 修复 hostapd 报错
cp -f $GITHUB_WORKSPACE/scripts/011-fix-mbo-modules-build.patch package/network/services/hostapd/patches/011-fix-mbo-modules-build.patch

# 修复 armv8 设备 xfsprogs 报错
sed -i 's/TARGET_CFLAGS.*/TARGET_CFLAGS += -DHAVE_MAP_SYNC -D_LARGEFILE64_SOURCE/g' feeds/packages/utils/xfsprogs/Makefile

sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

#修改默认主题
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# 更改 Argon 主题背景
cp -f $GITHUB_WORKSPACE/images/bg1.jpg package/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg

sed -i '$a src-git smpackage https://github.com/kenzok8/small-package' feeds.conf.default

./scripts/feeds update -a
rm -rf feeds/packages/net/{alist,adguardhome,mosdns,xray*,v2ray*,v2ray*,sing*,smartdns}
rm -rf feeds/packages/utils/v2dat


rm -rf feeds/luci/applications/luci-app-openclash
#cp -rf feeds/smpackage/luci-app-openclash   feeds/luci/applications/luci-app-openclash


./scripts/feeds install -a 


