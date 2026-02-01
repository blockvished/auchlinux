#!/bin/bash

set -e

LOG="$HOME/sddm-install-$(date +%d-%H%M%S).log"
WAYLAND_DIR="/usr/share/wayland-sessions"

echo "==== SDDM Setup Script Started ====" | tee -a "$LOG"

# -----------------------------
# Check if SDDM already enabled
# -----------------------------
if systemctl is-enabled sddm >/dev/null 2>&1; then
    echo "SDDM is already enabled. System is already using SDDM." | tee -a "$LOG"
    echo "Nothing to change. Exiting safely." | tee -a "$LOG"
    exit 0
fi

# -----------------------------
# Packages needed
# -----------------------------
PACKAGES=(
  sddm
  qt6-declarative
  qt6-svg
  qt6-virtualkeyboard
  qt6-multimedia-ffmpeg
  qt5-quickcontrols2
)

echo "[1/6] Installing SDDM and dependencies..." | tee -a "$LOG"
sudo pacman -S --needed "${PACKAGES[@]}" --noconfirm 2>&1 | tee -a "$LOG"

# -----------------------------
# Disable other display managers
# -----------------------------
LOGIN_MANAGERS=(
  lightdm
  gdm
  gdm3
  lxdm
  lxdm-gtk3
)

echo "[2/6] Disabling other display managers..." | tee -a "$LOG"

for dm in "${LOGIN_MANAGERS[@]}"; do
  if systemctl list-unit-files | grep -q "^$dm.service"; then
    echo "Disabling $dm..." | tee -a "$LOG"
    sudo systemctl disable "$dm" --now 2>&1 | tee -a "$LOG" || true
  fi
done

# -----------------------------
# Enable SDDM
# -----------------------------
echo "[3/6] Enabling SDDM service..." | tee -a "$LOG"
sudo systemctl enable sddm 2>&1 | tee -a "$LOG"

# -----------------------------
# Wayland session directory
# -----------------------------
echo "[4/6] Checking Wayland sessions directory..." | tee -a "$LOG"

if [ ! -d "$WAYLAND_DIR" ]; then
  echo "Creating $WAYLAND_DIR..." | tee -a "$LOG"
  sudo mkdir -p "$WAYLAND_DIR" 2>&1 | tee -a "$LOG"
fi

# -----------------------------
# Show available sessions
# -----------------------------
echo "[5/6] Available login sessions:" | tee -a "$LOG"
ls /usr/share/xsessions /usr/share/wayland-sessions 2>/dev/null | tee -a "$LOG"

# -----------------------------
# Finish
# -----------------------------
echo "[6/6] Done." | tee -a "$LOG"
echo "Reboot to enter the SDDM login screen." | tee -a "$LOG"

echo "==== Finished Successfully ===="
