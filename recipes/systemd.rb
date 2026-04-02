# recipes/systemd.rb — enable user systemd services
#
# Service files are located in systemd/.config/systemd/user/
# Mitamae creates the symlink and then enables each service via systemctl --user

SYSTEMD_USER_DIR = home_path('.config/systemd/user')

directory SYSTEMD_USER_DIR do
  owner USER
  mode  '755'
end

link SYSTEMD_USER_DIR do
  to    dotfiles_path('systemd/.config/systemd/user')
  force true
end

# Reload daemon and enable services found in the directory
execute 'systemctl --user daemon-reload' do
  user USER
  environment({ 'DBUS_SESSION_BUS_ADDRESS' => "unix:path=/run/user/#{`id -u`.strip}/bus" })
end

# List all .service files in the directory and enable each one
service_files = Dir.glob(
  File.join(DOTFILES_DIR, 'systemd/.config/systemd/user', '*.service')
)

service_files.each do |svc_path|
  svc_name = File.basename(svc_path)

  execute "enable systemd user service: #{svc_name}" do
    command "systemctl --user enable #{svc_name}"
    not_if  "systemctl --user is-enabled #{svc_name} 2>/dev/null | grep -q enabled"
    user    USER
    environment({ 'DBUS_SESSION_BUS_ADDRESS' => "unix:path=/run/user/#{`id -u`.strip}/bus" })
  end
end
