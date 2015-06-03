#
# Cookbook Name:: s3fs-fuse
# Recipe:: default
#

def puts! arg, label=""
  puts "+++ +++ #{label}"
  puts arg.inspect
end

mounted_directories = node[:s3fs_fuse][:mounts]
if(mounted_directories.is_a?(Hash) || !mounted_directories.respond_to?(:each))
  mounted_directories = [node[:s3fs_fuse][:mounts]].compact
end
# puts! mounted_directories
# => [{"bucket"=>"some-bucket", "path"=>"/mnt/some-bucket", "tmp_store"=>"/tmp/cache"}]

mounted_directories.each do |mount_point|
  directory mount_point[:path] do
    recursive true
    action :create
	not_if { File.directory? mount_point[:path] }
  end
end

include_recipe "s3fs-fuse::install"

# edit /etc/hosts file
mounted_directories.each do |m|
  bucket_name = m['bucket']
  hosts_line = "#{node[:s3fs_fuse][:s3_ip]}     #{bucket_name}.#{node[:s3fs_fuse][:s3_domain]}"
  if File.read("/etc/hosts").include?( hosts_line )
    # do nothing
  else
    cmd = %| echo "#{hosts_line}" >> /etc/hosts |
    puts! cmd
    ` #{cmd} `
  end
end

if(node[:s3fs_fuse][:bluepill])
  include_recipe 's3fs-fuse::bluepill'
elsif(node[:s3fs_fuse][:rc_mon])
  include_recipe 's3fs-fuse::rc_mon'
else
  mounted_directories.each do |dir_info|
    mount dir_info[:path] do
      device "s3fs##{dir_info[:bucket]}"
      fstype 'fuse'
      dump 0
      pass 0
      options "allow_other,url=http://#{node[:s3fs_fuse][:s3_domain]}:#{node[:s3fs_fuse][:s3_path]},passwd_file=/etc/passwd-s3fs,use_cache=#{dir_info[:tmp_store] || '/tmp/s3_cache'},retries=20#{",noupload" if dir_info[:no_upload]},#{dir_info[:read_only] ? 'ro' : 'rw'}"
      action [:mount, :enable]
      not_if "mountpoint -q #{dir_info[:path]}"
    end
  end
end
