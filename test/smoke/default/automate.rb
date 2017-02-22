# encoding: utf-8

# Inspec test for recipe jnj_chef_stack::automate

# The Inspec reference, with examples and extensive documentation, can be
# found at https://docs.chef.io/inspec_reference.html

packages = %w(delivery)
packages.each do |p|
  describe package(p) do
    it { should be_installed }
  end
end

config_files = %w(delivery.rb delivery-running.json
                  delivery-secrets.json)
config_files.each do |f|
  describe file("/etc/delivery/#{f}") do
    it { should exist }
  end
end

automate_ports = %w(80 443 5432 8989 9611)
automate_ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end

describe command('automate-ctl status') do
  its('exit_status') { should eq 0 }
end
