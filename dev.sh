#!/bin/bash
set -euo pipefail

IMAGE=environment:latest

build() {
  echo "Building environment..."
  docker build \
    --build-arg USER_ID="$(id -u)" \
    --build-arg GROUP_ID="$(id -g)" \
    -t "$IMAGE" .
}

run() {
  local extra_args=()
  [[ "${1:-}" == "root" ]] && extra_args+=(--user root)

  docker run \
    -it \
    --rm \
    --net=host \
    --gpus all \
    -v "$PWD":/app/ \
    -v "$HOME"/.ssh/:/home/user/.ssh/ \
    -v "$HOME"/.claude/.credentials.json:/home/user/.claude/.credentials.json \
    -v "$HOME"/.claude/settings.json:/home/user/.claude/settings.json \
    -v "$HOME"/.claude/projects/:/home/user/.claude/projects/ \
    -v "$HOME"/.codex/:/home/user/.codex/ \
    -v "$HOME"/.config/github-copilot/:/home/user/.config/github-copilot/ \
    -v "$HOME"/mount:/mount \
    --env-file .secrets \
    "${extra_args[@]}" \
    "$IMAGE" /bin/zsh
}

case "${1:-}" in
build)
  build
  ;;
rebuild)
  echo "Force building environment (no cache)..."
  docker build \
    --build-arg USER_ID="$(id -u)" \
    --build-arg GROUP_ID="$(id -g)" \
    --no-cache \
    -t "$IMAGE" .
  ;;
run)
  run "${2:-}"
  ;;
*)
  echo "Usage: $0 {build|rebuild|run [root]}"
  exit 1
  ;;
esac
