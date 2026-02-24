#cloud-config

# User setup
users:
  - name: vya
    groups: sudo, docker
    shell: /bin/zsh
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
    # Generate hash with: mkpasswd --method=SHA-512 YOUR_PASSWORD
    # Or: python3 -c "import crypt; print(crypt.crypt('YOUR_PASSWORD', crypt.mksalt(crypt.METHOD_SHA512)))"
    passwd: $6$PLACEHOLDER$REPLACE_THIS_WITH_YOUR_HASHED_PASSWORD

# Package management
package_update: true
package_upgrade: true

packages:
  # Base utilities
  - curl
  - wget
  - git
  - zsh
  - zip
  - unzip
  - tmux
  - python3-venv
  - python3-pip
  # Locale and build tools
  - locales
  - build-essential
  - software-properties-common
  # Dev tools
  - fzf
  - ripgrep
  - fd-find
  - luarocks
  # Security
  - ufw
  - fail2ban
  # Docker dependencies
  - ca-certificates
  - gnupg
  - lsb-release
  # Build dependencies for tmux (if building from source)
  - libevent-dev
  - ncurses-dev
  - bison
  # Python build dependencies
  - libssl-dev
  - zlib1g-dev
  - libbz2-dev
  - libreadline-dev
  - libsqlite3-dev
  - libffi-dev
  - liblzma-dev
  - tk-dev
  - libxml2-dev

# Locale setup
locale: en_US.UTF-8

# Write files
write_files:
  # Shared system setup script (same as Docker uses)
  - path: /opt/setup-system.sh
    permissions: '0755'
    owner: root:root
    content: |
      {{ include: setup-system.sh }}

  # Shared user setup script (same as Docker uses)
  - path: /home/vya/setup-user.sh
    permissions: '0755'
    owner: vya:vya
    content: |
      {{ include: setup-user.sh }}

  # Bootstrap script (dotfiles setup) — same as repo's bootstrap.sh
  - path: /home/vya/bootstrap.sh
    permissions: '0755'
    owner: vya:vya
    content: |
      {{ include: bootstrap.sh }}

  # Environment variables for zsh
  - path: /home/vya/.zshenv.local
    permissions: '0644'
    owner: vya:vya
    content: |
      export LANG=en_US.UTF-8
      export LANGUAGE=en_US:en
      export LC_ALL=en_US.UTF-8
      export TERM=xterm-256color
      export VIRTUAL_ENV="$HOME/.venv"
      export UV_CACHE_DIR="$HOME/.uv-cache"
      export UV_PROJECT_ENVIRONMENT="$HOME/.venv"
      export PATH="$VIRTUAL_ENV/bin:$HOME/.local/bin:$PATH"

# Run commands
runcmd:
  # Copy SSH keys from root to vya
  - mkdir -p /home/vya/.ssh
  - cp /root/.ssh/authorized_keys /home/vya/.ssh/authorized_keys 2>/dev/null || true
  - chown -R vya:vya /home/vya/.ssh
  - chmod 700 /home/vya/.ssh
  - chmod 600 /home/vya/.ssh/authorized_keys 2>/dev/null || true

  # Disable root SSH login
  - sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
  - sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
  - echo "PermitRootLogin no" >> /etc/ssh/sshd_config
  - systemctl restart sshd

  # Setup UFW firewall
  - ufw default deny incoming
  - ufw default allow outgoing
  - ufw allow ssh
  - ufw allow 22/tcp
  - ufw --force enable

  # Install Docker
  - install -m 0755 -d /etc/apt/keyrings
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  - chmod a+r /etc/apt/keyrings/docker.asc
  - echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
  - apt-get update
  - apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  - systemctl enable docker
  - systemctl start docker

  # Add vya to docker group (already in users section, but ensure it)
  - usermod -aG docker vya

  # Run shared system setup (Node.js, Neovim, lazygit, R, npm packages, etc.)
  - /opt/setup-system.sh

  # Set ownership of vya home directory
  - chown -R vya:vya /home/vya

  # Add first-login trigger to bashrc/zshrc (runs setup-user.sh once)
  - |
    echo '[ -f ~/setup-user.sh ] && [ ! -f ~/.first-login-complete ] && ~/setup-user.sh && touch ~/.first-login-complete' >> /home/vya/.bashrc
    echo '[ -f ~/setup-user.sh ] && [ ! -f ~/.first-login-complete ] && ~/setup-user.sh && touch ~/.first-login-complete' >> /home/vya/.zshrc 2>/dev/null || true
    chown vya:vya /home/vya/.bashrc

# Final message
final_message: |
  Cloud-init setup complete!

  SSH as user 'vya' (root login is disabled).
  On first login, setup-user.sh will run automatically to install:
  - uv and Python 3.12
  - Neovim plugins
  - Oh My Zsh with Powerlevel10k
  - Your dotfiles
