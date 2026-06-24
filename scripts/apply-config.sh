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
  "Kvantum"
  "qt5ct"
  "qt6ct"
  "rofi"
  "starship"
  "swaync"
  "waybar"
  "xfce4"
  "zsh"
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
    # Build per-folder exclude list to protect runtime-installed dirs not tracked in repo
    RSYNC_EXCLUDES=()
    if [[ "$folder" == "zsh" ]]; then
      RSYNC_EXCLUDES+=("--exclude=ohmyzsh/")       # installed by term-n-font.sh
      RSYNC_EXCLUDES+=("--exclude=.zcompdump*")    # zsh completion cache
      RSYNC_EXCLUDES+=("--exclude=.zsh_history")   # shell history
      RSYNC_EXCLUDES+=("--exclude=.zsh_sessions/") # zsh session files
    elif [[ "$folder" == "rofi" ]]; then
      RSYNC_EXCLUDES+=("--exclude=launcher/style.rasi")       # managed by rofi-theme
      RSYNC_EXCLUDES+=("--exclude=launcher/rofi_theme_mode")  # active theme state
    elif [[ "$folder" == "waybar" ]]; then
      RSYNC_EXCLUDES+=("--exclude=modules/")
      RSYNC_EXCLUDES+=("--exclude=includes/")
      RSYNC_EXCLUDES+=("--exclude=theme.css")
      RSYNC_EXCLUDES+=("--exclude=config.jsonc")
      RSYNC_EXCLUDES+=("--exclude=style.css")
      RSYNC_EXCLUDES+=("--exclude=themes/waybar_theme_mode")
    fi
    rsync --archive --delete "${RSYNC_EXCLUDES[@]}" "$SRC/" "$DST/"
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

# Sync individual files (like dolphinrc, kdeglobals)
FILES=(
  "dolphinrc"
  "kdeglobals"
  "dolphinstaterc"
)

for file in "${FILES[@]}"; do
  if [ -f "$REPO_CONFIG_DIR/$file" ]; then
    echo "[Sync] Syncing file $file to ~/.config/..."
    cp -f "$REPO_CONFIG_DIR/$file" "$TARGET_DIR/$file"
  fi
done

# Sync keepassxc config (lives in its own subdir)
if [ -f "$REPO_CONFIG_DIR/keepassxc/keepassxc.ini" ]; then
  echo "[Sync] Syncing keepassxc config..."
  mkdir -p "$TARGET_DIR/keepassxc"
  cp -f "$REPO_CONFIG_DIR/keepassxc/keepassxc.ini" "$TARGET_DIR/keepassxc/keepassxc.ini"
fi

if [ -f "$REPO_CONFIG_DIR/dolphinstaterc" ]; then
  mkdir -p "$HOME/.local/state"
  cp -f "$REPO_CONFIG_DIR/dolphinstaterc" "$HOME/.local/state/dolphinstaterc"
fi

if [ -f "$REPO_CONFIG_DIR/dolphin_kxmlgui/dolphinui.rc" ]; then
  echo "[Sync] Syncing Dolphin UI layout to ~/.local/share/kxmlgui5/dolphin/..."
  mkdir -p "$HOME/.local/share/kxmlgui5/dolphin"
  cp -f "$REPO_CONFIG_DIR/dolphin_kxmlgui/dolphinui.rc" "$HOME/.local/share/kxmlgui5/dolphin/dolphinui.rc"
fi

if [ -f "$REPO_CONFIG_DIR/dolphin_global_dir" ]; then
  echo "[Sync] Syncing Dolphin global sorting layout..."
  mkdir -p "$HOME/.local/share/dolphin/view_properties/global"
  cp -f "$REPO_CONFIG_DIR/dolphin_global_dir" "$HOME/.local/share/dolphin/view_properties/global/.directory"
fi

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

# Sync GTK Settings to dconf/gsettings
echo "[GTK] Syncing cursor theme to GSettings database..."
gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Ice" || true
gsettings set org.gnome.desktop.interface cursor-size 24 || true
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" || true

echo "[GTK] Configuring fallback cursor in ~/.icons/default..."
mkdir -p "$HOME/.icons/default"
echo -e "[Icon Theme]\nInherits=Bibata-Modern-Ice" > "$HOME/.icons/default/index.theme"

# Extract offline cursor/icon themes to ~/.icons (only if not already extracted)
REPO_ICONS="$REPO_CONFIG_DIR/../scripts/icons"
if [ -d "$REPO_ICONS" ]; then
  mkdir -p "$HOME/.icons"
  for tarball in "$REPO_ICONS"/*.tar.gz; do
    [ -f "$tarball" ] || continue
    name=$(basename "$tarball" .tar.gz)
    if [ ! -d "$HOME/.icons/$name" ]; then
      echo "[Sync] Extracting cursor/icon theme $name to ~/.icons..."
      tar -xzf "$tarball" -C "$HOME/.icons/"
    fi
  done
fi

echo "==== Configurations successfully applied! ===="
