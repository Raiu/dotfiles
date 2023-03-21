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

# Get distro
if [ ! -f /etc/os-release ]; then
    echo "ERROR: /etc/os-release does not exist."
    exit 1
fi
os_id=$(grep "^ID=" /etc/os-release | cut -d= -f2 | awk '{print tolower($0)}')
if [ -z "$os_id" ]; then
    echo "ERROR: ID field not found in /etc/os-release."
    exit 1
fi

# Install packages
case "$os_id" in
    "debian" | "ubuntu")
        packages="git zsh vim locales"
        $SUDO apt update
        $SUDO apt install -y $packages
        ;;
    "centos" | "fedora")
        ;;
    "arch")
        ;;
    "alpine")
        ;;
    *)
        echo "Error: Unable to detect distro."
        exit 1
        ;;
esac

cat << 'EOF' | sudo tee /etc/zsh/zshenv
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

# Set locale options
$SUDO locale-gen en_US.UTF-8 en_GB.UTF-8 sv_SE.UTF-8
#$SUDO update-locale LANG=en_GB.UTF-8 LC_TIME=sv_SE.UTF-8

# Set keyboard layout to Swedish
# $SUDO sed -i 's/XKBLAYOUT=".*"/XKBLAYOUT="se"/g' /etc/default/keyboard