#!/bin/bash
set -ex

export PATH="/opt/llvm19_krl/llvm-19.1.4-x86_64/bin/:$PATH"

# avoid redownload
[ -e /opt/llvm19_krl/llvm-19.1.4-x86_64/bin/clang ] && exit 0

## https://blobfolio.com/2024/building-a-custom-xanmod-kernel-on-ubuntu-23-10/
apt update -y &&  apt install -y curl libc6 libgcc-s1 libicu-dev liblzma5 libstdc++6 libxml2 libzstd1 zlib1g xz-utils && \
  apt install -y --no-install-recommends fakeroot build-essential git wget openssl libssl-dev ca-certificates libncurses-dev zstd xz-utils flex libelf-dev bison bc debhelper rsync kmod cpio gpg pahole python3 && \
  apt install -y python3 pkg-config libdwarf-dev libdw-dev systemtap-sdt-dev libunwind-dev python3-dev libzstd-dev libcap-dev libnuma-dev libtraceevent-dev uuid-dev libpfm4-dev libbfd-dev libbabeltrace-dev libperl-dev libpci-dev && \
  apt-get clean

curl -L https://mirrors.edge.kernel.org/pub/tools/llvm/files/llvm-19.1.4-x86_64.tar.xz -o /dev/shm/llvm19.tar.xz

sudo -E rm -rf /opt/llvm19_krl || true
mkdir -p /opt/llvm19_krl || true

cd /opt/llvm19_krl && tar -xJf /dev/shm/llvm19.tar.xz
rm /dev/shm/llvm19.tar.xz || true