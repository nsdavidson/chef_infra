return unless node.run_list?('recipe[chef_infra::standalone]')

default['chef_stack']['users'] = %w(workflow builder)
default['chef_stack']['conf_vault_item'] = 'standalone_secrets'

default['chef-server']['standalone']['addons'] = { 'push-jobs-server' => { version: '2.1.1', config: '' } }
# topology
default['chef-server']['standalone']['topology'] = 'standalone'
default['chef-server']['standalone']['ip_version'] = 'ipv4'
default['chef-server']['standalone']['api_fqdn'] = node['fqdn']
default['chef-server']['standalone']['oc_id'] = {}
default['chef-server']['standalone']['oc_id']['applications'] = {}
default['chef-server']['standalone']['data_collector'] = {}
default['chef-server']['standalone']['data_collector']['token'] = '93a49a4f2482c64126f7b6015e6b0f30284287ee4054ff8807fb63d9cbd1c506'
# nginx settings
default['chef-server']['standalone']['nginx'] = {}
default['chef-server']['standalone']['nginx']['ssl_certificate'] = '/var/opt/opscode/nginx/ca/jnjwildcard.pem'
default['chef-server']['standalone']['nginx']['ssl_certificate_key'] = '/var/opt/opscode/nginx/ca/jnjwildcard.key'
