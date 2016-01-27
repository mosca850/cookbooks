class Chef::Recipe
  include MesosHelper
end

include_recipe 'exhibitor::default'
include_recipe 'exhibitor::service'
include_recipe 'mesos::install'

# Mesos configuration validation
ruby_block 'mesos-master-configuration-validation' do
  block do
    # Get Mesos --help
    help = Mixlib::ShellOut.new("#{node['mesos']['master']['bin']} --help")
    help.run_command
    help.error!
    # Extract options
    options = help.stdout.strip.scan(/^  --(?:\[no-\])?(\w+)/).flatten - ['help']
    # Check flags are in the list
    node['mesos']['master']['flags'].keys.each do |flag|
      unless options.include?(flag)
        Chef::Application.fatal!("Invalid Mesos configuration option: #{flag}. Aborting!", 1000)
      end
    end
  end
end
# Marathon install
package 'marathon' do
  action :install
end
template 'marathon-init' do
  case node['mesos']['init']
  when 'systemd'
    path '/etc/systemd/system/marathon.service'
    source 'systemd.erb'
  when 'sysvinit_debian'
    mode 0755
    path '/etc/init.d/mesos-slave'
    source 'sysvinit_debian.erb'
  when 'upstart'
    path '/etc/init/mesos-slave.conf'
    source 'upstart.erb'
  end
  variables(name:    'marathon',
            wrapper: '/etc/marathon-chef/marathon')
end
# case node['platform_family']
# when 'debian'
#   package 'marathon' do
#     action :install
#   end
# when 'rhel'
#   yum_package 'marathon' do
#     action :install
#   end
# end

# ZooKeeper Exhibitor discovery
if node['mesos']['zookeeper_exhibitor_discovery'] && node['mesos']['zookeeper_exhibitor_url']
  zk_nodes = MesosHelper.discover_zookeepers_with_retry(node['mesos']['zookeeper_exhibitor_url'])

  if zk_nodes.nil?
    Chef::Application.fatal!('Failed to discover zookeepers. Cannot continue.')
  end

  node.override['mesos']['master']['flags']['zk'] = 'zk://' + zk_nodes['servers'].sort.map { |s| "#{s}:#{zk_nodes['port']}" }.join(',') + '/' + node['mesos']['zookeeper_path']
end

directory '/etc/marathon-chef'
# Mesos master configuration wrapper
template 'mesos-master-wrapper' do
  path '/etc/mesos-chef/mesos-master'
  owner 'root'
  group 'root'
  mode '0755'
  source 'wrapper.erb'
  variables(env:    node['mesos']['master']['env'],
            bin:    node['mesos']['master']['bin'],
            flags:  node['mesos']['master']['flags'],
            syslog: node['mesos']['master']['syslog'])
end

template 'marathon-wrapper' do
  path '/etc/marathon-chef/marathon'
  owner 'root'
  group 'root'
  mode '0755'
  source 'wrapper.erb'
  variables(env:    node['mesos']['marathon']['env'],
            bin:    node['mesos']['marathon']['bin'],
            flags:  node['mesos']['marathon']['flags'],
            syslog: node['mesos']['marathon']['syslog'])
end

# Mesos master service definition
service 'mesos-master' do
  case node['mesos']['init']
  when 'systemd'
    provider Chef::Provider::Service::Systemd
  when 'sysvinit_debian'
    provider Chef::Provider::Service::Init::Debian
  when 'upstart'
    provider Chef::Provider::Service::Upstart
  end
  supports status: true, restart: true
  subscribes :restart, 'template[mesos-master-init]'
  subscribes :restart, 'template[mesos-master-wrapper]'
  action [:enable, :start]
end

service 'marathon' do
  case node['mesos']['init']
  when 'systemd'
    provider Chef::Provider::Service::Systemd
  when 'sysvinit_debian'
    provider Chef::Provider::Service::Init::Debian
  when 'upstart'
    provider Chef::Provider::Service::Upstart
  end
  supports status: true, restart: true
  subscribes :restart, 'template[marathon-init]'
  subscribes :restart, 'template[marathon-wrapper]'
  action [:enable, :start]
end


