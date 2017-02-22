default['chef_stack']['bootstrap_backend'] = false
# default['chef_stack']['publish_address'] = node['fqdn']
default['chef_stack']['server_version'] = '12.11.1'

# workaround to see if kitchen is setting this
default['chef_stack']['chef_server_url'] = Chef::Config['chef_server_url'] unless normal['chef_stack']['chef_server_url'].to_s.start_with?('http')
default['chef_stack']['admins'] = ['workflow']
default['chef_stack']['users'] = ['workflow']

## If you change workflow_user or config_dir, you need to change any reference to client_key_path or chef_private_key
default['chef_stack']['workflow_user'] = 'workflow'
default['chef_stack']['chef_client_key_path'] = '/etc/chef/client.pem'
default['chef_stack']['knife_rb'] = '/etc/chef/client.rb'
default['chef_stack']['builder_key_path'] = '/etc/opscode/builder.pem'
default['chef_stack']['config_dir'] = '/etc/opscode/'

default['chef_stack']['workflow_enterprise'] = 'scm-infra'
default['chef_stack']['chef_org'] = 'jnj'
default['chef-server']['configuration']['nginx'] = {}
default['chef-server']['configuration']['nginx']['ssl_certificate'] = '/var/opt/opscode/nginx/ca/jnjwildcard.pem'
default['chef-server']['configuration']['nginx']['ssl_certificate_key'] = '/var/opt/opscode/nginx/ca/jnjwildcard.key'
