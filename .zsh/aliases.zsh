alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias bye='shutdown now'           # Immediate Shutdown
alias reboot='systemctl reboot'    # Restart
alias zzz='systemctl suspend'      # Sleep / Suspend
alias espacio='ncdu'
alias archivos='pcmanfm'
alias config_hypr='nvim ~/.config/hypr/hyprland.conf'
alias ls='lsd'
alias cat='bat'
alias find='fd'
alias grep='rg'

# The "Smart TUI" Wrapper
tui_mode() {
    # 1. Strip all margins and padding
    kitty @ set-spacing margin=0 padding=0
    
    # 2. Run your app (btop, nvim, etc.)
    "$@"
    
    # 3. Restore your specific config values
    kitty @ set-spacing margin=12 padding=7
}

# Apply to all your favorite full-screen tools
alias nvim='tui_mode nvim'
alias btop='tui_mode btop'

fastfetch

lf() {
    cd "$(command lf -print-last-dir 2>/dev/null || echo .)"
}

