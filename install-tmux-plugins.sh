#!/usr/bin/env bash
# Installs TPM (Tmux Plugin Manager) and fetches the plugins listed in .tmux.conf.
# MesloLGS NF (needed for Catppuccin's status icons) is installed via `brew bundle` (Brewfile).
set -euo pipefail

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
