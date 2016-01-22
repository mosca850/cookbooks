#
# Cookbook Name:: mesos-master
# Recipe:: default
#
# Copyright (C) 2016 YOUR_NAME
#
# All rights reserved - Do Not Redistribute
#
include_recipe 'exhibitor::default'
include_recipe 'mesos::master'
