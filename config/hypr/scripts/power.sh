#!/usr/bin/env bash

# Define options (labels must match the case patterns below)
options=$'  Lock\n󱄄  Suspend\n󰍃  Logout\n󰜉  Restart\n󰐥  Shutdown'

# Show rofi in dmenu mode
choice="$(printf '%s\n' "$options" | rofi -dmenu -p 'System' -i)"

# If user cancels (Esc / close), exit
[ -z "$choice" ] && exit 0

case "$choice" in
  "  Lock")
    hyprlock
    ;;

  "󰤄  Suspend")
    systemctl suspend
    ;;

  "󰍃  Logout")
    # Hyprland example:
    hyprctl dispatch exit
    ;;

  "󰜉  Restart")
    systemctl reboot
    ;;

  "󰐥  Shutdown")
    systemctl poweroff
    ;;

  *)
    # Unknown selection; do nothing
    ;;
esac

