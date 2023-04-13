FROM mcr.microsoft.com/devcontainers/base:ubuntu

RUN apt-get update && apt-get upgrade --yes && apt-get install --no-install-recommends --yes \
        curl git wget zsh iputils-ping redis-tools ssh sudo

COPY .devcontainer/zshenv /etc/zsh/zshenv