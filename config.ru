require File.join(File.dirname(__FILE__), 'lib/lib')
require File.join(File.dirname(__FILE__), 'init')
require 'resque/server'

use Rack::Static,
    :urls => ["/assets"],
    :root => "public"

map '/' do
  run Gorilla::App
end