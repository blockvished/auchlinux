#!/usr/bin/env bash

wallpaper_dir="$HOME/Pictures/Wallpapers"
theme="$HOME/.config/rofi/wallpaper/style.rasi"
state_file="$HOME/.cache/current_wallpaper"

find_wallpapers() {
  find "$wallpaper_dir" -maxdepth 2 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' -o -iname '*.gif' \) \
    -printf '%P\n' | sort
}

wallpaper_menu() {
  while IFS= read -r wallpaper; do
    printf '%s\0icon\x1f%s/%s\n' "$wallpaper" "$wallpaper_dir" "$wallpaper"
  done
}

if ! pgrep -x awww-daemon >/dev/null; then
  awww-daemon >/dev/null 2>&1 &
  sleep 0.2
fi

choice="$(find_wallpapers | wallpaper_menu | rofi -dmenu -i -no-custom -show-icons -p "Wallpaper" -theme "$theme")"
[[ -z "$choice" ]] && exit 0

wallpaper="$wallpaper_dir/$choice"

if [[ ! -f "$wallpaper" ]]; then
  notify-send -u low "Wallpaper" "File not found: $choice"
  exit 1
fi

awww img "$wallpaper" --resize crop --transition-type grow --transition-pos center --transition-duration 1
printf '%s\n' "$wallpaper" > "$state_file"
notify-send -u low -t 1200 "Wallpaper" "$choice"
