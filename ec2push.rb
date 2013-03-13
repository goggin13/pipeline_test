
key_path = '/Users/goggin/.ec2/5300.pem'
servers = [
  'ec2-23-20-57-177.compute-1.amazonaws.com',
  'ec2-54-242-170-99.compute-1.amazonaws.com',
  'ec2-50-16-152-175.compute-1.amazonaws.com',
  'ec2-23-22-127-206.compute-1.amazonaws.com',
  'ec2-54-234-28-68.compute-1.amazonaws.com',
  'ec2-54-234-225-86.compute-1.amazonaws.com',
  'ec2-184-72-181-60.compute-1.amazonaws.com',
  'ec2-54-234-216-76.compute-1.amazonaws.com'
]

servers.each do |server|
  cmd = "scp -i #{key_path} -r . ec2-user@#{server}:~/apps/test"
  puts cmd
  puts system(cmd) ? "\tsuccess" : "\tfailed"
end



