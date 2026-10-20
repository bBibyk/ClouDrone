#!/bin/sh
# Script pour exécuter Sunshine dans un environnement totalement sans interface graphique

# Chemin vers l'exécutable Sunshine
SUNSHINE=~/Downloads/sunshine.AppImage
# Répertoire pour stocker les fichiers temporaires
TEMP_DIR="$(mktemp -d /tmp/sunshine-headless-XXXX)"

[ -d "$TEMP_DIR" ] || exit 1

trap 'echo Sortie...; exit' INT
trap "rm -rf $TEMP_DIR" EXIT

# Isoler le XDG_RUNTIME_DIR pour éviter les conflits avec l'environnement hôte.
# Cependant, les clients PulseAudio doivent encore utiliser l'original pour que
# le son fonctionne.
export PULSE_RUNTIME_PATH="$XDG_RUNTIME_DIR/pulse"
export XDG_RUNTIME_DIR="$TEMP_DIR"

export WAYLAND_DISPLAY=wayland-0
export DISPLAY=:1

# démarrer la session labwc
# Les clients Wayland doivent voir la bonne variable WAYLAND_DISPLAY, et les clients X11
# doivent voir la bonne variable DISPLAY. Les compositeurs wlroots comme
# labwc ne nous permettent généralement pas de spécifier manuellement celles-ci à l'avance, ni il n'y a
# de moyen propre de les récupérer après le démarrage du compositeur. La meilleure
# solution que j'ai trouvée est de faire écrire labwc dans un fichier au démarrage
# que nous utilisons ensuite.
VARS_FILE="$TEMP_DIR"/vars.txt
WLR_BACKENDS=headless labwc -s "sh -c 'env | sed '\''/\(WAYLAND_\)\?DISPLAY=/!d;s/^/export /'\'' > $VARS_FILE'" &
# attendre 10 secondes que les variables soient écrites dans le fichier
for i in $(seq 40); do [ -f "$VARS_FILE" ] && break; sleep 0.25; done
[ -f "$VARS_FILE" ] || { echo 'labwc ne démarre pas correctement ?'; exit 1; }
. "$VARS_FILE"
echo "DISPLAY=$DISPLAY"
echo "WAYLAND_DISPLAY=$WAYLAND_DISPLAY"

# démarrer Sunshine
"$SUNSHINE" &

wait
