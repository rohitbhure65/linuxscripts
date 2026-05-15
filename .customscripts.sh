export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Added by Blackbox CLI v2 installer
export PATH="/home/rohit/.local/bin:$PATH"
export BLACKBOX_INSTALL_DIR="/home/rohit/.blackbox-cli-v2"

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PATH=$PATH:$JAVA_HOME/bin

# === ANDROID SDK (PERMANENT) ===
export ANDROID_HOME=$HOME/Android/Sdk
export ANDROID_SDK_ROOT=$HOME/Android/Sdk

export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/cmdline-tools

export PATH=$PATH:$HOME/flutter/bin

export OLLAMA_ORIGINS=*

# === SOURCE SCRIPTS ===
source ~/.myscripts/.pgsetup.sh
source ~/.myscripts/.nodejs.sh
source ~/.myscripts/.pgtools.sh
source ~/.myscripts/.gtools.sh
source ~/.myscripts/.dtools.sh
source ~/.myscripts/.todo.sh
source ~/.myscripts/.gitui.sh
source ~/.myscripts/.ftools.sh
source ~/.myscripts/.fsetup.sh
source ~/.myscripts/.mkdocs.sh
source ~/.myscripts/.dev.sh
source ~/.myscripts/.prismatools.sh


# sudo mv .pgsetup.sh       ./.myscripts/.pgsetup.sh
# sudo mv .nodejs.sh        ./.myscripts/.nodejs.sh
# sudo mv .pgtools.sh       ./.myscripts/.pgtools.sh
# sudo mv .gtools.sh        ./.myscripts/.gtools.sh
# sudo mv .dtools.sh        ./.myscripts/.dtools.sh
# sudo mv .todo.sh          ./.myscripts/.todo.sh
# sudo mv .gitui.sh         ./.myscripts/.gitui.sh
# sudo mv .ftools.sh        ./.myscripts/.ftools.sh
# sudo mv .fsetup.sh        ./.myscripts/.fsetup.sh
# sudo mv .mkdocs.sh        ./.myscripts/.mkdocs.sh

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export NODE_OPTIONS="--max-old-space-size=10192"
export BLACKBOX_OUTPUT_BUFFER=1

# opencode
export PATH=/home/rohit/.opencode/bin:$PATH

# Blackbox CLI alias - added by 'blackbox configure'
alias b='blackbox'

#####################################
# GIT BRANCH SHOW TERMINAL
#####################################
source /usr/lib/git-core/git-sh-prompt
PS1='\[\e[32m\]\u@\h\[\e[0m\]:\[\e[34m\]\w\[\e[33m\]$(__git_ps1 " (%s)")\[\e[0m\]\$ '
export PATH="$HOME/.local/bin:$PATH"

# ==================== CUSTOM ALIAS ==========================

#####################################
# SYSTEM & NAVIGATION
#####################################
alias cls='clear'
alias ll='ls -lah'
alias la='ls -A'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias home='cd ~'
alias reload='source ~/.bashrc'
# alias cat='cat -n'

#####################################
# APT / SYSTEM MANAGEMENT
#####################################
alias upgrade='sudo apt upgrade'
alias install='sudo apt install'
alias update='sudo apt-get update && sudo apt-get upgrade -y'
alias remove='sudo apt remove'
alias purge='sudo apt purge'
alias cleanapt='sudo apt autoremove && sudo apt autoclean'

#####################################
# NODE / NPM
#####################################
alias npmi='npm install'
alias npmid='npm install --save-dev'
alias npmr='npm run'
alias npms='npm start'
alias npmb='npm run build'
alias npmt='npm test'
alias npkill='npx npkill'

#####################################
# DEV UTILITIES
#####################################
alias ports='sudo lsof -i -P -n | grep LISTEN'
alias myip='ip a | grep inet'
alias disk='df -h'
alias mem='free -h'
alias cpu='top'
alias now='date +"%Y-%m-%d %H:%M:%S"'

#####################################
# END
#####################################
# PS1="\[\e[37m\]\u@\h:\w\$ \[\e[0m\]"

#####################################
# CLAUDE CODE
#####################################

alias olr='ollama launch claude --config'
alias olr06='ollama launch claude --model qwen3-embedding:0.6b'
alias olr4='ollama launch claude --model qwen3-embedding:4b'
alias olr35='ollama launch claude --model qwen3.5:latest'

# Claude shortcuts
alias cc="claude"
alias ccp="claude ."
