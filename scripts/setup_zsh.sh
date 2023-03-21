#!/usr/bin/env sh

# Check if $ZDOTDIR is set
if [ -z "$ZDOTDIR" ]; then
    # Set $ZDOTDIR to $XDG_CONFIG_HOME/zsh if it is set
    if [ -n "$XDG_CONFIG_HOME" ]; then
        ZDOTDIR="$XDG_CONFIG_HOME/zsh"
    else
        # Otherwise, set $ZDOTDIR to $HOME/.config/zsh
        ZDOTDIR="$HOME/.config/zsh"
    fi
fi

# Check if oh-my-zsh is installed
if [ ! -d "$ZDOTDIR/oh-my-zsh" ]; then
    # Install oh-my-zsh if it is not already installed
    ZSH="$ZDOTDIR/oh-my-zsh" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

BASEDIR="$(cd "$(dirname "${0}")" && pwd)"

if [ ! -f $BASEDIR/zsh.repo.list ]; then
    echo "Error: zsh.repo.list does not exist."
    exit 1
fi

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
done <$BASEDIR/zsh.repo.list
