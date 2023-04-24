#!/usr/bin/env sh

set -eu

_exist()    { command -v "$@" >/dev/null 2>&1; }
_error()    { printf '\nERROR: %s\n' "$1"; exit 1; }
_warn()     { printf '\nWARNING: %s\n' "$1"; }

SUDO=''
if [ "$(id -u)" -ne 0 ]; then
    ! _exist 'sudo' && _error 'sudo is not installed'
    SUDO=$(command -v 'sudo')
    $SUDO -n false 2>/dev/null && _error 'user does not have sudo permissions'
fi

BASEDIR="$(cd "$(dirname "${0}")" && pwd)"
DEBNI="DEBIAN_FRONTEND=noninteractive"

get_distro() {
    [ ! -f '/etc/os-release' ] && _error '/etc/os-release does not exist.'
    _distro=$(grep "^ID=" /etc/os-release | cut -d= -f2 | awk '{print tolower($0)}')
    [ -z "$_distro" ] && _error 'ID field not found in /etc/os-release.'
    printf '%s' "$_distro"
}

get_pkg_file() { 
    printf '%s/list.pkg.%s' "$BASEDIR" "$1"
}

get_pkges() {
    file=$1
    packages=""
    while IFS= read -r package; do
        packages="$packages $package"
    done < "$file"
    printf '%s' "$packages"
}

install_pkg_ubuntu() {
    pkg_file="$(get_pkg_file 'debian')"
    [ ! -f "$pkg_file" ] && _error "can not find ${pkg_file}"
    pkges="$(get_pkges "$pkg_file")"

    printf '# Installing Ubuntu packages\n'
    $SUDO $DEBNI apt-get update -y > /dev/null
    printf '    * Upgrading\n'
    $SUDO $DEBNI apt-get upgrade -y > /dev/null
    printf '    * Installing pkges: %s\n' "$pkges"
    $SUDO $DEBNI apt-get install $pkges -y > /dev/null 2>&1
    printf '    * Cleaning up\n'
    $SUDO $DEBNI apt-get autoremove -y > /dev/null
    $SUDO $DEBNI apt-get clean -y > /dev/null
}

install_pkg_debian() {
    pkg_file="$(get_pkg_file 'debian')"
    [ ! -f "$pkg_file" ] && _error "can not find ${pkg_file}"
    pkges="$(get_pkges "$pkg_file")"
    
    printf '# Installing Debian packages\n'
    printf '    * Upgrading\n'
    $SUDO $DEBNI apt-get update -y > /dev/null
    $SUDO $DEBNI apt-get upgrade -y > /dev/null
    printf '    * Installing pkges: %s\n' "$pkges"
    $SUDO $DEBNI apt-get install $pkges -y > /dev/null 2>&1
    printf '    * Cleaning up\n'
    $SUDO $DEBNI apt-get autoremove -y > /dev/null
    $SUDO $DEBNI apt-get clean -y > /dev/null
}

install_pkg_alpine() {
    pkg_file="$(get_pkg_file 'alpine')"
    [ ! -f "$pkg_file" ] && _error "can not find ${pkg_file}"
    pkges="$(get_pkges "$pkg_file")"

    printf '# Installing Alpine packages\n'
    printf '    * Upgrading\n'
    $SUDO apk --no-cache upgrade > /dev/null 2>&1
    printf '    * Installing packages: %s\n' "$pkges"
    $SUDO apk --no-cache add $pkges > /dev/null 2>&1
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
