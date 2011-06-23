#
# Cookbook Name:: application
# Recipe:: reverse_proxy_apache2
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

define :application_reverse_proxy_apache2 do

  app = node.run_state[:current_app]

  web_app app['id'] do
    template "reverse_proxy.erb"
    server_name app['domain_name']
    server_aliases app['domain_name_aliases'].split(",") if app['domain_name_aliases']
    frontend_path "/"
    backend_host "localhost"
    backend_port "8080"
    backend_path "/"
  end

end




