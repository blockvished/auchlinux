#!/usr/bin/env bash

set -euo pipefail

step="${VOLUME_STEP:-5%}"
sink="${VOLUME_SINK:-@DEFAULT_AUDIO_SINK@}"
source="${VOLUME_SOURCE:-@DEFAULT_AUDIO_SOURCE@}"
notify_id="${VOLUME_NOTIFY_ID:-91190}"
mic_notify_id="${MIC_NOTIFY_ID:-91191}"

has() {
  command -v "$1" >/dev/null 2>&1
}

has wpctl || {
  printf 'volume.sh: wpctl is required\n' >&2
  exit 1
}

volume_percent() {
  wpctl get-volume "$sink" | awk '{ printf "%d", $2 * 100 }'
}

is_muted() {
  wpctl get-volume "$sink" | grep -q MUTED
}

notify_volume() {
  has notify-send || return 0

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

case "${1:-}" in
  up)
    wpctl set-mute "$sink" 0
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
    has notify-send || exit 0
    notify-send \
      -a "Microphone" \
      -r "$mic_notify_id" \
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
