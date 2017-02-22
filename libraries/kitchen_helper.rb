require 'json'
require 'mixlib/shellout'
require 'rubygems'
require 'chef/knife'
require 'chef/node'

module KitchenStackHelpers
  def config_opts
    "--config-option chef_server_url=https://127.0.0.1:443/organizations/#{node['chef_stack']['chef_org']} -c /etc/opscode/pivotal.rb"
  end

  def orgs_dir
    '/etc/opscode/orgs'
  end

  def shared_dir
    '/opt/shared_data'
  end

  def bin_path
    '/opt/opscode/embedded/bin'
  end

  def run(cmd)
    tell("Running: #{cmd}")
    Mixlib::ShellOut.new(cmd, cwd: '/tmp', timeout: 600).run_command
  end

  def tell(it)
    Chef::Log.info(it)
  end

  def create_objects
    tell('Creating Clients and Nodes')
    install_knife_acl
    hosts = IO.read('/etc/hosts').split(/\s+/).find_all { |e| /centos/ =~ e }
    Dir.mkdir("#{shared_dir}/client_keys") unless File.exist?("#{shared_dir}/client_keys")

    hosts.each do |h|
      run("#{bin_path}/knife node delete #{h} -y #{config_opts}")
      run("#{bin_path}/knife node create #{h} -d #{config_opts}")
      run("#{bin_path}/knife client delete #{h} -y #{config_opts}")
      run("#{bin_path}/knife client create #{h} -d #{config_opts} -f #{shared_dir}/client_keys/#{h}.pem")
      run("#{bin_path}/knife acl add client #{h} clients #{h} update")
      run("#{bin_path}/knife acl add client #{h} clients #{h} create")
      run("#{bin_path}/knife acl add client #{h} clients #{h} read")
      run("#{bin_path}/knife acl add client #{h} nodes #{h} update")
      run("#{bin_path}/knife acl add client #{h} nodes #{h} create")
      run("#{bin_path}/knife acl add client #{h} nodes #{h} read")
    end
  end

  def install_knife_acl
    tell('Installing knife-acl')
    run("#{bin_path}/gem install knife-acl")
  end

  def install_ec_backup
    tell('Installing knife-ec-backup')
    run('yum install -y git')
    run('git clone https://github.com/chef/knife-ec-backup.git')
    run("cd knife-ec-backup && #{bin_path}/gem build knife-ec-backup.gemspec")
    run("cd knife-ec-backup && #{bin_path}/gem install knife-ec-backup*gem --no-ri --no-rdoc -V")
  end

  def backup
    install_ec_backup
    create_objects
    Dir.mkdir("#{shared_dir}/backups") unless File.exist?("#{shared_dir}/backups")
    run("#{bin_path}/knife ec backup backups --webui-key /etc/opscode/webui_priv.pem #{config_opts}")
    run("tar cvzf #{shared_dir}/backups/standalone_backup.tar.gz backups/ && touch /var/opt/opscode/chefstackbackedup")
  end

  def restore
    run('rm -rf /tmp/backups')
    run("tar xvf #{shared_dir}/backups/standalone_backup.tar.gz -C /tmp")
    run("cd /tmp && #{bin_path}/knife ec restore backups --webui-key /etc/opscode/webui_priv.pem #{config_opts}")
    run('touch /var/opt/opscode/chefstackrestored')
  end

  def backup_if_needed
    backup unless backup_exists?
  end

  def backup_exists?
    File.exist?("#{shared_dir}/backups/standalone_backup.tar.gz")
  end

  def restore_if_needed
    restore if backup_exists? && !already_restored?
  end

  def already_restored?
    File.exist?('/var/opt/opscode/chefstackrestored')
  end
end
