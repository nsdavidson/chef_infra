#
# Cookbook:: jnj_chef_stack
# Recipe:: automate
#
# Copyright:: 2017, The Authors, All Rights Reserved.
include_recipe 'jnj_chef_stack'

# Due to GTS umask need to create /var/opt/delivery with proper umask
directory '/var/opt/delivery' do
  mode '0755'
end

directory '/var/opt/delivery/license/' do
  mode '0755'
end

cookbook_file '/var/opt/delivery/license/delivery.license' do
  source 'delivery.license'
end

master_fqdn = search_for_nodes("chef_environment:#{node.chef_environment} AND chef_stack_is_chef_master:true", fqdn_only: true)[0]['fqdn']
node.default['chef-server']['automate']['delivery']['chef_server'] = "https://#{master_fqdn}/organizations/#{node['chef_stack']['chef_org']}"
automate_secrets = read_env_secret('automate_secrets')
search_fqdn_array = search_for_nodes(%(chef_environment:"#{node.chef_environment}") + ' AND recipes:jnj_chef_stack\:\:search').map { |node| node['fqdn'] }
node.default['chef-server']['automate']['elasticsearch']['urls'] = search_fqdn_array.map { |fqdn| "http://#{fqdn}:9200" } unless search_fqdn_array.empty?
node.default['chef-server']['configuration'] = Chef::Mixin::DeepMerge.deep_merge(node.default['chef-server']['automate'], node.default['chef-server']['configuration'])

chef_automate node['fqdn'] do
  version :latest
  config lazy { template_render(IO.read(File.expand_path('../../templates/default/chef-server.rb.erb', __FILE__))) }
  accept_license true
  enterprise node['chef_stack']['workflow_enterprise']
  chef_user node['chef_stack']['workflow_user']
  chef_user_pem automate_secrets['user_pem']
  validation_pem automate_secrets['validator_pem']
  builder_pem automate_secrets['builder_pem']
  license 'cookbook_file://delivery.license'
end

# template '/etc/delivery/workflow.rb' do
#  source 'workflow_knife.rb.erb'
#  variables 'chef_server_url' => node['chef_stack']['chef_server_url']
# end

ruby_block 'gather automate secrets' do
  block do
    automate = {
      'workflow_user_creds' => ::File.read("/etc/delivery/#{node['chef_stack']['workflow_enterprise']}.creds"),
    }
    write_env_secret('automate_secrets', automate)
  end
  action :run
end
