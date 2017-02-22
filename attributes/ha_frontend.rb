return unless node.run_list?('recipe[chef_infra::frontend]')

default['chef_stack']['chef_org'] = 'jnj'
default['chef_stack']['conf_vault_item'] = 'frontend_secrets'

# Chef Server Tunables
#
# For a complete list see:
# https://docs.chef.io/config_rb_server.html
# https://docs.chef.io/config_rb_server_optional_settings.html
#
# Example:
#
# In a recipe:
#
#     node.override['chef-server']['configuration']['nginx']['ssl_port'] = 4433
#
# In a role:
#
#     override_attributes(
#       'chef-server' => {
#         'configuration' => {
#           'nginx' => {
#             'ssl_port' => 4433
#           }
#         }
#       }
#     )
#

default['chef-server']['hafrontend']['addons'] = { 'manage' => { version: '2.4.4', config: '' } }

# config = default['chef-server']['configuration'] = {}
## REMINDER: Don't overwrite nested hashs on accident.

default['chef-server']['hafrontend']['use_chef_backend'] = true
default['chef-server']['hafrontend']['chef_backend_members'] = ['192.168.254.2'] # needs to be discovered in recipe

default['chef-server']['hafrontend']['haproxy'] = {}
default['chef-server']['hafrontend']['haproxy']['remote_postgresql_port'] = 5432
default['chef-server']['hafrontend']['haproxy']['remote_elasticsearch_port'] = 9200

# Specify that postgresql is an external database, and provide the
# VIP of this cluster.  This prevents the chef-server instance
# from creating it's own local postgresql instance.
default['chef-server']['hafrontend']['postgresql'] = {}
default['chef-server']['hafrontend']['postgresql']['external'] = true
default['chef-server']['hafrontend']['postgresql']['vip'] = '127.0.0.1'
default['chef-server']['hafrontend']['postgresql']['db_superuser'] = 'chef_pgsql'

# These settings ensure that we use remote elasticsearch
# instead of local solr for search.  This also
# set search_queue_mode to 'batch' to remove the indexing
# dependency on rabbitmq, which is not supported in this HA configuration.
default['chef-server']['hafrontend']['opscode_solr4'] = {}
default['chef-server']['hafrontend']['opscode_solr4']['external'] = true
default['chef-server']['hafrontend']['opscode_solr4']['external_url'] = 'http://127.0.0.1:9200'

default['chef-server']['hafrontend']['opscode_erchef'] = {}
default['chef-server']['hafrontend']['opscode_erchef']['search_provider'] = 'elasticsearch'
default['chef-server']['hafrontend']['opscode_erchef']['search_queue_mode'] = 'batch'
# Cookbook Caching
default['chef-server']['hafrontend']['opscode_erchef']['nginx_bookshelf_caching'] = :on
default['chef-server']['hafrontend']['opscode_erchef']['s3_url_expiry_window_size'] = '50%'

# HA mode requires sql-backed storage for bookshelf.
default['chef-server']['hafrontend']['bookshelf'] = {}
default['chef-server']['hafrontend']['bookshelf']['storage_type'] = :sql

# RabbitMQ settings
# At this time we are not providing a rabbit backend. Note that this makes
# this incompatible with reporting and analytics unless you're bringing in
# an external rabbitmq.
default['chef-server']['hafrontend']['rabbitmq'] = {}
default['chef-server']['hafrontend']['rabbitmq']['enable'] = false
default['chef-server']['hafrontend']['rabbitmq']['management_enabled'] = false
default['chef-server']['hafrontend']['rabbitmq']['queue_length_monitor_enabled'] = false

# Opscode Expander
# opscode-expander isn't used when the search_queue_mode is batch.  It
# also doesn't support the elasticsearch backend.
default['chef-server']['hafrontend']['opscode_expander'] = {}
default['chef-server']['hafrontend']['opscode_expander']['enable'] = false

# Prevent startup failures due to missing rabbit host
default['chef-server']['hafrontend']['dark_launch'] = {}
default['chef-server']['hafrontend']['dark_launch']['actions'] = false

# nginx settings
default['chef-server']['hafrontend']['nginx'] = {}
default['chef-server']['hafrontend']['nginx']['ssl_certificate'] = '/var/opt/opscode/nginx/ca/jnjwildcard.pem'
default['chef-server']['hafrontend']['nginx']['ssl_certificate_key'] = '/var/opt/opscode/nginx/ca/jnjwildcard.key'
