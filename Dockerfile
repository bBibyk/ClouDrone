FROM lizardbyte/sunshine:latest-ubuntu-26.10

USER root

RUN apt-get update && apt-get install -y software-properties-common \
    && add-apt-repository universe -y

RUN apt-get update && apt-get install -y \
    xserver-xorg-video-dummy \
    xserver-xorg-core \
    linux-tools-common \
    linux-tools-virtual \
    hwdata \
    libxfixes3 \
    libavahi-common3 \
    libavahi-client3 \
    stalonetray \
    && rm -rf /var/lib/apt/lists/*

COPY xorg.conf /etc/X11/xorg.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV DISPLAY=:99

ENTRYPOINT ["/entrypoint.sh"]