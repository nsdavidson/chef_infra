#
# Cookbook:: jnj_chef_stack
# Spec:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.

require 'spec_helper'

describe 'jnj_chef_stack::frontend' do
  context 'When all attributes are default, on an unspecified platform' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new(platform: 'centos', version: '7.0') do |node, server|
        server.create_environment('_default', default_attributes: {})

        # Assign the environment to the node
        node.chef_environment = '_default'
        server.create_data_bag('chef_stack',
                               'infra_secrets' => parse_data_bag('chef_stack/infra_secrets.json'))
      end.converge(described_recipe)
    end

    before do
      allow_any_instance_of(Chef::Recipe).to receive(:read_env_secret).with('backend_secrets')\
        .and_return(parse_data_bag('chef_stack/infra_secrets.json')['_default']['backend_secrets'])
      allow_any_instance_of(Chef::Recipe).to receive(:read_env_secret).with('frontend_secrets')\
        .and_return(parse_data_bag('chef_stack/infra_secrets.json')['_default']['frontend_secrets'])
      allow_any_instance_of(Chef::Recipe).to receive(:read_env_secret).with('certificates')\
        .and_return(parse_data_bag('chef_stack/infra_secrets.json')['_default']['certificates'])
      allow_any_instance_of(Chef::Recipe).to receive(:search_for_nodes).and_return([{ 'fqdn' => 'hostname' }])
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end
  end
end
