#!/bin/bash
set -ex

export BUILD_START=$(date)
echo ${BUILD_START}

export GITHUB_WORKSPACE=${WORK_DIR}
export 

# Clone Source Code
git config --global user.name "OpenWrt Builder"
git config --global user.email "buster-openwrt@ovvo.uk"

git config http.proxy http://192.168.0.25:9090
export http_proxy=http://192.168.0.25:9090
export https_proxy=http://192.168.0.25:9090


git clone $REPO_URL -b $REPO_BRANCH openwrt
cd $OPENWRT_PATH 

VERSION_INFO=$(git show -s --date=short --format="作者: %an<br/>时间: %cd<br/>内容: %s<br/>hash: %H") 
echo "VERSION_INFO=$VERSION_INFO" 

# Generate Variables
cd $WORK_DIR
cp $CONFIG_FILE $OPENWRT_PATH/.config 

cd $OPENWRT_PATH 
make defconfig > /dev/null 2>&1

export SOURCE_REPO="$(echo $REPO_URL | awk -F '/' '{print $(NF)}')"
echo "SOURCE_REPO=$SOURCE_REPO" 

export DEVICE_TARGET=$(cat .config | grep CONFIG_TARGET_BOARD | awk -F '"' '{print $2}')
echo "DEVICE_TARGET=$DEVICE_TARGET" 

export DEVICE_SUBTARGET=$(cat .config | grep CONFIG_TARGET_SUBTARGET | awk -F '"' '{print $2}')
echo "DEVICE_SUBTARGET=$DEVICE_SUBTARGET"

# Install Feeds
cd $WORK_DIR
cp $DIY_SCRIPT $OPENWRT_PATH/diy.sh  
cd $OPENWRT_PATH
chmod +x diy.sh
./diy.sh

# Load Custom Configuration
cd $WORK_DIR
[ -e files ] && mv files $OPENWRT_PATH/files
[ -e $CONFIG_FILE ] && mv $CONFIG_FILE $OPENWRT_PATH/.config

# Download DL Package
cd $OPENWRT_PATH
make defconfig
make download -j8
find dl -size -1024c -exec ls -l {} \;
find dl -size -1024c -exec rm -f {} \;

# Compile Firmware
cd $OPENWRT_PATH
echo -e "$(nproc) thread compile"
make -j$(nproc) || make -j$(nproc) V=sc || make -j$(nproc) || make -j4 || make -j2 V=sc || make -j1 || make -j1 V=s

echo "status=success"
export DATE=$(date +"%Y-%m-%d %H:%M:%S")
echo "DATE=$DATE"

export FILE_DATE=$(date +"%Y.%m.%d")
echo "FILE_DATE=$FILE_DATE"

# Organize Files
cd $OPENWRT_PATH/bin/targets/*/*

cat sha256sums
cp $OPENWRT_PATH/.config build.config
mv -f $OPENWRT_PATH/bin/packages/*/*/*.ipk packages || true
mv -f $OPENWRT_PATH/bin/packages/*/*/*.apk packages || true
tar -zcf Packages.tar.gz packages
rm -rf packages feeds.buildinfo version.buildinfo

export KERNEL=$(cat *.manifest | grep ^kernel | cut -d- -f2 | tr -d ' ')
echo "FILE_DATE=$FILE_DATE"

export FIRMWARE_PATH=$PWD
echo "FIRMWARE_PATH=$FIRMWARE_PATH"

export BUILD_END=$(date)

# release
echo "固件信息(WIFI版本)"
echo " 平台架构: ${DEVICE_TARGET}-${DEVICE_SUBTARGET} 用于 ${FIRMWARE_TAG} 平台"
echo " 固件源码: ${REPO_URL}"
echo " 源码分支: ${REPO_BRANCH}"
echo " 内核版本: ${KERNEL}"
echo " 默认地址: 192.168.6.1"
echo " 默认密码: password"
echo " 🧊 固件版本"
echo " 固件编译前最后一次➦[主源码](${REPO_URL})更新记录"
echo " ${VERSION_INFO}"
echo " 开始时间 ${BUILD_START} 结束时间 ${BUILD_END}"
