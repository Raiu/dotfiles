#!/usr/bin/env sh

set -e

DOTFILES_REPO=${DOTFILES_REPO:-Raiu/dotfiles}
DOTFILES_REMOTE=${DOTFILES_REMOTE:-https://github.com/${REPO}.git}
DOTFILES_BRANCH=${DOTFILES_BRANCH:-master}

DOTFILES_LOCATION=${DOTFILES_LOCATION:-$HOME/.dotfiles}

CONFIG="install.conf.yaml"
DOTBOT_DIR=".dotbot"

DOTBOT_BIN="bin/dotbot"
BASEDIR="$(cd "$(dirname "${0}")" && pwd)"

command_exists() {
    command -v "$@" >/dev/null 2>&1
}

command_exists sudo || {
    echo "sudo is not installed"
    exit 1
}

command_exists chsh || {
    echo "chsh is not installed"
    exit 1
}

command_exists git || {
    echo "git is not installed"
    exit 1
}

if [ ! -d "$DOTFILES_LOCATION" ]; then
    git clone "$DOTFILES_REPO" "$DOTFILES_LOCATION"
else
    echo "${DOTFILES_LOCATION} already exist, please delete before running this script"
fi

if command_exists zsh; then
    if [ -z "$ZSH_VERSION" ]; then
        echo "You are not using zsh. Would you like to switch to zsh? (y/n)"
        read -r answer
        if [ "$answer" = "y" ]; then
            chsh -s "$(which zsh)"
            echo "Shell changed to zsh. Please log out and log back in for changes to take effect."
        fi
    fi
fi

cd "${BASEDIR}"
git -C "${DOTBOT_DIR}" submodule sync --quiet --recursive
#git submodule update --init --recursive "${DOTBOT_DIR}"
git submodule update --init --recursive

"${BASEDIR}/${DOTBOT_DIR}/${DOTBOT_BIN}" -d "${BASEDIR}" -c "${CONFIG}" "${@}"
