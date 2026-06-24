-- ----------------------------------------------------
-- Hyprland Lua Scripts & Custom Functions
-- ----------------------------------------------------

local M = {}

-- Toggle Game Mode (Performance vs. Aesthetic Mode)
function M.toggle_gamemode()
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

-- Active Window Audio Muter (Native Lua implementation)
function M.mute_active_window()
    -- Get active window details
    local handle = io.popen("hyprctl activewindow -j")
    if not handle then return end
    local active_json = handle:read("*a")
    handle:close()
    
    -- Extract values using helper jq commands (safe for spaces and special characters)
    local function jq_extract(json, filter)
        local h = io.popen("echo '" .. json:gsub("'", "'\\''") .. "' | jq -r '" .. filter .. "'")
        if not h then return "" end
        local val = h:read("*l")
        h:close()
        return val or ""
    end

    local active_pid = jq_extract(active_json, ".pid")
    local active_title = jq_extract(active_json, ".title")
    local active_class = jq_extract(active_json, ".class"):lower()

    if active_pid == "null" or active_pid == "" then
        hl.dsp.exec_cmd("notify-send -a 'Mute Window' -u low 'Mute Window' 'No active window found'")
        return
    end

    -- Get all PIDs in the tree of active window
    local tree_handle = io.popen("(echo '" .. active_pid .. "'; pstree -p '" .. active_pid .. "' | grep -o '[0-9]\\+') | sort -u")
    if not tree_handle then return end
    local tree_pids_str = tree_handle:read("*a")
    tree_handle:close()
    
    local tree_pids = {}
    for pid in tree_pids_str:gmatch("%d+") do
        tree_pids[pid] = true
    end

    -- Read and parse sink inputs using tab delimiter
    local awk_cmd = [[pactl list sink-inputs | awk '
BEGIN { id = ""; pid = ""; app_name = ""; media_name = "" }
/^Sink Input #/ {
    if (id != "") { print id "\t" pid "\t" app_name "\t" media_name }
    id = substr($3, 2); pid = ""; app_name = ""; media_name = ""
}
/application.process.id =/ {
    val = $0; sub(/^.*application.process.id = "/, "", val); sub(/"$/, "", val); pid = val
}
/application.name =/ {
    val = $0; sub(/^.*application.name = "/, "", val); sub(/"$/, "", val); app_name = tolower(val)
}
/media.name =/ {
    val = $0; sub(/^.*media.name = "/, "", val); sub(/"$/, "", val); media_name = val
}
END {
    if (id != "") { print id "\t" pid "\t" app_name "\t" media_name }
}']]

    local inputs_handle = io.popen(awk_cmd)
    if not inputs_handle then return end
    
    local candidates = {}
    for line in inputs_handle:lines() do
        local id, pid, app_name, media_name = line:match("([^\t]+)\t([^\t]*)\t([^\t]*)\t([^\n]*)")
        if id then
            local match_found = false
            if tree_pids[pid] then
                match_found = true
            elseif active_class ~= "" and active_class ~= "null" and app_name ~= "" then
                if app_name == active_class or active_class:find(app_name, 1, true) or app_name:find(active_class, 1, true) then
                    match_found = true
                end
            end
            
            if match_found then
                table.insert(candidates, { id = id, media_name = media_name })
            end
        end
    end
    inputs_handle:close()

    if #candidates == 0 then
        hl.dsp.exec_cmd("notify-send -a 'Mute Window' -u low -i 'audio-volume-muted' 'Mute Window' 'No audio stream found for the active window'")
        return
    end

    -- Narrow down by media name matching window title
    local matched_ids = {}
    if active_title ~= "" and active_title ~= "null" then
        local lc_title = active_title:lower()
        for _, cand in ipairs(candidates) do
            if cand.media_name ~= "" then
                local lc_media = cand.media_name:lower()
                if lc_title:find(lc_media, 1, true) or lc_media:find(lc_title, 1, true) then
                    table.insert(matched_ids, cand.id)
                end
            end
        end
    end

    local final_ids = matched_ids
    if #final_ids == 0 then
        -- Fallback: use all app candidates
        final_ids = {}
        for _, cand in ipairs(candidates) do
            table.insert(final_ids, cand.id)
        end
    end

    -- Toggle mute
    local muted_count = 0
    local unmuted_count = 0
    
    for _, id in ipairs(final_ids) do
        local status_handle = io.popen("pactl list sink-inputs | awk -v target_id='" .. id .. "' '/^Sink Input #/ { id = substr($3, 2) } /Mute:/ { if (id == target_id) { print $2; exit } }'")
        if status_handle then
            local current_mute = status_handle:read("*l")
            status_handle:close()
            
            if current_mute == "yes" then
                os.execute("pactl set-sink-input-mute '" .. id .. "' no")
                unmuted_count = unmuted_count + 1
            else
                os.execute("pactl set-sink-input-mute '" .. id .. "' yes")
                muted_count = muted_count + 1
            end
        end
    end

    -- Desktop notification
    local display_title = (active_title ~= "" and active_title ~= "null") and active_title:sub(1, 30) or "Active Window"
    if muted_count > 0 then
        hl.dsp.exec_cmd("notify-send -a 'Mute Window' -u low -i 'audio-volume-muted' 'Muted window audio' '" .. display_title:gsub("'", "'\\''") .. "'")
    elseif unmuted_count > 0 then
        hl.dsp.exec_cmd("notify-send -a 'Mute Window' -u low -i 'audio-volume-high' 'Unmuted window audio' '" .. display_title:gsub("'", "'\\''") .. "'")
    end
end

-- Toggle Zsh Theme Mode (cycles dynamically using Lua script)
function M.toggle_zsh_theme()
    local home = os.getenv("HOME") or "/home/newpr"
    os.execute("lua " .. home .. "/.config/hypr/hyprland/luascript/zsh-theme.lua cycle &>/dev/null &")
end

-- Toggle Rofi Theme Mode (cycles dynamically using Lua script)
-- NOTE: The trailing & backgrounds the process so os.execute() returns
-- immediately without blocking the Hyprland compositor.
function M.toggle_rofi_theme()
    local home = os.getenv("HOME") or "/home/newpr"
    os.execute("lua " .. home .. "/.config/hypr/hyprland/luascript/rofi-theme.lua cycle &>/dev/null &")
end

-- Expose globally for convenience in other modules
_G.luafunctions = M

return M
