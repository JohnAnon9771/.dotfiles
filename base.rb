# base.rb — main entry point for mitamae
# Includes all recipes common to any Arch machine

DOTFILES_DIR = File.expand_path(__dir__)
HOME_DIR     = ENV['HOME']
USER         = ENV['USER']

# Helper: expands path relative to dotfiles directory
def dotfiles_path(*parts)
  File.join(DOTFILES_DIR, *parts)
end

# Helper: expands path in HOME directory
def home_path(*parts)
  File.join(HOME_DIR, *parts)
end

# Base system packages
include_recipe dotfiles_path('recipes/packages.rb')

# Stow to manage dotfile symlinks (automatically)
include_recipe dotfiles_path('recipes/stow.rb')

# Systemd user services
include_recipe dotfiles_path('recipes/systemd.rb')
