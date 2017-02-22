#
# Cookbook Name:: chef_stack
# Resource:: automate
#
# Copyright 2016 Chef Software Inc
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

resource_name 'chef_stack_objects'
default_action :backup

property :name, String, name_property: true

include KitchenStackHelpers

load_current_value do
  current_value_does_not_exist! unless backup_exists?
end

action :backup do
  backup
end

action :reset_config do
  ruby_block 'reload client.rb' do
    block do
      Chef::Config.from_file('/etc/chef/client.rb')
    end
    action :run
  end
end

action :backup_if_needed do
  converge_by 'restore backup and lay down client files' do
    backup_if_needed

    execute 'mkdir -p /opt/shared_data/standalone_keys && cp -f /etc/opscode/*pem /opt/shared_data/standalone_keys'

    file '/etc/chef/client.pem' do
      content lazy { IO.read("/opt/shared_data/client_keys/#{node['fqdn']}.pem") }
    end

    directory '/root/.chef'
    link '/root/.chef/knife.rb' do
      to '/etc/chef/client.rb'
    end
  end
end

action :restore do
  restore
end

action :restore_if_needed do
  restore_if_needed
end
