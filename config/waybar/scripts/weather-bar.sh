#!/usr/bin/env bash
# Start/stop the standalone weather bar (a separate Waybar instance, independent
# of the main auch/min bar so theme switches don't disturb it).
#   weather-bar.sh start | stop | toggle   (default: start)
CONF="$HOME/.config/waybar/config_weather.jsonc"
STYLE="$HOME/.config/waybar/style_weather.css"
MATCH="waybar.*config_weather.jsonc"

running(){ pgrep -f "$MATCH" >/dev/null; }

case "${1:-start}" in
    start)  running || setsid -f waybar -c "$CONF" -s "$STYLE" >/dev/null 2>&1 ;;
    stop)   pkill -f "$MATCH" ;;
    toggle) if running; then pkill -f "$MATCH"; else setsid -f waybar -c "$CONF" -s "$STYLE" >/dev/null 2>&1; fi ;;
    *)      echo "usage: weather-bar.sh start|stop|toggle" ;;
esac
