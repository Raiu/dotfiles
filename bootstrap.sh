#!/usr/bin/env sh

_exist() { command -v "$@" >/dev/null 2>&1; }

_exist "git" || { printf "install git\n"; exit 1; }

DOTFILES_REPO=${DOTFILES_REPO:-"Raiu/dotfiles"}
DOTFILES_REMOTE=${DOTFILES_REMOTE:-"https://github.com/${REPO}.git"}
DOTFILES_LOCATION=${DOTFILES_LOCATION:-"${HOME}/.dotfiles"}

is_valid_git_repo() {
    GIT_DIR="${DOTFILES_LOCATION}/.git"
    [ "$(git --git-dir=${GIT_DIR} rev-parse --is-inside-work-tree 2>/dev/null)" = "true" ] && \
    [ "$(git --git-dir=${GIT_DIR} config --get remote.origin.url)" = "${DOTFILES_REMOTE}" ] || return 1
}

if [ -d "${DOTFILES_LOCATION}" ]; then
    if [ "$1" = "-f" ]; then
        rm -rf "${DOTFILES_LOCATION}" || { printf "Failed to delete %s\n" "${DOTFILES_LOCATION}"; exit 1; }
        git clone "${DOTFILES_REMOTE}" "${DOTFILES_LOCATION}"
    else
        if ! is_valid_git_repo; then
            printf "%s already exists. Use the -f option to forcibly overwrite it.\n" "${DOTFILES_LOCATION}"
            exit 1
        fi
    fi
else
    git clone "${DOTFILES_REMOTE}" "${DOTFILES_LOCATION}"
fi

# Run prime found inside dotfiles
sh "${DOTFILES_LOCATION}/prime"

# Run install found inside dotfiles
sh "${DOTFILES_LOCATION}/install"