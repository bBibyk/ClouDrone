FROM lizardbyte/sunshine:latest-ubuntu-26.10

USER root

# Install dbus-x11 required for XFCE to launch
RUN apt-get update && apt-get install -y software-properties-common \
    && add-apt-repository universe -y

RUN apt-get update && apt-get install -y \
    xserver-xorg-video-dummy \
    xserver-xorg-core \
    linux-tools-common \
    linux-tools-virtual \
    hwdata \
    dbus-x11 \
    libxfixes3 \
    libavahi-common3 \
    libavahi-client3 \
    xfce4 \
    xfce4-terminal \
    x11vnc \
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

# Point Ubuntu to the libraries injected by Docker's NVIDIA runtime
ENV LD_LIBRARY_PATH=/usr/local/nvidia/lib:/usr/local/nvidia/lib64:${LD_LIBRARY_PATH}
ENV PATH=/usr/local/nvidia/bin:${PATH}

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 5900
ENV DISPLAY=:99

ENTRYPOINT ["/entrypoint.sh"]
