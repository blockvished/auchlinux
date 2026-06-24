#!/usr/bin/env bash

# Auchlinux Cursor Theme Switcher using Rofi
theme="$HOME/.config/rofi/powermenu/style.rasi"

get_themes() {
    # Dynamically find all installed cursor themes (they contain a "cursors" subfolder)
    find ~/.icons ~/.local/share/icons /usr/share/icons -mindepth 2 -maxdepth 2 -type d -name "cursors" 2>/dev/null | awk -F'/' '{print $(NF-1)}' | sort -u
}

current_theme=$(gsettings get org.gnome.desktop.interface cursor-theme | tr -d "'")

selected=$(get_themes | rofi -dmenu -i -no-custom -p "Cursor (Current: $current_theme)" -theme "$theme")

if [ -n "$selected" ]; then
    # Update GSettings (GTK/Waybar)
    gsettings set org.gnome.desktop.interface cursor-theme "$selected"
    
    # Update index.theme (Fallback)
    mkdir -p ~/.icons/default
    echo -e "[Icon Theme]\nInherits=$selected" > ~/.icons/default/index.theme
    
    # Update Hyprland environment variable in env_var.lua
    sed -i "s/hl.env(\"XCURSOR_THEME\",.*)/hl.env(\"XCURSOR_THEME\", \"$selected\")/g" ~/.config/hypr/hyprland/env_var.lua
    sed -i "s/hl.env(\"HYPRCURSOR_THEME\",.*)/hl.env(\"HYPRCURSOR_THEME\", \"$selected\")/g" ~/.config/hypr/hyprland/env_var.lua
    
    # Update GTK-3.0
    sed -i "s/gtk-cursor-theme-name.*/gtk-cursor-theme-name=$selected/g" ~/.config/gtk-3.0/settings.ini
    
    # Apply to running Hyprland session dynamically
    hyprctl setcursor "$selected" 24
    
    notify-send -u low "Cursor Theme" "Changed to $selected (Restart apps to fully apply)"
fi
