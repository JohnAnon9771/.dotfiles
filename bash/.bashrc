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

# O PATH sai daqui: environment.d/50-path.conf já o monta uma vez
# para a sessão inteira. Exportar de novo fazia cada shell aninhado
# reprefixar o mesmo diretório.

# O init do starship é o mesmo texto todo dia, e gerá-lo custava um
# fork+exec por shell interativo. Fica em cache e só é regerado quando
# o binário muda.
if command -v starship >/dev/null; then
    __starship_cache="${XDG_CACHE_HOME:-$HOME/.cache}/starship-init.bash"
    if [[ ! -s $__starship_cache || $(command -v starship) -nt $__starship_cache ]]; then
        starship init bash --print-full-init > "$__starship_cache"
    fi
    source "$__starship_cache"
fi
