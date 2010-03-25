require 'rubygems'
require 'sinatra'
require 'memcached'

mc = Memcached.new("localhost:11211")
mime_type :text, 'text/plain'

get '/*' do
  content_type :text
  begin
    mc.get splat_to_key(params[:splat])
  rescue Memcached::NotFound
    status 404
  end
end

put '/*' do
  mc.set splat_to_key(params[:splat]), request.body.read
end

post '/*' do
  begin
    mc.add splat_to_key(params[:splat]), request.body.read
  rescue Memcached::NotStored
    status 409
  end
end

delete '/*' do
  begin
    mc.delete splat_to_key(params[:splat])
  rescue Memcached::NotFound
    status 404
  end
end

def splat_to_key(splat)
  splat.first.split(/\//).join(':')
end
