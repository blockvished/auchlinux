---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "kitty"
local fileManager = "dolphin"
local menu        = "~/.config/rofi/launcher/launcher.sh || pkill rofi"
local TerminalEmulator = "kitty"

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
local closeWindowBind = hl.bind(mainMod .. " + SHIFT + q", hl.dsp.window.close())
-- closeWindowBind:set_enabled(false)
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || (command -v uwsm >/dev/null 2>&1 && uwsm check is-active && uwsm stop || hyprctl dispatch exit)"))
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("~/.config/hypr/scripts/restart-waybar.sh"))
hl.bind("CTRL + Escape", hl.dsp.exec_cmd("pgrep -x waybar > /dev/null && killall waybar || waybar &"))
hl.bind(mainMod .. " + Backspace", hl.dsp.exec_cmd("~/.config/hypr/scripts/power-menu.sh"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd("keepassxc"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("rofi -show calc -modi calc -no-show-match -no-sort -theme ~/.config/rofi/calc/style.rasi"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = 0 }))
hl.bind(mainMod .. " + CTRL + F", hl.dsp.window.fullscreen({ mode = 1 }))
hl.bind(mainMod .. " + W", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("~/.config/hypr/scripts/clipboard-menu.sh history"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("~/.config/hypr/scripts/clipboard-menu.sh options"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))    -- dwindle only
hl.bind(mainMod .. " + N",             hl.dsp.exec_cmd("~/.config/hypr/scripts/nightlight.sh toggle"))
hl.bind(mainMod .. " + SHIFT + N",     hl.dsp.exec_cmd("~/.config/hypr/scripts/nightlight.sh warmer"))
hl.bind(mainMod .. " + ALT + N",       hl.dsp.exec_cmd("~/.config/hypr/scripts/nightlight.sh cooler"))
hl.bind(mainMod .. " + SHIFT + G",     hl.dsp.exec_cmd("~/.config/hypr/scripts/nightlight.sh gamma-up"))
hl.bind(mainMod .. " + ALT + G",       hl.dsp.exec_cmd("~/.config/hypr/scripts/nightlight.sh gamma-down"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("~/.config/hypr/scripts/wallpaper-picker.sh"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("pypr toggle console"))
hl.bind(mainMod .. " + ALT + D", hl.dsp.exec_cmd("~/.config/hypr/scripts/rofi-web-search.sh"))
-- Toggle Game Mode
local function toggle_gamemode()
    local anims = hl.get_config("animations.enabled")
    if anims then
        hl.config({
            animations = { enabled = false },
            general = {
                gaps_in = 2,
                gaps_out = 2,
                border_size = 1
            },
            decoration = {
                shadow = { enabled = false },
                blur = { enabled = false },
                rounding = 0
            }
        })
        hl.dsp.exec_cmd("notify-send -a 'Game Mode' -i 'dialog-information' -u low 'Game Mode' 'Performance Mode Enabled (Effects, Gaps & Borders Reduced)'")
    else
        hl.config({
            animations = { enabled = true },
            general = {
                gaps_in = 5,
                gaps_out = 10,
                border_size = 2
            },
            decoration = {
                shadow = { enabled = true },
                blur = { enabled = true },
                rounding = 10
            }
        })
        hl.dsp.exec_cmd("notify-send -a 'Game Mode' -i 'dialog-information' -u low 'Game Mode' 'Aesthetic Mode Restored'")
    end
end

hl.bind(mainMod .. " + G", toggle_gamemode)
hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd("~/.config/hypr/scripts/glyph-picker.sh"))
hl.bind(mainMod .. " + period", hl.dsp.exec_cmd("~/.config/hypr/scripts/emoji-picker.sh"))
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd("python3 ~/.config/hypr/scripts/keybindings-hint.py"))

-- Screencapture
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("~/.config/hypr/scripts/poc/screenshot.sh s"))
hl.bind(mainMod .. " + CTRL + P", hl.dsp.exec_cmd("~/.config/hypr/scripts/poc/screenshot.sh sf"))
hl.bind(mainMod .. " + ALT + P", hl.dsp.exec_cmd("~/.config/hypr/scripts/poc/screenshot.sh w"))
hl.bind("Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/poc/screenshot.sh p"))
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("~/.config/hypr/scripts/poc/screenshot.sh sc"))
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("~/.config/hypr/scripts/poc/screenshot.sh sq"))
hl.bind(mainMod .. " + ALT + R", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenrecord.sh"))
hl.bind(mainMod .. " + ALT + SHIFT + R", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenrecord.sh --fullscreen"))

-- Zoom
hl.bind(mainMod .. " + ALT + mouse_down", hl.dsp.exec_cmd("hyprctl keyword cursor:zoom_factor \"$(hyprctl getoption cursor:zoom_factor | awk 'NR==1 {factor = $2; if (factor < 1) {factor = 1}; print factor * 2.0}')\""))
hl.bind(mainMod .. " + ALT + mouse_up", hl.dsp.exec_cmd("hyprctl keyword cursor:zoom_factor \"$(hyprctl getoption cursor:zoom_factor | awk 'NR==1 {factor = $2; if (factor < 1) {factor = 1}; print factor / 2.0}')\""))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- ── Hyprland Plugins ───────────────────────────────────────────
-- Hyprexpo  : workspace grid overview  (toggle with SUPER + grave)
hl.bind(mainMod .. " + grave", hl.dsp.exec_cmd("hyprctl dispatch hyprexpo:expo toggle"))
-- Hyprbars  : window title bars         (toggle with SUPER + B)
hl.bind(mainMod .. " + B",     hl.dsp.exec_cmd("hyprctl dispatch hyprbars:toggle"))
-- Hyprspace : GNOME-like overview       (toggle with SUPER + TAB)
hl.bind(mainMod .. " + Tab",   hl.dsp.exec_cmd("hyprctl dispatch hyprspace:overview toggle"))

-- ── Update Checker ─────────────────────────────────────────────
-- SUPER + U : open Rofi update picker
hl.bind(mainMod .. " + U", hl.dsp.exec_cmd("~/.config/hypr/scripts/update-checker.sh"))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("~/.config/hypr/scripts/volume.sh up"),       { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("~/.config/hypr/scripts/volume.sh down"),     { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("~/.config/hypr/scripts/volume.sh mute"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("~/.config/hypr/scripts/volume.sh mic-mute"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("~/.config/hypr/scripts/brightness.sh up"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("~/.config/hypr/scripts/brightness.sh down"), { locked = true, repeating = true })
hl.bind(mainMod .. " + SHIFT + F1", hl.dsp.exec_cmd("~/.config/hypr/scripts/brightness.sh min"), { locked = true })
hl.bind(mainMod .. " + SHIFT + F2", hl.dsp.exec_cmd("~/.config/hypr/scripts/brightness.sh max"), { locked = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("~/.config/hypr/scripts/media.sh next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("~/.config/hypr/scripts/media.sh play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("~/.config/hypr/scripts/media.sh play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("~/.config/hypr/scripts/media.sh previous"),   { locked = true })
