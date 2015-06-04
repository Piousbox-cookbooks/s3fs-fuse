#
# Cookbook Name: s3fs-fuse
# Recipe:        test
# Description:   copy a bunch of files and see that they match the checksum.
#

def puts! arg, label=""
  puts "+++ +++ #{label}"
  puts arg.inspect
end

