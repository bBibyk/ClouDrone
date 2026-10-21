FROM lizardbyte/sunshine:latest-ubuntu-26.10

USER root

RUN apt-get update && apt-get install -y software-properties-common \
    && add-apt-repository universe -y

RUN apt-get update && apt-get install -y \
    xserver-xorg-video-dummy \
    xserver-xorg-core \
    xserver-xorg-input-libinput \
    xserver-xorg-input-evdev \
    udev \
    linux-tools-common \
    linux-tools-generic \
    hwdata \
    stalonetray \
    openbox \
    x11vnc \
    pulseaudio \
    x11-xserver-utils \
    && rm -rf /var/lib/apt/lists/*
    
RUN dpkg --add-architecture i386 && apt-get update

RUN apt-get install -y \
    steam \
    libgl1:i386 \
    mesa-vulkan-drivers:i386 \
    mesa-vulkan-drivers \
    cabextract \
    xfonts-terminus \
    && rm -rf /var/lib/apt/lists/*

# Globally link NVIDIA libraries so they survive privilege drops
RUN echo "/usr/local/nvidia/lib" > /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV PATH=/usr/local/nvidia/bin:${PATH}

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 5900
ENV DISPLAY=:99

ENTRYPOINT ["/entrypoint.sh"]

