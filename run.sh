#!/bin/bash

if [[ "$1" == "root" ]]; then
  docker run \
    -it \
    --rm \
    --net=host \
    -v "$PWD":/app/ \
    -v "$HOME"/.ssh/:/home/user/.ssh/ \
    -v "$HOME"/.claude/:/home/user/.claude/ \
    --env-file .secrets \
    --user root \
    environment /bin/zsh
else
  docker run \
    -it \
    --rm \
    --net=host \
    -v "$PWD":/app/ \
    -v "$HOME"/.ssh/:/home/user/.ssh/ \
    -v "$HOME"/.claude/:/home/user/.claude/ \
    --env-file .secrets \
    environment /bin/zsh
fi
