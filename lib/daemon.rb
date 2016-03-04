module Gorilla

  class Daemon 
    @queue = :aggregate

    def initialize
      puts 'Initializing worker'
      Mongoid.load!('mongoid.yml')
      redis_url = ENV['REDISCLOUD_URL']
      uri = URI.parse(redis_url)
      @redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
    end
    
    def self.perform(json)
      (new).perform_aggregation(json)
    end    
  
    def perform_aggregation(json)
      data = JSON.parse(json, :symbolize_names => true)
      event_name = data[:event]
      text = 'Got external event &#40;#{event_name}&#41; at #{data[:timestamp]}'
      if event_name == 'payment_success'
        aggregate = process_payment(data)
      elsif  event_name == 'order_closed'
        aggregate = process_order_closed(data)
      elsif event_name == 'account_activated_for_existing_customer'
        aggregate = process_account_activated(data)
      elsif event_name == 'new_account_registered'
        aggregate = process_account_created(data)
      end
      flush 'Aggregation completed'
    end
    
    private

    def process_payment(data)
      flush 'Processing payment'
      aggregate = Gorilla::PaymentAggregate.first
      aggregate = Gorilla::PaymentAggregate.make unless aggregate

      payment = data[:payload][:payment]
      amount = payment[:amount]
      aggregate.add_amount(amount)
      aggregate.save
      aggregate
    end

    def process_account_created(data)
      flush 'Processing account created'
      aggregate = Gorilla::AccountAggregate.first
      aggregate = Gorilla::AccountAggregate.make unless aggregate

      aggregate.increment_account_created
      aggregate.save
      aggregate
    rescue => e
      flush e.message
      aggregate
     end

    def process_account_activated(data)
      flush 'Processing account activated'
      aggregate = Gorilla::AccountAggregate.first
      aggregate = Gorilla::AccountAggregate.make unless aggregate

      aggregate.increment_account_activated
      aggregate.save
      p aggregate
      aggregate
    end

    def process_order_closed(data)
      flush 'Processing order closed'
      aggregate = Gorilla::OrderAggregate.first
      aggregate = Gorilla::OrderAggregate.make unless aggregate

      aggregate.increment_order_closed
      aggregate.save
      aggregate
    end

    def flush(str)
      puts str
      $stdout.flush
    end
  end
  
end
