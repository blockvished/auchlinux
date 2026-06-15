# Add user configurations here
# For Zsh to load your beloved configurations,
# we loaded a config file for you to customize shell settings before loading zshrc
# Edit $ZDOTDIR/user.zsh to customize settings before loading zshrc

#  Plugins 
# oh-my-zsh plugins are loaded  in $ZDOTDIR/.user.zsh file, see the file for more information

#  Aliases 
# Override aliases here in '$ZDOTDIR/.zshrc' (already set in .zshenv)
alias resetportal="~/.config/hypr/scripts/reset-portal.sh"
alias secscan="~/.config/hypr/scripts/malware_scanner.sh"

#  Autosuggestions — make suggestions visible (default fg=8 is invisible on dark backgrounds)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#888888,underline"

#  Theme Switcher CLI — switch Zsh theme from the terminal
# Usage: zsh-theme         (helper menu / show available themes)
#        zsh-theme cycle   (cycle to next theme)
#        zsh-theme <name>  (switch to specific theme)
#        zsh-theme status  (show current theme)
zsh-theme() {
    local mode_file="$HOME/.config/zsh/zsh_theme_mode"
    local starship_dir="$HOME/.config/starship"
    local cycle=("lol" "newpr" "onmeds" "end4")
    local labels=(
        "lol    → Starship Pokemon + Pokemon art"
        "newpr  → Starship Minimal + fastfetch"
        "onmeds → Starship Powerline + fastfetch"
        "end4   → Starship End4 + fastfetch (End4 Black layout)"
    )

    local current
    current=$(cat "$mode_file" 2>/dev/null || echo "lol")

    # If no arguments provided, show helper menu
    if [[ -z "$1" ]]; then
        echo "🎨 Zsh Theme Switcher Help"
        echo "--------------------------"
        echo "Current active theme: $current"
        echo ""
        echo "Available themes:"
        for lbl in "${labels[@]}"; do
            if [[ "$lbl" == "$current"* ]]; then
                echo "  * $lbl (active)"
            else
                echo "    $lbl"
            fi
        done
        echo ""
        echo "Usage:"
        echo "  zsh-theme <name>  ➔  Switch to specific theme (e.g. zsh-theme lol)"
        echo "  zsh-theme cycle   ➔  Cycle to the next theme"
        echo "  zsh-theme status  ➔  Show the current active theme"
        return 0
    fi

    # Show status
    if [[ "$1" == "status" ]]; then
        echo "Current theme: $current"
        return
    fi

    local new_mode
    if [[ "$1" == "cycle" ]]; then
        # Cycle to next
        local idx=1
        for i in {1..$#cycle}; do
            [[ "${cycle[$i]}" == "$current" ]] && idx=$i
        done
        local next_idx=$(( (idx % $#cycle) + 1 ))
        new_mode="${cycle[$next_idx]}"
    else
        # Switch to specific theme
        if [[ "$1" == "lol" || "$1" == "newpr" || "$1" == "onmeds" || "$1" == "end4" ]]; then
            new_mode="$1"
        else
            echo "Unknown theme '$1'. Available: lol, newpr, onmeds, end4"
            return 1
        fi
    fi

    echo "$new_mode" > "$mode_file"

    # Update starship config symlink
    ln -sf "$starship_dir/starship_${new_mode}.toml" "$starship_dir/starship.toml" 2>/dev/null

    # Update fastfetch config symlink
    local ff_dir="$HOME/.config/fastfetch"
    [[ -d "$ff_dir" ]] && ln -sf "$ff_dir/config_${new_mode}.jsonc" "$ff_dir/config.jsonc" 2>/dev/null || true

    # Update kitty theme if config exists
    local kitty_src="$HOME/.config/kitty/kitty_${new_mode}.conf"
    local kitty_dst="$HOME/.config/kitty/kitty_theme.conf"
    [[ -f "$kitty_src" ]] && cp "$kitty_src" "$kitty_dst" && pkill -USR1 kitty 2>/dev/null || true

    echo "✓ Switched to: $new_mode"
    echo "  Open a new terminal to apply the theme."
    echo ""
    echo "  Themes:"
    for lbl in "${labels[@]}"; do echo "    $lbl"; done
}

#  Rofi Theme Switcher CLI — switch Rofi launcher design from the terminal
# Usage: rofi-theme         (helper menu / show available layouts)
#        rofi-theme cycle   (cycle to next layout)
#        rofi-theme <name>  (switch to specific layout)
#        rofi-theme status  (show current layout)
rofi-theme() {
    local mode_file="$HOME/.config/rofi/launcher/rofi_theme_mode"
    local rofi_launcher_dir="$HOME/.config/rofi/launcher"
    
    # Dynamically scan for style_*.rasi files to build available themes list
    local available_styles=()
    for file in "$rofi_launcher_dir"/style_*.rasi; do
        if [[ -f "$file" ]]; then
            # Extract theme name: style_name.rasi -> name
            local name=$(basename "$file" | sed -E 's/^style_(.*)\.rasi$/\1/')
            available_styles+=("$name")
        fi
    done

    # Sort and group the styles logically
    local auch_style=()
    local lol_style=()
    local lol_numeric=()
    local lol_other=()
    local end4_style=()
    local newpr_style=()
    local onmeds_style=()
    local end4_type_2=()
    local end4_type_3=()
    local end4_type_4=()
    local end4_type_others=()

    for theme in "${available_styles[@]}"; do
        if [[ "$theme" == "auch" ]]; then
            auch_style+=("auch")
        elif [[ "$theme" == "lol" ]]; then
            lol_style+=("lol")
        elif [[ "$theme" == "end4" ]]; then
            end4_style+=("end4")
        elif [[ "$theme" == "newpr" ]]; then
            newpr_style+=("newpr")
        elif [[ "$theme" == "onmeds" ]]; then
            onmeds_style+=("onmeds")
        elif [[ "$theme" =~ '^pre_lol_[0-9]+$' ]]; then
            lol_numeric+=("$theme")
        elif [[ "$theme" == pre_lol_* ]]; then
            lol_other+=("$theme")
        elif [[ "$theme" =~ '^pre_end4_type-2_style-[0-9]+$' ]]; then
            end4_type_2+=("$theme")
        elif [[ "$theme" =~ '^pre_end4_type-3_style-[0-9]+$' ]]; then
            end4_type_3+=("$theme")
        elif [[ "$theme" =~ '^pre_end4_type-4_style-[0-9]+$' ]]; then
            end4_type_4+=("$theme")
        elif [[ "$theme" =~ '^pre_end4_type-[0-9]+_style-[0-9]+$' ]]; then
            end4_type_others+=("$theme")
        fi
    done

    # Natural sorting
    lol_numeric=($(printf '%s\n' "${lol_numeric[@]}" | sort -V))
    lol_other=($(printf '%s\n' "${lol_other[@]}" | sort))
    end4_type_2=($(printf '%s\n' "${end4_type_2[@]}" | sort -V))
    end4_type_3=($(printf '%s\n' "${end4_type_3[@]}" | sort -V))
    end4_type_4=($(printf '%s\n' "${end4_type_4[@]}" | sort -V))
    end4_type_others=($(printf '%s\n' "${end4_type_others[@]}" | sort -V))

    # Combine in sorted order
    local sorted_styles=()
    sorted_styles+=("${auch_style[@]}")       # index 0
    sorted_styles+=("${lol_style[@]}")        # index 1
    sorted_styles+=("${lol_numeric[@]}")      # index 2 to 8
    sorted_styles+=("${lol_other[@]}")        # index 9 to 12
    sorted_styles+=("${onmeds_style[@]}")     # index 13 (Type 2)
    sorted_styles+=("${end4_style[@]}")       # index 14 (Type 3)
    sorted_styles+=("${newpr_style[@]}")      # index 15 (Type 4)
    sorted_styles+=("${end4_type_2[@]}")      # index 16+ (Type 2 first)
    sorted_styles+=("${end4_type_3[@]}")      # (Type 3 second)
    sorted_styles+=("${end4_type_4[@]}")      # (Type 4 third)
    sorted_styles+=("${end4_type_others[@]}") # (Rest of them last)

    local current
    current=$(cat "$mode_file" 2>/dev/null || echo "lol")

    # If no arguments provided, show helper menu
    if [[ -z "$1" ]]; then
        echo "🎨 Rofi Launcher Theme Switcher"
        echo "------------------------------"
        echo "Current active layout: $current"
        echo ""
        echo "Available layouts:"
        for i in {1..$#sorted_styles}; do
            local theme="${sorted_styles[$i]}"
            local desc=""
            case "$theme" in
                "lol") desc=" (Active Default - lol's Style 1)" ;;
                "auch") desc=" (Classic - Original theme without icons)" ;;
                "newpr") desc=" (Minimalist Centered Grid)" ;;
                "onmeds") desc=" (Capsule-Pill Layout)" ;;
                "end4") desc=" (Sleek Left Sidebar Dock)" ;;
                "pre_lol_custom") desc=" (Cyberpunk Glassmorphism)" ;;
                "pre_lol_steam_deck") desc=" (lol's Steam Deck style)" ;;
                "pre_lol_clipboard") desc=" (lol's clipboard theme)" ;;
            esac
            local display_index=$((i - 1))
            local num_str=$(printf "%3d. " $display_index)
            if [[ "$theme" == "$current" ]]; then
                echo "  * $num_str$theme$desc (active)"
            else
                echo "    $num_str$theme$desc"
            fi
        done
        echo ""
        echo "Usage:"
        echo "  rofi-theme <number>  ➔  Switch by index (e.g. rofi-theme 0)"
        echo "  rofi-theme <name>    ➔  Switch to specific layout (e.g. rofi-theme newpr)"
        echo "  rofi-theme cycle     ➔  Cycle to the next layout"
        echo "  rofi-theme status    ➔  Show the current active layout"
        return 0
    fi

    # Show status
    if [[ "$1" == "status" ]]; then
        echo "Current layout: $current"
        return
    fi

    local new_mode
    if [[ "$1" == "cycle" ]]; then
        # Cycle to next in sorted_styles
        local idx=-1
        for i in {1..$#sorted_styles}; do
            if [[ "${sorted_styles[$i]}" == "$current" ]]; then
                idx=$i
                break
            fi
        done
        if [[ $idx -eq -1 ]]; then
            new_mode="lol"
        else
            local next_idx=$(( (idx % $#sorted_styles) + 1 ))
            new_mode="${sorted_styles[$next_idx]}"
        fi
    else
        # Resolve requested theme / shortcut / alias
        local input="$1"
        local target=""
        
        # 1. Direct index check (e.g. 0 -> lol, 12 -> lol_clipboard)
        if [[ "$input" =~ '^[0-9]+$' ]]; then
            local val=$((input))
            local array_idx=$((val + 1))
            if [[ $array_idx -ge 1 && $array_idx -le $#sorted_styles ]]; then
                target="${sorted_styles[$array_idx]}"
            fi
        fi

        # 2. Direct exact match (e.g. rofi-theme lol)
        if [[ -z "$target" ]]; then
            for theme in "${sorted_styles[@]}"; do
                if [[ "$theme" == "$input" ]]; then
                    target="$theme"
                    break
                fi
            done
        fi

        # 3. Shorthand matches if not found directly
        if [[ -z "$target" ]]; then
            if [[ "$input" =~ '^([0-9]+)[_-]([0-9]+)$' ]]; then
                # e.g. 2_10 or 2-10 -> pre_end4_type-2_style-10
                local t="${match[1]}"
                local s="${match[2]}"
                target="pre_end4_type-${t}_style-${s}"
            elif [[ "$input" =~ '^t([0-9]+)s([0-9]+)$' ]]; then
                # e.g. t2s10 -> pre_end4_type-2_style-10
                local t="${match[1]}"
                local s="${match[2]}"
                target="pre_end4_type-${t}_style-${s}"
            else
                # Suffix matching for lol styles (e.g. custom -> pre_lol_custom, lol_3 -> pre_lol_3)
                for theme in "${sorted_styles[@]}"; do
                    if [[ "$theme" == "pre_lol_$input" ]]; then
                        target="pre_lol_$input"
                        break
                    elif [[ "$input" == lol_* && "$theme" == "pre_$input" ]]; then
                        target="pre_$input"
                        break
                    fi
                done
            fi
        fi

        # 4. Substring fallback match (if target is still empty)
        if [[ -z "$target" ]]; then
            local matches=()
            for theme in "${sorted_styles[@]}"; do
                if [[ "$theme" == *"$input"* ]]; then
                    matches+=("$theme")
                fi
            done
            if [[ ${#matches[@]} -eq 1 ]]; then
                target="${matches[1]}"
            elif [[ ${#matches[@]} -gt 1 ]]; then
                echo "Ambiguous match '$input'. Multiple layouts matched:"
                for m in "${matches[@]}"; do
                    echo "  - $m"
                done
                return 1
            fi
        fi

        # 5. Verify target exists in sorted_styles
        if [[ -n "$target" ]]; then
            local found=0
            for theme in "${sorted_styles[@]}"; do
                if [[ "$theme" == "$target" ]]; then
                    found=1
                    break
                fi
            done
            if [[ $found -eq 1 ]]; then
                new_mode="$target"
            fi
        fi

        if [[ -z "$new_mode" ]]; then
            echo "Unknown layout/index '$1'. Available layouts:"
            echo "  ${sorted_styles[*]}"
            return 1
        fi
    fi

    mkdir -p "$rofi_launcher_dir"
    echo "$new_mode" > "$mode_file"

    # Update style.rasi symlink
    ln -sf "$rofi_launcher_dir/style_${new_mode}.rasi" "$rofi_launcher_dir/style.rasi" 2>/dev/null

    # Trigger desktop notification if notify-send is available
    if command -v notify-send &>/dev/null; then
        notify-send -a "Rofi Theme" -i "preferences-desktop-theme" "Rofi Layout Switched" "Active theme: $new_mode"
    fi

    echo "✓ Switched Rofi layout to: $new_mode"
}

#  This is your file 
# Add your configurations here
export EDITOR=code

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
