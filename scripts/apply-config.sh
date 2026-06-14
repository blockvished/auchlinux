#!/usr/bin/env bash
# Script to safely apply/sync configurations from the repository to ~/.config

set -euo pipefail

REPO_CONFIG_DIR="$(cd "$(dirname "$0")/../config" && pwd)"
TARGET_DIR="$HOME/.config"

echo "==== Applying configurations from repository to ~/.config ===="

# Folders to sync (will overwrite destination completely after backup)
FOLDERS=(
  "cava"
  "dunst"
  "fastfetch"
  "gtk-3.0"
  "gtk-4.0"
  "hypr"
  "kitty"
  "matugen"
  "nwg-look"
  "pypr"
  "rofi"
  "swaync"
  "waybar"
  "xfce4"
)

# Folders to merge (will copy files recursively without wiping the target folder)
MERGE_FOLDERS=(
  "Code - OSS"
)

# Filter folders if arguments are provided
SELECTED_FOLDERS=()
if [[ $# -gt 0 ]]; then
  for arg in "$@"; do
    found=false
    for f in "${FOLDERS[@]}" "${MERGE_FOLDERS[@]}"; do
      if [[ "$arg" == "$f" ]]; then
        SELECTED_FOLDERS+=("$arg")
        found=true
        break
      fi
    done
    if [[ "$found" == false ]]; then
      echo "[Warning] Folder '$arg' is not configured for syncing. Skipping."
    fi
  done
  if [[ ${#SELECTED_FOLDERS[@]} -eq 0 ]]; then
    echo "[Error] No valid folders specified. Exiting."
    exit 1
  fi
else
  # Default to syncing all folders
  SELECTED_FOLDERS=("${FOLDERS[@]}" "${MERGE_FOLDERS[@]}")
fi

contains_folder() {
  local item="$1"
  for f in "${SELECTED_FOLDERS[@]}"; do
    if [[ "$f" == "$item" ]]; then
      return 0
    fi
  done
  return 1
}

# Sync each standard folder
for folder in "${FOLDERS[@]}"; do
  contains_folder "$folder" || continue
  SRC="$REPO_CONFIG_DIR/$folder"
  DST="$TARGET_DIR/$folder"
  
  if [ -d "$SRC" ]; then
    # If the destination is a file or symlink, remove it so rsync can write to the directory
    if [ -f "$DST" ] || [ -L "$DST" ]; then
      echo "[Clean] Removing file/symlink at $DST"
      rm -f "$DST"
    fi
    
    echo "[Sync] Syncing $folder to ~/.config/..."
    mkdir -p "$DST"
    rsync --archive --delete "$SRC/" "$DST/"
  else
    echo "[Skip] Folder $folder does not exist in repository config."
  fi
done

# Merge each merge-folder
for folder in "${MERGE_FOLDERS[@]}"; do
  contains_folder "$folder" || continue
  SRC="$REPO_CONFIG_DIR/$folder"
  DST="$TARGET_DIR/$folder"
  
  if [ -d "$SRC" ]; then
    echo "[Sync-Merge] Merging $folder into ~/.config/..."
    mkdir -p "$DST"
    rsync --archive "$SRC/" "$DST/"
  else
    echo "[Skip] Merge folder $folder does not exist in repository config."
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
  if systemctl --user is-active waybar.service >/dev/null 2>&1; then
    echo "[Reload] Restarting Waybar via systemd..."
    systemctl --user restart waybar || true
  elif pgrep -u "$USER" -x "waybar" > /dev/null; then
    echo "[Reload] Restarting Waybar manually..."
    pkill -u "$USER" -USR2 waybar || pkill -u "$USER" waybar && waybar &
  fi
  
  # Restart notification daemon
  if command -v swaync >/dev/null 2>&1; then
    echo "[Reload] Restarting SwayNC notification daemon..."
    systemctl --user restart swaync || (pkill -x swaync || true && swaync &)
  else
    echo "[Reload] Restarting Dunst notification daemon..."
    systemctl --user restart dunst || systemctl --user start dunst || true
  fi
fi

echo "==== Configurations successfully applied! ===="
