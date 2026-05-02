#!/usr/bin/env bash

step="5%"
sink="@DEFAULT_AUDIO_SINK@"
source="@DEFAULT_AUDIO_SOURCE@"
notify_id=91190

volume_percent() {
  wpctl get-volume "$sink" | awk '{ printf "%d", $2 * 100 }'
}

is_muted() {
  wpctl get-volume "$sink" | grep -q MUTED
}

notify_volume() {
  local volume="$1"
  local icon=""
  local message="${volume}%"

  if is_muted; then
    icon=""
    message="Muted"
  elif (( volume == 0 )); then
    icon=""
  elif (( volume < 50 )); then
    icon=""
  fi

  notify-send \
    -a "Volume" \
    -r "$notify_id" \
    -u low \
    -t 900 \
    -e \
    -h "int:value:${volume}" \
    -h "string:x-canonical-private-synchronous:volume" \
    -h "string:x-dunst-stack-tag:volume" \
    "$icon  Volume" "$message"
}

case "$1" in
  up)
    wpctl set-volume -l 1 "$sink" "$step+"
    ;;
  down)
    wpctl set-volume "$sink" "$step-"
    ;;
  mute)
    wpctl set-mute "$sink" toggle
    ;;
  mic-mute)
    wpctl set-mute "$source" toggle
    muted="$(wpctl get-volume "$source" | grep -q MUTED && printf Muted || printf Unmuted)"
    notify-send \
      -a "Microphone" \
      -r 91191 \
      -u low \
      -t 900 \
      -e \
      -h "string:x-canonical-private-synchronous:microphone" \
      -h "string:x-dunst-stack-tag:microphone" \
      "  Microphone" "$muted"
    exit 0
    ;;
  *)
    printf 'Usage: %s {up|down|mute|mic-mute}\n' "$0" >&2
    exit 1
    ;;
esac

notify_volume "$(volume_percent)"
