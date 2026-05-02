#!/usr/bin/env bash

theme="$HOME/.config/rofi/clipboard/style.rasi"
watcher="$HOME/.config/hypr/scripts/clipboard-watch.sh"
favorites_file="$HOME/.cache/cliphist_favorites"

"$watcher"

notify() {
  notify-send -a "Clipboard" -u low -t 1200 "󰅇  Clipboard" "$1"
}

run_rofi() {
  local prompt="$1"
  shift

  rofi -dmenu -i -no-custom -p "$prompt" -theme "$theme" "$@"
}

history_empty() {
  ! cliphist list >/dev/null 2>&1 || [[ -z "$(cliphist list 2>/dev/null)" ]]
}

copy_item() {
  local item="$1"

  if [[ "$item" == *"[[ binary data"* ]]; then
    printf '%s' "$item" | cliphist decode | wl-copy
    notify "Copied binary item"
  else
    printf '%s' "$item" | cliphist decode | wl-copy
    notify "Copied from history"
  fi
}

show_history() {
  if history_empty; then
    notify "History is empty. Copy something and try again."
    exit 0
  fi

  local selected
  selected="$(
    {
      printf ':favorites:\t📌 Favorites\n'
      printf ':options:\t⚙️ Options\n'
      cliphist list
    } | run_rofi "History" -multi-select -display-columns 2 -selected-row 2
  )"

  [[ -z "$selected" ]] && exit 0

  case "$selected" in
    :favorites:*) view_favorites ;;
    :options:*) show_options ;;
    *)
      while IFS= read -r item; do
        [[ -n "$item" ]] && copy_item "$item"
      done <<< "$selected"
      ;;
  esac
}

delete_items() {
  if history_empty; then
    notify "History is empty."
    return
  fi

  local selected
  selected="$(cliphist list | run_rofi "Delete" -multi-select -display-columns 2)"
  [[ -z "$selected" ]] && return

  while IFS= read -r item; do
    [[ -n "$item" ]] && printf '%s' "$item" | cliphist delete
  done <<< "$selected"

  notify "Deleted selected item(s)"
}

ensure_favorites_file() {
  mkdir -p "$(dirname "$favorites_file")"
  touch "$favorites_file"
}

favorite_preview() {
  base64 --decode <<< "$1" | tr '\n' ' '
}

add_favorite() {
  if history_empty; then
    notify "History is empty."
    return
  fi

  ensure_favorites_file

  local item decoded encoded
  item="$(cliphist list | run_rofi "Add Favorite" -display-columns 2)"
  [[ -z "$item" ]] && return

  decoded="$(printf '%s' "$item" | cliphist decode)"
  encoded="$(printf '%s' "$decoded" | base64 -w 0)"

  if grep -Fxq "$encoded" "$favorites_file"; then
    notify "Already in favorites"
  else
    printf '%s\n' "$encoded" >> "$favorites_file"
    notify "Added to favorites"
  fi
}

view_favorites() {
  ensure_favorites_file

  if [[ ! -s "$favorites_file" ]]; then
    notify "No favorites yet."
    return
  fi

  local previews selected index encoded
  previews="$(while IFS= read -r encoded; do favorite_preview "$encoded"; printf '\n'; done < "$favorites_file")"
  selected="$(printf '%s' "$previews" | run_rofi "Favorites")"
  [[ -z "$selected" ]] && return

  index="$(printf '%s' "$previews" | grep -nxF "$selected" | cut -d: -f1 | head -n 1)"
  [[ -z "$index" ]] && return

  encoded="$(sed -n "${index}p" "$favorites_file")"
  base64 --decode <<< "$encoded" | wl-copy
  notify "Copied favorite"
}

delete_favorite() {
  ensure_favorites_file

  if [[ ! -s "$favorites_file" ]]; then
    notify "No favorites to remove."
    return
  fi

  local previews selected index
  previews="$(while IFS= read -r encoded; do favorite_preview "$encoded"; printf '\n'; done < "$favorites_file")"
  selected="$(printf '%s' "$previews" | run_rofi "Remove Favorite")"
  [[ -z "$selected" ]] && return

  index="$(printf '%s' "$previews" | grep -nxF "$selected" | cut -d: -f1 | head -n 1)"
  [[ -z "$index" ]] && return

  sed -i "${index}d" "$favorites_file"
  notify "Removed favorite"
}

manage_favorites() {
  local action
  action="$(printf 'Add Favorite\nRemove Favorite\nClear Favorites\n' | run_rofi "Favorites")"

  case "$action" in
    "Add Favorite") add_favorite ;;
    "Remove Favorite") delete_favorite ;;
    "Clear Favorites")
      [[ "$(printf 'No\nYes\n' | run_rofi "Clear Favorites?")" == "Yes" ]] && : > "$favorites_file" && notify "Favorites cleared"
      ;;
  esac
}

wipe_history() {
  [[ "$(printf 'No\nYes\n' | run_rofi "Clear History?")" == "Yes" ]] || return
  cliphist wipe
  notify "History cleared"
}

show_options() {
  local action
  action="$(printf 'Delete\nManage Favorites\nClear History\n' | run_rofi "Options")"

  case "$action" in
    "Delete") delete_items ;;
    "Manage Favorites") manage_favorites ;;
    "Clear History") wipe_history ;;
  esac
}

case "$1" in
  delete) delete_items ;;
  favorites) view_favorites ;;
  manage-favorites) manage_favorites ;;
  wipe) wipe_history ;;
  "" | history) show_history ;;
  *)
    printf 'Usage: %s [history|delete|favorites|manage-favorites|wipe]\n' "$0" >&2
    exit 1
    ;;
esac
