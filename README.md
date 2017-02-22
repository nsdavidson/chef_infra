# chef_infra Cookbook

This cookbook provides an example implementation of a reference architecture capable of being used as a global deployment reference for Chef Software, Inc.'s products and add-ons including, but not limited to:

- Chef Server 12
- Chef Compliance Server
- Chef Automate
- Chef Push Jobs Server
- Supermarket

It will perform component installation and configuration for an end-to-end integrated topology. It relies on the [chef_stack](https://github.com/ncerny/chef_stack) library cookbook to provide the underlying resources needed. Environment/Role/or Wrapper cookbooks should be created using the recipes that this cookbook provides, controlling component configuration entirely through attributes.

### Platforms Tested
- CentOS 7

### Chef Client
- Chef 12.x

### Cookbooks
- chef_stack
- chef_vault

## Usage

The demonstrates spinning up a Backended cluster in AWS from a Managed Chef account.
First, ensure you have a working `knife-ec2` and working Managed Chef account setup:
```
~/Devel/ChefProject/chef_infra (master=)$ cat ~/.chef/config.rb
# See http://docs.chef.io/config_rb_knife.html for more information on knife configuration options

current_dir = File.dirname(__FILE__)
log_level                :info
log_location             STDOUT
node_name                "yourmanageduser"
client_key               "#{current_dir}/yourmanageduser.pem"
ssl_ca_path              "/Users/jmiller/.chef/ca_certs"
# for validatorless, comment out next two
validation_client_name   "yourmanagedorg-validator"
validation_key           "#{current_dir}/yourmanagedorg-validator.pem"
chef_server_url          "https://manage.chef.io/organizations/yourmanagedorg"
ssl_verify_mode          :verify_none
knife[:supermarket_site] = 'https://supermarket.chef.io'
knife[:aws_access_key_id] = ".."
knife[:aws_secret_access_key] = ".."
knife[:ssh_key_name] = ".."
knife[:ssh_user] = "centos"
knife[:image] = "ami-6bb7310b"
knife[:flavor] = "c4.large"
knife[:region] = "us-west-2"
knife[:availability_zone] = "us-west-2a"

versioned_cookbooks true
knife[:chef_repo_path] = Dir.pwd
~/Devel/ChefProject/chef_infra (master=)$
```

Next, spin it up:
```
git clone https://github.com/jeremymv2/chef_infra.git
cd chef_infra
./scripts/backend_cluster.sh
```

### Topology

Desired Sequence of provisioning and convergence:

1. Chef Management Master (standalone.rb)
2. Elastic Search cluster (search.rb)
3. Chef Automate server (automate.rb)
4. Supermarket (supermarket.rb)
5. Workflow Builders (workflow_builder.rb)
6. Regional Backend Bootstrap (backend.rb)
7. Regional Backend members (backend.rb)
8. Regional Frontend Bootstrap (frontend.rb)
9. Regional Frontend members (frontend.rb)

The reason for the sequence affinity is due to secret sharing amongst the nodes.

![diagram](./images/global_arch.png)
