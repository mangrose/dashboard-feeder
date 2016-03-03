module Gorilla

  class Daemon 
    @queue = :aggregate
    MESSAGING_CHANNEL        = ENV['GORILLA_MESSAGE_PIPELINE']

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
      else
        aggregate = Gorilla::Aggregate.where(:organisation_id => :all).first
        aggregate = {} unless aggregate
      end
      payload = {:handle => 'aggregator', :text => text, :data => data, :aggregate => aggregate.to_hash}.to_json
      flush 'Published payload: #{payload}'
      @redis.publish(MESSAGING_CHANNEL, payload)
    end
    
    private 
    
    def process_payment(data)
      flush 'Processing payment'
      aggregate = Gorilla::Aggregate.where(:organisation_id => :all).first
      aggregate = Gorilla::Aggregate.make(:all) unless aggregate
      
      payment = data[:payload][:payment]
      amount = payment[:amount]
      aggregate.add_amount(amount)
      aggregate.save
      aggregate
    end
    
    def flush(str)
      puts str
      $stdout.flush
    end
  end
  
end
