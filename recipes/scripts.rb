# recipes/scripts.rb — utility scripts (installed via stow)

# Stow already creates symlinks from scripts/.local/bin → ~/.local/bin
# This file only ensures that the parent directory exists

directory home_path('.local') do
  owner USER
  mode  '755'
end

directory home_path('.local/bin') do
  owner USER
  mode  '755'
end
