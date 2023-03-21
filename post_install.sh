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

get_distro() {
    if [ ! -f /etc/os-release ]; then
        echo "ERROR: /etc/os-release does not exist."
        exit 1
    fi
    os_id=$(grep "^ID=" /etc/os-release | cut -d= -f2 | awk '{print tolower($0)}')
    if [ -z "$os_id" ]; then
        echo "ERROR: ID field not found in /etc/os-release."
        exit 1
    fi
}

install_packages() {
    case "$os_id" in 
        "debian") 
            packages="git zsh vim locales software-properties-common" 
            $SUDO apt update 
            $SUDO apt install -y $packages 
            $SUDO apt-add-repository contrib && $SUDO apt-add-repository non-free 
            ;; 
        "ubuntu") 
            packages="git zsh vim locales" 
            $SUDO apt update 
            $SUDO apt install -y $packages 
            ;;  
        "centos"| "fedora") ;;
        "arch") ;;
        "alpine")
            packages="git zsh vim shadow"
            $SUDO apk add -y $packages
            ;;
        *)
            echo "Error: Unable to detect distro."
            exit 1
            ;;
    esac  
}

zshenv_xdg() {
cat << 'EOF' | sudo tee /etc/zsh/zshenv  
if [[ -z "$PATH" || "$PATH" == "/bin:/usr/bin"]]  
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
    mkdir -p '/root/.cache' '/root/.config' '/root/.local/share' '/root/.local/state'
    chown root:root '/root/.cache' '/root/.config' '/root/.local/share' '/root/.local/state'

    for d in /home/*

    for user_home in /home/*; do
    username=$(basename "$user_home")
    
    # Create XDG directories
    $SUDO mkdir -p "$user_home/.cache" "$user_home/.config" "$user_home/.local/state" "$user_home/.local/share"
    
    # Change ownership of XDG directories to user
    $SUDO chown -R "$username:$username" "$user_home/.cache" "$user_home/.config" "$user_home/.local/state" "$user_home/.local/share"
done
}

read_input() {
    read -p "$1 (y/n) " input_var   
    input_var=$(echo "$input_var"| tr '[:upper:]' '[:lower:]') 

    if [ "$input_var" = "y" ]; then   
        return 0   
     else   
         return 1   
     fi   
}

distro=$(get_distro)

read_input "Do you want to install packages?" && install_packages

read_input "Do you want to set up ZSH and XDG?" && setup_zsh_xdg
