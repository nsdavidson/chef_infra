if node['chef-server']['configuration']['nginx']['ssl_certificate']
  frontend_certs = read_env_secret('certificates')

  directory '/var/opt/opscode/nginx/ca' do
    owner 'root'
    group 'root'
    mode '0750'
    recursive true
  end

  file node['chef-server']['configuration']['nginx']['ssl_certificate'] do
    owner 'root'
    group 'root'
    mode '0640'
    content frontend_certs['cert']
  end

  file node['chef-server']['configuration']['nginx']['ssl_certificate_key'] do
    owner 'root'
    group 'root'
    mode '0640'
    content frontend_certs['key']
  end
end

directory '/etc/opscode'

unless node['chef_stack']['is_chef_master'] || node['chef_stack']['is_frontend_bootstrap']
  private_chef_secrets = read_env_secret(node['chef_stack']['conf_vault_item'])
  file '/etc/opscode/webui_pub.pem' do
    content private_chef_secrets['/etc/opscode/webui_pub.pem']
  end

  file '/etc/opscode/webui_priv.pem' do
    content private_chef_secrets['/etc/opscode/webui_priv.pem']
  end

  file '/etc/opscode/pivotal.pem' do
    content private_chef_secrets['/etc/opscode/pivotal.pem']
  end
end

chef_server node['fqdn'] do
  # version node['chef_stack']['server_version'] || :latest
  accept_license true
  config lazy { template_render(IO.read(File.expand_path('../../templates/default/chef-server.rb.erb', __FILE__))) }
  addons node['chef-server']['configuration']['addons']
  # data_collector_url  #if search(:node, 'name:automate-centos-72', filter_result: { 'name' => ['name'] }) # ~FC003
end

node['chef_stack']['users'].each do |user, _values|
  chef_user user do
    first_name user
    last_name user
    email "#{user}@#{user}.local"
    key_path "#{node['chef_stack']['config_dir']}/#{user}.pem"
  end
end

chef_org node['chef_stack']['chef_org'] do
  # TODO: why are we not using the chef_stack admins attribute?
  admins ['workflow']
end

chef_stack_objects node['fqdn'] do
  action [:backup_if_needed, :restore_if_needed, :reset_config]
  only_if { node['chef_stack']['is_chef_master'] }
end if running_in_kitchen?

# template '/etc/opscode/workflow.rb' do
#  source 'workflow_knife.rb.erb'
#  variables 'chef_server_url' => node['chef_stack']['chef_server_url']
# end

execute 'knife ssl fetch -c /etc/chef/client.rb'

ruby_block 'gather chef-server secrets' do
  block do
    chefserver = {}
    files = Dir.glob('/etc/opscode*/*.{rb,pem,pub}')
    files.each do |file|
      chefserver[file] = IO.read(file)
    end
    write_env_secret(node['chef_stack']['conf_vault_item'], chefserver)
  end
  action :run
  only_if { node['chef_stack']['is_frontend_bootstrap'] || node['chef_stack']['is_chef_master'] }
end
