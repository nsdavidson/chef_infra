#!/bin/bash
knife ec2 server create -N jmiller-chef-automate -r ""
knife ec2 server create -N jmiller-chef-backend01 -r ""
knife ec2 server create -N jmiller-chef-backend02 -r ""
knife ec2 server create -N jmiller-chef-backend03 -r ""
knife ec2 server create -N jmiller-chef-runner01 -r ""
knife ec2 server create -N jmiller-chef-frontend01 -r ""
knife ec2 server create -N jmiller-chef-frontend02 -r ""
knife ec2 server create -N jmiller-chef-search01 -r ""
knife ec2 server create -N jmiller-chef-search02 -r ""
knife ec2 server create -N jmiller-chef-search03 -r ""
knife ec2 server create -N jmiller-chef-standalone -r ""
knife ec2 server create -N jmiller-chef-supermarket -r ""
knife group create chef_stack_admins
knife acl add group chef_stack_admins data chef_stack create,update,read
knife acl add group chef_stack_admins containers clients read
knife acl bulk add group chef_stack_admins clients '.*' read -y
knife group add client jmiller-chef-standalone chef_stack_admins
knife group add client jmiller-chef-automate chef_stack_admins
knife group add client jmiller-chef-backend01 chef_stack_admins
knife group add client jmiller-chef-frontend01 chef_stack_admins
knife group add client jmiller-chef-search01 chef_stack_admins
knife vault update chef_stack chef_conf_files -A jmiller,jmiller-chef-standalone,jmiller-chef-automate,jmiller-chef-backend01,jmiller-chef-frontend01 -S "name:jmiller-chef-*"
knife node run_list set jmiller-chef-standalone 'role[chef_master], recipe[jnj_chef_stack::standalone]'
knife node run_list set jmiller-chef-backend01 'role[bootstrap_backend],recipe[jnj_chef_stack::backend]'
knife node run_list set jmiller-chef-backend02 'recipe[jnj_chef_stack::backend]'
knife node run_list set jmiller-chef-backend03 'recipe[jnj_chef_stack::backend]'
knife node run_list set jmiller-chef-frontend01 'role[bootstrap_frontend],recipe[jnj_chef_stack::frontend]'
knife node run_list set jmiller-chef-frontend02 'recipe[jnj_chef_stack::frontend]' &
knife node run_list set jmiller-chef-supermarket 'recipe[jnj_chef_stack::supermarket]'
knife node run_list set jmiller-chef-automate 'recipe[jnj_chef_stack::automate]'
knife node run_list set jmiller-chef-runner01 'recipe[jnj_chef_stack::workflow_builder]'
knife node run_list set jmiller-chef-search01 'role[bootstrap_search],recipe[jnj_chef_stack::search]'
knife node run_list set jmiller-chef-search02 'recipe[jnj_chef_stack::search]'
knife node run_list set jmiller-chef-search03 'recipe[jnj_chef_stack::search]'
knife ssh "name:jmiller-chef-standalone" "sudo chef-client"
knife ssh "name:jmiller-chef-backend01" "sudo chef-client"
knife ssh "name:jmiller-chef-backend02" "sudo chef-client"
knife ssh "name:jmiller-chef-backend03" "sudo chef-client"
knife ssh "name:jmiller-chef-frontend01" "sudo chef-client"
knife ssh "name:jmiller-chef-frontend02" "sudo chef-client"
knife ssh "name:jmiller-chef-supermarket" "sudo chef-client"
knife ssh "name:jmiller-chef-search01" "sudo chef-client"
knife ssh "name:jmiller-chef-search02" "sudo chef-client"
knife ssh "name:jmiller-chef-search03" "sudo chef-client"
knife ssh "name:jmiller-chef-automate" "sudo chef-client"
knife ssh "name:jmiller-chef-runner01" "sudo chef-client"
