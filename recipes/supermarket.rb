# Cookbook:: jnj_chef_stack
# Recipe:: supermarket
#
# Copyright:: 2017, The Authors, All Rights Reserved.
include_recipe 'jnj_chef_stack'

automate_secrets = read_env_secret('automate_secrets')
chef_supermarket node['fqdn'] do
  version :latest
  chef_oauth2_app_id automate_secrets['supermarket_oauth2_app_id']
  chef_oauth2_secret automate_secrets['supermarket_oauth2_secret']
  chef_oauth2_verify_ssl false
  accept_license true
  chef_server_url Chef::Config['chef_server_url']
end
