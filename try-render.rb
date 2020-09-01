require 'rubygems'
require 'cowsay'
require 'fauna'
require 'nokogiri'
require 'webrick'

puts("Cowsay gem version: " + Cowsay::VERSION)
puts("WEBrick gem version: " + WEBrick::VERSION)
puts("Fauna gem version: " + Fauna::VERSION)
puts("Nokogiri gem version: " + Nokogiri::VERSION)
puts("$LOAD_PATH: " + $LOAD_PATH.to_s)

class Handler < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    name = req.query['name'] || 'World'
    res.status = 200
    res['Content-Type'] = 'text/text; charset=utf-8'
    res.body = Cowsay.say("Hello #{name}", 'cow')
  end
end

server = WEBrick::HTTPServer.new(:Port => 8000)
server.mount("/", Handler)

['INT', 'TERM'].each {|signal|
  trap(signal) {server.shutdown}
}

server.start()
