#!/usr/bin/env sh

_exist() {
    command -v "$@" >/dev/null 2>&1
}

[ -z "$XDG_CONFIG_HOME" ]   && export XDG_CONFIG_HOME="$HOME/.config"
[ -z "$XDG_CACHE_HOME" ]    && export XDG_CACHE_HOME="$HOME/.cache"
[ -z "$XDG_DATA_HOME" ]     && export XDG_DATA_HOME="$HOME/.local/share"
[ -z "$XDG_STATE_HOME" ]    && export XDG_STATE_HOME="$HOME/.local/state"
[ -z "$VIMDIR" ]            && export VIMDIR="$XDG_CONFIG_HOME/vim"

git clone "https://github.com/VundleVim/Vundle.vim.git" "$XDG_CONFIG_HOME/vim/bundle/Vundle.vim"

vim -c PluginInstall -c qall
