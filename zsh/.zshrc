# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=( git zsh-autosuggestions fzf )

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

################################## Aliases ##################################

# Git
alias gits='git status'
alias gitp="git stash && git pull && git stash pop"
alias gitph='git push'
alias gitpl='git pull'

# Make
alias makef='make fclean -s'
alias remake='make -s'
alias makerel="make fclean -s && make -s"
# alias make='bear -- make'
# alias makef='bear -- make fclean -s'
# alias remake='bear -- make -s'
# alias makerel="bear -- make fclean -s && bear -- make -s"

# Documentation
alias documentations="echo 'Coding Style Rules: coding-style-rules\nTmux Shortcuts: tmux-shortcuts\nEmacs Shortcuts: emacs-shortcuts\nNVIM Shortcuts: nvim-shortcuts\nCommon C Stumper Errors: common-c-stumper-errors\nCommon C Errors: common-c-errors'"
alias coding-style-rules="nano ~/Documents/C\ Coding\ Style.txt"
alias tmux-shortcuts="nano ~/Documents/Tmux\ Shortcuts.txt"
alias emacs-shortcuts="nano ~/Documents/Emacs\ Shortcuts.txt"
alias nvim-shortcuts="nano ~/Documents/NVIM\ Shortcuts.txt"
alias common-c-stumper-errors="nano ~/Documents/Common\ C\ Stumper\ Errors.txt"
alias common-c-errors="nano ~/Documents/Common\ C\ Errors.txt"

# Softwares & Games
alias postman="~/Softwares/Postman/Postman && exit"
alias webcatalog="~/Softwares/WebCatalog/WebCatalog-56.6.2.AppImage && exit"
alias minecraft="~/Games/Minecraft\ Launcher/minecraft-launcher && exit"
alias rhytia="~/Games/Rhytia/SoundSpacePlus.x86_64 && exit"
alias speedtest="~/Softwares/Speedtest/speedtest"
alias ida="~/ida-free-pc-9.0/ida && exit"
alias ghidra="~/Softwares/Ghidra/ghidra_11.3_PUBLIC/ghidraRun"

# Shit
alias jaaj='yes JAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJ'
alias tpd='curl -s -L https://raw.githubusercontent.com/keroserene/rickrollrc/master/roll.sh | bash'
alias lsd="yes ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ | lolcat"
alias matrix='cmatrix'
alias aquarium='asciiquarium'

# Tools
alias ls='eza --icons --group-directories-first'
alias ll='eza -l --icons --group-directories-first --git'
alias la='eza -la --icons --group-directories-first --git'
alias tree='eza --tree --icons'
alias cat='bat --style=auto'
alias find='fd'
alias du='dust'
alias top='btop'
alias ps='procs'

# Code Utility
alias delivery="cd ~/Delivery/Projects"
alias emacs='emacs -nw'
alias cl='clear'
alias ter='gnome-terminal'
alias exitcode='echo $?'
alias csc='bananapy'
alias dc="docker"
alias unit_tests_report="gcovr --exclude tests/ && gcovr -b --exclude tests/"
alias count-project-lines="find . -type f -name \"*.c\" ! -path \"*/libs/*\" -print0 | xargs -0 wc -l"
alias count-project-lines-with-libs="find . -type f -name \"*.c\" -print0 | xargs -0 wc -l"
alias vg="valgrind -s --leak-check=full --show-leak-kinds=all --track-origins=yes"
alias repository-mirroring="cat ~/.ssh/RepositoryMirroring | xclip -selection clipboard"
alias complete-recent-discord-quest="cat ~/Documents/complete-recent-discord-quest.js | xclip -selection clipboard"
alias kctl="kubectl"

# Others
alias f="fuck"
alias edit-rc="~/my_scripts/edit_zshrc.sh"
alias refresh-rc="source ~/.zshrc && clear"
alias create-shortcut="ln -sf"
alias root="sudo nautilus /"
alias op="chmod 744"
alias info="neofetch"
alias vim="nvim"
alias only="&& exit"
alias update="sudo dnf update -y"
alias cop="ghcs"
alias azerdev-host="ssh azerty@azerdev.live"
alias myip="curl https://ipinfo.io/ip && echo ''"
alias vencord='sh -c "$(curl -sS https://raw.githubusercontent.com/Vendicated/VencordInstaller/main/install.sh)"'
alias cd="z"
alias cdi="zi"
alias battery="upower -i /org/freedesktop/UPower/devices/battery_BAT0"
alias t="todo.sh"
alias clipboard="xclip -selection clipboard"
alias cb="clipboard"

##############################################################################

# Add my_scripts to PATH
export PATH="/home/enoal/my_scripts:$PATH"

# PyEnv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Zsh Syntax Highlighting
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Zoxide
eval "$(zoxide init zsh)"

# pnpm
export PNPM_HOME="/home/enoal/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Add .local/bin to PATH
export PATH="$HOME/.local/bin:$PATH"

# Nix
. /home/enoal/.nix-profile/etc/profile.d/nix.sh

# Load secrets if the file exists
[ -f "$HOME/.zshrc.secrets" ] && source "$HOME/.zshrc.secrets"
