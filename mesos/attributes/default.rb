
# Default Java version
default['java']['jdk_version'] = '8'

# Use Mesosphere repo
default['mesos']['repo']       = true

# Mesosphere Mesos version.
default['mesos']['version']    = '0.25.0'

# Init system to use
default['mesos']['init']       = case node['platform']
                                 when 'debian'
                                   node['platform_version'].to_i >= 8 ? 'systemd' : 'sysvinit_debian'
                                 when 'ubuntu'
                                   node['platform_version'].to_f >= 15.04 ? 'systemd' : 'upstart'
                                 when 'redhat', 'centos', 'scientific' # ~FC024
                                   node['platform_version'].to_i >= 7 ? 'systemd' : 'upstart'
                                 else 'upstart'
                                 end

#
# Mesos MASTER configuration
#
default['mesos']['marathon']['env']['ULIMIT']         = '-n 16384'
default['mesos']['marathon']['bin']                   = '/usr/bin/marathon run_jar'
default['mesos']['marathon']['syslog']                = '/var/log/marathon'
default['mesos']['marathon']['flags']['http_port']    = 8000
# Mesos master binary location.
default['mesos']['master']['bin']                   = '/usr/sbin/mesos-master'

# Environmental variables set before calling the mesos master process.
default['mesos']['master']['env']['ULIMIT']         = '-n 16384'

# Send stdout and stderr to syslog.
default['mesos']['master']['syslog']                = true

# Mesos master command line flags.
# http://mesos.apache.org/documentation/latest/configuration/
default['mesos']['master']['flags']['port']          = 5050
default['mesos']['master']['flags']['log_dir']       = '/var/log/mesos'
default['mesos']['master']['flags']['logging_level'] = 'INFO'
default['mesos']['master']['flags']['cluster']       = 'MyMesosCluster'
default['mesos']['master']['flags']['work_dir']      = '/tmp/mesos'
default['mesos']['master']['flags']['quorum']        = 2
default['mesos']['master']['flags']['ip']            = node['ipaddress']

#
# Mesos SLAVE configuration
#

# Mesos slave binary location.
default['mesos']['slave']['bin']                    = '/usr/sbin/mesos-slave'

# Environmental variables set before calling the mesos-slave process.
default['mesos']['slave']['env']['ULIMIT']          = '-n 16384'

# Send stdout and stderr to syslog.
default['mesos']['slave']['syslog']                 = true

# Mesos slave command line flags
# http://mesos.apache.org/documentation/latest/configuration/
default['mesos']['slave']['flags']['port']          = 5051
default['mesos']['slave']['flags']['log_dir']       = '/var/log/mesos'
default['mesos']['slave']['flags']['logging_level'] = 'INFO'
default['mesos']['slave']['flags']['work_dir']      = '/tmp/mesos'
default['mesos']['slave']['flags']['isolation']     = 'posix/cpu,posix/mem'
# default['mesos']['slave']['flags']['master']        = 'localhost:5050'
default['mesos']['slave']['flags']['strict']        = true
default['mesos']['slave']['flags']['recover']       = 'reconnect'
default['mesos']['slave']['flags']['containerizers'] = 'docker,mesos'
  
# Workaround for setting default cgroups hierarchy root
if node['mesos']['init'] == 'systemd'
  default['mesos']['slave']['flags']['cgroups_hierarchy'] = '/sys/fs/cgroup'
else
  default['mesos']['slave']['flags']['cgroups_hierarchy'] = '/cgroup'
end

default['mesos']['slave']['flags']['ip']            = node['ipaddress']

# Use the following options if you are using Exhibitor to manage Zookeeper
# in your environment.

# Zookeeper path that Mesos will use to write to.
default['mesos']['zookeeper_path']                      = 'mesos'

# Flag to enable Zookeeper ensemble discovery via Netflix Exhibitor.
default['mesos']['zookeeper_exhibitor_discovery']       = true

# Netflix Exhibitor ZooKeeper ensemble url.
override['exhibitor']['cli']['configtype'] = 's3'
override['exhibitor']['cli']['s3config'] = 'tt-mesos-cluster-ventu:master'
override['exhibitor']['cli']['s3region'] = 'eu-west-1'
override[:zookeeper][:version] = '3.4.6'
override[:zookeeper][:mirror] = 'http://www.eu.apache.org/dist/zookeeper/'
#override['zookeeper']['install_dir'] = ""

