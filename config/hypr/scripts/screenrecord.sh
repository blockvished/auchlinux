#!/usr/bin/env bash

# Define paths
SAVE_DIR="${XDG_VIDEOS_DIR:-$HOME/Videos}/Recordings"
mkdir -p "$SAVE_DIR"
TIMESTAMP=$(date +'%Y-%m-%d_%H-%M-%S')
FILE_PATH="$SAVE_DIR/recording_$TIMESTAMP.mp4"

# Check if wf-recorder is already running
if pgrep -x "wf-recorder" > /dev/null; then
    # Stop recording gracefully
    pkill -INT -x "wf-recorder"
    notify-send -a "Screen Recorder" -i "video-x-generic" "Recording Stopped" "Video saved to $SAVE_DIR"
    # Update waybar status immediately
    pkill -RTMIN+9 waybar || true
    exit 0
fi

# Parse options
AUDIO=false
FULLSCREEN=false
SCALE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --audio|-a)
            AUDIO=true
            shift
            ;;
        --fullscreen|-f)
            FULLSCREEN=true
            shift
            ;;
        --scale|-s)
            SCALE=true
            shift
            ;;
        *)
            # support legacy positional f argument
            if [[ "$1" == "f" ]]; then
                FULLSCREEN=true
            fi
            shift
            ;;
    esac
done

# Build arguments for wf-recorder
ARGS=()
if [ "$AUDIO" = true ]; then
    ARGS+=("-a")
fi
if [ "$SCALE" = true ]; then
    # Downscale resolution to half (iw/2:ih/2)
    ARGS+=("-F" "scale=iw/2:ih/2")
fi

if [ "$FULLSCREEN" = true ]; then
    notify-send -a "Screen Recorder" -i "video-x-generic" "Recording Started" "Recording full screen. Press shortcut again to stop."
    # Start wf-recorder in background
    wf-recorder "${ARGS[@]}" -f "$FILE_PATH" >/dev/null 2>&1 &
else
    # If not running, start recording by selecting an area
    notify-send -a "Screen Recorder" -i "video-x-generic" "Select Area" "Drag a box to start recording, or press Escape to cancel."
    GEOM=$(slurp)

    # Check if geometry selection was cancelled
    if [ -z "$GEOM" ]; then
        notify-send -a "Screen Recorder" -i "dialog-error" "Recording Cancelled" "No area was selected."
        exit 1
    fi

    notify-send -a "Screen Recorder" -i "video-x-generic" "Recording Started" "Recording selected area. Press shortcut again to stop."

    # Start wf-recorder in background
    wf-recorder "${ARGS[@]}" -g "$GEOM" -f "$FILE_PATH" >/dev/null 2>&1 &
fi

# Trigger Waybar refresh to show recording status instantly
sleep 0.2
pkill -RTMIN+9 waybar || true
