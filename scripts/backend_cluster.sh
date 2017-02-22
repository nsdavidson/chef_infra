#!/bin/bash
set -e

STACK_PREFIX=chefinfra
chef gem list knife-config | grep -c knife-config || echo chef gem install knife-config
VAULT_ADMIN=`knife config node_name | awk -F: '{print $2}' | sed -e 's/^ *//'`

knife group destroy chef_stack_admins -y
knife group create chef_stack_admins
for role in `ls test/fixtures/roles/*.json`; do knife role from file $role & done
knife vault delete chef_stack infra_secrets -M client -y
knife vault create chef_stack infra_secrets -A $VAULT_ADMIN -J test/fixtures/data_bags/chef_stack/infra_secrets.json -S "name:$STACK_PREFIX**" -M client
knife acl add group chef_stack_admins data chef_stack create,update,read
knife acl add group chef_stack_admins containers clients read

knife ec2 server create -N $STACK_PREFIX-backend01 -r ""
knife ec2 server create -N $STACK_PREFIX-backend02 -r ""
knife ec2 server create -N $STACK_PREFIX-backend03 -r ""
knife ec2 server create -N $STACK_PREFIX-frontend01 -r ""
knife ec2 server create -N $STACK_PREFIX-frontend02 -r ""

knife vault update chef_stack infra_secrets -A $VAULT_ADMIN -S "name:$STACK_PREFIX**" -M client
knife acl bulk add group chef_stack_admins clients '.*' read -y

knife group add client $STACK_PREFIX-backend01 chef_stack_admins
knife group add client $STACK_PREFIX-frontend01 chef_stack_admins

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
