# encoding: utf-8

# Inspec test for recipe jnj_chef_stack::standalone

# The Inspec reference, with examples and extensive documentation, can be
# found at https://docs.chef.io/inspec_reference.html

packages = %w(chef-server-core)
packages.each do |p|
  describe package(p) do
    it { should be_installed }
  end
end

config_files = %w(chef-server.rb chef-server-running.json
                  private-chef-secrets.json)
config_files.each do |f|
  describe file("/etc/opscode/#{f}") do
    it { should exist }
  end
end

standalone_ports = %w(80 443 5672 9090 10000)
standalone_ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end

describe command('chef-server-ctl status') do
  its('exit_status') { should eq 0 }
end
