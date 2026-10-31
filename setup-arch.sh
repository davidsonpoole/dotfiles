#!/usr/bin/env bash
#
# Arch Linux (KDE Plasma, Wayland) desktop setup for a T2 MacBook. Makes the
# machine feel like macOS and installs the desktop apps. Configs live in arch/.
#
#   - keyd: Cmd acts as Ctrl (Cmd+C/V/T/W/Q/Tab...), Option word navigation,
#     Caps Lock <-> Left Ctrl swap
#   - keyd-application-mapper: iTerm-style Cmd shortcuts in Konsole
#   - Touchpad: tap-to-click off
#   - yay (AUR helper), ungoogled-chromium, Konsole, OpenSSH
#   - setup-linux.sh: CLI tools and dotfiles
#
# Safe to re-run.

set -euo pipefail

cd "$(dirname "$0")"

if ! command -v pacman >/dev/null 2>&1; then
  echo "This script is for Arch Linux (pacman not found)" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Link files
# Same as setup-linux.sh: existing real files/directories are moved aside
# rather than deleted.
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
link() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    mkdir -p "$BACKUP_DIR"
    echo "Backing up $dest to $BACKUP_DIR/"
    mv "$dest" "$BACKUP_DIR/"
  fi
  ln -sfn "$src" "$dest"
}

# Packages
# python-dbus: needed by keyd-application-mapper on KDE
# ksshaskpass: lets ssh-add store key passphrases in KWallet

echo "Installing packages with pacman"
sudo pacman -S --needed --noconfirm \
  base-devel git \
  keyd python-dbus \
  konsole \
  openssh ksshaskpass

# makepkg: don't split out (usually empty) -debug packages for AUR builds.
# Linked before building yay so it applies to that build too.
link "$PWD/arch/pacman/makepkg.conf" "$HOME/.config/pacman/makepkg.conf"

# yay (AUR helper), bootstrapped from the AUR by hand

if ! command -v yay >/dev/null 2>&1; then
  echo "Installing yay"
  git clone https://aur.archlinux.org/yay-bin.git "$TMP/yay-bin"
  (cd "$TMP/yay-bin" && makepkg -si --noconfirm)
fi

echo "Installing AUR packages with yay"
yay -S --needed --noconfirm ungoogled-chromium-bin

# keyd (Mac-style keybindings)
# keyd runs as root and reads /etc/keyd, so the config is copied rather
# than linked into $HOME. Re-run this script after editing it.

if ! cmp -s arch/keyd/default.conf /etc/keyd/default.conf; then
  echo "Installing /etc/keyd/default.conf"
  sudo install -Dm644 arch/keyd/default.conf /etc/keyd/default.conf
  if systemctl is-active --quiet keyd; then
    sudo keyd reload
  fi
fi
sudo systemctl enable --now keyd

# Per-app bindings (Cmd+C/V/T/W... in Konsole). The mapper talks to keyd's
# socket, which requires the keyd group, and is started at login.
link "$PWD/arch/keyd/app.conf" "$HOME/.config/keyd/app.conf"
link "$PWD/arch/autostart/keyd-application-mapper.desktop" \
  "$HOME/.config/autostart/keyd-application-mapper.desktop"

NEEDS_REBOOT=false
if ! id -nG "$USER" | grep -qw keyd; then
  echo "Adding $USER to the keyd group"
  sudo usermod -aG keyd "$USER"
  NEEDS_REBOOT=true
fi

# Touchpad: disable tap-to-click
# Written for every touchpad KWin knows about, keyed by vendor/product/name
# like System Settings does, and also applied to the running session.

# Print an InputDevice property's value without busctl's type prefix
input_prop() {
  busctl --user get-property org.kde.KWin "$1" org.kde.KWin.InputDevice "$2" | cut -d' ' -f2-
}

if busctl --user status org.kde.KWin >/dev/null 2>&1; then
  for dev in $(busctl --user tree org.kde.KWin --list | grep -E '/org/kde/KWin/InputDevice/event[0-9]+$'); do
    [ "$(input_prop "$dev" touchpad)" = true ] || continue
    name="$(input_prop "$dev" name | sed 's/^"//; s/"$//')"
    echo "Disabling tap-to-click for $name"
    kwriteconfig6 --file kcminputrc --group Libinput --group "$(input_prop "$dev" vendor)" \
      --group "$(input_prop "$dev" product)" --group "$name" --key TapToClick false
    busctl --user set-property org.kde.KWin "$dev" org.kde.KWin.InputDevice tapToClick b false
  done
else
  echo "Note: not in a Plasma session; skipping touchpad setup (re-run from Plasma)"
fi

# CLI tools and dotfiles (shared with the other Linux machines)

./setup-linux.sh

if [ "$NEEDS_REBOOT" = true ]; then
  echo "Done. Reboot so the keyd group applies (Cmd shortcuts in Konsole)."
else
  echo "Done."
fi
