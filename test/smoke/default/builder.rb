# encoding: utf-8

# Inspec test for recipe jnj_chef_stack::workflow_builder

# The Inspec reference, with examples and extensive documentation, can be
# found at https://docs.chef.io/inspec_reference.html

packages = %w(chefdk)
packages.each do |p|
  describe package(p) do
    it { should be_installed }
  end
end

dirs = %w(.chef bin lib etc)
dirs.each do |d|
  describe directory("/var/opt/delivery/workspace/#{d}") do
    it { should exist }
  end
end
