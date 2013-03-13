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
server = TCPServer.open(topology[id][:port])
puts "listening..."

if id == "0"

  (topology.length - 1).times do
    threads << Thread.new do
      client = server.accept
      bytes = 0
      buffer = client.recv(CHUNK_SIZE)
      while (buffer != END_OF_FILE && buffer.length > 0)
        buffer = buffer.strip.chomp
        if buffer != END_OF_FILE
          bytes += buffer.length
          puts "recd #{bytes}"
        end
        buffer = client.recv(CHUNK_SIZE)
      end
      
      duration = Time.now.to_i - start_time.to_i
      puts "Completed in #{duration} seconds"
      puts "total: received #{bytes} bytes"

      client.close
    end
  end

else
  
  threads << Thread.new do
    client = server.accept
    bytes = 0
    buffer = client.recv(CHUNK_SIZE)
    while (buffer != END_OF_FILE && buffer.length > 0)
      buffer = buffer.strip.chomp
      if buffer != END_OF_FILE
        bytes += buffer.length
      end
      buffer = client.recv(CHUNK_SIZE)
    end
    
    sending_thread.close
    puts "total: received #{bytes} bytes"
    client.close
    server.close
  end

end

# First server starts sending
if id == "0"
  print "press enter to start sending\n"
  STDIN.gets
  
  sending_threads = []
  topology.each do |k, v|
    if k != "0"
      sending_thread = SendingThread.new(k, topology)
      sending_threads << sending_thread
      threads << Thread.new { 
        sending_thread.send 
      }
    end
  end

  start_time = Time.now
  File.open "data.txt", "rb" do |io|
    pos = io.tell
    while buffer = io.read(CHUNK_SIZE)
      sending_threads.each do |st|
        st << buffer.strip.chomp
      end
      pos = io.tell
    end
  end
  sending_threads.each do |st|
    st.close
  end
else
  sending_thread = SendingThread.new("0", topology)
  threads << Thread.new { sending_thread.send }
end

threads.each(&:join)
puts "ALL DONE"
