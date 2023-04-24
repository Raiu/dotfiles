FROM mcr.microsoft.com/devcontainers/base:ubuntu

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade --yes && \
    apt-get install --no-install-recommends --yes \
      vim curl git wget zsh iputils-ping ssh sudo

RUN mkdir -p /etc/zsh
COPY zshenv /etc/zsh/