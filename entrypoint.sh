#!/bin/bash
export DISPLAY=:99

# Grant lizard user permission to use the GPU, Audio, and Video encoders
usermod -aG video,render,audio lizard

# Generate Dummy Xorg config with strict 1920x1080 Modeline
cat << 'EOF' > /etc/X11/xorg.conf
Section "Device"
    Identifier  "DummyDevice"
    Driver      "dummy"
    VideoRam    256000
EndSection

Section "Monitor"
    Identifier  "DummyMonitor"
    HorizSync   28.0-80.0
    VertRefresh 48.0-75.0
    Modeline "1920x1080_60.00"  173.00  1920 2048 2248 2576  1080 1083 1088 1120 -hsync +vsync
    Option "PreferredMode" "1920x1080_60.00"
EndSection

Section "Screen"
    Identifier  "DummyScreen"
    Monitor     "DummyMonitor"
    Device      "DummyDevice"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Modes "1920x1080_60.00"
    EndSubSection
EndSection
EOF

# 1. Start X11 virtual screen
Xorg -noreset +extension GLX +extension RANDR +extension RENDER -logfile /tmp/xorg.log -config /etc/X11/xorg.conf :99 &
sleep 3 

xhost +local:

# 2. Start Audio Server
su lizard -c "pulseaudio --start"

# 3. Start Openbox and Stalonetray
su lizard -c "env DISPLAY=:99 openbox-session" &
sleep 1
su lizard -c "env DISPLAY=:99 stalonetray" &
sleep 1

# 4. Start VNC Server
x11vnc -display :99 -nopw -listen 0.0.0.0 -xkb -forever -bg &

# 5. Configure Sunshine settings
mkdir -p /home/lizard/.config/sunshine
CONF_FILE="/home/lizard/.config/sunshine/sunshine.conf"

echo "upnp = disabled" > "$CONF_FILE"
echo "mdns = disabled" >> "$CONF_FILE"
echo "capture = x11" >> "$CONF_FILE" 
chown -R lizard:lizard /home/lizard

# 6. Set Sunshine Web UI Credentials
if [ -n "$SUNSHINE_USER" ] && [ -n "$SUNSHINE_PASS" ]; then
    su lizard -c "env DISPLAY=:99 sunshine $CONF_FILE --creds $SUNSHINE_USER $SUNSHINE_PASS"
fi

# 7. Start Steam (Big Picture mode)
su lizard -c "env DISPLAY=:99 steam -gamepadui &"
sleep 5

if [ -e /dev/uinput ]; then
    chmod 666 /dev/uinput
fi

chmod 666 /dev/nvidia* || true
chmod -R 666 /dev/dri || true

# 8. Attach USBIP Device by finding the raw binary and bypassing the kernel check
if [ -n "$USBIP_DEVICE" ]; then
    echo "Attempting to attach USBIP device $USBIP_DEVICE..."
    RAW_USBIP=$(find /usr/lib/linux-tools -name usbip -type f | head -n 1)
    
    if [ -n "$RAW_USBIP" ]; then
        $RAW_USBIP attach -r 127.0.0.1 -b "$USBIP_DEVICE" || echo "Warning: Failed to attach USBIP device."
    else
        echo "Error: USBIP binary not found in container."
    fi
fi

# 9. Start Sunshine
exec su lizard -c "env DISPLAY=:99 sunshine $CONF_FILE"
