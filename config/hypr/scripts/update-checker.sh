#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  update-checker.sh  —  Show pending pacman/AUR updates in Rofi
#  Usage: called by Waybar custom/updates module
# ─────────────────────────────────────────────────────────────

UPDATES=$(checkupdates 2>/dev/null)
AUR_UPDATES=$(paru -Qua 2>/dev/null || yay -Qua 2>/dev/null)

ALL_UPDATES=""
[[ -n "$UPDATES" ]] && ALL_UPDATES="$UPDATES"
[[ -n "$AUR_UPDATES" ]] && ALL_UPDATES="${ALL_UPDATES:+$ALL_UPDATES\n}[AUR] $AUR_UPDATES"

COUNT=$(echo -e "$ALL_UPDATES" | grep -c '\S' 2>/dev/null || echo 0)

# Called with --status: print JSON for Waybar
if [[ "$1" == "--status" ]]; then
    if [[ "$COUNT" -eq 0 ]]; then
        echo '{"text":"","tooltip":"System up to date","class":"up-to-date"}'
    else
        echo "{\"text\":\" $COUNT\",\"tooltip\":\"$COUNT update(s) pending\",\"class\":\"has-updates\"}"
    fi
    exit 0
fi

# Called without args: open Rofi picker and upgrade selected
if [[ -z "$ALL_UPDATES" ]]; then
    notify-send "System up to date" "No pending updates found." -i system-software-update
    exit 0
fi

SELECTED=$(echo -e "$ALL_UPDATES" | rofi -dmenu \
    -p "󰏖 Updates ($COUNT)" \
    -theme ~/.config/rofi/launcher/style.rasi \
    -mesg "Enter = upgrade all  |  Select a pkg to upgrade individually")

if [[ -z "$SELECTED" ]]; then
    exit 0
fi

# Extract pkg name (strip [AUR] prefix)
PKG=$(echo "$SELECTED" | awk '{print $NF == $1 ? $1 : $2}' | sed 's/\[AUR\] //')

kitty --title "System Upgrade" -e bash -c "
    echo '==> Upgrading: $PKG'
    if echo '$SELECTED' | grep -q '^\[AUR\]'; then
        paru -S --noconfirm $PKG || yay -S --noconfirm $PKG
    else
        sudo pacman -S --noconfirm $PKG
    fi
    echo '==> Done. Press Enter to close.'
    read
"
