#
# Cookbook Name:: build_cookbook
# Recipe:: smoke
#
# Copyright (c) 2017 The Authors, All Rights Reserved.
include_recipe 'delivery-truck::smoke'

def choose_transport(platform)
  case platform
  when 'windows'
    'winrm'
  else
    'ssh'
  end
end

def build_inspec_command(transport, vault, result, smoke_test)
  <<-EOC.gsub(/^\s+/, '')
    inspec exec test/smoke/default/#{smoke_test} \
      -t  #{transport}://sa-its-vcouser#{result['fqdn']} \
      --key-files /home/sa-its-vcouser/.ssh/id_rsa --sudo
  EOC
end

Chef::Config.from_file(automate_knife_rb)

# get a list of infrastructure nodes by environment and recipes in run_list
results = search(:node,
  "chef_environment:#{workflow_chef_environment_for_stage} && recipes:#{workflow_change_project}\:\:*",
  filter_result: {
    fqdn: ['fqdn'],
    run_list: ['run_list'],
    platform: ['platform']
  }
)

unless results.empty?
  results.each do |result|
    transport = choose_transport(result['platform'])
    if result[0]['run_list'][0] =~ /standalone/
      smoke_test = 'standalone.rb'
    elsif result[0]['run_list'][0] =~ /automate/
      smoke_test = 'automate.rb'
    elsif result[0]['run_list'][0] =~ /supermarket/
      smoke_test = 'supermarket.rb'
    elsif result[0]['run_list'][0] =~ /builder/
      smoke_test = 'builder.rb'
    elsif result[0]['run_list'][0] =~ /search/
      smoke_test = 'search.rb'
    elsif result[0]['run_list'][0] =~ /frontend/
      smoke_test = 'frontend.rb'
    elsif result[0]['run_list'][0] =~ /backend/
      smoke_test = 'backend.rb'
    else
      smoke_test = 'default.rb'
    end
    inspec_command = build_inspec_command(transport, {}, result, smoke_test)

    execute "run smoke tests on #{result['fqdn']}" do
      command inspec_command
      cwd delivery_workspace_repo
      sensitive true
      action :run
    end

  end
end
