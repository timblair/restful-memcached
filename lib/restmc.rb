require 'rubygems'
require 'sinatra/base'
require 'memcached'

module RESTmc
  class Application < Sinatra::Base
    mime_type :text, 'text/plain'
    set :reload_templates, false  # we have no templates

    ENABLE_MARSHAL = FALSE
    DEFAULT_TTL = 0  # never expire; use @mc.options[:default_ttl] for the client default of 1 week

    def initialize
      @mc = Memcached.new
    end

    before do
      content_type :text
    end

    get '/*' do
      begin
        @mc.get splat_to_key(params[:splat]), should_marshal?
      rescue Memcached::NotFound
        status 404
      end
    end

    put '/*' do
      @mc.set splat_to_key(params[:splat]), request.body.read, get_ttl, should_marshal?
    end

    post '/*' do
      begin
        @mc.add splat_to_key(params[:splat]), request.body.read, get_ttl, should_marshal?
      rescue Memcached::NotStored
        status 409
      end
    end

    delete '/*' do
      begin
        @mc.delete splat_to_key(params[:splat])
      rescue Memcached::NotFound
        status 404
      end
    end

    private

    def splat_to_key(splat)
      splat.first.split(/\//).join(':')
    end

    def get_ttl
      ttl = DEFAULT_TTL
      if request.env['HTTP_CACHE_CONTROL']
        control = request.env['HTTP_CACHE_CONTROL'].split(/\=/)
        ttl = control.last.to_i if control.first == 'max-age'
      end
      ttl
    end

    def should_marshal?
      ENABLE_MARSHAL
    end

  end
end
