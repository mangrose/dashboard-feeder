require 'sinatra/redis'
module Gorilla
  class App < Sinatra::Base
    helpers ResponseHelper

    CHANNEL        = ENV['GORILLA_MESSAGE_PIPELINE']

    def protected!
      unless authorized?
        response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
        throw(:halt, [401, "Not authorized\n"])
      end
    end

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [ENV['API_USER'], ENV['API_PASSWORD']]
    end

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
      @aggregate = Gorilla::PaymentAggregate.first
      erb :'index.html'
    end

    get '/payments' do
      protected!
      aggregate = Gorilla::PaymentAggregate.first
      aggregate = Gorilla::PaymentAggregate.make unless aggregate
      json_response(:raw => false) do
        aggregate.to_hash
      end
    end

    get '/accounts' do
      protected!
      aggregate = Gorilla::AccountAggregate.first
      aggregate = Gorilla::AccountAggregate.make unless aggregate
      json_response(:raw => false) do
        aggregate.to_hash
      end
    end

    get '/orders' do
      protected!
      aggregate = Gorilla::OrderAggregate.first
      aggregate = Gorilla::OrderAggregate.make unless aggregate
      json_response(:raw => false) do
        aggregate.to_hash
      end
    end

    post '/event/receive' do
      protected!
      json = request.body.read
      data = JSON.parse(json, :symbolize_names => true)
      events = %w(payment_success new_account_registered order_closed account_activated_for_existing_customer)
      if events.include?(data[:event])
        Resque.enqueue(Gorilla::Daemon, json)
      end
      process_event(data)

      200
    end

    post '/data/reset' do
      protected!
      json = request.body.read

      begin
        data = JSON.parse(json, :symbolize_names => true)
        seed = data[:seed]
        return 400 unless seed

        if seed.has_key?(:accounts)
          created = seed[:accounts].fetch(:total_created, 0)
          created_today = seed[:accounts].fetch(:total_created_today, 0)
          activated = seed[:accounts].fetch(:total_activated, 0)
          activated_today = seed[:accounts].fetch(:total_activated_today, 0)
          puts "Resetting account data. total created => #{created} activated => #{activated}"
          aggregate = Gorilla::AccountAggregate.first
          aggregate = Gorilla::AccountAggregate.make unless aggregate
          aggregate.total_created = created
          aggregate.total_activated = activated
          aggregate.total_created_day = created_today
          aggregate.total_activated_day = activated_today
          aggregate.save
        end
        if seed.has_key?(:orders)
          total_orders = seed[:orders].fetch(:total, 0)
          total_orders_today = seed[:orders].fetch(:total_today, 0)
          puts "Resetting order data. total closed => #{total_orders} today => #{total_orders_today}"
          aggregate = Gorilla::OrderAggregate.first
          aggregate = Gorilla::OrderAggregate.make unless aggregate
          aggregate.total = total_orders
          aggregate.total_day = total_orders_today
          aggregate.save
        end
        if seed.has_key?(:payments)
          total_amount = seed[:payments].fetch(:total_amount, '0')
          total_amount_today = seed[:payments].fetch(:total_amount_today, '0')
          total_transactions = seed[:payments].fetch(:total_transactions, 0)
          puts "Resetting payment data. total amount => #{total_amount} today => #{total_amount_today}"
          aggregate = Gorilla::PaymentAggregate.first
          aggregate = Gorilla::PaymentAggregate.make unless aggregate
          aggregate.total = total_amount
          aggregate.total_day = total_amount_today
          aggregate.total_transactions = total_transactions
          aggregate.save
        end

        200
      rescue => e
        puts e.message
        400
      end
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