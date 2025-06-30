docker run \
  -it \
  --rm \
  -v $PWD:/app/ \
  --env-file .secrets \
  environment /bin/zsh
