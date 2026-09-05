# O Torreão

Configuração de um Arch com Hyprland, num tema gótico-medieval.

Um castelo abandonado que ainda acende as tochas.

```
╭─────────────────────────────────────────────────────────────╮
│ † ARCHLINUX †   I II III IV    nvim — Theme.qml             │
│   cpu 42%  gpu 71%  ram 12G  58°  707G  ↓1.5K/s   ♫  23:47  │
╰┐┌──┐┌──┐┌──┐┌──┐┌──┐┌──┐┌──┐┌──┐┌──┐┌──┐┌──┐┌──┐┌──┐┌──┐┌──┐╯
```

## O que é

Um shell só, escrito em [Quickshell](https://quickshell.org), cobrindo
o que antes eram quatro programas:

| Superfície | Faz o quê | Substituiu |
|---|---|---|
| **A Muralha** | Barra: workspaces, CPU, GPU, RAM, temperatura, discos, rede, bandeja, mídia, som, notificações, relógio | waybar |
| **O Grimório** | Lançador com oito modos | wofi |
| **O Grande Salão** | Central de controle: sistema a fundo, áudio, wifi, bluetooth, cripta, sigilos, almanaque | — |
| **O Ossuário** | Menu de energia com segurar-para-confirmar | um scroll na barra |
| **Pergaminhos** | Notificações | — (não havia daemon) |
| **A Lápide** | Aviso rápido de volume, mudo, silêncio | — |
| **O Portão** | Bloqueio de tela | — (a máquina nunca trancava) |
| **O Selo** | Diálogo de autenticação | polkit-gnome |
| **A Névoa** | Papel de parede | hyprpaper |

## Estrutura

```
bash/        .bash_profile — o tty1 abre a sessao, o tty3 o modo jogo
btop/        tema dark-medieval do monitor de recursos
environment.d/ o PATH da sessão gráfica
fonts/       Cinzel e UnifrakturMaguntia (SIL OFL), versionadas
hypr/        Hyprland, em Lua (0.55+)
kitty/       terminal
opencode/    tema do agente de código
quickshell/  o torreão
scripts/     gamer-vt, gamer-mode, keep-shot, keep-session
starship/    prompt
systemd/     a unit do torreao, ligada em graphical-session.target
tools/       lint e testes — não é pacote stow
```

Este repositório **é** a configuração viva: `~/.config/hypr`, `kitty`,
`btop`, `starship.toml` e afins são links simbólicos para cá. Editar um
arquivo aqui muda o sistema na hora.

## Instalar

```sh
# Pacotes
sudo pacman -S --needed quickshell hyprland uwsm kitty btop starship stow \
    grim slurp wl-clipboard playerctl \
    pipewire pipewire-pulse wireplumber \
    networkmanager bluez bluez-utils \
    ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji \
    xdg-desktop-portal-hyprland

# Links
stow -t "$HOME" --no-folding \
    bash btop environment.d fonts hypr kitty opencode quickshell \
    scripts starship systemd

fc-cache -f
```

O `quickshell` está no repositório **extra** — não precisa de AUR.

Saem da lista: `waybar`, `wofi`, `hyprpaper`, `polkit-gnome`. O torreão
faz o trabalho dos quatro.

### A sessão

Este sistema usa **uwsm**, que monta uma sessão systemd de verdade em
volta do Hyprland. Nela, componente de sessão sobe por *unit* — não por
`exec-once`. Assim herda o ambiente que o uwsm exportou, cai na fatia
certa, reinicia sozinho se morrer, e é encerrado junto com a sessão em
vez de virar processo órfão.

```sh
systemctl --user daemon-reload
systemctl --user enable --now quickshell-keep.service
```

Se a máquina vem de um setup anterior, o `hyprpaper` **precisa sair** —
não basta desabilitar a unit: a Névoa desenha o papel de parede na mesma
camada de fundo, e os dois juntos brigam pelo espaço.

O compositor só dá a partida, em `autostart.lua`: chama `keep-session`,
que decide entre `uwsm finalize` — é ele que libera o
`graphical-session.target`, e com isso as units — e subir o torreão à
mão, quando não há systemd por trás.

```sh
systemctl --user status quickshell-keep    # como está
journalctl --user -fu quickshell-keep      # o log
systemctl --user reload quickshell-keep    # recarrega sem derrubar
```

## Rodar

```sh
qs -c keep            # em primeiro plano, com log no terminal
qs list --all         # instâncias vivas
qs log -f             # seguir o log de uma delas
qs -c keep ipc show   # o que dá para pedir ao shell

# Com mais de uma instância no ar, escolha a sua:
qs ipc --pid 12345 call keep hall
```

O shell recarrega sozinho ao salvar um arquivo.

## Teclas

| Tecla | O quê |
|---|---|
| `SUPER + SPACE` | Grimório |
| `SUPER + A` | Grande Salão |
| `SUPER + N` | Cripta · `SHIFT+N` silêncio |
| `SUPER + ESCAPE` | Ossuário |
| `SUPER + CTRL + L` | Trancar |
| `SUPER + C` | Almanaque |
| `SUPER + T` `B` `M` `G` | kitty · firefox · btop · modo jogo |
| `SUPER + Q` `V` `F` `P` `J` | fechar · flutuar · tela cheia · pseudo · split |
| `SUPER + 1..0` | Salões · `SHIFT` move a janela |
| `SUPER + S` | Scratchpad |
| `SUPER + setas` | Foco · `SHIFT` move · `CTRL` redimensiona |
| `F8` `SHIFT+F8` `CTRL+F8` | Capturar região · tela · janela |
| `SUPER + SHIFT + I` | Vigília eterna (não deixa dormir) |
| `SUPER + SHIFT + B` | Véu de âmbar (modo noturno) |
| `SUPER + SHIFT + R` | Reerguer o torreão |

### Sigilos do Grimório

| Prefixo | Modo |
|---|---|
| *(nenhum)* | Aplicativos |
| `>` | Comandos |
| `=` | Aritmancia |
| `/` | Arquivos |
| `:` | Janelas abertas |
| `;` | Símbolos, copia ao escolher |
| `!` | Trancar, dormir, desligar |
| `?` | Ajuda |

## O tema

A paleta canônica vive em `quickshell/.config/quickshell/keep/Theme.qml`
e é espelhada em `hypr/.config/hypr/theme.lua`.

| | | |
|---|---|---|
| `#15120f` pedra | `#dcd4c4` pergaminho | `#c2a35a` **ouro envelhecido** |
| `#1b1813` salão | `#f4f0e6` marfim | `#e1c97a` ouro aceso |
| `#3a3127` madeira | `#6f6559` pedra gasta | `#c9743a` **brasa** |
| `#7a736b` ferro | `#4f6b4a` musgo | `#b04b4b` **sangue seco** |
| `#3b2f45` véspera | `#86b39a` **fogo-fátuo** | `#8b6f9b` roxo realeza |
| `#4a6b66` azinhavre | `#3a8f8f` teal | `#1e9fb4` água do fosso |

Escala de estado, do sono ao pânico:

```
adormecido → normal → bom → info → atenção → alerta → crítico
verdigris   parchment  moss   moat    gold     ember    blood
```

**Três vozes tipográficas.** Cinzel para o que é entalhado (títulos,
algarismos romanos, relógio), UnifrakturMaguntia só para capitulares e
brasões, JetBrains Mono para todo dado. Nenhum glifo cai em fonte de
reserva: a iconografia usa codepoints Nerd Font conferidos, listados em
`Theme.glyph`.

**O castelo tem clima.** As cores respondem à carga da máquina: em
repouso cada módulo guarda a sua cor de identidade; conforme a pressão
passa de 60% ela desliza para a escala de estado, as tochas queimam mais
forte e a brasa sobe pelas ameias. Às três da manhã a paleta esfria em
direção ao espectral.

## Ferramentas

```sh
./tools/lint-qml.sh       # valida o QML contra os tipos reais do Quickshell
./tools/test-parsers.sh   # 70+ testes dos parsers de /proc e da busca
lua tools/test-hypr.lua   # executa a config do Hyprland e imprime cada bind
```

O `lint-qml.sh` monta uma árvore-espelho em `/tmp` com os `qmldir` que o
Quickshell sintetizaria em tempo de execução — escrever um `qmldir` no
repositório **desliga** essa síntese, então eles não existem aqui.

## Voltar atrás

Não há caminho de volta configurado, e é de propósito. A `waybar`, o
`wofi` e o `polkit-gnome` saíram da máquina; o `hyprland.conf` antigo,
os pacotes `waybar/` e `wofi/` e a unit do `hyprpaper` saíram do repo.
Enquanto existiam, prometiam um rollback que já não funcionava: metade
apontava para binário desinstalado.

O caminho de volta é o `git` — o commit anterior à migração tem tudo, e
os pacotes precisariam ser reinstalados junto.
