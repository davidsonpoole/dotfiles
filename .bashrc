#!/bin/bash

if [ -d ~/.bashrc.dir ]; then
    for f in $(ls ~/.bashrc.dir/.bashrc-*); do
        source $f
    done
fi

[ -f /etc/bashrc ] && . /etc/bashrc

# Enable the subsequent settings only in interactive sessions
case $- in
  *i*) ;;
    *) return;;
esac

# FZF
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# Suppress that annoying reminder to update to zsh
export BASH_SILENCE_DEPRECATION_WARNING=1

export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_R_OPTS="${FZF_CTRL_R_OPTS:+$FZF_CTRL_R_OPTS }--preview 'echo {}' --preview-window down:5:hidden:wrap --bind '?:toggle-preview'"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
#
# PATH stuff
export PATH="$HOME/git/vcpkg:$HOME/pspdev/bin:$HOME/.local/bin:$PATH"
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
