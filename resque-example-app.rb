require 'bundler/setup'
Bundler.require(:default)
require './lib/watermark'

configure do
  uri = URI.parse(ENV["REDISTOGO_URL"])
  Resque.redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
end

post '/upload' do
  unless params['file'][:tempfile].nil?
    tmpfile = params['file'][:tempfile]
    name = params['file'][:filename]
    file_token = send_to_s3(tmpfile, name)
    Resque.enqueue(Watermark, file_token)
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
end
