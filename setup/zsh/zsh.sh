#!/usr/bin/env sh

[ -z "$ZDOTDIR" ] && export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

set -eu

_exist()    { command -v "$@" >/dev/null 2>&1; }
_error()    { printf 'ERROR: %s\n' "$1"; exit 1; }
_warn()     { printf 'WARNING: %s\n' "$1"; }

! _exist 'zsh' && _error 'install zsh'
! _exist 'git' && _error 'install git'


OMZSCRIPT="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
OMZDIR="$ZDOTDIR/oh-my-zsh"

SUDO=""
[ "$(id -u)" -ne 0 ] && SUDO="$(command -v sudo)"

is_correct_repo() {
    dir=$1
    url=$2
    GIT_TERMINAL_PROMPT=0 git -C "/tmp" ls-remote --exit-code --heads "$url" \
        >/dev/null 2>&1 || return 1
    url="${url%.git}"
    [ "$(git -C "$dir" rev-parse --is-inside-work-tree 2>/dev/null)" = "true" ] &&
           git -C "$dir" config --get remote.origin.url | grep -qE "^${url}"
}



BASEDIR="$(cd "$(dirname "${0}")" && pwd)"
PLUGINS_LIST="${BASEDIR}/list.zsh.plugins"

# Install OMZ
printf '* Setup: %s\n' "$setup_script"
if [ ! -d "$OMZDIR" ]; then
    ZSH="$OMZDIR" sh -c "$(curl -fsSL $OMZSCRIPT)" "" --unattended --keep-zshrc
fi

#result="${string##*/}"

# Install plugins or update them
if [ -f "$PLUGINS_LIST" ]; then
    while read -r repo_url repo_dir; do
        eval repo_dir="$repo_dir"
        if [ -d "$repo_dir" ]; then
            if is_correct_repo "$repo_dir" "$repo_url"; then
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

printf '\n\n# whoami: %s\n\n' "$(whoami)"
# Change default shell for user
if [ -z "$ZSH_VERSION" ]; then
    $SUDO usermod --shell "$(command -v zsh)" "${USER}"
fi