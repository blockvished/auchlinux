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

-- Toggle Zsh Theme Mode (Lol vs Newpr Setup)
function M.toggle_zsh_theme()
    local mode_file = os.getenv("HOME") .. "/.config/zsh/zsh_theme_mode"
    
    -- Read current mode
    local current_mode = "lol"
    local f = io.open(mode_file, "r")
    if f then
        current_mode = f:read("*l") or "lol"
        f:close()
    end
    
    -- Cycle through 4 modes: lol → newpr → onmeds → end4 → lol
    local cycle = { lol = "newpr", newpr = "onmeds", onmeds = "end4", end4 = "lol" }
    local labels = {
        lol    = "Lol (Pokemon / Classic)",
        newpr  = "Newpr (Fastfetch / Minimalist)",
        onmeds = "Onmeds (Powerline / Compact)",
        end4   = "End4 (End4 Black layout)",
    }
    local new_mode = cycle[current_mode] or "lol"
    local friendly_name = labels[new_mode] or new_mode
    local icon = "dialog-information"
    
    -- Write new mode
    f = io.open(mode_file, "w")
    if f then
        f:write(new_mode)
        f:close()
    end
    
    local home = os.getenv("HOME")

    -- Copy corresponding Kitty theme configuration (fallback to lol if not found)
    local kitty_src = home .. "/.config/kitty/kitty_" .. new_mode .. ".conf"
    local kitty_dst = home .. "/.config/kitty/kitty_theme.conf"
    local kitty_fallback = home .. "/.config/kitty/kitty_lol.conf"
    os.execute("cp '" .. kitty_src .. "' '" .. kitty_dst .. "' 2>/dev/null || cp '" .. kitty_fallback .. "' '" .. kitty_dst .. "'")
    
    -- Update the active starship config symlink
    local starship_src = home .. "/.config/starship/starship_" .. new_mode .. ".toml"
    local starship_dst = home .. "/.config/starship/starship.toml"
    os.execute("ln -sf '" .. starship_src .. "' '" .. starship_dst .. "' 2>/dev/null || true")

    -- Update the active fastfetch config symlink
    local fastfetch_src = home .. "/.config/fastfetch/config_" .. new_mode .. ".jsonc"
    local fastfetch_dst = home .. "/.config/fastfetch/config.jsonc"
    os.execute("ln -sf '" .. fastfetch_src .. "' '" .. fastfetch_dst .. "' 2>/dev/null || true")

    -- Reload all active Kitty windows on-the-fly
    os.execute("pkill -USR1 kitty || true")
    
    -- Trigger desktop notification
    hl.dsp.exec_cmd("notify-send -a 'Zsh Theme' -i '" .. icon .. "' 'Zsh Theme Toggle' 'Switched to " .. friendly_name .. "'")
end

-- Toggle Rofi Theme Mode (cycles dynamically using Zsh helper)
-- NOTE: The trailing & backgrounds the process so os.execute() returns
-- immediately without blocking the Hyprland compositor.
function M.toggle_rofi_theme()
    os.execute("zsh -c 'source ~/.config/zsh/.zshrc && rofi-theme cycle' &>/dev/null &")
end

-- Expose globally for convenience in other modules
_G.luafunctions = M

return M
