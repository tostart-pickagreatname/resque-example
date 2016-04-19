require 'bundler/setup'
Bundler.require(:default)
require File.expand_path('../lib/watermark', __FILE__)
require File.expand_path('../lib/redis_keys', __FILE__)
require 'sinatra/redis'

configure do
  redis_url = ENV["REDISCLOUD_URL"] || ENV["OPENREDIS_URL"] || ENV["REDISGREEN_URL"] || ENV["REDISTOGO_URL"]
  uri = URI.parse(redis_url)
  Resque.redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
  Resque.redis.namespace = "resque:example"
  set :redis, redis_url
end

get "/" do
  @local_uploads = redis.get local_uploads_key
  @s3_originals = redis.get s3_originals_key
  @s3_watermarked = redis.get s3_watermarked_key
  @watermarked_urls = redis.lrange(watermarked_url_list, 0, 4)
  @working = Resque.working
  erb :index
end

post '/upload' do
  unless params['file'][:tempfile].nil?
    tmpfile = params['file'][:tempfile]
    name = params['file'][:filename]
    redis.incr local_uploads_key
    file_token = send_to_s3(tmpfile, name)
    Resque.enqueue(Watermark, file_token.key)
  end
end

get '/not_upload' do
  # we want to change this so that it makes the thing that we want.
  # Resque.enqueue(Whatever)
  # this allows me to specify the queue manually, what about the class variable
  # Resque.enqueue_to(:some_queue, Whatever)

  # we see the below working:
  # 1461092419.664375 [0 [::1]:60275] "rpush" "resque:example:queue:some_queue" "{\"class\":\"ClassNameDude\",\"args\":[]}"
  # "rpush" "resque:example:queue:some_queue" "{\"class\":\"ClassNameDude\",\"args\":[]}"
  # "rpush" "resque:example:queue:some_queue" "{\"class\":\"Whatever\",\"args\":[]}"
  Resque.push(:my_some_queue, class: 'NotWatermark', args: [])
end

def send_to_s3(tmpfile, name)
  connection = Fog::Storage.new({
    :provider => 'AWS',
    :aws_access_key_id => ENV['AWS_ACCESS_KEY_ID'],
    :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
  })

  directory = connection.directories.get(ENV['AWS_S3_BUCKET_ORIGINALS'])
  file_token = directory.files.create(
    :key    => name,
    :body   => File.open(tmpfile),
    :public => true
  )
  redis.incr s3_originals_key
  file_token
end

class Whatever
  @queue = :not_watermark
end
