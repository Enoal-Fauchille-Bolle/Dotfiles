# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Add .local/bin to PATH
export PATH="$HOME/.local/bin:$PATH"

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=( git zsh-autosuggestions fzf )
# plugins=( git zsh-autosuggestions fzf tirith )

# Set custom location for zcompdump cache
export ZSH_COMPDUMP="$HOME/.cache/zsh/.zcompdump-$HOST"

# History size (must be set before oh-my-zsh.sh, which only raises these to its
# own floors of 50000/10000 rather than overwriting them)
HISTSIZE=100000
SAVEHIST=100000

source $ZSH/oh-my-zsh.sh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

################################## Aliases ##################################

# Git
alias gits='git status'

# Tools
alias ls='eza --icons --group-directories-first'
alias ll='eza -l --icons --group-directories-first --git'
alias tree='eza --tree --icons'
# alias ccat='bat --style=auto'
# alias ffind='fd'
# alias du='dust'
alias top='btop'
alias k9s='k9s --splashless --all-namespaces'

# Code Utility
alias emacs='emacs -nw'
alias cl='clear'
alias ter='(ptyxis --new-window --working-directory="$(pwd)" > /dev/null 2>&1 &)'
alias d="docker"
alias dc="docker compose"
alias kctl="kubectl"
alias ch='claude-history'

# Others
alias edit-rc='code ~/Dotfiles/home/zsh/.zshrc'
alias refresh-rc="source ~/.zshrc"
alias create-shortcut="ln -sf"
alias op="chmod 744"
alias update="sudo apt update && sudo apt upgrade -y"
alias vencord='sh -c "$(curl -sS https://vencord.dev/install.sh)"'
# alias cd="z"
# alias cdi="zi"
alias docker-compose="docker compose"

##############################################################################

# Less configuration
export LESS="-RFMiS --incsearch --use-color -j.5"

# PyEnv
# export PYENV_ROOT="$HOME/.pyenv"
# [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init -)"

# Zsh Syntax Highlighting
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Zoxide
export _ZO_ECHO=1
eval "$(zoxide init zsh --cmd cd)"

# TheFuck
(( $+commands[thefuck] )) && eval "$(thefuck --alias)"

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac

# Load secrets if the file exists
[ -f "$HOME/.zshrc.secrets" ] && source "$HOME/.zshrc.secrets"

# Homebrew - provides a git recent enough (>= 2.54) for the config-based hooks
# declared in .gitconfig. Guarded so machines without Homebrew start cleanly.
# brew shellenv prepends its bin dirs, which would shadow the Debian tools (curl,
# openssl, python3...) with copies that apt does not patch, so they are moved to
# the end of PATH. git and betterleaks still resolve to Homebrew through the
# /usr/local/bin symlinks that Ansible creates (homebrew_system_links).
[ -x /home/linuxbrew/.linuxbrew/bin/brew ] && {
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  path=(${path:#/home/linuxbrew/.linuxbrew/(bin|sbin)} /home/linuxbrew/.linuxbrew/bin /home/linuxbrew/.linuxbrew/sbin)
}

# mise - Node and per-project variables. Must stay after the Homebrew block: called
# by its absolute path, or with Homebrew missing from PATH, mise would put the
# Homebrew bin dir ahead of the Debian tools.
(( $+commands[mise] )) && eval "$(mise activate zsh)"

# Tirith
# eval "$(tirith init --shell zsh)"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Atuin - binds ctrl-r, leaves the up arrow and the fzf ctrl-t/alt-c widgets alone.
# --disable-ai drops the '?' binding, which sends prompts off to a third party.
# Must stay after oh-my-zsh.sh so it can hook into zsh-autosuggestions.
(( $+commands[atuin] )) && eval "$(atuin init zsh --disable-up-arrow --disable-ai)"

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"
