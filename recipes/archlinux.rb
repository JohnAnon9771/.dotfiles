# nodes/my-machine.rb
#
# Rename this file to your machine's hostname:
#   mv nodes/my-machine.rb nodes/$(hostname).rb
#
# Here you can override or add recipes specific to this machine,
# in addition to including base.rb

include_recipe File.expand_path('../base.rb', __dir__)

# Example: install something only on this machine
package 'firefox' do
  action :install
end
