#!/usr/bin/env sh

_exist()    { command -v "$@" >/dev/null 2>&1; }
_error()    { printf '\nERROR: %s\n' "$1"; exit 1; }
_warn()     { printf '\nWARNING: %s\n' "$1"; }

SUDO=''
if [ "$(id -u)" -ne 0 ]; then
    ! _exist 'sudo' && _error 'sudo is not installed'
    SUDO=$(command -v 'sudo')
    $SUDO -n false 2>/dev/null && _error 'user does not have sudo permissions'
fi

DEBFE="DEBIAN_FRONTEND=noninteractive"
BASEDIR="$(cd "$(dirname "${0}")" && pwd)"

_get_distro() {
    [ ! -f '/etc/os-release' ] && _error '/etc/os-release does not exist.'
    _distro=$(grep "^ID=" /etc/os-release | cut -d= -f2 | awk '{print tolower($0)}')
    [ -z "$_distro" ] && _error 'ID field not found in /etc/os-release.'
    printf '%s' "$_distro"
}

_get_package_file() { 
    printf '%s/list.pkg.%s' "$BASEDIR" "$1"
}
#_get_packages() { "$(awk '{print}' ORS=' ' "$1")" ; }

_get_packages() {
    file=$1
    packages=""
    while IFS= read -r package; do
        packages="$packages $package"
    done < "$file"
    printf '%s' "$packages"
}

install_pkg_ubuntu() {
    _pkg_file="$(_get_package_file 'debian')"
    [ ! -f "$_pkg_file" ] && _error "can not find ${_pkg_file}"
    _packages="$(_get_packages "$_pkg_file")"

    printf '# Installing Ubuntu packages\n'
    $SUDO $DEBFE apt-get update -y > /dev/null
    printf '    * Upgrading\n'
    $SUDO $DEBFE apt-get upgrade -y > /dev/null
    printf '    * Installing _packages: %s\n' "$_packages"
    $SUDO $DEBFE apt-get install $_packages -y > /dev/null 2>&1
    printf '    * Cleaning up\n'
    $SUDO $DEBFE apt-get autoremove -y > /dev/null
    $SUDO $DEBFE apt-get clean -y > /dev/null
}

install_pkg_debian() {
    _pkg_file="$(_get_package_file 'debian')"
    [ ! -f "$_pkg_file" ] && _error "can not find ${_pkg_file}"
    _packages="$(_get_packages "$_pkg_file")"
    
    printf '# Installing Debian packages\n'
    printf '    * Upgrading\n'
    $SUDO $DEBFE apt-get update -y > /dev/null
    $SUDO $DEBFE apt-get upgrade -y > /dev/null
    printf '    * Installing _packages: %s\n' "$_packages"
    $SUDO $DEBFE apt-get install $_packages -y > /dev/null 2>&1
    printf '    * Cleaning up\n'
    $SUDO $DEBFE apt-get autoremove -y > /dev/null
    $SUDO $DEBFE apt-get clean -y > /dev/null
}

install_pkg_alpine() {
    _pkg_file="$(_get_package_file 'alpine')"
    [ ! -f "$_pkg_file" ] && _error "can not find ${_pkg_file}"
    _packages="$(_get_packages "$_pkg_file")"

    printf '# Installing Alpine packages\n'
    printf '    * Upgrading\n'
    $SUDO apk --no-cache upgrade > /dev/null 2>&1
    printf '    * Installing packages: %s\n' "$_packages"
    $SUDO apk --no-cache add $_packages
}

distro=$(_get_distro)
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
