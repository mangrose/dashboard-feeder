require 'sinatra/redis'
module Gorilla
  class App < Sinatra::Base
    helpers ResponseHelper

    CHANNEL        = ENV['GORILLA_MESSAGE_PIPELINE']

    configure do
      redis_url = ENV['REDISCLOUD_URL']
      puts "REDIS: #{redis_url}"
      uri = URI.parse(redis_url)
      Resque.redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
      Resque.redis.namespace = 'resque:example'
      puts 'Configured Resque'
      set :redis, redis_url
      set :views, File.join(File.dirname(__FILE__), '../views')
    end
    
    get '/' do
      @aggregate = Gorilla::Aggregate.first
      erb :'index.html'
    end

    get '/aggregate' do
      json_response(:raw => true, :logging => false) do
        Gorilla::Aggregate.first.to_hash
      end
    end

    post '/event/receive' do
      json = request.body.read
      data = JSON.parse(json, :symbolize_names => true)
      if data[:event] == 'payment_success'
        Resque.enqueue(Gorilla::Daemon, json)
      end
      process_event(data)

      200
    end
    
    get '/dynamic/assets/js/application.js' do
      content_type :js
      @scheme = ENV['RACK_ENV'] == 'production' ? 'wss://' : 'ws://'
      puts 'scheme: #{@scheme}'
      erb :'application.js'
    end
    
    private

    def process_event(data)
      if data[:event] == 'payment_success'
        order = data[:payload][:order]
        product_code = order[:details].first[:product_code]
        payment = data[:payload][:payment]
        currency = currency(data)
        method = 'using my credit card' if order[:payment_option] == 'creditcard'
        method = 'using my phone' if order[:payment_option] == 'sms'
        method = 'asking for an invoice' if order[:payment_option] == 'invoice'
        method = 'using my bank' if order[:payment_option] == 'directdebit'
        method = 'asking for autogiro payment' if order[:payment_option] == 'autogiro'

        message = "Hey! I just payed #{payment[:amount]} #{currency} #{method} for product #{product_code}!"
        if order[:payment_option] == 'free'
          message = "Hey! I just got #{product_code} for free!"
        end
        publish_event(data, message)
      end
    end

    def publish_event(data, message)
      handle = "#{data[:payload][:account][:contact_email]}"

      publish(handle, oid(data), data[:timestamp], message)
    end

    def publish(handle, oid, timestamp, message)
      data = {:handle => handle, :oid => oid, :timestamp => timestamp, :text => message}.to_json
      redis_client.publish(CHANNEL, sanitize(data))
    end

    def currency(data)
      euro_oids = %w(hameensanomat forssanlehti media marvamedia alandstidningen)
      return '€' if euro_oids.include?(oid(data))
      'SEK'
    end

    def oid(data)
      data[:payload][:account][:organisation_id]
    end

    def sanitize(message)
      json = JSON.parse(message)
      json.each {|key, value| json[key] = ERB::Util.html_escape(value) }
      JSON.generate(json)
    end

    def redis_client
      redis_url = ENV['REDISCLOUD_URL']
      uri = URI.parse(redis_url)
      Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
    end
  end
end