# .dotfiles (mitamae + stow)

Configs gerenciadas com [mitamae](https://github.com/itamae-kitchen/mitamae) + [GNU Stow](https://www.gnu.org/software/stow/) no Arch Linux.

## Ferramentas incluídas

- **Hyprland** — window manager Wayland
- **Waybar** — barra de status
- **Kitty** — terminal
- **Wofi** — launcher
- **Starship** — prompt do shell
- **btop** — monitor de recursos
- **systemd** — serviços de usuário

## Instalação

```bash
git clone git@github.com:SEU_USER/.dotfiles ~/.dotfiles
cd ~/.dotfiles
chmod +x install.sh
./install.sh
```

O script baixa o mitamae automaticamente e aplica todas as recipes, **instalando automaticamente todas as configs via stow**.

## Debug

```bash
MITAMAE_LOG_LEVEL=debug ./install.sh
```

## Estrutura

```
.dotfiles/
├── install.sh          # Entry point — baixa mitamae e roda
├── base.rb             # Inclui todas as recipes
├── bin/                # Binário do mitamae (gerado pelo install.sh)
├── recipes/            # Uma recipe por categoria
│   ├── packages.rb     # Pacotes base (pacman + stow)
│   ├── stow.rb         # Gerencia symlinks dos dotfiles (automático)
│   ├── systemd.rb      # Serviços systemd do usuário
│   └── scripts.rb      # Diretório de scripts (instalado via stow)
├── hypr/.config/hypr/         # Configs do Hyprland (instaladas via stow)
├── waybar/.config/waybar/     # Configs do Waybar (instaladas via stow)
├── kitty/.config/kitty/       # Configs do Kitty (instaladas via stow)
├── wofi/.config/wofi/         # Configs do Wofi (instaladas via stow)
├── starship/.config/          # starship.toml (instalado via stow)
├── btop/.config/btop/         # Configs do btop (instaladas via stow)
├── systemd/.config/systemd/user/  # Serviços systemd
└── scripts/                   # Scripts em ~/.local/bin (instalados via stow)
```

## Como funciona

### 1. Instalação Automática de Pacotes
A recipe `recipes/packages.rb` instala todos os pacotes necessários via pacman, incluindo:
- Hyprland, Waybar, Kitty, Wofi, Starship, btop
- Dependências: pipewire, bluez, networkmanager, etc.
- **GNU Stow** (gerenciador de dotfiles)

### 2. Stow Instala Todas as Configs Automaticamente
A recipe `recipes/stow.rb` executa:
```bash
stow --no-folding -t ~/ hypr waybar kitty wofi starship btop scripts
```

Isso cria symlinks inteligentes:
- `hypr/.config/hypr` → `~/.config/hypr`
- `waybar/.config/waybar` → `~/.config/waybar`
- `kitty/.config/kitty` → `~/.config/kitty`
- `scripts/` → `~/.local/bin`
- etc.

**Tudo completamente automático!**

### 3. Serviços de Usuário
A recipe `recipes/systemd.rb` ativa serviços systemd do usuário (hypridle, etc)

## Remover Configs (se precisar)

Para desfazer stow:
```bash
cd ~/.dotfiles
stow --no-folding -t ~/ -D hypr waybar kitty wofi starship btop scripts
```

## Adicionando uma Nova Máquina

Crie um node file baseado no hostname:
```bash
mkdir -p nodes
# Seu node file aqui se precisar de customizações por máquina
```

