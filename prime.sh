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
PACKAGES_DEBIAN="git zsh vim locales"
PACKAGES_UBUNTU="git zsh vim locales"
PACKAGES_RHEL=""
PACKAGES_ALPINE="git zsh vim shadow"

get_distro() {
    if [ ! -f /etc/os-release ]; then
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
            ;;
        "alpine")
            $SUDO apk add -y ${PACKAGES_ALPINE}
            ;;
        *)
            echo "Error: Unable to detect distro."
            ;;
    esac
}

zshenv_xdg() {
$SUDO tee /etc/zsh/zshenv > /dev/null << 'EOF'
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
    $SUDO chown root:root '/root/.cache' '/root/.config' '/root/.local/share' '/root/.local/state'
    for user_home in /home/*; do
        username=$(basename "$user_home")
        $SUDO mkdir -p "$user_home/.cache" "$user_home/.config" "$user_home/.local/state" "$user_home/.local/share"
        $SUDO chown -R "$username:$username" "$user_home/.cache" "$user_home/.config" "$user_home/.local/state" "$user_home/.local/share"
    done
}

distro=$(get_distro)
echo $distro
install_packages "$distro"
zshenv_xdg
mkdir_xdg