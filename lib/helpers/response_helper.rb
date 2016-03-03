module ResponseHelper
  def json_response(opts = {})
    raw = opts[:raw] || false

    content_type :json
    status 200

    response = begin
      raw ? yield : {:status => 'ok', :result => yield}
    rescue => e
      logger.error "Exception => #{e.message}"
      logger.error "Backtrace: #{e.backtrace.join("\n")}"
      {:status => 'error',
       :message => e.message}
    end
    json = JSON.generate(response)
    json
  end
end
Sinatra::helpers ResponseHelper

