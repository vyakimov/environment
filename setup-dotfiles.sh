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

echo -e "${GREEN}✅ Dotfiles setup complete!${NC}"
echo -e "${YELLOW}Note: Backed up files can be found in ~/.config-backup/${NC}"
