return unless node.run_list?('recipe[chef_infra::automate]')

default['chef_stack']['config_dir'] = '/etc/delivery/'
default['chef_stack']['users'] = %w(workflow builder)
default['chef_stack']['workflow_user'] = 'workflow'
default['chef_stack']['chef_client_key_path'] = '/etc/delivery/workflow.pem'

################################
## Attributes for delivery.rb #
################################
#
default['chef-server']['automate'] = {}
default['chef-server']['automate']['delivery_fqdn'] = node['fqdn']
default['chef-server']['automate']['delivery'] = {}
default['chef-server']['automate']['delivery']['chef_username'] = 'workflow'
default['chef-server']['automate']['delivery']['chef_private_key'] = '/etc/delivery/workflow.pem'
default['chef-server']['automate']['insights'] = {}
default['chef-server']['automate']['insights']['enable'] = true
# default['chef-server']['automate']['delivery']['ldap_hosts'] = ["jnj.com"]
# default['chef-server']['automate']['delivery']['ldap_port'] = 3269
# default['chef-server']['automate']['delivery']['ldap_timeout'] = 5000
# default['chef-server']['automate']['delivery']['ldap_base_dn'] = "dc=jnj,dc=com"
# default['chef-server']['automate']['delivery']['ldap_bind_dn'] = "SA-NCSUS-TestApp"
# default['chef-server']['automate']['delivery']['ldap_bind_dn_password'] = "PASSWORD"
# default['chef-server']['automate']['delivery']['ldap_encryption'] = "start_tls"
# default['chef-server']['automate']['delivery']['ldap_attr_login'] = 'sAMAccountName'
# default['chef-server']['automate']['delivery']['ldap_attr_mail'] = 'mail'
# default['chef-server']['automate']['delivery']['ldap_attr_full_name'] = 'cn'
