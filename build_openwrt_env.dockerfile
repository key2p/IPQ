FROM ubuntu:22.04
ENV TZ=Asia/Shanghai

RUN sed -i "s/archive.ubuntu.com/mirrors.ustc.edu.cn/g" /etc/apt/sources.list && \
    sed -i "s/security.ubuntu.com/mirrors.ustc.edu.cn/g" /etc/apt/sources.list
    
RUN (rm -rf /usr/share/dotnet /etc/apt/sources.list.d /usr/local/lib/android $AGENT_TOOLSDIRECTORY || true) && \
    (apt-get -y purge azure-cli ghc* zulu* llvm* firefox google* dotnet* powershell openjdk* mongodb* moby* || true) && \
    apt-get -y update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install sudo ack antlr3 asciidoc autoconf make automake autopoint binutils bison btrfs-progs build-essential bzip2 ca-certificates ccache cmake coreutils cpio curl device-tree-compiler fastjar flex g++-multilib gawk gcc-multilib gettext git git-core gperf gzip haveged intltool jq libc6-dev-i386 libelf-dev libfuse-dev libglib2.0-dev libgmp3-dev libltdl-dev libmpc-dev libmpfr-dev libncurses5-dev libncursesw5-dev libpython3-dev libreadline-dev libssl-dev libtool libz-dev lrzsz mkisofs msmtp nano ninja-build p7zip p7zip-full patch pigz pkgconf python2.7 python3 python3-pip python3-pyelftools python3-setuptools qemu-utils rsync scons squashfs-tools swig tar texinfo uglifyjs unzip upx upx-ucl vim wget xmlto xsltproc xxd xz-utils yasm zip zlib1g-dev zstd liblzma-dev libpam0g-dev clang && \
    echo "update done, start clean" && \
    (apt-get -y autoremove --purge || true ) && (apt-get -y clean || true) && \
    rm -rf /var/lib/apt/lists/* && rm -rf /var/cache/apt/* && \
    git config --system user.name "user" && git config --system user.email "user@example.com" && \
    useradd -m user && echo 'user ALL=NOPASSWD: ALL' > /etc/sudoers.d/user && \
    (timedatectl set-timezone "$TZ" || (ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && dpkg-reconfigure -f noninteractive tzdata))

USER user
WORKDIR /home/user

# docker build -t openwrt_builder:24.10 -f build_openwrt_env.dockerfile .    

