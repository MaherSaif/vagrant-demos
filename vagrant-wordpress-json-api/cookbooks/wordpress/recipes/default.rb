#
# Cookbook Name:: wordpress
# Recipe:: default
#
# Copyright 2009-2010, Opscode, Inc.
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

include_recipe "apache2"

if node.has_key?("ec2")
  server_fqdn = node.ec2.public_hostname
else
  server_fqdn = node.fqdn
end 
server_port = ""
if node.has_key?("wordpress_hostname")
  server_fqdn = node.wordpress_hostname 
  server_port = ":#{node[:vagrant][:config][:vm][:forwarded_ports][:web][:hostport]}"
end  

remote_file "#{Chef::Config[:file_cache_path]}/wordpress-#{node[:wordpress][:version]}.tar.gz" do
  checksum node[:wordpress][:checksum]
  source "http://wordpress.org/wordpress-#{node[:wordpress][:version]}.tar.gz"
  mode "0644"
end

directory "#{node[:wordpress][:dir]}" do
  owner "root"
  group "root"
  mode "0755"
  action :create
end

execute "untar-wordpress" do
  cwd node[:wordpress][:dir]
  command "tar --strip-components 1 -xzf #{Chef::Config[:file_cache_path]}/wordpress-#{node[:wordpress][:version]}.tar.gz"
  creates "#{node[:wordpress][:dir]}/wp-settings.php"
end

execute "mysql-install-wp-privileges" do
  command "/usr/bin/mysql -u root -p#{node[:mysql][:server_root_password]} < /etc/mysql/wp-grants.sql"
  action :nothing
end

include_recipe "mysql::server"
require 'rubygems'
Gem.clear_paths
require 'mysql'

template "/etc/mysql/wp-grants.sql" do
  path "/etc/mysql/wp-grants.sql"
  source "grants.sql.erb"
  owner "root"
  group "root"
  mode "0600"
  variables(
    :user     => node[:wordpress][:db][:user],
    :password => node[:wordpress][:db][:password],
    :database => node[:wordpress][:db][:database]
  )
  notifies :run, resources(:execute => "mysql-install-wp-privileges"), :immediately
end

execute "create #{node[:wordpress][:db][:database]} database" do
  command "/usr/bin/mysqladmin -u root -p#{node[:mysql][:server_root_password]} create #{node[:wordpress][:db][:database]}"
  not_if do
    m = Mysql.new("localhost", "root", node[:mysql][:server_root_password])
    m.list_dbs.include?(node[:wordpress][:db][:database])
  end
end

# save node data after writing the MYSQL root password, so that a failed chef-client run that gets this far doesn't cause an unknown password to get applied to the box without being saved in the node data.
#ruby_block "save node data" do
#  block do
#    node.save
#  end
#  action :create
#end

log "Navigate to 'http://#{server_fqdn}#{server_port}/wp-admin/install.php' to complete wordpress installation" do
  action :nothing
end

template "#{node[:wordpress][:dir]}/wp-config.php" do
  source "wp-config.php.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    :database        => node[:wordpress][:db][:database],
    :user            => node[:wordpress][:db][:user],
    :password        => node[:wordpress][:db][:password],
    :auth_key        => node[:wordpress][:keys][:auth],
    :secure_auth_key => node[:wordpress][:keys][:secure_auth],
    :logged_in_key   => node[:wordpress][:keys][:logged_in],
    :nonce_key       => node[:wordpress][:keys][:nonce]
  )
  notifies :write, resources(:log => "Navigate to 'http://#{server_fqdn}#{server_port}/wp-admin/install.php' to complete wordpress installation")
end

include_recipe %w{php::php5 php::module_mysql}

web_app "wordpress" do
  template "wordpress.conf.erb"
  docroot "#{node[:wordpress][:dir]}"
  server_name server_fqdn
  server_aliases node.fqdn
end 

cookbook_file File.join(node[:wordpress][:dir],".htaccess") do
  source "dot.htaccess" 
  mode "0644"
end  

remote_file "#{Chef::Config[:file_cache_path]}/json-api.1.0.7.zip" do
  source "http://downloads.wordpress.org/plugin/json-api.1.0.7.zip"
  mode "0644"
  checksum "be94942e19450ec8c31e022aa514972baad9a538a475c73dccc4a77eb050e00e"
end  

execute "unzip-json-api" do
  cwd File.join(node[:wordpress][:dir],"wp-content/plugins")
  command "unzip #{Chef::Config[:file_cache_path]}/json-api.1.0.7.zip"
  creates "#{node[:wordpress][:dir]}/wp-content/plugins/json-api/readme.txt"
end

cookbook_file File.join(node[:wordpress][:dir],"wp-content/plugins/json-api/controllers/posts.php") do
  source "json-api_controllers_posts.php" 
  mode "0644"
end

cookbook_file File.join(node[:wordpress][:dir],"wp-content/plugins/json-api/models/post.php") do
  source "json-api_models_post.php" 
  mode "0644"
end

remote_file "#{Chef::Config[:file_cache_path]}/paragrams.zip" do
  source "http://wpshower.com/paragrams.zip"
  mode "0644"
end

execute "unzip-paragrams" do
  cwd node[:wordpress][:dir]
  command "unzip #{Chef::Config[:file_cache_path]}/paragrams.zip"
  creates "#{node[:wordpress][:dir]}/wp-content/themes/paragrams/functions.php"
end 

cookbook_file File.join(node[:wordpress][:dir],"wp-content/themes/paragrams/functions.php") do
  source "paragrams_functions.php" 
  mode "0644"                         
  checksum "d3b9a8f5561000608c83f45b8df56feba28638974588afe681e796ad10fa33b5"
end   














# drive wordpress install from chef
# %W{libxslt1-dev libxml2-dev}.each do |pkg|
#   p = package pkg do
#     action :nothing                                     
#   end            
#   p.run_action(:install)    
# end  
# 
# r = gem_package "mechanize" do
#   action :nothing
# end
# 
# r.run_action(:install)    
# 
# begin
#   require 'mechanize'
# rescue LoadError
#   Chef::Log.warn("Missing gem 'mechanize'")
# end     
# 
# ruby_block "setup wordpress for demo" do
#   block do
# 
#     end
#   end
#   action :create
# end





