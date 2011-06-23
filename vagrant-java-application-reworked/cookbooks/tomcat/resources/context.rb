#
# Cookbook Name:: tomcat
# Resource: tomcat_context
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

actions :deploy,:start,:stop,:update,:undeploy

attribute :port,     :kind_of => String, :default => "8080"#node["tomcat"]["port"].to_s
attribute :host,     :kind_of => String, :default => "localhost"
attribute :admin,     :kind_of => String, :default => "tomcat-manager"#node["tomcat"]["user"]
attribute :password,     :kind_of => String, :default => ""#node["tomcat"]["password"]
attribute :context_name, :kind_of => String, :name_attribute => true
attribute :war,     :kind_of => String
attribute :tag,     :kind_of => String
attribute :config,     :kind_of => String
attribute :deployed, :default => false
attribute :running, :default => false
attribute :checksum, :kind_of => String

