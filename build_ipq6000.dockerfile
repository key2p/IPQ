FROM openwrt_builder:24.10

ENV REPO_URL=https://github.com/LiBwrt-op/openwrt-6.x \
    REPO_BRANCH=openwrt-24.10 \
    CONFIG_FILE=configs/ipq60xx-all.config \
    DIY_SCRIPT=diy-script.sh \
    CLASH_KERNEL=amd64 \
    CACHE_TOOLCHAIN=true \
    UPLOAD_BIN_DIR=false \
    FIRMWARE_RELEASE=true \
    FIRMWARE_TAG=IPQ60XX \
    TZ=Asia/Shanghai

ENV OPENWRT_PATH=/builder/openwrt
ENV WORK_DIR=/builder

WORKDIR /builder    
COPY . /builder

RUN pwd && ls -al && \
    useradd work && (mkdir -p /home/work || true) && \
    chown -R work:work /builder && chown -R work:work /home/work && \     
    chmod +x build_openwrt.sh && \
    su -p work -c "export HOME=/home/work && cd /builder && ./build_openwrt.sh" 

COPY /builder/openwrt/bin ./bin_IPQ60XX

# docker build --rm -f build_ipq6000.dockerfile .