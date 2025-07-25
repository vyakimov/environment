docker run \
  -it \
  --rm \
  -v $PWD:/app/ \
  -v $HOME/.ssh/:/home/user/.ssh/ \
  --env-file .secrets \
  environment /bin/zsh
