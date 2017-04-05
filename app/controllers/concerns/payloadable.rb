module Payloadable
  extend ActiveSupport::Concern

  def post_to_api(resource, action=nil, payload)        

    puts "\n\n Posting to API - Sending Notification \n\n"

    if action
      
      if request.env['SERVER_NAME'].eql? "localhost"
        endpoint_str = "http://#{@key.host}:3000/api/v1/#{resource}/#{action}.json"
      else
        endpoint_str = "http://#{@key.host}/api/v1/#{resource}/#{action}.json"
      end
    
    else

      if request.env['SERVER_NAME'].eql? "localhost"
        endpoint_str = "http://#{@key.host}:3000/api/v1/#{resource}.json"
      else
        endpoint_str = "http://#{@key.host}/api/v1/#{resource}.json"
      end
    end

    data = {
      :api_key => @key.api_key,
      :payload => payload 
    }
    # Make HTTParty go talk to the API:
    puts "---- POSTING TO API: #{endpoint_str} ------"
    puts data
    response = HTTParty.post(endpoint_str, { body: data })
    return response.body
  end


end