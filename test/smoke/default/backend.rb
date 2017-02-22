# encoding: utf-8

# Inspec test for recipe jnj_chef_stack::backend

# The Inspec reference, with examples and extensive documentation, can be
# found at https://docs.chef.io/inspec_reference.html

packages = %w(chef chef-backend)
packages.each do |p|
  describe package(p) do
    it { should be_installed }
  end
end

config_files = %w(chef-backend.rb chef-backend-running.json
                  chef-backend-secrets.json)
config_files.each do |f|
  describe file("/etc/chef-backend/#{f}") do
    it { should exist }
  end
end

backend_ports = %w(2379 2380 4369 5432 9200 9300)
backend_ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end

elastic_resp = json(command: 'curl -XGET \'localhost:9200/_cluster/health\'')
describe elastic_resp do
  its(['status']) { should eq 'green' }
end

etcd_resp = json(command: 'curl -XGET -L \'http://127.0.0.1:2379/health\'')
describe etcd_resp do
  its(['health']) { should eq 'true' }
end

describe command('chef-backend-ctl status') do
  its('exit_status') { should eq 0 }
end
