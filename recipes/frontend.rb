require 'json'
include_recipe 'chef_infra'

backend_secrets = read_env_secret('backend_secrets')
db_superuser_password = JSON.parse(backend_secrets['content'])['postgresql']['db_superuser_password']
node.default['chef-server']['hafrontend']['postgresql']['db_superuser_password'] = db_superuser_password

unless node.run_list?("recipe[chef_infra\:\:_kitchen]")
  node.default['chef-server']['hafrontend']['chef_backend_members'] = search_for_nodes(%(chef_environment:"#{node.chef_environment}") + ' AND recipes:chef_infra\:\:backend').map { |node| node['ipaddress'] }.sort
end

unless node['chef_stack']['is_frontend_bootstrap']
  directory '/var/opt/opscode/' do
    recursive true
  end

  file '/var/opt/opscode/bootstrapped'
end

# Merge the hafrontend and default configuration attributes, with the hafrontend winning any conflict.
node.default['chef-server']['configuration'] = Chef::Mixin::DeepMerge.deep_merge(node.default['chef-server']['hafrontend'], node.default['chef-server']['configuration'])
include_recipe 'chef_infra::_server'
