require 'rest-client'

module Gorilla

  class Daemon
    @queue = :aggregate

    def initialize
      puts 'Initializing worker'
      Mongoid.load!('mongoid.yml')
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
      aggregate.add_amount(amount, currency(data))
      aggregate.save
      update_widget('money-today', aggregate)

      aggregate
    end

    def process_account_created(data)
      flush 'Processing account created'
      aggregate = Gorilla::AccountAggregate.first
      aggregate = Gorilla::AccountAggregate.make unless aggregate

      aggregate.increment_account_created
      aggregate.save

      update_widget('accounts-today', aggregate)
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

      update_widget('activations-today', aggregate)
      aggregate
    end

    def process_order_closed(data)
      flush 'Processing order closed'
      aggregate = Gorilla::OrderAggregate.first
      aggregate = Gorilla::OrderAggregate.make unless aggregate

      aggregate.increment_order_closed
      aggregate.save
      update_widget('orders-today', aggregate)
      aggregate
    end

    def update_widget(widget, aggregate)
      dashing_app_url = ENV['DASHING_APP_URL']
      dashing_app_token = ENV['DASHING_APP_TOKEN']
      data = {:auth_token => dashing_app_token}

      #curl -d '{"auth_token":"my-secret-token-1234","current":4}' http://payway-dash.herokuapp.com/widgets/accounts-today
      if widget == 'accounts-today'
        data = data.merge({:current => aggregate.total_created_day})
      elsif widget == 'activations-today'
        data = data.merge({:current => aggregate.total_activated_day})
      elsif widget == 'orders-today'
        data = data.merge({:current => aggregate.total_day})
      elsif widget == 'money-today'
        data = data.merge({:current => aggregate.total_day})
      end
      url = "#{dashing_app_url}/widgets/#{widget}"
      puts "Updating widget: #{widget}"
      RestClient.post(url, data.to_json)
    end

    def flush(str)
      puts str
      $stdout.flush
    end

    def currency(data)
      euro_oids = %w(hameensanomat forssanlehti media marvamedia alandstidningen)
      return '€' if euro_oids.include?(oid(data))
      'SEK'
    end

    def oid(data)
      data[:payload][:account][:organisation_id]
    end

  end

end
