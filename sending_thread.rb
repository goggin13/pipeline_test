require 'rubygems'
require 'rest_client'
require 'thread'


CHUNK_SIZE = 1024
END_OF_FILE = "X" * CHUNK_SIZE

class SendingThread
  
  def initialize(dest, topology)
    @data = []
    @mutex = Mutex.new
    @data_to_send = ConditionVariable.new
    @dest = dest
    @socket = TCPSocket.open(topology[dest][:host], topology[dest][:port])
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
