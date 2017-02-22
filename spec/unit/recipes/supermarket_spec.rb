#
# Cookbook:: jnj_chef_stack
# Spec:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.

require 'spec_helper'

describe 'jnj_chef_stack::supermarket' do
  context 'When all attributes are default, on an unspecified platform' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new(platform: 'centos', version: '7.0') do |node, server|
        server.create_environment('_default', default_attributes: {})

        # Assign the environment to the node
        node.chef_environment = '_default'
        server.create_data_bag('chef_stack',
                               'infra_secrets' => parse_data_bag('chef_stack/infra_secrets.json'))
        server.node.override['chef_stack']['chef_server_url'] = 'http://foo.com'
      end.converge(described_recipe)
    end

    before do
      allow_any_instance_of(Chef::Recipe).to receive(:read_env_secret).with('automate_secrets')\
        .and_return(parse_data_bag('chef_stack/infra_secrets.json')['_default']['automate_secrets'])
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end
  end
end
