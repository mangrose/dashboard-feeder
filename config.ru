require File.join(File.dirname(__FILE__), 'lib/lib')
require File.join(File.dirname(__FILE__), 'init')
require 'resque/server'

use Rack::Static,
    :urls => ["/assets"],
    :root => "public"

use Gorilla::SocketBackend

map '/' do
  run Gorilla::App
end

map '/resque' do
  run Resque::Server
end
