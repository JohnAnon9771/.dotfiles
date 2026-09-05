# recipes/stow.rb — GNU Stow automatically manages dotfiles

# Ensure stow is installed
package 'stow' do
  action :install
end

# Stow packages — each directory is a package that will be "stowed"
# Structure: hypr/.config/hypr → ~/.config/hypr, etc.
STOW_PACKAGES = %w[
  hypr
  waybar
  kitty
  wofi
  starship
  btop
  scripts
].join(' ')

# Execute stow to create all symlinks automatically
execute 'Install dotfiles with stow' do
  command "cd '#{DOTFILES_DIR}' && stow --no-folding -t '#{HOME_DIR}' -S #{STOW_PACKAGES}"
  user USER
  # Ignore error if already stowed before
  ignore_failure true
end
