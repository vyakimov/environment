#!/bin/bash
case "$1" in
env)
  echo "building environment"
  docker build --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g) --build-arg PYTHON_V=3.10.13 -f Dockerfile.environment"$2" -t environment:latest .
  ;;
rebuild-env)
  echo "force building environment"
  docker build --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g) --build-arg PYTHON_V=3.10.13 -f Dockerfile.environment"$2" -t environment:latest --no-cache .
  ;;
python_base)
  echo "building python base"
  docker build \
    --build-arg USER_ID=$(id -u) \
    --build-arg GROUP_ID=$(id -g) \
    --build-arg PYTHON_V=3.10.13 \
    -f Dockerfile.pythonBase \
    -t python_base:latest .
  ;;
run)
  echo "running environment"
  docker run \
    -it \
    --rm \
    -v $PWD:/app/ \
    --env-file .secrets \
    environment /bin/zsh
  ;;
*)
  echo "Usage: $0 {env|rebuild-env|python_base|run}"
  exit 1
  ;;
esac
