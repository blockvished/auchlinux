#!/bin/bash
set -e

THEME_REPO="https://github.com/JaKooLit/simple-sddm-2.git"
THEME_NAME="simple_sddm_2"
SDDM_CONF="/etc/sddm.conf"
LOG="$HOME/sddm-theme-install-$(date +%d-%H%M%S).log"

echo "==== SDDM Theme Installation Started ====" | tee -a "$LOG"

# -----------------------------
# Clone theme
# -----------------------------
echo "[1/5] Downloading theme..." | tee -a "$LOG"

rm -rf "/tmp/$THEME_NAME"
git clone --depth=1 "$THEME_REPO" "/tmp/$THEME_NAME" 2>&1 | tee -a "$LOG"

# -----------------------------
# Install theme
# -----------------------------
echo "[2/5] Installing theme to /usr/share/sddm/themes..." | tee -a "$LOG"

sudo mkdir -p /usr/share/sddm/themes
sudo rm -rf "/usr/share/sddm/themes/$THEME_NAME"
sudo mv "/tmp/$THEME_NAME" "/usr/share/sddm/themes/$THEME_NAME" 2>&1 | tee -a "$LOG"

# -----------------------------
# Configure SDDM
# -----------------------------
echo "[3/5] Configuring SDDM..." | tee -a "$LOG"

# Backup config
if [ -f "$SDDM_CONF" ]; then
    sudo cp "$SDDM_CONF" "$SDDM_CONF.bak" 2>&1 | tee -a "$LOG"
else
    sudo touch "$SDDM_CONF"
fi

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

# # -----------------------------
# # Fix wallpaper if present
# # -----------------------------
# echo "[4/5] Checking wallpaper config..." | tee -a "$LOG"

# THEME_CONF="/usr/share/sddm/themes/$THEME_NAME/theme.conf"
# if [ -f "$THEME_CONF" ]; then
#     sudo sed -i 's|^wallpaper=.*|wallpaper="Backgrounds/default"|g' "$THEME_CONF" || true
# fi

# # -----------------------------
# # Done
# # -----------------------------
# echo "[5/5] Theme installed successfully." | tee -a "$LOG"
# echo "Reboot to see the new SDDM theme." | tee -a "$LOG"

# echo "==== Finished ===="
