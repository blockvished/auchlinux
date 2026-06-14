#!/usr/bin/env bash

if systemctl --user is-active waybar.service >/dev/null 2>&1; then
    echo "Restarting Waybar via systemd..."
    systemctl --user restart waybar
else
    echo "Restarting Waybar manually..."
    killall -q -9 waybar || true
    sleep 0.2
    waybar &
fi