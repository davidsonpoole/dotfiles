#!/usr/bin/env bash
#
# Headless Linux counterpart to setup.sh. Installs the CLI subset of the
# Brewfile (no fonts, casks or VS Code) and links the dotfiles.
#
# Supports dnf (Amazon Linux / Fedora / RHEL) and apt (Debian / Ubuntu).
# Tools that are missing or too old in those repos (neovim, ripgrep, fd,
# tree-sitter, tmux) are installed into ~/.local instead.

set -euo pipefail

cd "$(dirname "$0")"

# Pinned versions for tools installed outside the package manager
NVIM_VERSION="v0.12.5"
RIPGREP_VERSION="15.2.0"
FD_VERSION="v10.5.0"
TREE_SITTER_VERSION="v0.27.0"
TMUX_VERSION="3.8"
TMUX_MIN_VERSION="3.3" # .tmux.conf uses allow-passthrough (added in 3.3)
NVM_VERSION="v0.40.3"

LOCAL="$HOME/.local"
mkdir -p "$LOCAL/bin" "$LOCAL/opt"
export PATH="$LOCAL/bin:$PATH"

case "$(uname -m)" in
  x86_64) ARCH=x86_64 ;;
  aarch64 | arm64) ARCH=aarch64 ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

# Package manager

if command -v dnf >/dev/null 2>&1; then
  echo "Installing packages with dnf"
  # Amazon Linux ships curl-minimal, which conflicts with the curl package
  command -v curl >/dev/null 2>&1 || sudo dnf install -y curl
  sudo dnf install -y \
    git wget tar gzip unzip which procps-ng \
    gcc gcc-c++ make cmake ninja-build gdb \
    autoconf automake libtool bison flex pkgconf \
    openssl-devel zlib-devel libevent-devel ncurses-devel \
    python3 python3-pip
elif command -v apt-get >/dev/null 2>&1; then
  echo "Installing packages with apt"
  sudo apt-get update
  sudo apt-get install -y \
    git curl wget tar gzip unzip procps \
    gcc g++ make cmake ninja-build gdb \
    autoconf automake libtool bison flex pkgconf \
    libssl-dev zlib1g-dev libevent-dev libncurses-dev \
    python3 python3-pip
else
  echo "No supported package manager found (need dnf or apt-get)" >&2
  exit 1
fi

# Helpers

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Download a URL into $TMP and print the resulting path
fetch() {
  local url="$1" out="$TMP/$(basename "$1")"
  curl -fsSL "$url" -o "$out"
  echo "$out"
}

# Succeeds if version $1 >= version $2
version_ge() {
  [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -1)" = "$2" ]
}

# Neovim (distro packages are missing or too old for nvim-treesitter's main branch)

if [ "$(nvim --version 2>/dev/null | head -1)" != "NVIM $NVIM_VERSION" ]; then
  echo "Installing neovim $NVIM_VERSION"
  nvim_arch=$([ "$ARCH" = x86_64 ] && echo x86_64 || echo arm64)
  tarball="$(fetch "https://github.com/neovim/neovim/releases/download/$NVIM_VERSION/nvim-linux-$nvim_arch.tar.gz")"
  rm -rf "$LOCAL/opt/nvim"
  mkdir -p "$LOCAL/opt/nvim"
  tar -xzf "$tarball" -C "$LOCAL/opt/nvim" --strip-components=1
  ln -sfn "$LOCAL/opt/nvim/bin/nvim" "$LOCAL/bin/nvim"
fi

# ripgrep / fd (static musl builds)

if ! command -v rg >/dev/null 2>&1; then
  echo "Installing ripgrep $RIPGREP_VERSION"
  name="ripgrep-$RIPGREP_VERSION-$ARCH-unknown-linux-musl"
  tar -xzf "$(fetch "https://github.com/BurntSushi/ripgrep/releases/download/$RIPGREP_VERSION/$name.tar.gz")" -C "$TMP"
  install -m 755 "$TMP/$name/rg" "$LOCAL/bin/rg"
fi

if ! command -v fd >/dev/null 2>&1; then
  echo "Installing fd $FD_VERSION"
  name="fd-$FD_VERSION-$ARCH-unknown-linux-musl"
  tar -xzf "$(fetch "https://github.com/sharkdp/fd/releases/download/$FD_VERSION/$name.tar.gz")" -C "$TMP"
  install -m 755 "$TMP/$name/fd" "$LOCAL/bin/fd"
fi

# tree-sitter CLI (nvim-treesitter uses it to build parsers). The release
# binaries are linked against glibc 2.39, so on older distros (e.g. Amazon
# Linux 2023 has 2.34) it won't run; skip it there and live without the
# extra parsers rather than pulling in a whole Rust toolchain.

