#!/usr/bin/env sh

_exist() { command -v "$@" >/dev/null 2>&1 ; }
_error() { printf '\nERROR: %s\n' "$1" ; rm "$TMP_FILE" >/dev/null 2>&1 ; exit 1 ; }
_warn()  { printf '\nWARNING: %s\n' "$1" ; }

if ! grep -qiE '^ID=debian' /etc/os-release >/dev/null 2>&1; then
    _error 'This script is intended to run on Debian only.'
fi

SUDO=''
if [ "$(id -u)" -ne 0 ] ; then
    ! _exist 'sudo' && _error 'sudo is not installed'
    SUDO=$(command -v 'sudo')
    $SUDO -n false 2>/dev/null && _error 'user does not have sudo permissions'
fi

! _exist 'curl' && _error 'can not find curl.'

show_help() {
    cat <<EOF
Usage: $(basename "$0") [-m MIRRORS] [-r REPOS]
Update the apt repositories in Debian.

Optional arguments:
  -m MIRRORS  Specify a comma-separated list of mirrors to use.
  -r REPOS    Specify a comma-separated list of repositories to add.
  -n          Dry run
  -h          Display this help message and exit.
EOF
}

MIRRORS="
http://ftp.acc.umu.se/debian
http://ftp.uio.no/debian
http://mirror.asergo.com/debian
http://ftp.fi.debian.org/debian
http://debian.mirror.su.se/debian
http://ftp.debian.org/debian
http://deb.debian.org/debian"
REPOS="main contrib non-free"
APT_FILE='/etc/apt/sources.list'
DRYRUN="false"

while getopts "m:r:nh" opt ; do
    case $opt in
        m) MIRRORS=$(echo "$OPTARG" | tr ',' ' ') ;;
        r) REPOS=$(echo "$OPTARG" | tr ',' ' ') ;;
        n) DRYRUN='true' ;;
        h) show_help ; exit 0 ;;
        *) show_help ; exit 1 ;;
    esac
done

CODENAME=$(grep VERSION_CODENAME /etc/os-release | cut -d= -f2 | tr '[:upper:]' '[:lower:]')

for MIRROR in $MIRRORS ; do
    if curl --head --silent --fail "${MIRROR}/dists/${CODENAME}/Release" >/dev/null ; then
        break
    fi
done

TMP_FILE=$(mktemp)
cat <<EOF >"$TMP_FILE"
deb $MIRROR $CODENAME $REPOS
deb $MIRROR $CODENAME-updates $REPOS
deb $MIRROR $CODENAME-backports $REPOS
deb http://deb.debian.org/debian-security $CODENAME-security $REPOS

# Uncomment lines below to enable source packages
#deb-src $MIRROR $CODENAME $REPOS
#deb-src $MIRROR $CODENAME-updates $REPOS
#deb-src $MIRROR $CODENAME-backports $REPOS
#deb-src http://deb.debian.org/debian-security $CODENAME-security $REPOS
EOF

if [ $DRYRUN = 'true' ] ; then
    cat "$TMP_FILE"
    rm "$TMP_FILE" >/dev/null 2>&1
    exit 0
fi

[ ! -f "$APT_FILE" ] && _error "${APT_FILE} does not exist."
$SUDO cp "$APT_FILE" "${APT_FILE}.bak"

$SUDO mv "$TMP_FILE" "$APT_FILE" || _error "failed writing to ${APT_FILE}"
$SUDO chmod 644 "$APT_FILE"

if [ -f "$TMP_FILE" ] ; then
    rm "$TMP_FILE" >/dev/null 2>&1 || _warn "failed to remove ${TMP_FILE}"
fi