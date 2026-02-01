#!/bin/bash
set -e

THEME_REPO="https://github.com/JaKooLit/simple-sddm-2.git"
THEME_NAME="simple_sddm_2"
SDDM_THEME_DIR="/usr/share/sddm/themes"
SDDM_CONF="/etc/sddm.conf"
LOG="$HOME/sddm-theme-install-$(date +%d-%H%M%S).log"

print() { echo -e "$1" | tee -a "$LOG"; }

print "==== SDDM Theme Installation Started ===="

# -----------------------------
# Check SDDM installed
# -----------------------------
if ! pacman -Q sddm &>/dev/null; then
    print "[ERROR] SDDM is not installed."
    exit 1
fi

# -----------------------------
# Install required Qt modules
# -----------------------------
print "[1/6] Installing Qt dependencies..."
sudo pacman -S --needed --noconfirm qt6-declarative qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg qt6-5compat

# -----------------------------
# Clone theme
# -----------------------------
print "[2/6] Downloading theme..."
rm -rf "/tmp/$THEME_NAME"
git clone --depth=1 "$THEME_REPO" "/tmp/$THEME_NAME" 2>&1 | tee -a "$LOG"

# -----------------------------
# Install theme
# -----------------------------
print "[3/6] Installing theme..."
sudo mkdir -p "$SDDM_THEME_DIR"
sudo rm -rf "$SDDM_THEME_DIR/$THEME_NAME"
sudo mv "/tmp/$THEME_NAME" "$SDDM_THEME_DIR/$THEME_NAME"

# -----------------------------
# Configure SDDM
# -----------------------------
# print "[4/6] Configuring SDDM..."

# if [ -f "$SDDM_CONF" ]; then
#     sudo cp "$SDDM_CONF" "$SDDM_CONF.bak"
# else
#     sudo touch "$SDDM_CONF"
# fi

# # Set theme
# if grep -q '^\[Theme\]' "$SDDM_CONF"; then
#     sudo sed -i "/^\[Theme\]/,/^\[/{s/^Current=.*/Current=$THEME_NAME/}" "$SDDM_CONF"
# else
#     echo -e "\n[Theme]\nCurrent=$THEME_NAME" | sudo tee -a "$SDDM_CONF" > /dev/null
# fi

# # Enable virtual keyboard
# if grep -q '^\[General\]' "$SDDM_CONF"; then
#     sudo sed -i "/^\[General\]/,/^\[/{s/^InputMethod=.*/InputMethod=qtvirtualkeyboard/}" "$SDDM_CONF"
# else
#     echo -e "\n[General]\nInputMethod=qtvirtualkeyboard" | sudo tee -a "$SDDM_CONF" > /dev/null
# fi

# -----------------------------
# Wallpaper fix
# -----------------------------
# print "[5/6] Fixing wallpaper..."

# THEME_CONF="$SDDM_THEME_DIR/$THEME_NAME/theme.conf"
# if [ -f "$THEME_CONF" ]; then
#     sudo sed -i 's|^wallpaper=.*|wallpaper="Backgrounds/default"|' "$THEME_CONF" || true
# fi

# -----------------------------
# Done
# -----------------------------
print "[6/6] Theme installed successfully!"
print "Theme: $THEME_NAME"
print "Reboot to see the new SDDM theme."
print "=================================="
