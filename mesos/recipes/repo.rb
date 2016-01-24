case node['platform_family']
when 'debian'
  include_recipe 'apt'

  apt_repository 'mesosphere' do
    uri "http://repos.mesosphere.io/#{node['platform']}"
    distribution node['lsb']['codename']
    keyserver 'hkp://keyserver.ubuntu.com:80'
    key 'E56151BF'
    components ['main']
  end
when 'rhel'
  include_recipe 'yum'

  version = case node['platform']
            when 'amazon' then '6'
            else node['platform_version'].split('.').first
            end
  yum_repository 'mesosphere' do
    description 'Mesosphere Packages for Enteprise Linux'
    baseurl "http://repos.mesosphere.io/el/#{version}/$basearch/"
    gpgkey 'https://repos.mesosphere.io/el/RPM-GPG-KEY-mesosphere'
  end
  yum_repository 'cloudera-cdh4' do
    description 'cloudera-cdh4'
    baseurl "http://archive.cloudera.com/cdh4/redhat/6/x86_64/cdh/4/"
    gpgkey 'http://archive.cloudera.com/cdh4/redhat/6/x86_64/cdh/RPM-GPG-KEY-cloudera'
  end
end
