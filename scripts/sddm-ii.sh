#!/bin/bash

set -e

LOG="$HOME/sddm-theme-setup-$(date +%d-%H%M%S).log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print() { echo -e "$1" | tee -a "$LOG"; }

print "==== SDDM Theme Setup ===="

# ----------------------------
# Check if SDDM is installed
# ----------------------------
if ! pacman -Q sddm &>/dev/null; then
    print "[ERROR] SDDM is not installed."
    exit 1
fi

print "[OK] SDDM detected."

# ----------------------------
# Create config directory
# ----------------------------
sudo mkdir -p /etc/sddm.conf.d

# ----------------------------
# Choose theme
# ----------------------------
print "\nSelect SDDM theme:"
print "[1] Candy"
print "[2] Corners"
read -p "Enter option number: " choice

case $choice in
    1) THEME="Candy" ;;
    *) THEME="Corners" ;;
esac

print "Selected theme: $THEME"

# ----------------------------
# Theme archive location
# ----------------------------
THEMEFILE="${SCRIPT_DIR}/sddm/Sddm_${THEME}.tar.gz"

if [ ! -f "$THEMEFILE" ]; then
    print "[ERROR] Theme archive not found: $THEMEFILE"
    exit 1
fi

# ----------------------------
# Install theme
# ----------------------------
print "Installing theme from $THEMEFILE ..."
sudo tar -xzf "$THEMEFILE" -C /usr/share/sddm/themes

# ----------------------------
# Configure SDDM
# ----------------------------
CONF_FILE="/etc/sddm.conf.d/the_theme.conf"

sudo bash -c "cat > $CONF_FILE" <<EOF
[Theme]
Current=$THEME
EOF

print "[OK] Theme set to $THEME"

# ----------------------------
# Backup config
# ----------------------------
sudo cp "$CONF_FILE" /etc/sddm.conf.d/backup_the_theme.conf

# ----------------------------
# Set avatar if exists
# ----------------------------
AVATAR="$HOME/${USER}.face.icon"
if [ -f "$AVATAR" ]; then
    sudo mkdir -p /usr/share/sddm/faces
    sudo cp "$AVATAR" /usr/share/sddm/faces/
    print "[OK] Avatar set for $USER"
fi

print "\nDone! Reboot to see changes."
print "=========================="
