#!/usr/bin/env sh

set -e

[ -z "$XDG_CONFIG_HOME" ]       && export XDG_CONFIG_HOME="${HOME}/.config"
[ -z "$XDG_CACHE_HOME" ]        && export XDG_CACHE_HOME="${HOME}/.cache"
[ -z "$XDG_DATA_HOME" ]         && export XDG_DATA_HOME="${HOME}/.local/share"
[ -z "$XDG_STATE_HOME" ]        && export XDG_STATE_HOME="${HOME}/.local/state"
[ -z "$DOTFILES_REPO" ]         && export DOTFILES_REPO="Raiu/dotfiles"
[ -z "$DOTFILES_REMOTE" ]       && export DOTFILES_REMOTE="https://github.com/${DOTFILES_REPO}.git"
[ -z "$DOTFILES_BRANCH" ]       && export DOTFILES_BRANCH="master"
[ -z "$DOTFILES_LOCATION" ]     && export DOTFILES_LOCATION="${HOME}/.dotfiles"
[ -z "$DOTBOT_DIR" ]            && export DOTBOT_DIR="${DOTFILES_LOCATION}/.dotbot"
[ -z "$DOTBOT_BIN" ]            && export DOTBOT_BIN="${DOTBOT_DIR}/bin/dotbot"
[ -z "$DOTBOT_CONFIG" ]         && export DOTBOT_CONFIG="${DOTFILES_LOCATION}/install.conf.yaml"

set -u

     BOLD="$(tput bold 2>/dev/null      || printf '')"
     GREY="$(tput setaf 0 2>/dev/null   || printf '')"
UNDERLINE="$(tput smul 2>/dev/null      || printf '')"
      RED="$(tput setaf 1 2>/dev/null   || printf '')"
    GREEN="$(tput setaf 2 2>/dev/null   || printf '')"
   YELLOW="$(tput setaf 3 2>/dev/null   || printf '')"
     BLUE="$(tput setaf 4 2>/dev/null   || printf '')"
  MAGENTA="$(tput setaf 5 2>/dev/null   || printf '')"
 NO_COLOR="$(tput sgr0 2>/dev/null      || printf '')"

_completed()    { printf '%s\n' "${GREEN}✓${NO_COLOR} $*"; }
_info()         { printf '%s\n' "${BOLD}${GREY}>${NO_COLOR} $*"; }
_warn()         { printf '%s\n' "${YELLOW}! $*${NO_COLOR}"; }
_error()        { printf '%s\n' "${RED}x $*${NO_COLOR}" >&2; }
_error_exit()   { _error "$@"; exit 1; }
_exist()        { command -v "$1" 1>/dev/null 2>&1; }


! _exist 'git' && _error_exit 'install git'


SUDO=''
if [ "$(id -u)" -ne 0 ]; then
    ! _exist 'sudo' && _error_exit 'sudo is not installed'
    SUDO=$(command -v 'sudo')
    $SUDO -n false 2>/dev/null && _error_exit 'user does not have sudo permissions'
fi

if [ -z "${REALUSER:-}" ]; then
    if [ -n "${SUDO_USER:-}" ]; then
        export REALUSER="${SUDO_USER}"
    else
        REALUSER="$(whoami)"
        export REALUSER
    fi
fi


is_correct_repo() {
    dir=$1
    url=$2
    GIT_TERMINAL_PROMPT=0 git -C "/tmp" ls-remote --exit-code --heads "$url" \
        >/dev/null 2>&1 || return 1
    url="${url%.git}"
    [ "$(git -C "$dir" rev-parse --is-inside-work-tree 2>/dev/null)" = "true" ] &&
           git -C "$dir" config --get remote.origin.url | grep -qE "^${url}"
}


clone_dotfiles() {
    if [ -d "$DOTFILES_LOCATION" ]; then
        if ! is_correct_repo "$DOTFILES_LOCATION" "$DOTFILES_REMOTE"; then
            _error "${DOTFILES_LOCATION} already exists and it doesnt contain our repo."
            return 1
        fi
    else
        git clone "$DOTFILES_REMOTE" "$DOTFILES_LOCATION" --recursive
    fi
}

run_dotbot() {
    git -C "${DOTBOT_DIR}" submodule sync --quiet --recursive
    git -C "${DOTFILES_LOCATION}" submodule update --init --recursive
    "${DOTBOT_BIN}" -d "${DOTFILES_LOCATION}" -c "${DOTBOT_CONFIG}" "${@}"
}

setup() {
    setup_script=$1
    printf '* Setup: %s\n' "$setup_script"
    sh "${DOTFILES_LOCATION}/setup/${setup_script}/${setup_script}.sh" || 
        _error "${setup_script} setup script failed"
}

ubuntu_exa_fix() {
    if ! grep -qiE '^ID=ubuntu' /etc/os-release >/dev/null 2>&1; then
        return 0
    fi
    if ! [ -f "/usr/local/bin/exa" ]; then
        $SUDO mkdir -p "/usr/local/bin"
        $SUDO install "${DOTFILES_LOCATION}/bin/exa" "/usr/local/bin/exa"
    fi
}

main() {
    printf '# Cloning dotfiles\n'
    clone_dotfiles
    printf '# Running dotbot\n'
    run_dotbot "${@}"
    setup 'pkg'
    setup 'vim'
    echo ""

    ubuntu_exa_fix # temp solution to ubuntu exa
    echo ""

    printf 'Change shell\n'
    $SUDO usermod --shell "$(command -v zsh)" "${REALUSER}" > /dev/null 2>&1
    echo ""

    printf 'Nopasswd\n'
    if [ "$(id -u)" -ne 0 ] ; then
        file="/etc/sudoers.d/nopasswd_$REALUSER"
        content="$REALUSER ALL=(ALL:ALL) NOPASSWD: ALL"
        printf "%s" "$content" | $SUDO tee "$file" > /dev/null 2>&1
    fi

    echo ""

    return 0
}

main "${@}"

echo ""
exit 0