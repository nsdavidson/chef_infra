#
# Cookbook Name:: jnj_chef_stack
# Spec:: default
#
# Copyright (c) 2017 The Authors, All Rights Reserved.

require 'spec_helper'

describe 'jnj_chef_stack::default' do
  context 'When all attributes are default, on an unspecified platform' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new(platform: 'centos', version: '7.0') do |node, server|
        server.create_environment('_default', default_attributes: {})

        # Assign the environment to the node
        node.chef_environment = '_default'
      end.converge(described_recipe)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end
  end
end
