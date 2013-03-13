require 'rubygems'
require 'rest_client'
require 'thread'
require_relative 'sending_thread'

start_time = nil
end_time = nil

id = ARGV[0]
config_url = 'https://raw.github.com/gist/5129352'

topology = {}
response = (RestClient.get config_url).body
response.each_line do |line|
  arr = line.chomp.split(":")
  topology[arr[0]] = {
    host: arr[1],
    port: arr[2].to_i
  }
end

recipient_id = ((id.to_i + 1) % topology.length).to_s
sending_thread = nil
threads = []

# Start a thread which listens to the open port
# and forwards on the bytes to the next link in the chain 
# unless this is member 0
threads << Thread.new do
  server = TCPServer.open(topology[id][:port])
  puts "listening..."

  client = server.accept
  bytes = 0
  buffer = client.recv(CHUNK_SIZE)
  while (buffer != END_OF_FILE && buffer.length > 0)
    buffer = buffer.strip.chomp
    if buffer != END_OF_FILE
      bytes += buffer.length
      unless id == "0"
        sending_thread << buffer
      end
    end
    buffer = client.recv(CHUNK_SIZE)
  end
  
  if id == "0"
    duration = Time.now.to_i - start_time.to_i
    puts "Completed in #{duration} seconds"
  else
    sending_thread.close
  end
  
  puts "total: received #{bytes} bytes"

  client.close
  server.close
end

# First server starts sending
if id == "0"
  print "press enter to start sending\n"
  STDIN.gets
  sending_thread = SendingThread.new(recipient_id, topology)
  threads << Thread.new { sending_thread.send }
  start_time = Time.now
  File.open "data.txt", "rb" do |io|
    pos = io.tell
    while buffer = io.read(CHUNK_SIZE)
      sending_thread << buffer.strip.chomp
      pos = io.tell
    end
  end
  sending_thread.close
else
  sending_thread = SendingThread.new(recipient_id, topology)
  threads << Thread.new { sending_thread.send }
end

threads.each(&:join)
puts "ALL DONE"
