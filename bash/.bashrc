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

# O ~/.local/bin.
#
# A sessão gráfica já o recebe do environment.d/50-path.conf, pelo
# systemd do usuário. Isto aqui é para o shell interativo que NÃO desce
# dali — um terminal aberto fora da sessão, um container.
#
# O que faltava era a guarda: o .bashrc roda em todo shell aninhado, e
# sem ela cada um reprefixava o mesmo diretório. Tirar a linha inteira
# também resolvia a duplicação, mas de quebra tirava o único PATH que
# esses shells de fora tinham.
#
# Não cobre ssh nem tty2, e nunca cobriu: lá o shell é de login, e o
# ~/.bash_profile desta máquina não carrega este arquivo.
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) PATH="$HOME/.local/bin:$PATH" ;;
esac

# Uma linha, medida. Guardar o init em cache já esteve aqui: ele custa
# 1,1 ms e roda uma vez por shell, e a guarda que evitava gerá-lo custava
# 0,29 ms — economia de 0,8 ms, menos do que UM prompt, que custa 5 ms.
# Não pagava as sete linhas, o arquivo de cache, nem uma regra de validade
# por mtime que erra calada num downgrade do starship.
eval "$(starship init bash)"
