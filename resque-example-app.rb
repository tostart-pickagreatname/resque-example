require 'bundler/setup'
Bundler.require(:default)

module PopString
  @queue = :puts

  def self.perform(str)
    puts "Received #{str}"
  end
end

configure do
  uri = URI.parse(ENV["REDISTOGO_URL"])
  Resque.redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
end

get '/pop/:str' do
  Resque.enqueue(PopString, params['str'])
  puts "Popping #{params['str']} onto the queue..."
end
