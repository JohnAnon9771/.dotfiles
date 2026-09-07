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
fonts/       Cormorant, Silkscreen e UnifrakturMaguntia (SIL OFL)
hypr/        Hyprland, em Lua (0.55+)
kitty/       terminal
opencode/    tema do agente de código
quickshell/  o torreão
scripts/     gamer-vt, gamer-mode, keep-shot, keep-session
starship/    prompt
systemd/     a unit do torreao, ligada em graphical-session.target
uwsm/        as envs da sessão gráfica, e o PATH que os binds precisam
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
    bash btop fonts hypr kitty opencode quickshell \
    scripts starship systemd uwsm

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
e é espelhada, por gerador, no Hyprland, no kitty, no starship, no btop
e no opencode. Dessincronizar dá erro: `tools/theme-sync.py`.

São **nove**, e são os únicos hexes escritos à mão no castelo inteiro:

| | | |
|---|---|---|
| `#0a0908` carvão | `#6d6a63` cinza | `#c9a24a` **ouro velho** |
| `#1c1a17` pedra | `#6e1420` **sangue seco** | `#e8dcc0` pergaminho |
| `#241a12` madeira | `#3a3630` fio de luz | `#8b6bd9` **espectral** |

Todo o resto é derivado deles por `mix()`, para nada entrar na família
por acidente:

| | | |
|---|---|---|
| `#201a14` salão | `#44423d` adormecido | `#e3c37a` ouro aceso |
| `#56544e` ferro | `#b1a996` cinza claro | `#a06237` **brasa** |
| `#261f36` véspera | `#f1ead9` marfim | `#9f6460` sangue legível |
| | | `#ac93d0` espectral aceso |

**Três leis, e são leis.** Ouro só em foco e estado ativo. Vermelho só
em risco real. Violeta é do sobrenatural, e nunca decorativo.

Não há verde nem azul. Uma máquina ociosa pintada de verde e um link
pintado de azul dizem *isto aqui é um dashboard*, e o castelo deixa de
ser um castelo.

Escala de estado, do sono ao pânico — e monocromática até 60%, porque o
que está bem simplesmente não chama:

```
adormecido → bom  → info  → normal    → atenção → alerta → crítico
dim          ash    cinza   parchment   gold      ember    scar
```

**Quatro vozes tipográficas.** UnifrakturMaguntia só para capitulares e
brasões, e nunca abaixo de 18px. Cormorant Garamond para o que é escrito
— prosa, epitáfios, relógio. JetBrains Mono para todo dado. E Silkscreen
para os algarismos romanos e os microrrótulos, porque eles encostam em
pixel art e uma haste inteira encaixa ali melhor que uma serifa.

Nenhum glifo cai em fonte de reserva, e isso é testado: o
`tools/glyph-audit.py` lê o `cmap` de cada TTF versionado e confere tanto
os codepoints da `Theme.glyph` quanto o alfabeto que cada voz precisa
cobrir sozinha. Ele existe porque a tabela já errou em silêncio duas
vezes — um codepoint errado na Nerd Font não vira tofu, vira o ícone
errado.

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
