name             'mesos'
maintainer       'YOUR_NAME'
maintainer_email 'YOUR_EMAIL'
license          'All rights reserved'
description      'Installs/Configures mesos'
long_description 'Installs/Configures mesos'
version          '0.1.0'
%w( java apt ).each do |cb|
  depends cb
end
depends 'yum', '~> 3.0'
depends 'exhibitor'