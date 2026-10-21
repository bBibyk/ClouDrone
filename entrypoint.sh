#!/bin/bash
export DISPLAY=:99

# Generate Dummy Xorg config
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

xhost +local:

# 2. Start Openbox and Stalonetray (No DBUS required)
su lizard -c "env DISPLAY=:99 openbox-session" &
sleep 1
su lizard -c "env DISPLAY=:99 stalonetray" &
sleep 1

# 3. Start VNC Server
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
    usbip attach -r 127.0.0.1 -b "$USBIP_DEVICE" || echo "Warning: Failed to attach USBIP device."
fi

# Grant the lizard user permission to the NVIDIA device nodes for NVENC
chmod 666 /dev/nvidia* || true

# 8. Start Sunshine
exec su lizard -c "env DISPLAY=:99 sunshine $CONF_FILE"
