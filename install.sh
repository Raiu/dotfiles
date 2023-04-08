#!/usr/bin/env sh

set -e

# Common functions
_exist() {
    command -v "$@" >/dev/null 2>&1
}

check_commands() {
    for cmd in "$@"; do
        if ! _exist "$cmd"; then
            echo "$cmd is not installed"
            exit 1
        fi
    done
}

check_commands sudo git

# Set sudo
SUDO=""
[ "$EUID" -ne 0 ] && SUDO="$(command -v sudo)"

[ -z "$XDG_CONFIG_HOME" ]   && export XDG_CONFIG_HOME="$HOME/.config"
[ -z "$XDG_CACHE_HOME" ]    && export XDG_CACHE_HOME="$HOME/.cache"
[ -z "$XDG_DATA_HOME" ]     && export XDG_DATA_HOME="$HOME/.local/share"
[ -z "$XDG_STATE_HOME" ]    && export XDG_STATE_HOME="$HOME/.local/state"

# Set variables
DOTFILES_REPO=${DOTFILES_REPO:-"Raiu/dotfiles"}
DOTFILES_REMOTE=${DOTFILES_REMOTE:-"https://github.com/${REPO}.git"}
DOTFILES_BRANCH=${DOTFILES_BRANCH:-"master"}
DOTFILES_LOCATION=${DOTFILES:-"$HOME/.dotfiles"}
DOTBOT_DIR="$DOTFILES_LOCATION/.dotbot"
DOTBOT_BIN="$DOTBOT_DIR/bin/dotbot"
BASEDIR="$(cd "$(dirname "${0}")" && pwd)"
CONFIG="install.conf.yaml"

# First check if $DOTFILES_LOCATION already exist
# If exist, check if install.sh and install.conf.yaml exist
# if they exist skip to next step, if not stop and inform the user to remove dir
# clone the dotfiles repo to the directory
# pull all the submodules

is_valid_git_repo() {
    [ "$(git -C "${DOTFILES_LOCATION}" rev-parse --is-inside-work-tree 2>/dev/null)" = "true" ] && \
    [ "$(git -C "${DOTFILES_LOCATION}" config --get remote.origin.url)" = "${DOTFILES_REMOTE}" ] || return 1
}

clone_dotfiles() {
    if [ -d "${DOTFILES_LOCATION}" ]; then
        if ! is_valid_git_repo; then
            printf "%s already exists and it doesnt contain our repo.\n" "${DOTFILES_LOCATION}"
            exit 1
        fi
    else
        git clone "${DOTFILES_REMOTE}" "${DOTFILES_LOCATION}"
    fi
}

run_dotbot() {
    git -C "${DOTBOT_DIR}" submodule sync --quiet --recursive
    git -C "${DOTFILES_LOCATION}"  submodule update --init --recursive
    "${DOTBOT_BIN}" -d "${DOTFILES_LOCATION}" -c "${CONFIG}" "${@}"
}

setup_sudo() {
    file="/etc/sudoers.d/$USER"
    content="$USER ALL=(ALL:ALL) NOPASSWD: ALL"
    printf "%s" "$content" | $SUDO tee "$file" > /dev/null
}

install_pkg() {
    $SUDO sh "$DOTFILES_LOCATION/setup/pkg/pkg_install.sh" # Install packages
}


install_zsh() {
    sh "$DOTFILES_LOCATION/setup/zsh/setup_zsh.sh"
    if _exist zsh; then
        if [ -z "$ZSH_VERSION" ]; then
            $SUDO usermod --shell "$(command -v zsh)" "${USER}"
        fi
    fi
}
