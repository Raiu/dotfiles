#!/usr/bin/env sh

_exist()    { command -v "$@" >/dev/null 2>&1; }
_error()    { printf 'ERROR: %s\n' "$1"; exit 1; }
_warn()     { printf 'WARNING: %s\n' "$1"; }

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if _exist "sudo"; then
        SUDO="$(command -v sudo)"
    else
        _error 'Please run as root or install sudo'
    fi
fi

if [ "$(id -u)" -ne 0 ]; then
    file="/etc/sudoers.d/nopasswd_$USER"
    content="$USER ALL=(ALL:ALL) NOPASSWD: ALL"
    printf "%s" "$content" | $SUDO tee "$file" > /dev/null
fi