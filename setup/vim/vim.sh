#!/usr/bin/env sh

_exist()    { command -v "$@" >/dev/null 2>&1; }
_error()    { printf 'ERROR: %s\n' "$1"; exit 1; }
_warn()     { printf 'WARNING: %s\n' "$1"; }

! _exist 'vim' && _error 'install vim'
! _exist 'git' && _error 'install git'

[ -z "$VIMDIR" ]    && export VIMDIR="$XDG_CONFIG_HOME/vim"
[ -z "$MYVIMRC" ]   && export MYVIMRC="$VIMDIR/vimrc"

if [ ! -d "$VIMDIR/bundle/Vundle.vim" ]; then
    git clone --quiet "https://github.com/VundleVim/Vundle.vim.git" \
      "$VIMDIR/bundle/Vundle.vim" > /dev/null
fi

if [ -f "$MYVIMRC" ]; then 
    vim -c PluginInstall -c qall
else
    printf 'Can not find %s\nSkip PluginInstall. Run it manually' "$MYVIMRC"
fi
