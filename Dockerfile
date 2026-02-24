FROM ubuntu:24.04
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

ARG USER_ID=1000
ARG GROUP_ID=1000

ENV LANG=en_US.UTF-8 \
  LANGUAGE=en_US:en \
  LC_ALL=en_US.UTF-8 \
  TERM=alacritty

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

RUN apt-get update && apt-get install -y \
  curl zsh zip unzip wget git python3-venv && \
  rm -rf /var/lib/apt/lists/*

# System-level setup (root)
COPY setup-system.sh /tmp/setup-system.sh
RUN chmod +x /tmp/setup-system.sh && /tmp/setup-system.sh

# Create user
RUN getent group ${GROUP_ID} || groupadd -g ${GROUP_ID} user && \
  useradd -l -m -u ${USER_ID} -g ${GROUP_ID} user

USER user
WORKDIR /home/user

ENV VIRTUAL_ENV="/home/user/.venv"
ENV UV_CACHE_DIR="/home/user/.uv-cache"
ENV UV_PROJECT_ENVIRONMENT="/home/user/.venv"
ENV PATH="${VIRTUAL_ENV}/bin:/home/user/.local/bin:${PATH}"
ENV COLORTERM=truecolor

# User-level setup
COPY --chown=user:user setup-user.sh /home/user/setup-user.sh
COPY --chown=user:user setup-dotfiles.sh /home/user/setup-dotfiles.sh
RUN chmod +x /home/user/setup-user.sh /home/user/setup-dotfiles.sh && /home/user/setup-user.sh

WORKDIR /app
