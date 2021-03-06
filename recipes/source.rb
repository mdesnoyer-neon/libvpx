#
# Cookbook Name:: libvpx
# Recipe:: source
#
# Copyright 2014, Escape Studios
#

include_recipe "build-essential"
include_recipe "git"
include_recipe "yasm::source"

libvpx_packages.each do |pkg|
    package pkg do
        action :purge
    end
end

creates_libvpx = "#{node['libvpx']['prefix']}/bin/vpxenc"

file "#{creates_libvpx}" do
    action :nothing
    subscribes :delete, "bash[compile_yasm]", :immediately
end

git node['libvpx']['build_dir'] do
    repository node['libvpx']['git_repository']
    reference node['libvpx']['git_revision']
    action :sync
    notifies :delete, "file[#{creates_libvpx}]", :immediately
end

# Write the flags used to compile the application to Disk. If the flags
# do not match those that are in the compiled_flags attribute - we recompile
template "#{node['libvpx']['build_dir']}/libvpx-compiled_with_flags" do
    source "compiled_with_flags.erb"
    owner "root"
    group "root"
    mode 0600
    variables(
        :compile_flags => node['libvpx']['compile_flags']
    )
    notifies :delete, "file[#{creates_libvpx}]", :immediately
end

bash "compile_libvpx" do
    cwd node['libvpx']['build_dir']
    code <<-EOH
        ./configure --prefix=#{node['libvpx']['prefix']} #{node['libvpx']['compile_flags'].join(' ')}
        make clean && make && make install
    EOH
    not_if {  ::File.exists?(creates_libvpx) }
end
