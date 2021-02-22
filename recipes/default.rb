#
# Cookbook:: pozoledf-sample-app-deployment
# Recipe:: default
#
# Copyright:: 2021, The Authors, All Rights Reserved.

directory "/var/lib/sample-app/#{version}" do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
  recursive true
end

cookbook_file "/var/lib/sample-app/#{version}/manifests/" do
  source 'manifests/*'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

bash 'kubectl' do
  cwd "/var/lib/sample-app/#{version}/manifests"
  code <<-EOH
    kubectl apply -k .
  EOH
  action :run
end
