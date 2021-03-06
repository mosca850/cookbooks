class Chef::Recipe
  include MesosHelper
end

include_recipe 'mesos::install'
# Mesos configuration validation
ruby_block 'mesos-slave-configuration-validation' do
  block do
    # Get Mesos --help
    help = Mixlib::ShellOut.new("#{node['mesos']['slave']['bin']} --help")
    help.run_command
    help.error!
    # Extract options
    options = help.stdout.strip.scan(/^  --(?:\[no-\])?(\w+)/).flatten - ['help']
    # Check flags are in the list
    node['mesos']['slave']['flags'].keys.each do |flag|
      unless options.include?(flag)
        Chef::Application.fatal!("Invalid Mesos configuration option: #{flag}. Aborting!", 1000)
      end
    end
  end
end

# ZooKeeper Exhibitor discovery
if node['mesos']['zookeeper_exhibitor_discovery'] && node['mesos']['zookeeper_exhibitor_url']
  zk_nodes = MesosHelper.discover_zookeepers_with_retry(node['mesos']['zookeeper_exhibitor_url'])
  node.override['mesos']['slave']['flags']['master'] = 'zk://' + zk_nodes['servers'].map { |s| "#{s}:#{zk_nodes['port']}" }.join(',') + '/' + node['mesos']['zookeeper_path']
end

# this directory doesn't exist on newer versions of Mesos, i.e. 0.21.0+
directory '/usr/local/var/mesos/deploy/' do
  recursive true
end

# Mesos slave configuration wrapper
template 'mesos-slave-wrapper' do
  path '/etc/mesos-chef/mesos-slave'
  owner 'root'
  group 'root'
  mode '0755'
  source 'wrapper.erb'
  variables(env:    node['mesos']['slave']['env'],
            bin:    node['mesos']['slave']['bin'],
            flags:  node['mesos']['slave']['flags'],
            syslog: node['mesos']['slave']['syslog'])
end

# Mesos master service definition
service 'mesos-slave' do
  case node['mesos']['init']
  when 'systemd'
    provider Chef::Provider::Service::Systemd
  when 'sysvinit_debian'
    provider Chef::Provider::Service::Init::Debian
  when 'upstart'
    provider Chef::Provider::Service::Upstart
  end
  supports status: true, restart: true
  subscribes :restart, 'template[mesos-slave-init]'
  subscribes :restart, 'template[mesos-slave-wrapper]'
  action [:enable, :start]
end
package 'docker' do
  action :install
  notifies :run, 'execute[app_requires_reboot]', :immediately
end
execute 'app_requires_reboot' do
  command "shutdown -r now"
  action :nothing
end
