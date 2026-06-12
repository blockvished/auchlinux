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
    exit 0
fi

# Check if fullscreen argument is provided
if [[ "${1:-}" == "--fullscreen" || "${1:-}" == "-f" || "${1:-}" == "f" ]]; then
    notify-send -a "Screen Recorder" -i "video-x-generic" "Recording Started" "Recording full screen. Press shortcut again to stop."
    # Start wf-recorder in background
    wf-recorder -f "$FILE_PATH" &
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
    wf-recorder -g "$GEOM" -f "$FILE_PATH" &
fi
