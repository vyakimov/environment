#!/bin/bash
set -e # Exit on error
# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting dotfiles setup...${NC}"

# Add .cfg.git to gitignore if not already present
if ! grep -q "^\.cfg\.git$" "$HOME/.gitignore" 2>/dev/null; then
  echo ".cfg.git" >>"$HOME/.gitignore"
  echo -e "${GREEN}✓ Added .cfg.git to .gitignore${NC}"
else
  echo -e "${YELLOW}→ .cfg.git already in .gitignore${NC}"
fi

# Clone bare repository
echo -e "${GREEN}Cloning dotfiles repository...${NC}"
if [ -d "$HOME/.cfg.git" ]; then
  echo -e "${YELLOW}→ .cfg.git already exists, removing...${NC}"
  rm -rf "$HOME/.cfg.git"
fi
git clone --bare https://github.com/vyakimov/dotfiles.git "$HOME/.cfg.git"
echo -e "${GREEN}✓ Dotfiles repository cloned${NC}"

# Create backup directory
mkdir -p "$HOME/.config-backup"
echo -e "${GREEN}✓ Created backup directory${NC}"

# Backup conflicting files
echo -e "${GREEN}Checking for conflicting files...${NC}"
CONFLICTS=$(git --git-dir="$HOME/.cfg.git/" --work-tree="$HOME" checkout 2>&1 | grep -E "^\s+" | awk '{print $1}' || true)

if [ -n "$CONFLICTS" ]; then
  echo -e "${YELLOW}Found conflicting files, backing up:${NC}"
  echo "$CONFLICTS" | while read -r file; do
    if [ -n "$file" ]; then
      # Create the parent directory in backup location
      mkdir -p "$HOME/.config-backup/$(dirname "$file")"
      # Move the conflicting file to backup
      if [ -e "$HOME/$file" ]; then
        mv "$HOME/$file" "$HOME/.config-backup/$file"
        echo -e "  ${YELLOW}→ Backed up: $file${NC}"
      fi
    fi
  done
  echo -e "${GREEN}✓ Conflicting files backed up${NC}"
else
  echo -e "${GREEN}✓ No conflicting files found${NC}"
fi

# Checkout dotfiles
echo -e "${GREEN}Checking out dotfiles...${NC}"
git --git-dir="$HOME/.cfg.git/" --work-tree="$HOME" checkout
git --git-dir="$HOME/.cfg.git/" --work-tree="$HOME" config --local status.showUntrackedFiles no
echo -e "${GREEN}✓ Dotfiles checked out${NC}"

# Install Oh My Zsh
echo -e "${GREEN}Installing Oh My Zsh...${NC}"
if [ -d "$HOME/.oh-my-zsh" ]; then
  echo -e "${YELLOW}→ Oh My Zsh already installed, skipping...${NC}"
else
  git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
  echo -e "${GREEN}✓ Oh My Zsh installed${NC}"
fi

# Install Powerlevel10k theme
echo -e "${GREEN}Installing Powerlevel10k theme...${NC}"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [ -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
  echo -e "${YELLOW}→ Powerlevel10k already installed, skipping...${NC}"
else
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
  echo -e "${GREEN}✓ Powerlevel10k installed${NC}"
fi

# Install zsh-vim-mode plugin
echo -e "${GREEN}Installing zsh-vim-mode plugin...${NC}"
if [ -d "$HOME/.oh-my-zsh/plugins/zsh-vim-mode" ]; then
  echo -e "${YELLOW}→ zsh-vim-mode already installed, skipping...${NC}"
else
  git clone https://github.com/softmoth/zsh-vim-mode.git "$HOME/.oh-my-zsh/plugins/zsh-vim-mode"
  echo -e "${GREEN}✓ zsh-vim-mode installed${NC}"
fi

# Install iTerm2 shell integration (skip on Linux)
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo -e "${GREEN}Installing iTerm2 shell integration...${NC}"
  if [ ! -f "$HOME/.iterm2_shell_integration.zsh" ]; then
    curl -L https://iterm2.com/shell_integration/zsh -o "$HOME/.iterm2_shell_integration.zsh"
    if ! grep -q "source ~/.iterm2_shell_integration.zsh" "$HOME/.zshrc" 2>/dev/null; then
      printf "\nsource ~/.iterm2_shell_integration.zsh\n" >>"$HOME/.zshrc"
      echo -e "${GREEN}✓ iTerm2 shell integration installed${NC}"
    fi
  else
    echo -e "${YELLOW}→ iTerm2 shell integration already installed${NC}"
  fi
else
  echo -e "${YELLOW}→ Skipping iTerm2 integration (Linux system detected)${NC}"
fi

# Configure tmux
echo -e "${GREEN}Configuring tmux...${NC}"
touch "$HOME/.tmux.conf"

# Check and add tmux configurations if not present
if ! grep -q "terminal-overrides.*xterm:Tc" "$HOME/.tmux.conf" 2>/dev/null; then
  echo "set-option -ga terminal-overrides ',xterm:Tc'" >>"$HOME/.tmux.conf"
  echo -e "${GREEN}✓ Added true color support to tmux${NC}"
else
  echo -e "${YELLOW}→ True color support already configured${NC}"
fi

if ! grep -q "set -g set-clipboard on" "$HOME/.tmux.conf" 2>/dev/null; then
  echo "set -g set-clipboard on # nvim osc52" >>"$HOME/.tmux.conf"
  echo -e "${GREEN}✓ Added clipboard support to tmux${NC}"
else
  echo -e "${YELLOW}→ Clipboard support already configured${NC}"
fi

if ! grep -q "set -g allow-passthrough on" "$HOME/.tmux.conf" 2>/dev/null; then
  echo "set -g allow-passthrough on # nvim osc52" >>"$HOME/.tmux.conf"
  echo -e "${GREEN}✓ Added passthrough support to tmux${NC}"
else
  echo -e "${YELLOW}→ Passthrough support already configured${NC}"
fi

echo -e "${GREEN}✅ Dotfiles setup complete!${NC}"
echo -e "${YELLOW}Note: Backed up files can be found in ~/.config-backup/${NC}"
