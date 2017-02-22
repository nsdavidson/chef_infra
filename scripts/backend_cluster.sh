#!/bin/bash
set -e

STACK_PREFIX=chefinfra
declare -a requiredgems=("knife-acl" "knife-config" "knife-ec2")
for gem in "${requiredgems[@]}"
do
  chef gem list "$gem" | grep -q "$gem" | chef gem install "$gem"
done
KNIFE_USER=`knife config node_name | awk -F: '{print $2}' | sed -e 's/^ *//'`
VAULT_ADMIN=${KNIFE_USER:-admin}

knife group show chef_stack_admins || knife group create chef_stack_admins 
for role in `ls test/fixtures/roles/*.json`; do knife role from file $role & done
knife vault show chef_stack infra_secrets || knife vault create chef_stack infra_secrets -A $VAULT_ADMIN -J test/fixtures/data_bags/chef_stack/infra_secrets.json -S "name:$STACK_PREFIX**" -M client 
knife acl add group chef_stack_admins data chef_stack create,update,read
knife acl add group chef_stack_admins containers clients read

declare -a servers=("backend01" "backend02" "backend03" "frontend01" "frontend02")
for server in "${servers[@]}"
do
  knife node show $STACK_PREFIX-$server || knife ec2 server create -N $STACK_PREFIX-$server
done

knife vault update chef_stack infra_secrets -A $VAULT_ADMIN -S "name:$STACK_PREFIX**" -M client
knife acl bulk add group chef_stack_admins clients '.*' read -y

knife group add client $STACK_PREFIX-backend01 chef_stack_admins
knife group add client $STACK_PREFIX-frontend01 chef_stack_admins

berks install
berks update
berks vendor
knife cookbook upload -a -o berks-cookbooks/

knife node run_list set $STACK_PREFIX-backend01 'role[bootstrap_backend],recipe[chef_infra::backend]'
knife ssh "name:$STACK_PREFIX-backend01" "sudo chef-client"
knife node run_list set $STACK_PREFIX-backend02 'recipe[chef_infra::backend]'
knife ssh "name:$STACK_PREFIX-backend02" "sudo chef-client"
knife node run_list set $STACK_PREFIX-backend03 'recipe[chef_infra::backend]'
knife ssh "name:$STACK_PREFIX-backend03" "sudo chef-client"
knife node run_list set $STACK_PREFIX-frontend01 'role[bootstrap_frontend],recipe[chef_infra::frontend]'
knife ssh "name:$STACK_PREFIX-frontend01" "sudo chef-client"
knife node run_list set $STACK_PREFIX-frontend02 'recipe[chef_infra::frontend]'
knife ssh "name:$STACK_PREFIX-frontend02" "sudo chef-client"
