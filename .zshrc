# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
setopt autocd
bindkey -v
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/quimisagi/.zshrc'

autoload -Uz compinit
compinit
#
# End of lines added by compinstall

alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias bye='shutdown now'           # Immediate Shutdown
alias reboot='systemctl reboot'    # Restart
alias zzz='systemctl suspend'      # Sleep / Suspend

lf() {
    cd "$(command lf -print-last-dir 2>/dev/null || echo .)"
}
