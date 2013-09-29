#
# Cookbook Name:: redisio
# Recipe:: install
#
# Copyright 2013, Brian Bianco <brian.bianco@gmail.com>
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
include_recipe 'redisio::default'
include_recipe 'ulimit::default'

redis = node['redisio']
location = "#{redis['mirror']}/#{redis['base_name']}#{redis['version']}.#{redis['artifact_type']}"

redis_instances = redis['servers']
if redis_instances.nil?
  redis_instances = [{'port' => '6379'}]
  node.set['redisio']['servers'] = redis_instances
end

redisio_install "redis-servers" do
  version redis['version']
  download_url location
  default_settings redis['default_settings']
  servers redis_instances
  safe_install redis['safe_install']
  base_piddir redis['base_piddir']
  install_dir redis['install_dir']
end

# Create a service resource for each redis instance
RedisioHelper.each_server(redis_instances) do |current_server|
  service_name = RedisioHelper.service_name(current_server)
  job_control = current_server['job_control'] || redis['default_settings']['job_control']

  service service_name do
    if job_control == 'initd'
      start_command "/etc/init.d/#{service_name} start"
      stop_command "/etc/init.d/#{service_name} stop"
      restart_command "/etc/init.d/#{service_name} restart"
    elsif job_control == 'upstart'
      provider Chef::Provider::Service::Upstart
      start_command "start #{service_name}"
      stop_command "stop #{service_name}"
      restart_command "restart #{service_name}"
    else
      raise 'Unknown job control type, no service resource created!'
    end
    status_command "pgrep -lf '#{service_name}' | grep -v 'sh'"
    supports :start => true, :stop => true, :restart => true, :status => false
  end
end


