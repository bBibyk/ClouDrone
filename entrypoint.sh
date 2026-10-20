#!/bin/bash
export DISPLAY=:99

# 1. Démarrage de l'écran virtuel X11
Xorg -noreset +extension GLX +extension RANDR +extension RENDER -logfile /tmp/xorg.log -config /etc/X11/xorg.conf :99 &
sleep 2 

# Autoriser les connexions locales à X11 (Crucial pour que l'utilisateur lizard puisse afficher Steam)
xhost +local:

# 2. Démarrage du Window Manager et du System Tray
openbox-session &
sleep 1
stalonetray &
sleep 1

# 3. Configuration de Sunshine
mkdir -p /home/lizard/.config/sunshine
CONF_FILE="/home/lizard/.config/sunshine/sunshine.conf"

echo "upnp = disabled" > "$CONF_FILE"
echo "mdns = disabled" >> "$CONF_FILE"
echo "capture = x11" >> "$CONF_FILE" # Force la capture X11 au lieu de KMS/DRM

chown -R lizard:lizard /home/lizard

# 4. Démarrage de Steam (en s'assurant que DISPLAY est transmis)
su lizard -c "env DISPLAY=:99 steam -gamepadui &"

sleep 5

# 5. Démarrage de Sunshine en tant qu'utilisateur lizard (pas root)
exec su lizard -c "env DISPLAY=:99 sunshine $CONF_FILE"
