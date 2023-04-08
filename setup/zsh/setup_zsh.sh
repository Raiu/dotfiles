#!/usr/bin/env sh

_exist() {
    command -v "$@" >/dev/null 2>&1
}

[ -z "$XDG_CONFIG_HOME" ]   && export XDG_CONFIG_HOME="$HOME/.config"
[ -z "$XDG_CACHE_HOME" ]    && export XDG_CACHE_HOME="$HOME/.cache"
[ -z "$XDG_DATA_HOME" ]     && export XDG_DATA_HOME="$HOME/.local/share"
[ -z "$XDG_STATE_HOME" ]    && export XDG_STATE_HOME="$HOME/.local/state"
[ -z "$ZDOTDIR" ]           && export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Get this scripts location
BASEDIR="$(cd "$(dirname "${0}")" && pwd)"

# Check if oh-my-zsh is installed
if [ ! -d "$ZDOTDIR/oh-my-zsh" ]; then
    # Install oh-my-zsh if it is not already installed
    ZSH="$ZDOTDIR/oh-my-zsh" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
fi

if [ ! -f "$BASEDIR/list.zsh.plugins" ]; then
    echo "Error: list.zsh.plugins does not exist."
else
    # Read the list of repositories from a file
    while read -r repo_url repo_path; do
        eval repo_path="$repo_path"
        # Check if the repo is already cloned
        if [ -d "$repo_path/.git" ]; then
            # Update the repo if it is already cloned
            cd "$repo_path"
            git pull
            cd "$BASEDIR"
        else
            # Clone the repo if it is not already cloned
            git clone "$repo_url" "$repo_path"
        fi
    done < $BASEDIR/list.zsh.plugins
fi