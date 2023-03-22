#!/usr/bin/env sh

# Root or sudo
if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
elif command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
else
    echo "ERROR: Please run as root or install sudo"
    exit
fi

# Var
PACKAGES_DEBIAN="sudo bash zsh git vim locales"
PACKAGES_UBUNTU="sudo bash zsh git vim locales"
PACKAGES_RHEL="sudo bash zsh git vim"
PACKAGES_ALPINE="sudo bash zsh git vim shadow"
PACKAGES_ARCH="sudo bash zsh git vim"

get_distro() {
    if [ ! -f '/etc/os-release' ]; then
        echo "ERROR: /etc/os-release does not exist."
        exit 1
    fi
    distro=$(grep "^ID=" /etc/os-release | cut -d= -f2 | awk '{print tolower($0)}')
    if [ -z "$distro" ]; then
        echo "ERROR: ID field not found in /etc/os-release."
        exit 1
    else
        echo $distro
    fi
}

install_packages() {
    distro=$1
    case "$distro" in
        "debian")
            $SUDO apt update
            $SUDO apt install -y software-properties-common
            $SUDO apt-add-repository -y contrib non-free
            $SUDO apt upgrade -y
            $SUDO apt install -y ${PACKAGES_DEBIAN}
            $SUDO apt autoclean
            ;;
        "ubuntu")
            $SUDO apt update
            $SUDO add-apt-repository -y universe multiverse restricted
            $SUDO apt upgrade -y
            $SUDO apt install -y ${PACKAGES_UBUNTU}
            $SUDO apt autoclean
            ;;
        "centos"| "fedora")
            $SUDO dnf install -y ${PACKAGES_RHEL}
            ;;
        "alpine")
            alpine_enable_repo
            $SUDO apk update && apk upgrade
            $SUDO apk add -y ${PACKAGES_ALPINE}
            ;;
        "arch")
            $SUDO pacman -S --noconfirm ${PACKAGES_ARCH}
            ;;
        *)
            echo "Error: Unable to detect distro."
            ;;
    esac
}

alpine_enable_repo() {
$SUDO tee '/etc/apk/repositories' > /dev/null << EOF
http://ftp.acc.umu.se/mirror/alpinelinux.org/v$(cut -d'.' -f1,2 /etc/alpine-release)/main/
http://ftp.acc.umu.se/mirror/alpinelinux.org/v$(cut -d'.' -f1,2 /etc/alpine-release)/community/
EOF
}

zshenv_xdg() {
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
}

mkdir_xdg() {
    $SUDO mkdir -p '/root/.cache' '/root/.config' '/root/.local/share' '/root/.local/state'
    $SUDO chown root:root '/root/.cache' '/root/.config' '/root/.local'
    for user_home in /home/*; do
        username=$(basename "$user_home")
        $SUDO mkdir -p "$user_home/.cache" "$user_home/.config" "$user_home/.local/bin" "$user_home/.local/state" "$user_home/.local/share"
        $SUDO chown -R "$username:$username" "$user_home/.cache" "$user_home/.config" "$user_home/.local"
    done
}

locales_input() {
    distro=$1
    # debian or ubuntu
    if [ "$distro" = "debian" ] || [ "$distro" = "ubuntu" ]; then
$SUDO tee '/etc/locale.gen' > /dev/null << EOF
en_US.UTF-8 UTF-8
en_GB.UTF-8 UTF-8
sv_SE.UTF-8 UTF-8
EOF
$SUDO locale-gen
$SUDO tee '/etc/default/locale' > /dev/null << EOF
LANG=en_GB.UTF-8
LANGUAGE=en_GB:en
LC_CTYPE=en_GB.UTF-8
LC_NUMERIC=sv_SE.utf8
LC_TIME=sv_SE.utf8
LC_COLLATE=en_GB.UTF-8
LC_MONETARY=sv_SE.utf8
LC_MESSAGES=en_GB.UTF-8
LC_PAPER=sv_SE.utf8
LC_NAME=sv_SE.UTF-8
LC_ADDRESS=sv_SE.UTF-8
LC_TELEPHONE=sv_SE.UTF-8
LC_MEASUREMENT=sv_SE.utf8
LC_IDENTIFICATION=sv_SE.UTF-8
LC_ALL=
EOF
$SUDO tee '/etc/zsh/zshenv' >> /dev/null << EOF
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
$SUDO tee '/etc/default/keyboard' > /dev/null << EOF
XKBMODEL="pc105"
XKBLAYOUT="se"
XKBVARIANT=""
XKBOPTIONS=""
BACKSPACE="guess"
EOF
    fi
    ##
}

# Start running
DISTRO="$(get_distro)"
install_packages "$DISTRO"
zshenv_xdg
mkdir_xdg
locales_input "$DISTRO"