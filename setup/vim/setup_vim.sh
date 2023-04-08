#!/usr/bin/env sh

git clone "https://github.com/VundleVim/Vundle.vim.git" "$XDG_CONFIG_HOME/vim/bundle/Vundle.vim"

vim -c PluginInstall -c qall
