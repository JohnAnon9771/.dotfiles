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
- **Distrobox** — containers de desenvolvimento

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
├── base.rb             # Inclui todas as recipes base
├── nodes/              # Node files por máquina
│   └── archlinux.rb   # Node para máquinas Arch Linux
├── recipes/            # Uma recipe por categoria
│   ├── packages.rb     # Pacotes base (pacman)
│   ├── stow.rb         # Gerencia symlinks dos dotfiles (automático)
│   ├── systemd.rb      # Serviços systemd do usuário
│   └── scripts.rb      # Scripts (via stow)
├── hypr/.config/hypr/         # Configs do Hyprland (via stow)
├── waybar/.config/waybar/     # Configs do Waybar (via stow)
├── kitty/.config/kitty/       # Configs do Kitty (via stow)
├── wofi/.config/wofi/         # Configs do Wofi (via stow)
├── starship/.config/          # starship.toml (via stow)
├── btop/.config/btop/         # Configs do btop (via stow)
└── systemd/.config/systemd/user/  # Serviços systemd
```

## Node Files

Omitamae detecta o hostname da máquina e usa o node file correspondente:
- `nodes/<hostname>.rb` — configuração específica da máquina
- Se não encontrar, usa `nodes/archlinux.rb` como fallback

Para criar um node file específico:
```bash
cp nodes/archlinux.rb nodes/<seu-hostname>.rb
```

## Como funciona

### 1. Instalação Automática de Pacotes
A recipe `recipes/packages.rb` instala todos os pacotes necessários via pacman, incluindo:
- Hyprland, Waybar, Kitty, Wofi, Starship, btop, Distrobox
- Dependências: pipewire, bluez, networkmanager, etc.
- **GNU Stow** (gerenciador de dotfiles)

### 2. Stow Instala Todas as Configs Automaticamente
A recipe `recipes/stow.rb` executa:
```bash
stow --no-folding -t ~/ hypr waybar kitty wofi starship btop scripts
```

### 3. Serviços de Usuário
A recipe `recipes/systemd.rb` ativa serviços systemd do usuário

## Remover Configs (se precisar)

Para desfazer stow:
```bash
cd ~/.dotfiles
stow --no-folding -t ~/ -D hypr waybar kitty wofi starship btop scripts
```