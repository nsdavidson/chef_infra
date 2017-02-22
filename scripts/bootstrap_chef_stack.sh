#!/bin/bash
set -e
STACK_PREFIX=${1:-chef-stack}
VAULT_ADMIN=${2:-chef}

# Make all the servers with empty run_lists so we can register their clients with chef-vault.
knife ec2 server create -N $STACK_PREFIX-automate -r "" &
knife ec2 server create -N $STACK_PREFIX-backend01 -r "" &
sleep 1
knife ec2 server create -N $STACK_PREFIX-backend02 -r "" &
knife ec2 server create -N $STACK_PREFIX-backend03 -r "" &
sleep 1
knife ec2 server create -N $STACK_PREFIX-runner01 -r "" &
knife ec2 server create -N $STACK_PREFIX-frontend01 -r "" &
sleep 1
knife ec2 server create -N $STACK_PREFIX-frontend02 -r "" &
knife ec2 server create -N $STACK_PREFIX-search01 -r "" &
sleep 1
knife ec2 server create -N $STACK_PREFIX-search02 -r "" &
knife ec2 server create -N $STACK_PREFIX-search03 -r "" &
sleep 1
knife ec2 server create -N $STACK_PREFIX-standalone -r "" &
knife ec2 server create -N $STACK_PREFIX-supermarket -r ""
# Create the chef_stack_admins group and give it the permissions it needs.
# Hack so the script doesn't error out if the group exists.
set +e
knife group create chef_stack_admins
for role in `ls test/fixtures/roles/*.json`; do knife role from file $role & done
knife vault create chef_stack infra_secrets -A $VAULT_ADMIN -J test/fixtures/data_bags/chef_stack/infra_secrets.json -S "name:$STACK_PREFIX**"
knife vault update chef_stack infra_secrets -A $VAULT_ADMIN,$STACK_PREFIX-standalone,$STACK_PREFIX-backend01,$STACK_PREFIX-search01,$STACK_PREFIX-automate,$STACK_PREFIX-frontend01 -J test/fixtures/data_bags/chef_stack/infra_secrets.json -S "name:$STACK_PREFIX**"
set -e
knife acl add group chef_stack_admins data chef_stack create,update,read
knife acl add group chef_stack_admins containers clients read
echo 'Sleeping for 5 seconds because race conditions and whatnot..'
sleep 5
knife acl bulk add group chef_stack_admins clients '.*' read -y
# Add the clients that need to write secrets to the chef_stack_admins group.
knife group add client $STACK_PREFIX-standalone chef_stack_admins
knife group add client $STACK_PREFIX-automate chef_stack_admins
knife group add client $STACK_PREFIX-backend01 chef_stack_admins
knife group add client $STACK_PREFIX-frontend01 chef_stack_admins
knife group add client $STACK_PREFIX-search01 chef_stack_admins
# Update client keys for all the vaults. I'm not sure if any clients need to be admin since using knife acl.
knife cookbook upload jnj_chef_stack -o ../
knife node run_list set $STACK_PREFIX-standalone 'role[chef_master], recipe[jnj_chef_stack::standalone]' &
knife node run_list set $STACK_PREFIX-backend01 'role[bootstrap_backend],recipe[jnj_chef_stack::backend]' &
knife node run_list set $STACK_PREFIX-backend02 'recipe[jnj_chef_stack::backend]' &
knife node run_list set $STACK_PREFIX-backend03 'recipe[jnj_chef_stack::backend]' &
knife node run_list set $STACK_PREFIX-frontend01 'role[bootstrap_frontend],recipe[jnj_chef_stack::frontend]' &
knife node run_list set $STACK_PREFIX-frontend02 'recipe[jnj_chef_stack::frontend]' &
knife node run_list set $STACK_PREFIX-supermarket 'recipe[jnj_chef_stack::supermarket]' &
knife node run_list set $STACK_PREFIX-automate 'recipe[jnj_chef_stack::automate]' &
knife node run_list set $STACK_PREFIX-runner01 'recipe[jnj_chef_stack::workflow_builder]' &
knife node run_list set $STACK_PREFIX-search01 'role[bootstrap_search],recipe[jnj_chef_stack::search]' &
knife node run_list set $STACK_PREFIX-search02 'recipe[jnj_chef_stack::search]' &
knife node run_list set $STACK_PREFIX-search03 'recipe[jnj_chef_stack::search]'
# Converge nodes in parallel where possible
# Converge the master chef standalone and backend/search bootstraps
knife ssh "name:$STACK_PREFIX-standalone OR name:$STACK_PREFIX-backend01 OR name:$STACK_PREFIX-search01" "sudo chef-client"
# Converge the non-bootstrap backends/searchs
knife ssh "name:$STACK_PREFIX-backend02 OR name:$STACK_PREFIX-search02" "sudo chef-client"
knife ssh "name:$STACK_PREFIX-backend03 OR name:$STACK_PREFIX-search03" "sudo chef-client"
# Converge the bootstrap frontend that seeds the database.
knife ssh "name:$STACK_PREFIX-frontend01" "sudo chef-client"
# Converge the non bootstrap frontend, supermarket, and automate
knife ssh "name:$STACK_PREFIX-frontend02 OR name:$STACK_PREFIX-supermarket OR name:$STACK_PREFIX-automate" "sudo chef-client"
# Converge a runner
knife ssh "name:$STACK_PREFIX-runner01" "sudo chef-client"
