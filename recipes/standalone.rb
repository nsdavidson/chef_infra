#
# Cookbook:: jnj_chef_stack
# Recipe:: standalone
#
# Copyright:: 2017, The Authors, All Rights Reserved.
include_recipe 'jnj_chef_stack'

# See if an automate exists yet before setting the data collector url.
automate_fqdn_array = search_for_nodes(%(chef_environment:"#{node.chef_environment}") + ' AND recipes:jnj_chef_stack\:\:automate').map { |node| node['fqdn'] }
node.default['chef-server']['standalone']['data_collector']['root_url'] = "https://#{automate_fqdn_array[0]}/data-collector/v0/" unless automate_fqdn_array.empty?

# See if a supermarket exists yet before setting the oc_id information.
supermarket_fqdn_array = search_for_nodes(%(chef_environment:"#{node.chef_environment}") + ' AND recipes:jnj_chef_stack\:\:supermarket').map { |node| node['fqdn'] }
unless supermarket_fqdn_array.empty?
  node.default['chef-server']['standalone']['oc_id']['applications']['supermarket'] = {}
  node.default['chef-server']['standalone']['oc_id']['applications']['supermarket']['redirect_uri'] = "https://#{supermarket_fqdn_array[0]}/auth/chef_oauth2/callback"
end

# Merge the standalone and default configuration attributes, with the standalone winning any conflict.
node.default['chef-server']['configuration'] = Chef::Mixin::DeepMerge.deep_merge(node.default['chef-server']['standalone'], node.default['chef-server']['configuration'])

include_recipe 'jnj_chef_stack::_server'

ruby_block 'gather automate secrets' do
  block do
    automate = {
      'validator_pem' => ::File.read("/etc/opscode/orgs/#{node['chef_stack']['chef_org']}-validation.pem"),
      'user_pem' => ::File.read(node['chef_stack']['chef_client_key_path']),
      'builder_pem' => ::File.read(node['chef_stack']['builder_key_path']),
    }

    unless supermarket_fqdn_array.empty?
      #  'builder_pub' => "ssh-rsa #{[builder_key.to_blob].pack('m0')}",
      supermarket_ocid = JSON.parse(::File.read('/etc/opscode/oc-id-applications/supermarket.json'))
      automate.merge('supermarket_oauth2_app_id' => supermarket_ocid['uid'],
                     'supermarket_oauth2_secret' => supermarket_ocid['secret'],
                     'supermarket_fqdn' => URI(supermarket_ocid['redirect_uri']).host)
    end

    write_env_secret('automate_secrets', automate)
  end
  action :run
  only_if { node['chef_stack']['is_chef_master'] }
end
