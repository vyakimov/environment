#!/bin/bash
set -euo pipefail

# ── Version pins (single source of truth) ──
TMUX_VERSION=3.6a
NODE_VERSION=25.2.1
NVIM_VERSION=0.11.5
CODEX_ACP_VERSION=0.9.2

export DEBIAN_FRONTEND=noninteractive

# ── Locale ──
apt-get update
apt-get install -y locales curl nvtop
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8

# ── R repository ──
curl -fsSL https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc |
  tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc >/dev/null
echo "deb https://cloud.r-project.org/bin/linux/ubuntu noble-cran40/" \
  > /etc/apt/sources.list.d/cran.list

# ── APT packages ──
apt-get update
apt-get install -y \
  r-base git fzf ripgrep build-essential fd-find \
  software-properties-common zsh wget unzip luarocks
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -f /etc/apt/sources.list.d/cran.list

# ── tmux ──
curl -sSL "https://github.com/tmux/tmux-builds/releases/download/v${TMUX_VERSION}/tmux-${TMUX_VERSION}-linux-x86_64.tar.gz" |
  tar xz -C /usr/local/bin

# ── Node.js ──
curl -LO "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz"
tar xf "node-v${NODE_VERSION}-linux-x64.tar.gz" -C /opt/
ln -sf /opt/node-v${NODE_VERSION}-linux-x64/bin/* /usr/local/bin/
npm config set prefix /usr/local/
npm install -g \
  mcp-hub \
  @openai/codex \
  @github/copilot-language-server \
  @zed-industries/claude-code-acp
rm "node-v${NODE_VERSION}-linux-x64.tar.gz"

# ── lazygit ──
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" |
  grep -Po '"tag_name": *"v\K[^"]*')
curl -Lo /tmp/lazygit.tar.gz \
  "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
install /tmp/lazygit /usr/local/bin/
rm /tmp/lazygit.tar.gz /tmp/lazygit

# ── codex-acp ──
curl -sSL "https://github.com/zed-industries/codex-acp/releases/download/v${CODEX_ACP_VERSION}/codex-acp-${CODEX_ACP_VERSION}-x86_64-unknown-linux-gnu.tar.gz" |
  tar -xz -C /usr/local/bin

# ── Neovim ──
curl -LO "https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim-linux-x86_64.tar.gz"
tar xzf nvim-linux-x86_64.tar.gz -C /opt
ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
rm nvim-linux-x86_64.tar.gz

echo "System setup complete."
