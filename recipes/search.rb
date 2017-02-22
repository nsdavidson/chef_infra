#
# Cookbook:: jnj_chef_stack
# Recipe:: search
#
# Copyright:: 2017, The Authors, All Rights Reserved.

include_recipe 'jnj_chef_stack'

directory '/etc/chef-backend' do
  mode '0755'
  owner 'root'
  group 'root'
end

search_secrets = read_env_secret('search_secrets')
file '/etc/chef-backend/chef-backend-secrets.json' do
  content search_secrets['content'].to_s
end
bootstrap_search = if node['chef_stack']['is_search_bootstrap']
                     node['fqdn']
                   elsif node.run_list?("recipe[jnj_chef_stack\:\:_kitchen]")
                     node['chef_stack']['bootstrap_search']
                   else
                     search_for_nodes("chef_environment:#{node.chef_environment} AND chef_stack_is_search_bootstrap:true", fqdn_only: true)[0]['fqdn']
                   end

chef_backend node['fqdn'] do
  bootstrap_node bootstrap_search
  accept_license true
  publish_address node['ipaddress']
end

ruby_block 'gather search secrets' do
  block do
    content_value = { 'content' => File.read('/etc/chef-backend/chef-backend-secrets.json') }
    write_env_secret('search_secrets', content_value)
  end
  action :run
  only_if { node['chef_stack']['is_backend_bootstrap'] }
end
