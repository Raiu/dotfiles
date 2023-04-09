#!/usr/bin/env sh

_exist()    { command -v "$@" >/dev/null 2>&1; }
_error()    { printf 'ERROR: %s\n' "$1"; exit 1; }
_warn()     { printf 'WARNING: %s\n' "$1"; }

# Elevate script to root$
if [ "$(id -u)" -ne 0 ]; then
    if _exist 'sudo'; then
        exec sudo "$0" "$@"
    else
        _error 'Please run as root or install sudo'
    fi
fi

# Packages
PACKAGES_UBUNTU="curl wget sudo bash zsh git vim locales ca-certificates gnupg"
PACKAGES_DEBIAN="curl wget sudo bash zsh git vim locales ca-certificates gnupg"
PACKAGES_ALPINE="curl wget sudo bash zsh git vim shadow"

get_distro() {
    [ ! -f '/etc/os-release' ] && _error '/etc/os-release does not exist.'
    distro_id=$(grep "^ID=" /etc/os-release | cut -d= -f2 | awk '{print tolower($0)}')
    [ -z "$distro_id" ] && _error 'ID field not found in /etc/os-release.'
    printf '%s' "$distro_id"
}

setup_pkg() {
    _distro=$1
    case "$_distro" in
        "debian")
            setup_pkg_ubuntu
            ;;
        "ubuntu")
            setup_pkg_debian
            ;;
        "alpine")
            setup_pkg_alpine
            ;;
        *)
            printf 'Unknown distro: %s\n' "$_distro"
            ;;
    esac
}

setup_pkg_ubuntu() {
    printf '* Installing Ubuntu packages'
    apt-get update -qq                                      > /dev/null
    apt-get install software-properties-common -qq          > /dev/null
    add-apt-repository -y universe multiverse restricted    > /dev/null
    apt-get upgrade -qq                                     > /dev/null
    apt-get install $PACKAGES_UBUNTU -qq
    apt-get autoclean -qq                                   > /dev/null
}

setup_pkg_debian() {
    printf '* Installing Debian packages'
    apt-get update -qq                              > /dev/null
    apt-get install software-properties-common -qq  > /dev/null
    apt-add-repository -y contrib non-free          > /dev/null
    apt-get upgrade -qq                             > /dev/null
    apt-get install $PACKAGES_DEBIAN -qq
    apt-get autoclean -qq                           > /dev/null
}

setup_pkg_alpine() {
    printf '* Installing Alpine packages'
    tee '/etc/apk/repositories' > /dev/null << EOF
http://ftp.acc.umu.se/mirror/alpinelinux.org/v$(cut -d'.' -f1,2 /etc/alpine-release)/main/
http://ftp.acc.umu.se/mirror/alpinelinux.org/v$(cut -d'.' -f1,2 /etc/alpine-release)/community/
EOF
    apk update
    apk upgrade
    apk add -y $PACKAGES_ALPINE
}

setup_zsh() {
    printf '* Configuring ZSH'
    mkdir -p '/etc/zsh'
    tee '/etc/zsh/zshenv' > /dev/null << 'EOF'
if [[ -z "$PATH" || "$PATH" == "/bin:/usr/bin" ]]
then
        export PATH="/usr/local/bin:/usr/bin:/bin"
fi

# XDG
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_DATA_DIRS="/usr/local/share:/usr/share"
export XDG_CONFIG_DIRS="/etc/xdg"

# ZSH
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Locales
export LANG="en_GB.UTF-8"
export LANGUAGE="en_GB:en"
export LC_CTYPE="en_GB.UTF-8"
export LC_NUMERIC="sv_SE.utf8"
export LC_TIME="sv_SE.utf8"
export LC_COLLATE="en_GB.UTF-8"
export LC_MONETARY="sv_SE.utf8"
export LC_MESSAGES="en_GB.UTF-8"
export LC_PAPER="sv_SE.utf8"
export LC_NAME="sv_SE.UTF-8"
export LC_ADDRESS="sv_SE.UTF-8"
export LC_TELEPHONE="sv_SE.UTF-8"
export LC_MEASUREMENT="sv_SE.utf8"
export LC_IDENTIFICATION="sv_SE.UTF-8"
export LC_ALL=""
EOF
}

setup_xdg_dir() {
    printf '* Creating XDG directories'
    mkdir -p '/root/.cache' '/root/.config' '/root/.local/share' '/root/.local/state'
    chown root:root '/root/.cache' '/root/.config' '/root/.local'
    for user_home in /home/*; do
        username=$(basename "$user_home")
        mkdir -p "$user_home/.cache" "$user_home/.config" "$user_home/.local/bin" "$user_home/.local/state" "$user_home/.local/share"
        chown -R "$username:$username" "$user_home/.cache" "$user_home/.config" "$user_home/.local"
    done
}

setup_locales() {
    printf '* Configuring Locales'
    _distro=$1
    case "$_distro" in
        "debian")
            setup_locales_deb
            ;;
        "ubuntu")
            setup_locales_deb
            ;;
        *)
            ;;
    esac
}

setup_locales_deb() {
    tee '/etc/locale.gen' > /dev/null << EOF
en_US.UTF-8 UTF-8
en_GB.UTF-8 UTF-8
sv_SE.UTF-8 UTF-8
EOF
    locale-gen > /dev/null
    tee '/etc/default/keyboard' > /dev/null << EOF
XKBMODEL="pc105"
XKBLAYOUT="se"
XKBVARIANT=""
XKBOPTIONS=""
BACKSPACE="guess"
EOF
}


DISTRO="$(get_distro)"

# Start prime
printf '#\n Start prime the system.\n###\n\n'

setup_pkg "$DISTRO"
setup_xdg_dir
setup_locales "$DISTRO"
setup_zsh

printf '\n###\n# Finished.\n'