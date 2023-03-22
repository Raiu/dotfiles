#!/usr/bin/env sh

set -e

[ -z "$XDG_CONFIG_HOME" ]   && export XDG_CONFIG_HOME="$HOME/.config"
[ -z "$XDG_CACHE_HOME" ]    && export XDG_CACHE_HOME="$HOME/.cache"
[ -z "$XDG_DATA_HOME" ]     && export XDG_DATA_HOME="$HOME/.local/share"
[ -z "$XDG_STATE_HOME" ]    && export XDG_STATE_HOME="$HOME/.local/state"

BASEDIR="$(cd "$(dirname "${0}")" && pwd)"

DOTFILES_REPO=${DOTFILES_REPO:-Raiu/dotfiles}
DOTFILES_REMOTE=${DOTFILES_REMOTE:-https://github.com/${REPO}.git}
DOTFILES_BRANCH=${DOTFILES_BRANCH:-master}

DOTFILES_LOCATION=${DOTFILES_LOCATION:-$HOME/.dotfiles}

DOTBOT_DIR="$DOTFILES_LOCATION/.dotbot"
DOTBOT_BIN="bin/dotbot"
CONFIG="install.conf.yaml"

FIRST_INSTALL=false


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
    FIRST_INSTALL=true
    touch "$DOTFILES_LOCATION/installed" 
elif [ ! -f "$DOTFILES_LOCATION/installed" ]; then
    echo "${DOTFILES_LOCATION} already exist, please delete before running this script"
    exit 1
fi

cd "${BASEDIR}"
git -C "${DOTBOT_DIR}" submodule sync --quiet --recursive
git submodule update --init --recursive

"${BASEDIR}/${DOTBOT_DIR}/${DOTBOT_BIN}" -d "${BASEDIR}" -c "${CONFIG}" "${@}"

# nopasswd Sudo
echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee "/etc/sudoers.d/$USER" > /dev/null

sudo bash ~/.dotfiles/scripts/pkg_install.sh # Install packages
bash ~/.dotfiles/scripts/setup_zsh.sh

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