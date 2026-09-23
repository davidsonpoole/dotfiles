#!/usr/bin/env bash

set -euo pipefail

# macOS ships an ancient bash 3.2 (frozen for GPLv3 licensing reasons) that
# lacks READLINE_POINT support in `bind -x`, which breaks fzf's Ctrl-T
# file widget (it always inserts at the start of the line). Install a
# modern bash via Homebrew and make it the login shell if needed.
if [[ "$OSTYPE" == darwin* ]] && ((BASH_VERSINFO[0] < 4)); then
  echo "Detected old bash (${BASH_VERSION}); installing modern bash via Homebrew"
  brew install bash

  BREW_BASH="$(brew --prefix bash)/bin/bash"

  if ! grep -qxF "$BREW_BASH" /etc/shells; then
    echo "Adding $BREW_BASH to /etc/shells (requires sudo)"
    echo "$BREW_BASH" | sudo tee -a /etc/shells >/dev/null
  fi

  if [ "$SHELL" != "$BREW_BASH" ]; then
    echo "Changing login shell to $BREW_BASH (may prompt for your password)"
    chsh -s "$BREW_BASH"
  fi

  echo "Login shell updated to $BREW_BASH. Note: some terminal apps (e.g. iTerm2)"
  echo "override the login shell with their own profile 'Command' setting - make"
  echo "sure that also points to $BREW_BASH (see iTermProfile.json)."
fi

# Oh-my-bash
echo "$OSH" || bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"

# Link files
# Use -n (no-dereference) so ln replaces an existing symlink-to-directory
# in place instead of following it and nesting the new link inside it.
# For real (non-symlink) directories left over from before, remove them
# first since -n alone won't stop ln from nesting inside a real directory.
link() {
  local src="$1" dest="$2"
  if [ -d "$dest" ] && [ ! -L "$dest" ]; then
    rm -rf "$dest"
  fi
  ln -sfn "$src" "$dest"
}

link "$PWD/.vimrc" "$HOME/.vimrc"
link "$PWD/.tmux.conf" "$HOME/.tmux.conf"
link "$PWD/.bashrc" "$HOME/.bashrc"
link "$PWD/.bashrc.dir" "$HOME/.bashrc.dir"
mkdir -p "$HOME/.config"
link "$PWD/nvim" "$HOME/.config/nvim"

# coc.nvim extensions
echo "Installing coc.nvim extensions"
nvim --headless -c 'CocInstall -sync coc-java' -c 'qa'

# Tmux Plugins

TPM_DIR="$HOME/.tmux/plugins/tpm"
CATPPUCCIN_DIR="$HOME/.config/tmux/plugins/catppuccin/tmux"

if [ -d "$TPM_DIR" ]; then
  echo "tpm already installed at $TPM_DIR"
else
  echo "Cloning tpm into $TPM_DIR"
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

echo "Installing tmux plugins"
"$TPM_DIR/bin/install_plugins"

# Catppuccin is loaded directly via `run` in .tmux.conf, not through tpm's
# @plugin mechanism, so it needs its own clone.
if [ -d "$CATPPUCCIN_DIR" ]; then
  echo "catppuccin/tmux already installed at $CATPPUCCIN_DIR"
else
  echo "Cloning catppuccin/tmux into $CATPPUCCIN_DIR"
  mkdir -p "$(dirname "$CATPPUCCIN_DIR")"
  git clone https://github.com/catppuccin/tmux.git "$CATPPUCCIN_DIR"
fi

echo "Done. Reload tmux config with: prefix + :source ~/.tmux.conf"
