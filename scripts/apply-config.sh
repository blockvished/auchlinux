#!/usr/bin/env bash
# Script to safely apply/sync configurations from the repository to ~/.config

set -euo pipefail

REPO_CONFIG_DIR="$(cd "$(dirname "$0")/../config" && pwd)"
TARGET_DIR="$HOME/.config"
BACKUP_SUFFIX=".bak-$(date +'%y%m%d-%H%M%S')"

echo "==== Applying configurations from repository to ~/.config ===="

# Folders to sync
FOLDERS=(
  "cava"
  "dunst"
  "fastfetch"
  "gtk-3.0"
  "gtk-4.0"
  "hypr"
  "kitty"
  "nwg-look"
  "rofi"
  "waybar"
  "xfce4"
)

# Sync each folder
for folder in "${FOLDERS[@]}"; do
  SRC="$REPO_CONFIG_DIR/$folder"
  DST="$TARGET_DIR/$folder"
  
  if [ -d "$SRC" ]; then
    # If the destination already exists and is not a symlink/empty, back it up
    if [ -d "$DST" ] && [ ! -L "$DST" ]; then
      echo "[Backup] Backing up existing $DST to ${DST}${BACKUP_SUFFIX}"
      mv "$DST" "${DST}${BACKUP_SUFFIX}"
    elif [ -L "$DST" ] || [ -f "$DST" ]; then
      echo "[Backup] Removing old symlink/file at $DST"
      rm -rf "$DST"
    fi
    
    echo "[Sync] Copying $folder to ~/.config/..."
    mkdir -p "$TARGET_DIR"
    cp -r "$SRC" "$DST"
  else
    echo "[Skip] Folder $folder does not exist in repository config."
  fi
done

# Ensure all scripts under ~/.config/ are executable
echo "[Permissions] Ensuring all scripts under ~/.config/ are executable..."
find "$TARGET_DIR" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} + 2>/dev/null || true

# Reload Hyprland config (if running)
if pgrep -x "Hyprland" > /dev/null; then
  echo "[Reload] Reloading Hyprland configuration..."
  hyprctl reload || true
  
  # Also reload waybar if running
  if pgrep -u "$USER" -x "waybar" > /dev/null; then
    echo "[Reload] Restarting Waybar..."
    pkill -u "$USER" -USR2 waybar || pkill -u "$USER" waybar && waybar &
  fi
  
  # Restart Dunst notification daemon using systemd
  echo "[Reload] Restarting Dunst notification daemon..."
  systemctl --user restart dunst || systemctl --user start dunst || true
fi

echo "==== Configurations successfully applied! ===="
