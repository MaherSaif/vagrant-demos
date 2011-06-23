#
# Cookbook Name:: tomcat
# Provider: tomcat_context
#
# Copyright 2011, Edmund Haselwanter
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

require 'chef/mixin/checksum' 
require 'digest'   
require "rexml/document"

include Chef::Mixin::Checksum

def initialize(*args)
  super
  @action = :nothing
  @tomcat_manager = TomcatManager.new :host => @new_resource.host,
          :port => @new_resource.port,
          :admin => @new_resource.admin,
          :password => @new_resource.password,
          :path => @new_resource.context_name,
          :war => @new_resource.war,
          :name => @new_resource.name,
          :tag => @new_resource.tag,
          :config => @new_resource.config
end


def load_current_resource
  @context = Chef::Resource::TomcatContext.new(new_resource.name)
  @context.context_name(new_resource.context_name)
  war_name = new_resource.context_name == "/" ? "ROOT" : new_resource.context_name.gsub("/","")
  war_file = ::File.join(node["tomcat"]["webapp_dir"],"#{war_name}.war")
  if new_resource.config && ::File.exists?(new_resource.config)  
    new_deploy_descriptor = REXML::Document.new(::File.new new_resource.config) 
    current_deploy_descriptor = ::File.join(
      node["tomcat"]["context_dir"],
      ::File.basename("#{new_deploy_descriptor.root.attributes['path'].strip}.xml")
    ) 
    if ::File.exists?(current_deploy_descriptor)
      doc = REXML::Document.new ::File.new current_deploy_descriptor 
      war_file = doc.root.attributes["docBase"]
    end
  end
  if ::File.exists?(war_file)
    @context.checksum(checksum(war_file))
  end
  

  Chef::Log.debug("Checking status of Context #{new_resource.context_name}")

  begin
    case @tomcat_manager.status_for_context(new_resource.context_name)
      when :running
        @context.running(true)
        @context.deployed(true)
      when :stopped
        @context.running(false)
        @context.deployed(true)
      else
        @context.running(false)
        @context.deployed(false)
    end
  rescue Chef::Exceptions::Exec
    @context.deployed(false)
    @context.running(false)
    nil
  end

end

action :deploy do
  action = "deploy"
  unless @context.deployed && @context.checksum == @new_resource.checksum
    log_info(action)
    result = @tomcat_manager.deploy
    evaluate_result(result,action)
  end
end

action :update  do
  action = "update"   
  Chef::Log.debug "deployed = #{@context.deployed}, checksum = #{@context.checksum},new checksum = #{@new_resource.checksum}" 
  
  unless @context.deployed && @context.checksum == @new_resource.checksum
    log_info(action)
    result = @tomcat_manager.update
    evaluate_result(result,action)   
  else
    Chef::Log.info "Not Running tomcat_manager[#{@new_resource.name}] #{action}: already deployed and matching checksum"
  end
end

action :start  do
  action = "start"
  unless @context.running
    log_info(action)
    result = @tomcat_manager.start
    evaluate_result(result,action)
  end
end

action :stop  do
  action = "stop"
  unless !@context.running
    log_info(action)
    result = @tomcat_manager.stop
    evaluate_result(result,action)
  end
end

action :undeploy  do
  action = "undeploy"
  unless !@context.deployed
    log_info(action)
    result = @tomcat_manager.undeploy
    evaluate_result(result,action)
  end
end

def evaluate_result(result,action)
  if (!"200".eql?(result.code) || result.body.include?("FAIL"))
      message = "Ran tomcat_manager[#{@new_resource.name}] #{action} failed: HTTP #{result.code} #{result.body}"
      Chef::Log.error
      raise RuntimeError, message , caller
    else
      Chef::Log.info "Ran tomcat_manager[#{@new_resource.name}] #{action} successfully"
    end
end

def log_info(action)
  Chef::Log.info "Running tomcat_manager[#{@new_resource.name}] #{action}"
end 

#def checksum(file_path)
#  Digest::SHA256.file(file_path).hexdigest if file_path && ::File.exists?(file_path)
#end