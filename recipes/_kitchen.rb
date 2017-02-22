node.automatic['ipaddress'] = node['network']['interfaces']['enp0s8']['addresses'].keys[1]

hosts = Chef::Util::FileEdit.new('/etc/hosts')
hosts.insert_line_if_no_match(/backend01-centos-72/, '192.168.254.2 backend01-centos-72')
hosts.insert_line_if_no_match(/backend02-centos-72/, '192.168.254.3 backend02-centos-72')
hosts.insert_line_if_no_match(/backend03-centos-72/, '192.168.2541 backend03-centos-72')
hosts.insert_line_if_no_match(/frontend01-centos-72/, '192.168.254.4 frontend01-centos-72')
hosts.insert_line_if_no_match(/frontend02-centos-72/, '192.168.254.5 frontend02-centos-72')
hosts.insert_line_if_no_match(/automate-centos-72/, '192.168.254.7 automate-centos-72')
hosts.insert_line_if_no_match(/standalone-centos-72/, '192.168.254.6 standalone-centos-72')
hosts.insert_line_if_no_match(/supermarket-centos-72/, '192.168.254.8 supermarket-centos-72')
hosts.insert_line_if_no_match(/builder01-centos-72/, '192.168.254.9 builder01-centos-72')
hosts.insert_line_if_no_match(/search01-centos-72/, '192.168.254.10 search01-centos-72')
hosts.insert_line_if_no_match(/search02-centos-72/, '192.168.254.11 search02-centos-72')
hosts.insert_line_if_no_match(/search03-centos-72/, '192.168.254.12 search03-centos-72')
hosts.search_file_replace_line(/#{node['fqdn']}/, "#{node['ipaddress']} #{node['fqdn']}")
hosts.write_file

directory '/etc/chef' do
  action :nothing
end.run_action(:create)

template '/etc/chef/client.rb' do
  source 'workflow_knife.rb.erb'
  variables 'chef_server_url' => node['chef_stack']['chef_server_url']
  action :nothing
end.run_action(:create)
