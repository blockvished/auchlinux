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

-- Expose globally for convenience in other modules
_G.luascripts = M

return M
