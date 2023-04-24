#!/usr/bin/env sh

set -eu

_exist()    { command -v "$@" >/dev/null 2>&1; }
_error()    { printf 'ERROR: %s\n' "$1"; exit 1; }
_warn()     { printf 'WARNING: %s\n' "$1"; }

SUDO=''
if [ "$(id -u)" -ne 0 ]; then
    ! _exist 'sudo' && _error 'sudo is not installed'
    SUDO=$(command -v 'sudo')
    $SUDO -n false 2>/dev/null && _error 'user does not have sudo permissions'
fi

if [ -z "${REALUSER:-}" ]; then
    if [ -n "${SUDO_USER:-}" ]; then
        export REALUSER="${SUDO_USER}"
    else
        REALUSER="$(whoami)"
        export REALUSER
    fi
fi

DEBNI="DEBIAN_FRONTEND=noninteractive"
NOREC="--no-install-recommends"
NOCACHE="--no-cache"

# Packages
PACKAGES_UBUNTU="dialog readline-common apt-utils ssh curl wget sudo bash zsh \
git vim locales ca-certificates gnupg python3-minimal"
PACKAGES_DEBIAN="dialog readline-common apt-utils ssh curl wget sudo bash zsh \
git vim locales ca-certificates gnupg python3"
PACKAGES_ALPINE="dropbear tzdata curl wget sudo bash zsh git vim shadow musl \
musl-utils musl-locales python3"

#REPO_URL='https://github.com/Raiu/dotfiles'
REPO_URL_RAW='https://raw.githubusercontent.com/Raiu/dotfiles/main'
DOTFILES_DIR="${HOME}/.dotfiles"

# Helpers
###
get_distro() {
    [ ! -f "/etc/os-release" ] && _error "/etc/os-release does not exist."
    distro_id=$(grep "^ID=" /etc/os-release | cut -d= -f2 | awk '{print tolower($0)}')
    [ -z "$distro_id" ] && _error 'ID field not found in /etc/os-release.'
    printf '%s' "$distro_id"
}

#
###
setup_pkg_ubuntu() {
    printf '# Installing Ubuntu packages\n'

    # Fix repos
    printf '    * Updating repositories\n'
    if [ -f "${DOTFILES_DIR}/scripts/update_repo_ubuntu.sh" ] ; then
        printf '        -> with local\n'
        $SUDO sh "${DOTFILES_DIR}/scripts/update_repo_ubuntu.sh"
        $SUDO $DEBNI apt-get update -y > /dev/null
    
    elif    script_file=$(mktemp) ; \
            curl -fsSL "${REPO_URL_RAW}/scripts/update_repo_ubuntu.sh" \
            -o "${script_file}" ; then
        printf '        -> with remote\n'
        $SUDO sh "${script_file}"
        rm "${script_file}"
        $SUDO $DEBNI apt-get update -y > /dev/null 
    else
        printf '        -> with apt\n'
        $SUDO $DEBNI apt-get update -y > /dev/null
        $SUDO $DEBNI apt-get install $NOREC software-properties-common -y > /dev/null 2>&1
        $SUDO $DEBNI add-apt-repository universe multiverse restricted -y > /dev/null 2>&1
    fi


    printf '    * Upgrading\n'
    $SUDO $DEBNI apt-get upgrade -y > /dev/null
  
    printf '    * Installing packages: %s\n' "$PACKAGES_UBUNTU"
    $SUDO $DEBNI apt-get install $NOREC $PACKAGES_UBUNTU -y > /dev/null 2>&1
  
    printf '    * Cleaning up\n'
    $SUDO $DEBNI apt-get autoremove -y > /dev/null
    $SUDO $DEBNI apt-get clean -y > /dev/null
}

