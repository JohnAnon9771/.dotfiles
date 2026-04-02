# nodes/archlinux.rb — Node file for Arch Linux hosts
#
# Rename this file to your machine's hostname:
#   mv nodes/archlinux.rb nodes/$(hostname).rb
#
# Include base.rb which contains common recipes

include_recipe File.expand_path('../base.rb', __dir__)