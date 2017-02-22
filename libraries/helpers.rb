require 'erubis'

def running_in_kitchen?
  node.run_list?('recipe[jnj_chef_stack::_kitchen]')
end

def search_for_nodes(query, fqdn_only: false)
  nodes = fqdn_only ? search(:node, query, filter_result: { 'fqdn' => ['fqdn'] }) : search(:node, query)
  if nodes.count.zero? || !nodes[0].key?('ipaddress')
    Chef::Log.warn "Unable to find nodes for search #{query}!"
  end

  nodes
end

def template_render(content)
  Erubis::Eruby.new(content).evaluate(run_context)
end

def load_infra_secrets
  ChefVault::Item.load(
    'chef_stack',
    'infra_secrets',
    node_name: Chef::Config['node_name'],
    client_key_path: '/etc/chef/client.pem'
  )
rescue
  Chef::Log.warn('Failed to load infra_secrets vault item.')
  nil
end

def read_env_secret(key)
  ChefVault::Item.load(
    'chef_stack',
    'infra_secrets',
    node_name: Chef::Config['node_name'],
    client_key_path: '/etc/chef/client.pem'
  )[node.chef_environment][key]
  # TODO: We need to handle multiple rescues here.
  # rescue
  #  Chef::Log.warn("Failed to read env secret #{key} in vault item infra_secrets.")
  #  nil
end

def write_env_secret(key, data)
  item = load_infra_secrets || ChefVault::Item.new(
    'chef_stack',
    'infra_secrets',
    node_name: Chef::Config['node_name'],
    client_key_path: '/etc/chef/client.pem'
  )
  item.raw_data ||= { 'id' => 'infra_secrets' } # is this being overwritten by the ChefVault::Item instantiation?
  item.raw_data[node.chef_environment] ||= {}
  item.raw_data[node.chef_environment][key] ||= {}
  item.raw_data[node.chef_environment][key].merge!(data)
  # item.search("chef_environment:#{node.chef_environment}")
  item.clients(Chef::Config['node_name'])
  # item.admins(Chef::Config['node_name'])
  item.save
end
