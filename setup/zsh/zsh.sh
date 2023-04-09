#!/usr/bin/env sh

_exist()    { command -v "$@" >/dev/null 2>&1; }
_error()    { printf 'ERROR: %s\n' "$1"; exit 1; }
_warn()     { printf 'WARNING: %s\n' "$1"; }

! _exist 'zsh' && _error 'install zsh'
! _exist 'git' && _error 'install git'

SUDO=""
[ "$(id -u)" -ne 0 ] && SUDO="$(command -v sudo)"

_is_correct_repo() {
    _dir=$1
    _url=$2
    [ "$(git -C "$_dir" rev-parse --is-inside-work-tree 2>/dev/null)" = "true" ] && \
    [ "$(git -C "$_dir" config --get remote.origin.url)" = "$_url" ]
}

[ -z "$ZDOTDIR" ] && export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

BASEDIR="$(cd "$(dirname "${0}")" && pwd)"
PLUGINS_LIST="${BASEDIR}/list.zsh.plugins"

# Install OMZ
if [ ! -d "$ZDOTDIR/oh-my-zsh" ]; then
    ZSH="$ZDOTDIR/oh-my-zsh" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
fi

# Install plugins
if [ -f "$PLUGINS_LIST" ]; then
    while read -r repo_url repo_dir; do
        eval repo_dir="$repo_dir"
        if [ -d "$repo_dir" ]; then
            if _is_correct_repo "$repo_dir" "$repo_url"; then
                git -C "$repo_dir" pull
            else
                printf 'Cannot pull plugin. %s already exist' "$repo_dir"
            fi
        else
            git clone "$repo_url" "$repo_dir"
        fi
    done < "$PLUGINS_LIST"
else
    _warn "${PLUGINS_LIST} does not exist."
fi

# Change default shell for user
if [ -z "$ZSH_VERSION" ]; then
    $SUDO usermod --shell "$(command -v zsh)" "${USER}"
fi