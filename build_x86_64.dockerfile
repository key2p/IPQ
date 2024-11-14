FROM openwrt_builder:24.10

ENV REPO_URL=https://github.com/immortalwrt/immortalwrt.git \
    REPO_BRANCH=master \
    CONFIG_FILE=configs/x86_64.config \
    DIY_SCRIPT=diy-script.sh \
    CLASH_KERNEL=amd64 \
    CACHE_TOOLCHAIN=true \
    UPLOAD_BIN_DIR=false \
    FIRMWARE_RELEASE=true \
    FIRMWARE_TAG=X86_64 \
    TZ=Asia/Shanghai

ENV OPENWRT_PATH=/builder/openwrt
ENV WORK_DIR=/builder

WORKDIR /builder    
       
RUN pwd && ls -al && \
    useradd work && (mkdir -p /home/work || true) && \
    chown -R work:work /builder && chown -R work:work /home/work && \     
    chmod +x build_openwrt.sh && \
    su -p work -c "export HOME=/home/work && cd /builder && ./build_openwrt.sh" 

#COPY /builder/build.log     ./bin_x64
#COPY /builder/openwrt/bin   ./bin_x64

# docker build --rm -v $PWD:/builder  -f build_x86_64.dockerfile .
# docker run --rm -it -v $PWD:/builder openwrt_builder:24.10 /bin/bash
#
# cp ../diy-script.sh ./diy.sh &&  ./diy.sh
# cp ../configs/x86_64.config ./.config &&  make defconfig && make -j8
