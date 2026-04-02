# recipes/packages.rb — base system packages (pacman)

PACMAN_PACKAGES = %w[
  hyprland
  waybar
  kitty
  wofi
  starship
  btop
  stow
  git
  base-devel
  curl
  wget
  pipewire
  pipewire-pulse
  wireplumber
  xdg-desktop-portal-hyprland
  polkit-gnome
  grim
  slurp
  wl-clipboard
  networkmanager
  bluez
  bluez-utils
  ttf-jetbrains-mono-nerd
  noto-fonts
  noto-fonts-emoji
  distrobox
]

PACMAN_PACKAGES.each do |pkg|
  package pkg do
    action :install
  end
end
