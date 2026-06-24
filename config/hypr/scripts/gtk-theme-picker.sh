#!/usr/bin/env bash

# Auchlinux GTK Theme Switcher using Rofi
theme="$HOME/.config/rofi/powermenu/style.rasi"

get_themes() {
    find /usr/share/themes ~/.themes -mindepth 1 -maxdepth 1 -type d 2>/dev/null | rev | cut -d '/' -f 1 | rev | sort -u
}

current_theme=$(grep "gtk-theme-name" ~/.config/gtk-3.0/settings.ini | cut -d '=' -f 2)

selected=$(get_themes | rofi -dmenu -i -no-custom -p "GTK Theme (Current: $current_theme)" -theme "$theme")

if [ -n "$selected" ]; then
    # Update GTK 3
    sed -i "s/gtk-theme-name.*/gtk-theme-name=$selected/g" ~/.config/gtk-3.0/settings.ini
    
    # Update GTK 4 / gsettings
    gsettings set org.gnome.desktop.interface gtk-theme "$selected"
    
    notify-send -u low "GTK Theme" "Changed to $selected"
fi
