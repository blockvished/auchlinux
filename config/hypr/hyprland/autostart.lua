-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

hl.on("hyprland.start", function()
    -- Import display environment variables into systemd
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DISPLAY")
    
    -- Start services via systemd user units
    hl.exec_cmd("systemctl --user start waybar")
    hl.exec_cmd("systemctl --user start hypridle")
    hl.exec_cmd("command -v swaync >/dev/null 2>&1 && systemctl --user start swaync || systemctl --user start dunst")
    
    -- Start daemons without systemd units directly
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("~/.config/hypr/scripts/clipboard-watch.sh")
    hl.exec_cmd("pypr")
end)
