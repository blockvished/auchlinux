#!/usr/bin/env bash

step="5%"; notify_id=91192

brightness_percent() {
  brightnessctl -m | awk -F, '{ gsub("%", "", $4); print $4 }'
}

case "$1" in
  up)
    brightnessctl -e4 -n2 set "$step+"
    ;;
  down)
    brightnessctl -e4 -n2 set "$step-"
    ;;
  *)
    printf 'Usage: %s {up|down}\n' "$0" >&2
    exit 1
    ;;
esac

brightness="$(brightness_percent)"
notify-send \
  -a "Brightness" \
  -r "$notify_id" \
  -u low \
  -t 900 \
  -e \
  -h "int:value:${brightness}" \
  -h "string:x-canonical-private-synchronous:brightness" \
  -h "string:x-dunst-stack-tag:brightness" \
  "󰃠  Brightness" "${brightness}%"
