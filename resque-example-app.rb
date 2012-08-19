require 'bundler/setup'
Bundler.require(:default)
require File.expand_path('../lib/watermark', __FILE__)
require File.expand_path('../lib/redis_keys', __FILE__)
require 'sinatra/redis'

configure do
  uri = URI.parse(ENV["REDISTOGO_URL"])
  Resque.redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
  Resque.redis.namespace = "resque:example"
  set :redis, ENV["REDISTOGO_URL"]
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
