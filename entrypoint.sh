#!/bin/bash
# 1. Démarrage de l'écran virtuel X11
Xorg -noreset +extension GLX +extension RANDR +extension RENDER -logfile /tmp/xorg.log -config /etc/X11/xorg.conf :99 &
sleep 2 

# 2. Démarrage du faux System Tray pour empêcher le crash de Qt
stalonetray &
sleep 1

# 3. Forcer la configuration pour le bon utilisateur (lizard)
mkdir -p /home/lizard/.config/sunshine
CONF_FILE="/home/lizard/.config/sunshine/sunshine.conf"

if [ ! -f "$CONF_FILE" ]; then
    echo "upnp = disabled" > "$CONF_FILE"
    echo "mdns = disabled" >> "$CONF_FILE"
else
    grep -q "mdns = disabled" "$CONF_FILE" || echo "mdns = disabled" >> "$CONF_FILE"
    grep -q "upnp = disabled" "$CONF_FILE" || echo "upnp = disabled" >> "$CONF_FILE"
fi

# Donner les droits d'écriture à l'utilisateur interne de Sunshine
chown -R lizard:lizard /home/lizard/.config/sunshine

# 4. Démarrage de Sunshine
exec sunshine "$CONF_FILE"