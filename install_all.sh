#!/bin/bash

# ==========================================
# 1. INSTALLATION DES PRÉREQUIS (Exécuté une seule fois)
# ==========================================
echo "Vérification et installation des dépendances..."

# Installation des paquets de base (équivalent du Dockerfile)
sudo apt-get update
sudo apt-get install -y \
    software-properties-common \
    xserver-xorg-video-dummy \
    xserver-xorg-core \
    linux-tools-generic \
    linux-tools-virtual \
    hwdata \
    libxfixes3 \
    libavahi-common3 \
    libavahi-client3 \
    stalonetray \
    curl \
    wget

# Installation de Sunshine natif (s'il n'est pas déjà là)
if ! command -v sunshine &> /dev/null; then
    echo "Installation de Sunshine..."
    curl -1sLf 'https://dl.cloudsmith.io/public/lizardbyte/sunshine/setup.deb.sh' | sudo -E bash
    sudo apt-get install -y sunshine
    # Ajout de l'utilisateur aux groupes nécessaires pour la manette/vidéo
    sudo usermod -aG input $USER
    sudo usermod -aG video $USER
    sudo usermod -aG render $USER
fi

# Installation et lancement de Tailscale
if ! command -v tailscale &> /dev/null; then
    echo "Installation de Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
fi
echo "Démarrage de Tailscale..."
sudo tailscale up

# Création du fichier de l'écran virtuel s'il n'existe pas
if [ ! -f /etc/X11/xorg.conf ]; then
    echo "Création de la configuration de l'écran virtuel X11..."
    sudo bash -c 'cat > /etc/X11/xorg.conf <<EOF
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
EOF'
fi

# ==========================================
# 2. DÉMARRAGE DE L'ENVIRONNEMENT
# ==========================================
echo "Démarrage de l'écran virtuel..."
sudo Xorg -noreset +extension GLX +extension RANDR +extension RENDER -logfile /tmp/xorg.log -config /etc/X11/xorg.conf :99 &
sleep 2 

export DISPLAY=:99

echo "Démarrage du System Tray..."
stalonetray &
sleep 1

echo "Configuration de Sunshine..."
# On utilise le dossier de l'utilisateur actuel au lieu de l'utilisateur docker 'lizard'
mkdir -p "$HOME/.config/sunshine"
CONF_FILE="$HOME/.config/sunshine/sunshine.conf"

# Désactivation de mDNS et UPnP pour la stabilité réseau
if [ ! -f "$CONF_FILE" ]; then
    echo "upnp = disabled" > "$CONF_FILE"
    echo "mdns = disabled" >> "$CONF_FILE"
else
    grep -q "mdns = disabled" "$CONF_FILE" || echo "mdns = disabled" >> "$CONF_FILE"
    grep -q "upnp = disabled" "$CONF_FILE" || echo "upnp = disabled" >> "$CONF_FILE"
fi

# Application automatique des identifiants s'ils sont passés en variable
if [ -n "$SUNSHINE_USER" ] && [ -n "$SUNSHINE_PASS" ]; then
    echo "Application des identifiants Sunshine..."
    sunshine "$CONF_FILE" --creds "$SUNSHINE_USER" "$SUNSHINE_PASS"
fi

echo "Lancement de Sunshine..."
exec sunshine "$CONF_FILE"