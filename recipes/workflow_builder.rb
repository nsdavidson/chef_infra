#
# Cookbook:: jnj_chef_stack
# Recipe:: workflow_builder
#
# Copyright:: 2017, The Authors, All Rights Reserved.

include_recipe 'jnj_chef_stack'

automate_secrets = read_env_secret('automate_secrets')

unless running_in_kitchen?
  node.default['chef_stack']['automate_fqdn'] = search_for_nodes(%(chef_environment:"#{node.chef_environment}") + ' AND recipes:jnj_chef_stack\:\:automate').map { |node| node['fqdn'] }[0]
  node.default['chef_stack']['supermarket_fqdn'] = search_for_nodes(%(chef_environment:"#{node.chef_environment}") + ' AND recipes:jnj_chef_stack\:\:supermarket').map { |node| node['fqdn'] }[0]
end

directory node['chef_stack']['config_dir']

workflow_builder node['fqdn'] do
  version :latest
  pj_version :latest
  accept_license true
  chef_user node['chef_stack']['workflow_user']
  chef_user_pem automate_secrets['user_pem']
  builder_pem automate_secrets['builder_pem']
  chef_fqdn URI.parse(Chef::Config['chef_server_url']).host
  automate_enterprise node['chef_stack']['workflow_enterprise']
  automate_fqdn node['chef_stack']['automate_fqdn']
  supermarket_fqdn node['chef_stack']['supermarket_fqdn']
  job_dispatch_version 'v2'
  # automate_user 'builder'
  # automate_password ::File.read('/tmp/config/chef.creds')[/Admin password: (?<pw>.*)$/, 'pw']
  automate_password automate_secrets['workflow_user_creds'][/Admin password: (?<pw>.*)$/, 'pw']
  # not_if { node['tags'].include?('kitchen') }
end
