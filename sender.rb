require 'rubygems'
require 'rest_client'
require 'thread'

END_OF_FILE = "XX"
CHUNK_SIZE = 256
start_time = nil
end_time = nil

id = ARGV[0]
config_url = 'https://raw.github.com/gist/5129352'

topology = {}
#response = (RestClient.get config_url).body
response = File.read('config.txt')
response.each_line do |line|
  arr = line.chomp.split(":")
  topology[arr[0]] = {
    host: arr[1],
    port: arr[2].to_i
  }
end

topology.delete "4"
topology.delete "5"

recipient_id = ((id.to_i + 1) % topology.length).to_s

class SendingThread
  
  def initialize(dest, topology)
    @data = []
    @mutex = Mutex.new
    @data_to_send = ConditionVariable.new
    @socket = TCPSocket.open(topology[dest][:host], topology[dest][:port])
    @counter = 0
    @sending = true
    @sent = 0
  end

  def <<(data)
    @mutex.synchronize do
      @data << data
      @data_to_send.signal
    end
  end

  def send
    @mutex.synchronize do
      while (@sending)
        while (@sending && @data.length == 0)
          @data_to_send.wait(@mutex)
        end
        while (@data.length > 0)
          d = @data.pop
          @sent += d.length
          @socket.write d
        end
      end
      @socket.puts END_OF_FILE
      @socket.close
      puts "Done sending #{@sent} bytes"
    end
  end

  def close
    @mutex.synchronize do
      @sending = false      
      @data_to_send.signal
    end
  end
end


sending_thread = nil
threads = []
threads << Thread.new do
  server = TCPServer.open(topology[id][:port])
  puts "#{topology[id]} : listening..."

  client = server.accept
  bytes = 0
  buffer = client.recv(CHUNK_SIZE)
  f = File.open id, 'w'
  while (buffer != END_OF_FILE && buffer.length > 0)
    if buffer != END_OF_FILE
      bytes += buffer.length
      f.write buffer
      unless id == "0"
        sending_thread << trimmed
      end
    end
    buffer = client.recv(CHUNK_SIZE)
  end
  
  f.close
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
