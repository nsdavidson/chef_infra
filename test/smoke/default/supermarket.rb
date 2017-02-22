# encoding: utf-8

# Inspec test for recipe jnj_chef_stack::supermarket

# The Inspec reference, with examples and extensive documentation, can be
# found at https://docs.chef.io/inspec_reference.html

packages = %w(supermarket)
packages.each do |p|
  describe package(p) do
    it { should be_installed }
  end
end

config_files = %w(supermarket.rb supermarket-running.json
                  secrets.json)
config_files.each do |f|
  describe file("/etc/supermarket/#{f}") do
    it { should exist }
  end
end

standalone_ports = %w(80 443 15432)
standalone_ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end

describe command('supermarket-ctl status') do
  its('exit_status') { should eq 0 }
end
