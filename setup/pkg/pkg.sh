#!/usr/bin/env sh

_exist()    { command -v "$@" >/dev/null 2>&1; }
_error()    { printf 'ERROR: %s\n' "$1"; exit 1; }
_warn()     { printf 'WARNING: %s\n' "$1"; }

SUDO=""
SUDO_APT=""
if [ "$(id -u)" -ne 0 ]; then
    if _exist "sudo"; then
        SUDO="$(command -v sudo)"
        SUDO_APT="$(command -v sudo) DEBIAN_FRONTEND=noninteractive"
    else
        _error 'Please run as root or install sudo'
    fi
fi

BASEDIR="$(cd "$(dirname "${0}")" && pwd)"

get_distro() {
    [ ! -f '/etc/os-release' ] && _error '/etc/os-release does not exist.'
    _distro=$(grep "^ID=" /etc/os-release | cut -d= -f2 | awk '{print tolower($0)}')
    [ -z "$_distro" ] && _error 'ID field not found in /etc/os-release.'
    printf '%s' "$_distro"
}

get_packages() {
    _dist=$1
    package_file="${BASEDIR}/list.pkg.${_dist}"
    if [ -f "$package_file" ]; then
        packages=$(awk '{print}' ORS=' ' "$package_file")
    else
        _error "Cannot find ${package_file}"
    fi   
}

install_pkg_ubuntu() {
    packages="$(get_packages 'ubuntu')"
    $SUDO apt-get update -qq > /dev/null
    $SUDO apt-get upgrade -qq > /dev/null
    $SUDO apt-get install $packages -qq
    $SUDO apt-get autoremove -qq > /dev/null
    $SUDO apt-get clean -qq > /dev/null
}

install_pkg_debian() {
    packages="$(get_packages 'debian')"
    $SUDO apt-get update -qq > /dev/null
    $SUDO apt-get upgrade -qq > /dev/null
    $SUDO apt-get install $packages -qq
    $SUDO apt-get autoremove -qq > /dev/null
    $SUDO apt-get clean -qq > /dev/null
}

install_pkg_alpine() {
    apk update
    apk upgrade
    apk add -y $PACKAGES_ALPINE
}

distro=$(get_distro)
case "${distro}" in
    'ubuntu')
        install_pkg_ubuntu
        ;;
    'debian')
        install_pkg_debian
        ;;
    'alpine')
        install_pkg_alpine
        ;;
    *)
        _error "Uknown distro: ${distro}"
        ;;
esac
