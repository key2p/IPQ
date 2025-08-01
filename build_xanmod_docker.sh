#!/bin/bash
set -ex

SAVE_DIR=${PWD}

[ -e "${GITHUB_WORKSPACE}/runner/01_nodoc" ] && cp -a ${GITHUB_WORKSPACE}/runner/01_nodoc /etc/dpkg/dpkg.cfg.d/ || true
[ -e "runner/01_nodoc" ] && cp -a runner/01_nodoc /etc/dpkg/dpkg.cfg.d/ || true

export LLVMVER="20.1.8"
export PATH="/opt/llvm19_krl/llvm-x86_64/bin/:/opt/llvm19_krl/llvm-${LLVMVER}-x86_64/bin/:/usr/lib/llvm-20/bin/:$PATH"

# avoid redownload
[ -e /usr/bin/lld-20 ] && exit 0
[ -e /opt/llvm19_krl/llvm-x86_64/bin/clang ] && exit 0
[ -e /opt/llvm19_krl/llvm-${LLVMVER}-x86_64/bin/clang ] && exit 0

# config apt llvm
sed -i '/llvm-toolchain/d' /etc/apt/sources.list
echo "deb http://apt.llvm.org/jammy/ llvm-toolchain-jammy-20 main" >> /etc/apt/sources.list

mkdir -p /etc/apt/trusted.gpg.d/ || true
curl -L https://apt.llvm.org/llvm-snapshot.gpg.key -o /etc/apt/trusted.gpg.d/apt.llvm.org.asc
apt update -y

## https://blobfolio.com/2024/building-a-custom-xanmod-kernel-on-ubuntu-23-10/

# for linux kernel build
apt install -y --no-install-suggests --no-install-recommends curl libc6 libgcc-s1 libicu-dev liblzma5 libstdc++6 libxml2 libzstd1 zlib1g xz-utils \
  fakeroot build-essential git wget openssl libssl-dev ca-certificates libncurses-dev zstd xz-utils flex libelf-dev bison bc debhelper rsync kmod cpio gpg pahole python3 \
  pkgconf libdwarf-dev libdw-dev systemtap-sdt-dev libunwind-dev python3-dev libzstd-dev libcap-dev libnuma-dev libtraceevent-dev uuid-dev libpfm4-dev libbfd-dev libbabeltrace-dev libperl-dev libpci-dev libpcap-dev rpm
  
# for openwrt build  
apt install -y --no-install-suggests --no-install-recommends dosfstools xorriso mtools sudo ack antlr3 asciidoc autoconf make automake autopoint binutils bison btrfs-progs \
  build-essential bzip2 ca-certificates ccache cmake coreutils cpio curl device-tree-compiler fastjar flex g++-multilib gawk gcc-multilib \
  gettext git git-core gperf gzip haveged intltool jq libc6-dev-i386 libelf-dev libfuse-dev libglib2.0-dev libgmp3-dev libltdl-dev libmpc-dev \
  libmpfr-dev libncurses5-dev libncursesw5-dev libpython3-dev libreadline-dev libssl-dev libtool libz-dev lrzsz mkisofs msmtp nano ninja-build \
  p7zip p7zip-full patch pigz pkgconf python3 python3-pip python3-pyelftools python3-setuptools qemu-utils rsync scons squashfs-tools swig \
  tar uglifyjs unzip upx upx-ucl vim wget xmlto xsltproc xxd xz-utils yasm zip zlib1g-dev zstd liblzma-dev libpam0g-dev pahole dwarves llvm-20 clang-20 lld-20

apt-get clean
which llc || true
sudo -E ln -s /usr/bin/llc-20 /usr/bin/llc || true
sudo -E ln -s /usr/bin/lld-20 /usr/bin/lld || true
sudo -E ln -s /usr/bin/lld-20 /usr/bin/ld.lld || true
sudo -E ln -s /usr/bin/lld-20 /usr/bin/ld64.lld || true
sudo -E ln -s /usr/bin/clang-20 /usr/bin/clang  || true
ls -al /usr/bin/ll* || true

# llvm pgo version
#curl -L https://mirrors.edge.kernel.org/pub/tools/llvm/files/llvm-${LLVMVER}-x86_64.tar.xz -o /dev/shm/llvm19.tar.xz

#sudo -E rm -rf /opt/llvm19_krl || true
#mkdir -p /opt/llvm19_krl || true

#tar -C /opt/llvm19_krl -xJf /dev/shm/llvm19.tar.xz
#rm /dev/shm/llvm19.tar.xz || true
#ls -al /opt/llvm19_krl/llvm-${LLVMVER}-x86_64/bin || true

#sudo -E rm /opt/llvm19_krl/llvm-x86_64 || true
#sudo -E ln -s /opt/llvm19_krl/llvm-${LLVMVER}-x86_64 /opt/llvm19_krl/llvm-x86_64 || true
#ls -al /opt/llvm19_krl/ || true

cd $SAVE_DIR