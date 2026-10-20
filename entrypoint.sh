#!/bin/bash
# 1. Démarrage de l'écran virtuel X11
Xorg -noreset +extension GLX +extension RANDR +extension RENDER -logfile /tmp/xorg.log -config /etc/X11/xorg.conf :99 &
sleep 2 

# 2. Démarrage du faux System Tray pour empêcher le crash de Qt
stalonetray &
sleep 1

# 3. Configuration des dossiers et permissions avant de lancer Steam
mkdir -p /home/lizard/.config/sunshine
CONF_FILE="/home/lizard/.config/sunshine/sunshine.conf"

if [ ! -f "$CONF_FILE" ]; then
    echo "upnp = disabled" > "$CONF_FILE"
    echo "mdns = disabled" >> "$CONF_FILE"
else
    grep -q "mdns = disabled" "$CONF_FILE" || echo "mdns = disabled" >> "$CONF_FILE"
    grep -q "upnp = disabled" "$CONF_FILE" || echo "upnp = disabled" >> "$CONF_FILE"
fi

# Donner les droits d'écriture à l'utilisateur interne sur tout son dossier
# Ceci est crucial pour que Steam puisse se mettre à jour et écrire ses logs
chown -R lizard:lizard /home/lizard

# 4. Démarrage de Steam en mode Big Picture
# -gamepadui est le flag moderne pour la nouvelle interface Big Picture (style Steam Deck)
su lizard -c "steam -gamepadui &"

# Laisser le temps à Steam de faire sa mise à jour initiale ou de démarrer
sleep 5

# 5. Démarrage de Sunshine
exec sunshine "$CONF_FILE"
