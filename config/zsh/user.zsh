#  Startup & Theme Toggle 

if [[ $- == *i* ]]; then
    # Default theme mode
    theme_mode="hyde"
    if [[ -f "$HOME/.config/zsh/zsh_theme_mode" ]]; then
        theme_mode=$(cat "$HOME/.config/zsh/zsh_theme_mode" | tr -d '[:space:]')
    fi
    
    if [[ "$theme_mode" == "end4" ]]; then
        # End4 Style: Minimalist prompt + fastfetch
        export STARSHIP_CONFIG="$HOME/.config/starship/starship_end4.toml"
        if command -v fastfetch >/dev/null; then
            fastfetch
        fi
    else
        # HyDE Style: Custom prompt + Pokemon graphics
        export STARSHIP_CONFIG="$HOME/.config/starship/starship_hyde.toml"
        if command -v pokego >/dev/null; then
            pokego --no-title -r 1,3,6
        elif command -v pokemon-colorscripts >/dev/null; then
            pokemon-colorscripts --no-title -r 1,3,6
        elif command -v fastfetch >/dev/null; then
            fastfetch --logo-type kitty
        fi
    fi
fi
