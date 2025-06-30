#!/bin/bash
echo ".cfg.git" >>$HOME/.gitignore
git clone --bare https://bitbucket.org/viyaki/cfg.git $HOME/.cfg.git
mkdir -p .config-backup
git --git-dir=$HOME/.cfg.git/ --work-tree=$HOME checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} .config-backup/{}
git --git-dir=$HOME/.cfg.git/ --work-tree=$HOME checkout
git --git-dir=$HOME/.cfg.git/ --work-tree=$HOME config --local status.showUntrackedFiles no
git clone https://github.com/ohmyzsh/ohmyzsh.git ${HOME}/.oh-my-zsh
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
git clone https://github.com/softmoth/zsh-vim-mode.git ${HOME}/.oh-my-zsh/plugins/zsh-vim-mode
curl -L https://iterm2.com/shell_integration/zsh \
  -o $HOME/.iterm2_shell_integration.zsh &&
  printf "\nsource ~/.iterm2_shell_integration.zsh\n" >>$HOME/.zshrc
echo "set-option -ga terminal-overrides ',xterm:Tc'" >>"$HOME/.tmux.conf" &&
  echo "set -g set-clipboard on # nvim osc52" >>$HOME/.tmux.conf &&
  echo "set -g allow-passthrough on #nvim osc52" >>$HOME/.tmux.conf
