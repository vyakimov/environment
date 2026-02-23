#!/bin/bash
set -euo pipefail

# ── Python (uv) ──
# If uv isn't on PATH yet (cloud-init case), install it
if ! command -v uv &>/dev/null; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
fi

curl -fsSL https://claude.ai/install.sh | bash

uv python install 3.12
uv venv --python 3.12

export VIRTUAL_ENV="$HOME/.venv"
export UV_CACHE_DIR="$HOME/.uv-cache"
export UV_PROJECT_ENVIRONMENT="$HOME/.venv"
export PATH="$VIRTUAL_ENV/bin:$HOME/.local/bin:$PATH"

# ── Python tools ──
uv tool install 'vectorcode[lsp,mcp]'
uv pip install --upgrade --no-cache-dir ipython pyright

# ── Neovim config ──
if [ ! -d "$HOME/.config/nvim" ]; then
  git clone https://github.com/vyakimov/neovim_setup.git ~/.config/nvim
fi
nvim --headless "+Lazy! sync" +qa || true

# ── Dotfiles (bootstrap.sh) ──
if [ -f "$HOME/bootstrap.sh" ]; then
  chmod +x "$HOME/bootstrap.sh"
  "$HOME/bootstrap.sh"
fi

# ── gitstatusd (powerlevel10k) ──
mkdir -p "$HOME/.cache/gitstatus"
curl -sSL -o "$HOME/.cache/gitstatus/gitstatusd-linux-x86_64" \
  https://github.com/zinox9/zsh-windows/raw/refs/heads/master/Resources/powerlevel10k/powerlevel10k/gitstatus/bin/gitstatusd-linux-x86_64-static
chmod +x "$HOME/.cache/gitstatus/gitstatusd-linux-x86_64"

# ── Terminfo ──
curl -sSL https://raw.githubusercontent.com/alacritty/alacritty/master/extra/alacritty.info |
  tic -x - 2>/dev/null || true
curl -sSL https://gist.githubusercontent.com/vyakimov/d17c01ab4ebab804e8393563980f557b/raw/9098c07250d144c71fd4bdb8873ec91673e68b14/ghostty.info |
  tic -x - 2>/dev/null || true

echo "User setup complete."
