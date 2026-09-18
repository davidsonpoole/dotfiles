#!/usr/bin/env bash

set -euo pipefail

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
