#
# Cookbook Name:: tomcat
# Recipe:: default
#
# Copyright 2010, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require 'etc'

include_recipe "java"

case node.platform
when "centos","redhat","fedora"
  include_recipe "jpackage"
end

tomcat_pkgs = value_for_platform(
  ["debian","ubuntu"] => {
    "default" => ["tomcat6","tomcat6-admin","libmysql-java"," libtcnative-1"]
  },
  ["centos","redhat","fedora"] => {
    "default" => ["tomcat6","tomcat6-admin-webapps"]
  },
  "default" => ["tomcat6"]
)
tomcat_pkgs.each do |pkg|
  package pkg do
    action :install
  end
end

service "tomcat" do
  service_name "tomcat6"
  case node["platform"]
  when "centos","redhat","fedora"
    supports :restart => true, :status => true
  when "debian","ubuntu"
    supports :restart => true, :reload => true, :status => true
  end
  action [:nothing]
end

case node["platform"]
when "centos","redhat","fedora"
  template "/etc/sysconfig/tomcat6" do
    source "sysconfig_tomcat6.erb"
    owner "root"
    group "root"
    mode "0644"
    notifies :restart, resources(:service => "tomcat")
  end
else  
  template "/etc/default/tomcat6" do
    source "default_tomcat6.erb"
    owner "root"
    group "root"
    mode "0644"
    notifies :restart, resources(:service => "tomcat")
  end
end

case node["platform"]
  when "ubuntu"
    link "#{node['tomcat']['home']}/lib/mysql-connector-java.jar" do
      to "/usr/share/java/mysql-connector-java.jar"
      notifies :restart, resources(:service => "tomcat")
    end
    execute "change-tomcat-webapps-user" do
      command "chown -R #{node["tomcat"]["user"]}:#{node["tomcat"]["group"]} #{node["tomcat"]["webapp_dir"]}"
# this must be done for each war file and directory in the folder not just the base folder to give tomcat full control of its apps
#      not_if do
#        cstats = ::File.stat(node["tomcat"]["webapp_dir"])
#        Etc.getpwnam(node["tomcat"]["user"]).uid == cstats.uid && Etc.getgrnam(node["tomcat"]["group"]).gid == cstats.gid
#      end
    end
    execute "change-tomcat-home-user" do
      command "chown #{node["tomcat"]["user"]}:#{node["tomcat"]["group"]} #{node["tomcat"]["home"]}"
      not_if do
        cstats = ::File.stat(node["tomcat"]["home"])
        Etc.getpwnam(node["tomcat"]["user"]).uid == cstats.uid && Etc.getgrnam(node["tomcat"]["group"]).gid == cstats.gid
      end
    end
end

link "#{node['tomcat']['home']}/logs" do
  to node['tomcat']['log_dir']
end

template "/etc/tomcat6/server.xml" do
  source "server.xml.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, resources(:service => "tomcat")
end

template "/etc/tomcat6/tomcat-users.xml" do
  source "tomcat-users.xml.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, resources(:service => "tomcat"),:immediately
end

service "tomcat" do
  service_name "tomcat6"
  action [:enable, :start]
end
