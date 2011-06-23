#
# Cookbook Name:: application
# Recipe:: java
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

define :application_java_webapp do
  app = node.run_state[:current_app]

  ###
  # You really most likely don't want to run this recipe from here - let the
  # default application recipe work it's mojo for you.
  ###

  node.default[:apps][app['id']][node.app_environment][:run_migrations] = false

  ## First, install any application specific packages
  if app['packages']
    app['packages'].each do |pkg,ver|
      package pkg do
        action :install
        version ver if ver && ver.length > 0
      end
    end
  end

  directory app['deploy_to'] do
    owner app['owner']
    group app['group']
    mode '0755'
    recursive true
  end

  directory "#{app['deploy_to']}/releases" do
    owner app['owner']
    group app['group']
    mode '0755'
    recursive true
  end

  directory "#{app['deploy_to']}/shared" do
    owner app['owner']
    group app['group']
    mode '0755'
    recursive true
  end

  %w{ log pids system }.each do |dir|

    directory "#{app['deploy_to']}/shared/#{dir}" do
      owner app['owner']
      group app['group']
      mode '0755'
      recursive true
    end

  end

  # do we have a database configured for this environment?
  if app['databases'] && app['databases'][node.app_environment]
    if app["database_master_role"]
      dbm = nil
      # If we are the database master
      if node.roles.include?(app["database_master_role"][0])
        dbm = node
      else
      # Find the database master
        results = search(:node, "run_list:role\\[#{app["database_master_role"][0]}\\] AND app_environment:#{node[:app_environment]}", nil, 0, 1)
        rows = results[0]
        if rows.length == 1
          dbm = rows[0]
        end
      end

      # Assuming we have one...
      if dbm
        template "#{app['deploy_to']}/shared/#{app['id']}.xml" do
          cookbook "application"
          source "context.xml.erb"
          owner app["owner"]
          group app["group"]
          mode "644"
          template_vars = {
              :host => dbm['fqdn'],
              :app => app['id'],
              :database => app['databases'][node.app_environment],
              :war => "#{app['deploy_to']}/releases/#{app['war'][node.app_environment]['checksum']}.war",
          }
          template_vars[:path] = app['path'] if app['path']
          template_vars[:privileged] = true if app['privileged']
          variables(template_vars)
        end
      end
    end
    # no database required. same template, other data (maybe do it another way?)
  else
    template "#{app['deploy_to']}/shared/#{app['id']}.xml" do
      cookbook "application"
      source "context.xml.erb"
      owner app["owner"]
      group app["group"]
      mode "644"
      template_vars = {
          :app => app['id'],
          :war => "#{app['deploy_to']}/releases/#{app['war'][node.app_environment]['checksum']}.war",
      }
      template_vars[:path] = app['path'] if app['path']
      template_vars[:privileged] = true if app['privileged']
      variables(template_vars)
    end
  end

  ## Then, deploy
  if app['war'][node.app_environment]['source'] =~ /^http/
    remote_file app['id'] do
      path "#{app['deploy_to']}/releases/#{app['war'][node.app_environment]['checksum']}.war"
      source app['war'][node.app_environment]['source']
      mode "0644"
      checksum app['war'][node.app_environment]['checksum']
    end
  elsif app['war'][node.app_environment]['source'] =~ /^file/
    execute app['id'] do
      command "cp #{app['war'][node.app_environment]['source'].gsub("file://","")} #{app['deploy_to']}/releases/#{app['war'][node.app_environment]['checksum']}.war"
      creates "#{app['deploy_to']}/releases/#{app['war'][node.app_environment]['checksum']}.war"
    end
  end
end