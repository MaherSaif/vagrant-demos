#
# Cookbook Name:: tomcat
# Library: default
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

require 'net/http'
require 'net/https'

class TomcatManager
  # wrapper around tomcat manager http api

  def initialize(opts={})
    @configuration = opts
    @config_param = (@configuration[:config])? "&config=file:#{@configuration[:config]}" :""
    @tag_param = (@configuration[:tag])?"&tag=#{@configuration[:tag]}":""
    @war_param = (@configuration[:war])?"&war=file:#{@configuration[:war]}":""
  end

  def configuration
    @configuration
  end

  def deploy
    get("/manager/deploy?path=#{@configuration[:path]}#{@war_param}#{@config_param}#{@tag_param}")
  end

  def update
    get("/manager/deploy?path=#{@configuration[:path]}#{@war_param}#{@config_param}#{@tag_param}&update=true")
  end

  def undeploy
    get("/manager/undeploy?path=#{@configuration[:path]}")
  end

  def reload
    get("/manager/reload?path=#{@configuration[:path]}")
  end

  def start
    get("/manager/start?path=#{@configuration[:path]}")
  end

  def stop
    get("/manager/stop?path=#{@configuration[:path]}")
  end

  def status
    get("/manager/status")
  end

  def list
    # we get something like
    #OK - Listed applications for virtual host localhost
    #/webdav:running:0
    #/examples:running:0
    #/manager:running:0
    #/:running:0

    get("/manager/list")
  end

  def contexts
    contexts = Hash.new
    status_text = list.body
    lines = status_text.send(status_text.respond_to?(:lines) ? :lines : :to_s).to_a
    if lines && lines.first =~ /OK/
      lines[1..-1].each do |line|
        path,status,sessions = line.split(":")
        contexts[path] = {:status => status.to_sym,:sessions => sessions.chomp.to_i}
      end
    end
    contexts
  end

  def status_for_context(context)
    contexts[context] ? contexts[context][:status] : :undeployed
  end

  def get(url)
    site = Net::HTTP.new(@configuration[:host], @configuration[:port])
    site.use_ssl = false
    site.read_timeout=180
    result = nil
    begin
      result = site.get2( url, 'Authorization' => 'Basic ' + ["#{@configuration[:admin]}:#{@configuration[:password]}"].pack('m').strip)
    rescue Timeout::Error => e
      raise RuntimeError, "Timeout Error while calling #{url}", caller
    end
    result
  end

end


