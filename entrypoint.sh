#!/bin/bash
export DISPLAY=:99

# Generate the correct Dummy Xorg config (Hybrid setup)
cat << 'EOF' > /etc/X11/xorg.conf
Section "Device"
    Identifier  "DummyDevice"
    Driver      "dummy"
    VideoRam    256000
EndSection

Section "Monitor"
    Identifier  "DummyMonitor"
    HorizSync   31.5-48.5
    VertRefresh 50-70
EndSection

Section "Screen"
    Identifier  "DummyScreen"
    Monitor     "DummyMonitor"
    Device      "DummyDevice"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Modes "1920x1080"
    EndSubSection
EndSection
EOF

# 1. Start X11 virtual screen
Xorg -noreset +extension GLX +extension RANDR +extension RENDER -logfile /tmp/xorg.log -config /etc/X11/xorg.conf :99 &
sleep 3 

# Allow local connections
xhost +local:

# 2. Start the XFCE Desktop Environment
su lizard -c "env DISPLAY=:99 startxfce4" &
sleep 3

# 3. Start VNC Server for debugging
x11vnc -display :99 -nopw -listen 0.0.0.0 -xkb -forever -bg &

# 4. Configure Sunshine settings
mkdir -p /home/lizard/.config/sunshine
CONF_FILE="/home/lizard/.config/sunshine/sunshine.conf"

echo "upnp = disabled" > "$CONF_FILE"
echo "mdns = disabled" >> "$CONF_FILE"
echo "capture = x11" >> "$CONF_FILE" 
chown -R lizard:lizard /home/lizard

# 5. Set Sunshine Web UI Credentials
if [ -n "$SUNSHINE_USER" ] && [ -n "$SUNSHINE_PASS" ]; then
    su lizard -c "env DISPLAY=:99 sunshine $CONF_FILE --creds $SUNSHINE_USER $SUNSHINE_PASS"
fi

# 6. Start Steam (Big Picture mode)
su lizard -c "env DISPLAY=:99 steam -gamepadui &"
sleep 5

if [ -e /dev/uinput ]; then
    chmod 666 /dev/uinput
fi

# 7. Attach USBIP Device
if [ -n "$USBIP_DEVICE" ]; then
    echo "Attempting to attach USBIP device $USBIP_DEVICE..."
    usbip attach -r 127.0.0.1 -b "$USBIP_DEVICE" || echo "Warning: Failed to attach USBIP device."
fi

# 8. Start Sunshine
exec su lizard -c "env DISPLAY=:99 sunshine $CONF_FILE"
