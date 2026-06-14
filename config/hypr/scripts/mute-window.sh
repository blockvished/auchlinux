#!/usr/bin/env bash

# Get the active window's PID, title, and class from Hyprland
ACTIVE_JSON=$(hyprctl activewindow -j)
ACTIVE_PID=$(echo "$ACTIVE_JSON" | jq -r '.pid')
ACTIVE_TITLE=$(echo "$ACTIVE_JSON" | jq -r '.title')
ACTIVE_CLASS=$(echo "$ACTIVE_JSON" | jq -r '.class' | tr '[:upper:]' '[:lower:]')

if [ -z "$ACTIVE_PID" ] || [ "$ACTIVE_PID" = "null" ]; then
    notify-send -a "Mute Window" -u low "Mute Window" "No active window found"
    exit 0
fi

# Get all PIDs in the tree of active window
TREE_PIDS=$( (echo "$ACTIVE_PID"; pstree -p "$ACTIVE_PID" | grep -o '[0-9]\+') | sort -u )

# Get all sink inputs from pactl with tab delimiter
SINK_INPUTS=$(pactl list sink-inputs | awk '
BEGIN {
    id = ""
    pid = ""
    app_name = ""
    media_name = ""
}
/^Sink Input #/ {
    if (id != "") {
        print id "\t" pid "\t" app_name "\t" media_name
    }
    id = substr($3, 2)
    pid = ""
    app_name = ""
    media_name = ""
}
/application.process.id =/ {
    val = $0
    sub(/^.*application.process.id = "/, "", val)
    sub(/"$/, "", val)
    pid = val
}
/application.name =/ {
    val = $0
    sub(/^.*application.name = "/, "", val)
    sub(/"$/, "", val)
    app_name = tolower(val)
}
/media.name =/ {
    val = $0
    sub(/^.*media.name = "/, "", val)
    sub(/"$/, "", val)
    media_name = val
}
END {
    if (id != "") {
        print id "\t" pid "\t" app_name "\t" media_name
    }
}')

# Phase 1: Filter inputs matching the process tree or application class
CANDIDATES=""
while IFS=$'\t' read -r id pid app_name media_name; do
    [ -z "$id" ] && continue
    
    match_found=false
    # Check if PID matches process tree
    if echo "$TREE_PIDS" | grep -q -x "$pid"; then
        match_found=true
    # Check if class name matches app name
    elif [ -n "$ACTIVE_CLASS" ] && [ "$ACTIVE_CLASS" != "null" ]; then
        if [ "$app_name" = "$ACTIVE_CLASS" ] || [[ "$ACTIVE_CLASS" == *"$app_name"* ]] || [[ "$app_name" == *"$ACTIVE_CLASS"* ]]; then
            match_found=true
        fi
    fi
    
    if [ "$match_found" = true ]; then
        # Append candidate details tab-separated
        CANDIDATES="$CANDIDATES$id"$'\t'"$media_name"$'\n'
    fi
done <<< "$SINK_INPUTS"

# Remove empty lines
CANDIDATES=$(echo "$CANDIDATES" | grep -v '^$')

if [ -z "$CANDIDATES" ]; then
    notify-send -a "Mute Window" -u low -i "audio-volume-muted" "Mute Window" "No audio stream found for the active window"
    exit 0
fi

# Phase 2: Narrow down by title / media name if we have candidates
MATCHED_IDS=""
while IFS=$'\t' read -r id media_name; do
    [ -z "$id" ] && continue
    
    if [ -n "$media_name" ] && [ -n "$ACTIVE_TITLE" ] && [ "$ACTIVE_TITLE" != "null" ]; then
        # Convert to lowercase for matching
        lc_media=$(echo "$media_name" | tr '[:upper:]' '[:lower:]')
        lc_title=$(echo "$ACTIVE_TITLE" | tr '[:upper:]' '[:lower:]')
        
        if [[ "$lc_title" == *"$lc_media"* ]] || [[ "$lc_media" == *"$lc_title"* ]]; then
            MATCHED_IDS="$MATCHED_IDS $id"
        fi
    fi
done <<< "$CANDIDATES"

# If we matched specifically by title/media name, use those
# Otherwise, fall back to muting all candidates matching the PID/class
if [ -n "$MATCHED_IDS" ]; then
    FINAL_IDS="$MATCHED_IDS"
else
    FINAL_IDS=$(echo "$CANDIDATES" | cut -f1 | tr '\n' ' ')
fi

# Toggle mute for all selected IDs
MUTED_COUNT=0
UNMUTED_COUNT=0

for id in $FINAL_IDS; do
    # Get current mute status
    CURRENT_MUTE=$(pactl list sink-inputs | awk -v target_id="$id" '
    /^Sink Input #/ { id = substr($3, 2) }
    /Mute:/ { if (id == target_id) { print $2; exit } }
    ')
    
    if [ "$CURRENT_MUTE" = "yes" ]; then
        pactl set-sink-input-mute "$id" no
        UNMUTED_COUNT=$((UNMUTED_COUNT + 1))
    else
        pactl set-sink-input-mute "$id" yes
        MUTED_COUNT=$((MUTED_COUNT + 1))
    fi
done

# Send a notification showing what was done
DISPLAY_TITLE=$(echo "$ACTIVE_TITLE" | cut -c1-30)
if [ "$MUTED_COUNT" -gt 0 ]; then
    notify-send -a "Mute Window" -u low -i "audio-volume-muted" "Muted window audio" "$DISPLAY_TITLE"
elif [ "$UNMUTED_COUNT" -gt 0 ]; then
    notify-send -a "Mute Window" -u low -i "audio-volume-high" "Unmuted window audio" "$DISPLAY_TITLE"
fi
