#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

fcd() {
  cd "$(find -type d | fzf)"
}

open() {
  xdg-open "$(find -type f | fzf)"
}

alias icat="kitty +kitten icat"

export PATH="$HOME/.local/bin:$PATH"

eval "$(starship init bash)"
