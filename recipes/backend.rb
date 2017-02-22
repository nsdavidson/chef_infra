include_recipe 'chef_infra'

directory '/etc/chef-backend' do
  mode '0755'
  owner 'root'
  group 'root'
end

unless node['chef_stack']['is_backend_bootstrap']
  backend_secrets = read_env_secret('backend_secrets')
  file '/etc/chef-backend/chef-backend-secrets.json' do
    content backend_secrets['content'].to_s
  end
end

bootstrap_backend = if node['chef_stack']['is_backend_bootstrap']
                      node['fqdn']
                    elsif running_in_kitchen?
                      node['chef_stack']['bootstrap_backend']
                    else
                      search_for_nodes("chef_environment:#{node.chef_environment} AND chef_stack_is_backend_bootstrap:true", fqdn_only: true)[0]['fqdn']
                    end

chef_backend node['fqdn'] do
  bootstrap_node bootstrap_backend
  accept_license true
  publish_address node['ipaddress']
end

ruby_block 'gather backend secrets' do
  block do
    content_value = { 'content' => File.read('/etc/chef-backend/chef-backend-secrets.json') }
    write_env_secret('backend_secrets', content_value)
  end
  action :run
  only_if { node['chef_stack']['is_backend_bootstrap'] }
end