if ! tree-sitter --version >/dev/null 2>&1; then
  echo "Installing tree-sitter $TREE_SITTER_VERSION"
  ts_arch=$([ "$ARCH" = x86_64 ] && echo x64 || echo arm64)
  gz="$(fetch "https://github.com/tree-sitter/tree-sitter/releases/download/$TREE_SITTER_VERSION/tree-sitter-linux-$ts_arch.gz")"
  gunzip -c "$gz" > "$LOCAL/bin/tree-sitter"
  chmod 755 "$LOCAL/bin/tree-sitter"
  if ! tree-sitter --version >/dev/null 2>&1; then
    echo "Warning: tree-sitter $TREE_SITTER_VERSION needs a newer glibc than" \
      "$(ldd --version | head -1 | awk '{print $NF}'); skipping treesitter parsers"
    rm -f "$LOCAL/bin/tree-sitter"
  fi
fi

# tmux (built from source when the distro's is too old for .tmux.conf)

tmux_current="$(tmux -V 2>/dev/null | sed -En 's/^tmux ([0-9.]+).*/\1/p' || true)"
if [ -z "$tmux_current" ] || ! version_ge "$tmux_current" "$TMUX_MIN_VERSION"; then
  echo "Building tmux $TMUX_VERSION (found: ${tmux_current:-none})"
  tar -xzf "$(fetch "https://github.com/tmux/tmux/releases/download/$TMUX_VERSION/tmux-$TMUX_VERSION.tar.gz")" -C "$TMP"
  (
    cd "$TMP/tmux-$TMUX_VERSION"
    ./configure --prefix="$LOCAL" >/dev/null
    make -j"$(nproc)" >/dev/null
    make install >/dev/null
  )
fi

# fzf (--no-update-rc: .bashrc already sources ~/.fzf.bash)

if [ ! -d "$HOME/.fzf" ]; then
  echo "Cloning fzf into ~/.fzf"
  git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
fi
"$HOME/.fzf/install" --bin --key-bindings --completion --no-update-rc

# Node via nvm (needed by coc.nvim)

export NVM_DIR="$HOME/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  echo "Installing nvm $NVM_VERSION"
  PROFILE=/dev/null bash -c "$(curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh")"
fi
set +u
# shellcheck disable=SC1091
. "$NVM_DIR/nvm.sh"
if ! nvm ls --no-colors default >/dev/null 2>&1; then
  echo "Installing Node LTS"
  nvm install --lts
  nvm alias default 'lts/*'
fi
nvm use default >/dev/null
set -u

# Oh-my-bash (--unattended: don't switch shells; its ~/.bashrc gets replaced below)

if [ ! -d "$HOME/.oh-my-bash" ]; then
  echo "Installing oh-my-bash"
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" "" --unattended
fi

# Link files
# Unlike setup.sh, existing real files/directories are moved aside rather
# than deleted, since a fresh Linux box usually has a distro ~/.bashrc.
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
link() {
  local src="$1" dest="$2"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    mkdir -p "$BACKUP_DIR"
    echo "Backing up $dest to $BACKUP_DIR/"
    mv "$dest" "$BACKUP_DIR/"
  fi
  ln -sfn "$src" "$dest"
}

link "$PWD/.vimrc" "$HOME/.vimrc"
link "$PWD/.tmux.conf" "$HOME/.tmux.conf"
link "$PWD/.bashrc" "$HOME/.bashrc"
link "$PWD/.bashrc.dir" "$HOME/.bashrc.dir"
mkdir -p "$HOME/.config"
link "$PWD/nvim" "$HOME/.config/nvim"

# Neovim plugins, treesitter parsers and coc.nvim extensions

# nvim/autoload/plug.vim is a symlink into ~/.vim, shared with plain vim
if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
  echo "Installing vim-plug"
  curl -fsSLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

echo "Installing neovim plugins"
nvim --headless -c 'PlugInstall --sync' -c 'qa'

if command -v tree-sitter >/dev/null 2>&1; then
  echo "Installing treesitter parsers"
  nvim --headless \
    -c "lua require('nvim-treesitter').install({ 'c', 'cpp', 'java', 'python' }):wait(600000)" \
    -c 'qa'
fi

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

if ! command -v java >/dev/null 2>&1; then
  echo "Note: coc-java needs a JDK 21+ (e.g. java-21-amazon-corretto-devel or openjdk-21-jdk)."
fi

echo "Done. Start a new shell (exec bash -l) to pick up the new config."
