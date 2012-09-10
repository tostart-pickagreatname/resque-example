require './resque-example-app.rb'
require 'resque/server'

STDOUT.sync = true

run Rack::URLMap.new \
  "/"       => Sinatra::Application,
  "/resque" => Resque::Server.new
