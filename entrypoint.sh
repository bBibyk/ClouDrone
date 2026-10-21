#!/bin/bash
export DISPLAY=:99

# 1. Start X11 virtual screen
Xorg -noreset +extension GLX +extension RANDR +extension RENDER -logfile /tmp/xorg.log -config /etc/X11/xorg.conf :99 &
sleep 2 

# Allow local connections
xhost +local:

# 2. Start the XFCE Desktop Environment
su lizard -c "env DISPLAY=:99 startxfce4" &
sleep 3

# 3. Start VNC Server for debugging
x11vnc -display :99 -nopw -listen 0.0.0.0 -xkb -forever -bg

# 4. Configure Sunshine settings
mkdir -p /home/lizard/.config/sunshine
CONF_FILE="/home/lizard/.config/sunshine/sunshine.conf"

echo "upnp = disabled" > "$CONF_FILE"
echo "mdns = disabled" >> "$CONF_FILE"
echo "capture = x11" >> "$CONF_FILE" 

chown -R lizard:lizard /home/lizard

# 5. Set Sunshine Web UI Credentials (from .env)
if [ -n "$SUNSHINE_USER" ] && [ -n "$SUNSHINE_PASS" ]; then
    echo "Setting Sunshine Web UI credentials..."
    su lizard -c "env DISPLAY=:99 sunshine $CONF_FILE --creds $SUNSHINE_USER $SUNSHINE_PASS"
fi

# 6. Start Steam (Big Picture mode)
su lizard -c "env DISPLAY=:99 steam -gamepadui &"

sleep 5

if [ -e /dev/uinput ]; then
    chmod 666 /dev/uinput
fi

# 7. Attach USBIP Device (from .env)
if [ -n "$USBIP_DEVICE" ]; then
    echo "USBIP device $USBIP_DEVICE specified. Attempting to attach..."
    # Connects to 127.0.0.1. (Requires --network host in Docker run)
    usbip attach -r 127.0.0.1 -b "$USBIP_DEVICE" || echo "Warning: Failed to attach USBIP device $USBIP_DEVICE."
fi

# 8. Start Sunshine
exec su lizard -c "env DISPLAY=:99 sunshine $CONF_FILE"
