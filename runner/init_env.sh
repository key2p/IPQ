#!/bin/bash

set -ex

export http_proxy=socks5h://192.168.0.25:9090
export https_proxy=${http_proxy}

mkdir -p /etc/apt/apt.conf.d || true
echo -e "Acquire::http::Proxy \"${http_proxy}\";\nAcquire::https::Proxy \"${https_proxy}\";" > /etc/apt/apt.conf.d/01proxy

df -h && ls -al /dev/shm && ls -al /tmp
apt-get update -y && apt-get install -y --no-install-suggests --no-install-recommends curl ca-certificates jq git tzdata sudo

# config apt
sed -i '/llvm-toolchain/d' /etc/apt/sources.list
echo "deb http://apt.llvm.org/jammy/ llvm-toolchain-jammy-18 main" >> /etc/apt/sources.list

mkdir -p /etc/apt/trusted.gpg.d/ || true
curl -L https://apt.llvm.org/llvm-snapshot.gpg.key -o /etc/apt/trusted.gpg.d/apt.llvm.org.asc
apt update -y

# common config
timedatectl set-timezone "Asia/Shanghai" || (ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && dpkg-reconfigure -f noninteractive tzdata)
#git config --global http.proxy http://192.168.0.25:9090 || true

useradd -m docker && echo 'docker ALL=NOPASSWD: ALL' > /etc/sudoers.d/docker
(mkdir -p /home/docker/actions-runner || true) && chown -R docker:docker /home/docker

# for linux kernel build
apt install -y --no-install-suggests --no-install-recommends curl libc6 libgcc-s1 libicu-dev liblzma5 libstdc++6 libxml2 libzstd1 zlib1g xz-utils \
  fakeroot build-essential git wget openssl libssl-dev ca-certificates libncurses-dev zstd xz-utils flex libelf-dev bison bc debhelper rsync kmod cpio gpg pahole python3 \
  pkg-config libdwarf-dev libdw-dev systemtap-sdt-dev libunwind-dev python3-dev libzstd-dev libcap-dev libnuma-dev libtraceevent-dev uuid-dev libpfm4-dev libbfd-dev libbabeltrace-dev libperl-dev libpci-dev 
  
# for openwrt build  
apt install -y --no-install-suggests --no-install-recommends dosfstools xorriso mtools sudo ack antlr3 asciidoc autoconf make automake autopoint binutils bison btrfs-progs \
  build-essential bzip2 ca-certificates ccache cmake coreutils cpio curl device-tree-compiler fastjar flex g++-multilib gawk gcc-multilib \
  gettext git git-core gperf gzip haveged intltool jq libc6-dev-i386 libelf-dev libfuse-dev libglib2.0-dev libgmp3-dev libltdl-dev libmpc-dev \
  libmpfr-dev libncurses5-dev libncursesw5-dev libpython3-dev libreadline-dev libssl-dev libtool libz-dev lrzsz mkisofs msmtp nano ninja-build \
  p7zip p7zip-full patch pigz pkgconf python3 python3-pip python3-pyelftools python3-setuptools qemu-utils rsync scons squashfs-tools swig \
  tar uglifyjs unzip upx upx-ucl vim wget xmlto xsltproc xxd xz-utils yasm zip zlib1g-dev zstd liblzma-dev libpam0g-dev pahole dwarves llvm-18 clang-18

ln -s /usr/bin/llc-18 /usr/bin/llc || true
ln -s /usr/bin/clang-18 /usr/bin/clang  || true

# llvm pgo version
curl -L https://mirrors.edge.kernel.org/pub/tools/llvm/files/llvm-19.1.4-x86_64.tar.xz -o /dev/shm/llvm19.tar.xz

rm -rf /opt/llvm19_krl || true
mkdir -p /opt/llvm19_krl || true

cd /opt/llvm19_krl
tar -xJf /dev/shm/llvm19.tar.xz
rm /dev/shm/llvm19.tar.xz || true

# cd into the user directory, download and unzip the github actions runner
cd /home/docker/actions-runner 

RUNNER_TAR_BIN=actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
curl -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${RUNNER_TAR_BIN} -o /dev/shm/${RUNNER_TAR_BIN}
tar xzf /dev/shm/${RUNNER_TAR_BIN} && rm /dev/shm/${RUNNER_TAR_BIN}

# install some additional dependencies
/home/docker/actions-runner/bin/installdependencies.sh
    
(apt-get -y autoremove --purge || true ) && (apt-get -y clean || true) && rm -rf /var/lib/apt/lists/* && rm -rf /var/cache/apt/* 

# copy over the start.sh script
cp /tmp/start.sh /home/docker/start.sh && chmod +x /home/docker/start.sh

chown -R docker:docker /home/docker
ls -al