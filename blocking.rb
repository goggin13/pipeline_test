require 'rest_client'

url = "http://localhost:3000/"
url = "https://raw.github.com/gist/5129352"
iterations = 10

def do_sys_call
  #s = Time.now
  #RestClient.get url
  #puts "retrieved in #{Time.now - s} seconds"
  system("sleep 1")
end

start = Time.now
threads = []
iterations.times {
  threads << Thread.new do
    do_sys_call
  end
}

threads.each(&:join)
puts "threads completed in #{Time.now - start} seconds"

start = Time.now
iterations.times do
  do_sys_call
end

puts "sequentially completed in #{Time.now - start} seconds"
