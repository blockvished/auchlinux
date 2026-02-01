#!/usr/bin/env bash

# Constants
TEMP=4000
GAMMA=80
STATE_FILE="$HOME/.cache/nightlight_state"
WAYBAR_SIGNAL=8 # Match this to your Waybar config (see below)

ensure_state() {
    [[ -f "$STATE_FILE" ]] || echo "off" > "$STATE_FILE"
}

update_waybar() {
    # This sends a signal to Waybar to refresh the module immediately
    pkill -RTMIN+$WAYBAR_SIGNAL waybar
}

start_nightlight() {
    pkill -x hyprsunset 2>/dev/null
    # Give the previous process a moment to release the display
    sleep 0.1
    hyprsunset -t "$TEMP" -g "$GAMMA" >/dev/null 2>&1 &
    echo "on" > "$STATE_FILE"
    notify-send -u low "🌙 Night Light Enabled" "${TEMP}K | Gamma ${GAMMA}%"
}

stop_nightlight() {
    pkill -x hyprsunset 2>/dev/null
    # Hyprsunset usually resets the screen on exit; 
    # we only need -i if the screen stays tinted.
    echo "off" > "$STATE_FILE"
    notify-send -u low "☀️ Night Light Disabled"
}

case "$1" in
    toggle)
        ensure_state
        state=$(cat "$STATE_FILE")
        if [[ "$state" == "on" ]]; then
            stop_nightlight
        else
            start_nightlight
        fi
        update_waybar
        ;;
    status)
        ensure_state
        state=$(cat "$STATE_FILE")
        if [[ "$state" == "on" ]]; then
            printf '{"text":"","class":"on","tooltip":"Night Light ON (%sK)"}\n' "$TEMP"
        else
            printf '{"text":"","class":"off","tooltip":"Night Light OFF"}\n'
        fi
        ;;
esac