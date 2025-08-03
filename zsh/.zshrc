source_if_exists () {
    if test -r "$1"; then
        source "$1"
    fi
}

source_if_exists $HOME/.env.sh # Adds environment variables like DOTFILES generated from install.sh
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
source_if_exists "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

source_if_exists "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc"
source_if_exists "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc"

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

export PYENV_ROOT="$HOME/.pyenv"
[[ ":$PATH:" =~ ":$PYENV_ROOT/bin:" ]] || [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
# initialize pyenv each time we open a new terminal
if command -v pyenv &> /dev/null
then
    eval "$(pyenv init -)"
fi

export MANPAGER="NVIM_DISABLE_AUTOSESSION=1 nvim +Man!"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"
source_if_exists $(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme

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
plugins=(
    git
    zsh-autosuggestions
    web-search
)

source_if_exists $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Remote sessions - if someone connects to this machine (whatever machine hosts this file) via SSH then SSH_CONNECTION will be set automatically
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

source_if_exists $(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh

# see issue: https://github.com/jeffreytse/zsh-vi-mode/issues/4
function after_init() {
    # created with $(brew --prefix)/opt/fzf/install after installing fzf
    source_if_exists ~/.fzf.zsh
    source_if_exists $ZSH_CUSTOM/plugins/zsh-fzf-history-search/zsh-fzf-history-search.plugin.zsh
}
zvm_after_init_commands+=(after_init)

ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
ZVM_CURSOR_STYLE_ENABLED=false
ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT

autoload -Uz edit-command-line
bindkey -M vicmd "^v" edit-command-line # use Neovim for editing the current line

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Maybe pull git aliases into own file at some point if needed
# Format: <commit-hash> <date-in-local-timezone>  <ref-names> <message> [<author>]
# g=git

# Useful aliases from oh-my-zsh
# ga='git add'
# gaa='git add --all'
# gb='git branch'
# gbD='git branch -D'
# gba='git branch -a'
# gbd='git branch -d'
# gc='git commit -v'
# gcb='git checkout -b'
# gco='git checkout'
# gd='git diff'
# gf='git fetch'
# gfa='git fetch --all --prune --jobs=10'
# gl='git pull'
# glods='git log --graph --pretty='\''%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset'\'' --date=short'
# glol='git log --graph --pretty='\''%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset'\'
# glola='git log --graph --pretty='\''%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset'\'' --all'
# glols='git log --graph --pretty='\''%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset'\'' --stat'
# glp='git log --pretty=format:"%C(yellow)%h %C(blue)%ad %C(red)%d %C(reset)%s %C(green)[%an]" --decorate --date=format-local:"%Y-%m-%d %H:%M:%S"'
# gm='git merge'
# gp='git push'
# 'gpf!'='git push --force'
# gpsup='git push --set-upstream origin $(git_current_branch)'
# grhh='git reset --hard'

function checkout_fzf() {
  git branch | fzf | xargs git checkout
}

function merge_fzf() {
  git branch | fzf | xargs git merge
}

alias glp='git log --pretty=format:"%C(yellow)%h %C(blue)%ad %C(red)%d %C(reset)%s %C(green)[%an]" --decorate --date=format-local:"%Y-%m-%d %H:%M:%S"'
alias gs='git status'
alias gca='git commit --amend --no-edit'
alias gcm='git commit -m'
alias gcof='checkout_fzf'
alias gmf='merge_fzf'
alias pwb='git rev-parse --abbrev-ref HEAD'

# Size of all files and dirs in current dir (files are listed by the find command since du -ha doesn't seem to work well on Mac)
alias fs='du -h -d 1 2> /dev/null | sort -hr && find . -type f -maxdepth 1 -exec du -ah {} +'

source_if_exists $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

[[ ":$PATH:" =~ ":$HOME/.local/bin:/Applications/IntelliJ IDEA.app/Contents/MacOS:" ]] || export PATH="$HOME/.local/bin:/Applications/IntelliJ IDEA.app/Contents/MacOS:$PATH"

[[ ":$PATH:" =~ ":$HOME/bin:" ]] || export PATH="$HOME/bin:$PATH"

# For older versions of Go (1.11 and earlier) that don't support modules
[[ ":$PATH:" =~ ":$HOME/go/bin:" ]] || export PATH="$HOME/go/bin:$PATH"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source_if_exists ~/.p10k.zsh

# pulled from https://github.com/linkarzu/dotfiles-latest/blob/10ea8be847622f712f42b642fd043569d8e062fd/zshrc/zshrc-file.sh
install_xterm_kitty_terminfo() {
  # Attempt to get terminfo for xterm-kitty
  if ! infocmp xterm-kitty &>/dev/null; then
    echo "xterm-kitty terminfo not found. Installing..."
    # Create a temp file
    tempfile=$(mktemp)
    # Download the kitty.terminfo file
    # https://github.com/kovidgoyal/kitty/blob/master/terminfo/kitty.terminfo
    if curl -o "$tempfile" https://raw.githubusercontent.com/kovidgoyal/kitty/master/terminfo/kitty.terminfo; then
      echo "Downloaded kitty.terminfo successfully."
      # Compile and install the terminfo entry for my current user
      if tic -x -o ~/.terminfo "$tempfile"; then
        echo "xterm-kitty terminfo installed successfully."
      else
        echo "Failed to compile and install xterm-kitty terminfo."
      fi
    else
      echo "Failed to download kitty.terminfo."
    fi
    # Remove the temporary file
    rm "$tempfile"
  fi
}
install_xterm_kitty_terminfo

install_wezterm_terminfo() {
  # Attempt to get terminfo for xterm-kitty
  if ! infocmp wezterm &>/dev/null; then
    echo "wezterm terminfo not found. Installing..."
    # Create a temp file
    tempfile=$(mktemp)
    # https://wezfurlong.org/wezterm/config/lua/config/term.html
    if curl -o "$tempfile" https://raw.githubusercontent.com/wez/wezterm/main/termwiz/data/wezterm.terminfo; then
      echo "Downloaded wezterm.terminfo successfully."
      # Compile and install the terminfo entry for my current user
      if tic -x -o ~/.terminfo "$tempfile"; then
        echo "wezterm terminfo installed successfully."
      else
        echo "Failed to compile and install wezterm terminfo."
      fi
    else
      echo "Failed to download wezterm.terminfo."
    fi
    # Remove the temporary file
    rm "$tempfile"
  fi
}
install_wezterm_terminfo

# To support image.nvim
export DYLD_FALLBACK_LIBRARY_PATH="$(brew --prefix)/lib:$DYLD_FALLBACK_LIBRARY_PATH"

# To get to zsh help pages
unalias run-help 2>/dev/null
autoload run-help
export HELPDIR=/usr/share/zsh/5.9/help
alias help=run-help # Bash-style help for builtins

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source_if_exists "$HOME/.sdkman/bin/sdkman-init.sh"

