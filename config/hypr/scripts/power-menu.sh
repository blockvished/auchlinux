#!/usr/bin/env bash

theme="$HOME/.config/rofi/powermenu/style.rasi"

options=$'  Lock\n󰤄  Suspend\n󰍃  Logout\n󰜉  Restart\n󰐥  Shutdown'

menu() {
  local prompt="$1"
  local lines="${2:-5}"

  rofi -dmenu -i -no-custom -p "$prompt" -theme "$theme" -theme-str "listview { lines: ${lines}; }"
}

confirm() {
  local action="$1"
  local answer

  answer="$(printf 'No\nYes\n' | menu "$action?" 2)"
  [[ "$answer" == "Yes" ]]
}

lock_screen() {
  pidof hyprlock >/dev/null || hyprlock
}

choice="$(printf '%s\n' "$options" | menu "System" 5)"
[[ -z "$choice" ]] && exit 0

case "$choice" in
  "  Lock")
    lock_screen
    ;;
  "󰤄  Suspend")
    loginctl lock-session
    systemctl suspend
    ;;
  "󰍃  Logout")
    confirm "Logout" && hyprctl dispatch exit
    ;;
  "󰜉  Restart")
    confirm "Restart" && systemctl reboot
    ;;
  "󰐥  Shutdown")
    confirm "Shutdown" && systemctl poweroff
    ;;
  *)
    notify-send -u low "Power menu" "Unknown action: $choice"
    ;;
esac
