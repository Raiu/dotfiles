#!/usr/bin/env sh

set -eu

_exist() { command -v "$@" >/dev/null 2>&1 ; }
_error() { printf '\nERROR: %s\n' "$1" ; rm "$TMP_FILE" >/dev/null 2>&1 ; exit 1 ; }
_warn()  { printf '\nWARNING: %s\n' "$1" ; }

if ! grep -qiE '^ID=alpine' /etc/os-release >/dev/null 2>&1; then
    _error 'This script is intended to run on Alpine Linux only.'
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
Update the apk repositories in Alpine Linux.

Optional arguments:
  -m MIRRORS  Specify a comma-separated list of mirrors to use.
  -r REPOS    Specify a comma-separated list of repositories to add.
  -n          Dry run
  -h          Display this help message and exit.
EOF
}

MIRRORS="
http://ftp.acc.umu.se/mirror/alpinelinux.org
http://ftp.lysator.liu.se/pub/alpine
http://alpine.mirror.far.fi
http://mirrors.edge.kernel.org/alpine
http://dl-cdn.alpinelinux.org/alpine"
REPOS="main community"
APK_FILE='/etc/apk/repositories'
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

CODENAME="v$(cut -d'.' -f1,2 /etc/alpine-release)"

for MIRROR in $MIRRORS ; do
    if curl --head --silent --fail "${MIRROR}/${CODENAME}/main" >/dev/null ; then
        break
    fi
done

TMP_FILE=$(mktemp)
for REPO in $(echo "$REPOS" | tr ' ' '\n') ; do
    printf '%s/%s/%s\n' "$MIRROR" "$CODENAME" "$REPO" >>"$TMP_FILE"
done

if [ $DRYRUN = 'true' ] ; then
    cat "$TMP_FILE"
    rm "$TMP_FILE" >/dev/null 2>&1
    exit 0
fi

[ ! -f "$APK_FILE" ] && _error "${APK_FILE} does not exist."
$SUDO cp "$APK_FILE" "${APK_FILE}.bak"

$SUDO mv "$TMP_FILE" "$APK_FILE" || _error "failed writing to ${APK_FILE}"
$SUDO chmod 644 "$APK_FILE"

if [ -f "$TMP_FILE" ]; then
    rm "$TMP_FILE" >/dev/null 2>&1 || _warn "failed to remove ${TMP_FILE}"
fi