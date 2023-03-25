# $PATH
typeset -U path PATH
path=("$HOME/.local/bin" "$path[@]")

# Env
export ZSH="$ZDOTDIR/oh-my-zsh"
export ZSH_CUSTOM="$ZSH/custom"
fpath+=($ZDOTDIR/pure)
[[ -f "$ZDOTDIR/.env" ]] && source "$ZDOTDIR/.env"

# OMZ
ZSH_THEME=""
plugins=(git zsh-autosuggestions zsh-syntax-highlighting ohmyzsh-full-autoupdate)
source $ZSH/oh-my-zsh.sh
DISABLE_AUTO_UPDATE=true
DISABLE_UPDATE_PROMPT=true

# History
[[ ! -d "${XDG_STATE_HOME}/zsh" ]] && mkdir -p "${XDG_STATE_HOME}/zsh"
HISTFILE="${XDG_STATE_HOME}/zsh/history"
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

# Fix TC
export COLORTERM='truecolor'

# Silence or i kill you
unsetopt BEEP

# Completion
compinit -d "${XDG_CACHE_HOME}/zsh/zcompdump-${ZSH_VERSION}"
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME}/zsh/zcompcache"

# Pure
autoload -U promptinit; promptinit
zstyle :prompt:pure:path color white
zstyle ':prompt:pure:prompt:*' color cyan
zstyle :prompt:pure:git:stash show yes
prompt pure

# Mod functions
if which exa >/dev/null; then
    chpwd() {
        exa --icons --group-directories-first
    }
else
    chpwd() {
        LC_COLLATE=C ls -h --group-directories-first --color=auto
    }
fi

if $(whence batcat >/dev/null); then
  alias bat="batcat"
fi

alias tmux="TERM=screen-256color-bce tmux"
TMUX_DEFAULT_SESSION="TMUX"
alias t="tmux -u a -d -t ${TMUX_DEFAULT_SESSION} 2> /dev/null || tmux -u new -s ${TMUX_DEFAULT_SESSION}"
if [[ $WT_PROFILE_ID = $TMUXWTPROFILE ]]; then
    if [[ -z "$TMUX" ]]; then
        tmux attach -t $TMUX_DEFAULT_SESSION || tmux new -s $TMUX_DEFAULT_SESSION
    fi
fi

# Switch to xterm if we're in a tmux session.
[[ -z "$TMUX" ]] && TERM="xterm-256color"

# Alias
if which exa > /dev/null; then
    alias ls='exa --icons --group-directories-first'
    alias lsa='exa -a --icons --group-directories-first'
    alias lt='exa -T --group-directories-first --icons --git'
    alias lta='exa -Ta --group-directories-first --icons --git'
    alias ll='exa -lmhg@ --group-directories-first --color-scale --icons --git'
    alias la='exa -lamhg@ --group-directories-first --color-scale --icons --git'
    alias lx='exa -lbhHigUmuSa@ --group-directories-first --color-scale --icons --git --time-style=long-iso'
else
    alias ls='LC_COLLATE=C ls -h --group-directories-first --color=auto'
    alias lsa='LC_COLLATE=C ls -Ah --group-directories-first --color=auto'
    alias ll='LC_COLLATE=C ls -lh --group-directories-first --color=auto'
    alias la='LC_COLLATE=C ls -lAh --group-directories-first --color=auto'
fi

alias screen='screen -e^tt'
alias wget='wget --hsts-file $XDG_CACHE_HOME/wget/wget-hsts'

alias zre='source "${ZDOTDIR}/.zshrc"'
alias zed='vim "${ZDOTDIR}/.zshrc"'
alias ved='vim "${XDG_CONFIG_HOME}/vim/vimrc"'
