# CLAUDE.md

This is a personal developer environment setup repo. It provisions a reproducible Linux dev environment via Docker (local) and cloud-init (VPS). The standalone shell scripts are the single source of truth — Docker and cloud-init both consume them.

## Key Architecture

```
setup-system.sh    # root-level tools (Node.js, Neovim, R, lazygit, etc.)
setup-user.sh      # user-level config (uv, Python, Neovim plugins, dotfiles)
setup-dotfiles.sh  # dotfiles via bare git repo (~/.cfg.git)

Dockerfile         # Ubuntu 24.04 + uv + setup scripts
dev.sh             # Docker orchestration (build, rebuild, run)

cloud-init.yaml.tpl      # VPS template with {{ include: filename.sh }} markers
build-cloud-init.py      # resolves markers → writes cloud-init.yaml (generated)
cloud-init.yaml          # GENERATED — do not edit directly
```

## Workflow

### Docker (local dev)
```bash
./dev.sh build        # build environment image
./dev.sh rebuild      # force rebuild (no cache)
./dev.sh run          # run as user (with SSH/Claude/Copilot mounts)
./dev.sh run root     # run as root
```

### Cloud-init (VPS provisioning)
```bash
# After editing any .sh file or cloud-init.yaml.tpl:
python3 build-cloud-init.py   # regenerates cloud-init.yaml
```
Paste `cloud-init.yaml` into the VPS provider's user-data field. The scripts run at boot; `setup-user.sh` is deferred to first SSH login.

## Version Pins (single source of truth in setup-system.sh)

| Tool | Version |
|------|---------|
| tmux | 3.6a |
| Node.js | 25.2.1 |
| Neovim | 0.11.5 |
| codex-acp | 0.9.2 |
| Python | 3.12 (hardcoded in uv commands) |
| Lazygit | latest (fetched from GitHub API at runtime) |

To update a version, change the variable in `setup-system.sh` and rebuild.

## Important Rules

- **Never edit `cloud-init.yaml` directly** — it is generated. Edit the `.tpl` and `.sh` files, then run `python3 build-cloud-init.py`.
- **The `.sh` files are authoritative** over the cloud-init inline copies.
- All setup scripts use `set -euo pipefail`.
- Scripts are idempotent — they check before installing/cloning.

## Secrets

`.secrets` is gitignored. It is sourced by `dev.sh` as `--env-file`. It must exist locally for Docker runs to work.

## Cloud-init Notes

- VPS username: `vya`, shell: `/bin/zsh`, passwordless sudo
- Password hash placeholder in `cloud-init.yaml.tpl` must be replaced:
  ```bash
  mkpasswd --method=SHA-512 YOUR_PASSWORD
  ```
- `setup-user.sh` runs on first login only (guarded by `~/.first-login-complete` flag)
- Root SSH login is disabled; SSH authorized_keys are copied from root to `vya`

## Python Environment

Managed by `uv`. After `setup-user.sh` runs:
- Venv at `~/.venv` (Python 3.12)
- Tools: `vectorcode[lsp,mcp]`, `ipython`, `pyright`
- Key env vars: `VIRTUAL_ENV`, `UV_CACHE_DIR`, `UV_PROJECT_ENVIRONMENT`


## Docker Volume Mounts (dev.sh run)

| Host path | Container path |
|-----------|---------------|
| `$PWD` | `/app` |
| `$HOME/.ssh` | `/home/user/.ssh` |
| `$HOME/.claude/.credentials.json` | `/home/user/.claude/.credentials.json` |
| `$HOME/.claude/settings.json` | `/home/user/.claude/settings.json` |
| `$HOME/.claude/projects/` | `/home/user/.claude/projects/` |
| `$HOME/.codex` | `/home/user/.codex` |
| `$HOME/.config/github-copilot` | `/home/user/.config/github-copilot` |
| `$HOME/mount` | `/mount` |

Runs with `--net=host` and `--gpus all`.

## Dotfiles

`setup-dotfiles.sh` uses a bare git repo approach:
- Remote: `https://github.com/vyakimov/dotfiles.git`
- Bare repo: `~/.cfg.git`, work tree: `~/`
- Conflicts backed up to `~/.config-backup/`

Neovim config cloned from `https://github.com/vyakimov/neovim_setup.git` → `~/.config/nvim`; plugins synced via Lazy.
