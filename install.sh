#!/usr/bin/env sh

# Common functions
_exist()    { command -v "$@" >/dev/null 2>&1; }
_error()    { printf 'ERROR: %s\n' "$1"; exit 1; }
_warn()     { printf 'WARNING: %s\n' "$1"; }

! _exist 'git' && _error 'install git'

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if _exist "sudo"; then
        SUDO="$(command -v sudo)"
    else
        _error 'Please run as root or install sudo'
    fi
fi

[ -z "$USER" ]              && export USER="$(whoami)"
[ -z "$XDG_CONFIG_HOME" ]   && export XDG_CONFIG_HOME="${HOME}/.config"
[ -z "$XDG_CACHE_HOME" ]    && export XDG_CACHE_HOME="${HOME}/.cache"
[ -z "$XDG_DATA_HOME" ]     && export XDG_DATA_HOME="${HOME}/.local/share"
[ -z "$XDG_STATE_HOME" ]    && export XDG_STATE_HOME="${HOME}/.local/state"

[ -z "$DOTFILES_REPO" ]      && export DOTFILES_REPO="Raiu/dotfiles"
[ -z "$DOTFILES_REMOTE" ]    && export DOTFILES_REMOTE="https://github.com/${REPO}.git"
[ -z "$DOTFILES_BRANCH" ]    && export DOTFILES_BRANCH="master"
[ -z "$DOTFILES_LOCATION" ]  && export DOTFILES_LOCATION="${HOME}/.dotfiles"
[ -z "$DOTBOT_DIR" ]         && export DOTBOT_DIR="${DOTFILES_LOCATION}/.dotbot"
[ -z "$DOTBOT_BIN" ]         && export DOTBOT_BIN="${DOTBOT_DIR}/bin/dotbot"
[ -z "$DOTBOT_CONFIG" ]      && export DOTBOT_CONFIG="${DOTFILES_LOCATION}/install.conf.yaml"

#echo "DOTFILES_REPO: $DOTFILES_REPO"
#echo "DOTFILES_REMOTE: $DOTFILES_REMOTE"
#echo "DOTFILES_BRANCH: $DOTFILES_BRANCH"
#echo "DOTFILES_LOCATION: $DOTFILES_LOCATION"
#echo "DOTBOT_DIR: $DOTBOT_DIR"
#echo "DOTBOT_BIN: $DOTBOT_BIN"
#echo "DOTBOT_CONFIG: $DOTBOT_CONFIG"

is_correct_repo() {
    _dir=$1
    _url=$2
    [ "$(git -C "$_dir" rev-parse --is-inside-work-tree 2>/dev/null)" = "true" ] && \
    [ "$(git -C "$_dir" config --get remote.origin.url)" = "$_url" ]
}

clone_dotfiles() {
    if [ -d "$DOTFILES_LOCATION" ]; then
        if ! is_correct_repo "$DOTFILES_LOCATION" "$DOTFILES_REMOTE"; then
            _error "${DOTFILES_LOCATION} already exists and it doesnt contain our repo."
        fi
    else
        git clone "$DOTFILES_REMOTE" "$DOTFILES_LOCATION"
    fi
}

run_dotbot() {
    git -C "${DOTBOT_DIR}" submodule sync --quiet --recursive
    git -C "${DOTFILES_LOCATION}"  submodule update --init --recursive
    "${DOTBOT_BIN}" -d "${DOTFILES_LOCATION}" -c "${DOTBOT_CONFIG}" "${@}"
}

setup() {
    _setup_script=$1
    
    printf '* Setup: %s\n' "$_setup_script"
    sh "${DOTFILES_LOCATION}/setup/${_setup_script}/${_setup_script}.sh"
}

main() {
    run_dotbot
    setup 'pkg' # Install packages
    setup 'zsh'
    setup 'vim'
    setup 'sudo'
}

main "${@}"