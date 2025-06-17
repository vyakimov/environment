#!/bin/bash
case "$1" in
build)
  docker build --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g) --build-arg PYTHON_V=3.10.13 -f Dockerfile.environment"$2" -t environment"$2":latest .
  ;;
rebuild)
  docker build --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g) --build-arg PYTHON_V=3.10.13 -f Dockerfile.environment"$2" -t environment"$2":latest --no-cache .
  ;;
*)
  echo "Usage: $0 {build|rebuild}"
  exit 1
  ;;
esac