setup_pkg_debian() {
    printf '# Installing Debian packages\n'
    
    # Fix repos
    printf '    * Updating repositories\n'
    if [ -f "${DOTFILES_DIR}/scripts/update_repo_debian.sh" ] ; then
        printf '        -> with local\n'
        $SUDO sh "${DOTFILES_DIR}/scripts/update_repo_debian.sh"
        $SUDO $DEBNI apt-get update -y > /dev/null
    
    elif    script_file=$(mktemp) ; \
            curl -fsSL "${REPO_URL_RAW}/scripts/update_repo_debian.sh" \
            -o "${script_file}" ; then 
        printf '        -> with remote\n'
        $SUDO sh "${script_file}"
        rm "${script_file}"
        $SUDO $DEBNI apt-get update -y > /dev/null  
    else
        printf '        -> with apt\n'
        $SUDO $DEBNI apt-get update -y > /dev/null
        $SUDO $DEBNI apt-get install $NOREC software-properties-common -y > /dev/null 2>&1
        $SUDO $DEBNI add-apt-repository contrib -y > /dev/null 2>&1
        $SUDO $DEBNI add-apt-repository non-free -y > /dev/null 2>&1
    fi
    

    printf '    * Upgrading\n'
    $SUDO $DEBNI apt-get upgrade -y > /dev/null
    
    printf '    * Installing packages: %s\n' "$PACKAGES_DEBIAN"
    $SUDO $DEBNI apt-get install $NOREC $PACKAGES_DEBIAN -y > /dev/null 2>&1
    
    printf '    * Cleaning up\n'
    $SUDO $DEBNI apt-get autoremove -y > /dev/null
    $SUDO $DEBNI apt-get clean -y > /dev/null
}

setup_pkg_alpine() {
    printf '# Installing Alpine packages\n'

    # Fix repos
    printf '    * Updating repositories\n'
    if [ -f "${DOTFILES_DIR}/scripts/update_repo_alpine.sh" ] ; then
        printf '        -> with local\n'
        $SUDO sh "${DOTFILES_DIR}/scripts/update_repo_alpine.sh"
    
    elif    script_file=$(mktemp) ; \
            curl -fsSL "${REPO_URL_RAW}/scripts/update_repo_alpine.sh" \
            -o "${script_file}"
        then 
        printf '        -> with remote\n'
        $SUDO sh "${script_file}"
        rm "${script_file}"
    fi


    printf '    * Upgrading\n'
    $SUDO apk $NOCACHE upgrade > /dev/null 2>&1

    printf '    * Installing packages: %s\n' "$PACKAGES_ALPINE"
    $SUDO apk $NOCACHE add $PACKAGES_ALPINE > /dev/null 2>&1
}

setup_pkg() {
    _distro=$1
    case "$_distro" in
        "ubuntu")
            setup_pkg_ubuntu
            ;;
        "debian")
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

setup_zsh() {
    printf '# Configuring ZSH\n'
    $SUDO mkdir -p '/etc/zsh'
    
    $SUDO tee '/etc/zsh/zshenv' > /dev/null << 'EOF'
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
EOF
    
    $SUDO tee -a '/etc/zsh/zshenv' > /dev/null << 'EOF'

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
    printf '# Creating XDG directories\n'
    printf '    * root\n'
    $SUDO install -d -m 700 -o root -g root /root/.cache /root/.config \
      /root/.local/share /root/.local/state
    for user_home in /home/*; do
        username=$(basename "$user_home")
        printf '    * %s\n' "$username"
        $SUDO install -d -m 700 -o "$username" -g "$username" "${user_home}/.cache" \
          "${user_home}/.config" "${user_home}/.local/bin" "${user_home}/.local/state" \
          "${user_home}/.local/share"
    done
}

setup_locales_deb() {
    $SUDO tee '/etc/locale.gen' > /dev/null << EOF
en_US.UTF-8 UTF-8
en_GB.UTF-8 UTF-8
sv_SE.UTF-8 UTF-8
EOF
    $SUDO locale-gen > /dev/null
    $SUDO tee '/etc/default/keyboard' > /dev/null << EOF
XKBMODEL="pc105"
XKBLAYOUT="se"
XKBVARIANT=""
XKBOPTIONS=""
BACKSPACE="guess"
EOF
}

setup_locales_alpine() {
    zone_file="/usr/share/zoneinfo/Europe/Stockholm"
    if [ -f "$zone_file" ] ; then
        $SUDO cp "$zone_file" "/etc/localtime"
    fi
    echo "Europe/Stockholm" | $SUDO tee "/etc/timezone" > /dev/null
}

setup_locales() {
    printf '# Configuring Locales\n'
    _distro=$1
    case "$_distro" in
        "debian")
            setup_locales_deb ;;
        "ubuntu")
            setup_locales_deb ;;
        "alpine")
            setup_locales_alpine ;;
        *) ;;
    esac
}

# Start prime
printf '\n# Start prime the system.\n###\n\n'

DISTRO="$(get_distro)"
setup_pkg "$DISTRO"
setup_xdg_dir
setup_locales "$DISTRO"
setup_zsh "$DISTRO"

printf '\n###\n# Finished.\n\n'

exit 0