#!/usr/bin/env sh
_exist()    { command -v "$@" >/dev/null 2>&1; }
_error()    { printf 'ERROR: %s\n' "$1"; exit 1; }
_warn()     { printf 'WARNING: %s\n' "$1"; }

! _exist 'curl' && _error 'install curl'

DOTFILES_REPO=${DOTFILES_REPO:-"Raiu/dotfiles"}
DOTFILES_REMOTE=${DOTFILES_REMOTE:-"https://github.com/${DOTFILES_REPO}.git"}
DOTFILES_LOCATION=${DOTFILES_LOCATION:-"${HOME}/.dotfiles"}
PRIME_SH="${DOTFILES_LOCATION}/prime.sh"
INSTALL_SH="${DOTFILES_LOCATION}/install.sh"

is_correct_repo() {
    _dir=$1; _url=$2

    # Check if url is valid
    ! GIT_TERMINAL_PROMPT=0 git ls-remote --exit-code --heads "$_url" > /dev/null 2>&1 && \
        _error "${_url} is not a valid git repo"

    # Check git _dir for _url
    [ "$(git -C "$_dir" rev-parse --is-inside-work-tree 2>/dev/null)" = "true" ] && \
    [ "$(git -C "$_dir" config --get remote.origin.url)" = "$_url" ]
}

if [ -f "${PRIME_SH}" ]; then
    sh "${PRIME_SH}" || _error 'prime.sh failed'
else
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/Raiu/dotfiles/main/prime.sh)" || \
        _error 'remote prime.sh failed'
fi

# Clone dotfiles repo
if [ -d "$DOTFILES_LOCATION" ]; then
    ! _exist 'git' && _error 'Need git to verify dotfiles directory'
    if ! is_correct_repo "$DOTFILES_LOCATION" "$DOTFILES_REMOTE"; then
        _error "${DOTFILES_LOCATION} already exists and it doesnt contain our repo."
    fi
else
    # Clone it
    ! _exist 'git' && _error 'install git'
    git clone "$DOTFILES_REMOTE" "$DOTFILES_LOCATION" || _error 'Failed to clone repo'
fi

# Run install found inside dotfiles
if [ -f "${INSTALL_SH}" ]; then
    sh "${INSTALL_SH}" || _error 'install.sh failed'
else
    _error "Cannot find ${INSTALL_SH}"
fi