module Payloadable
  extend ActiveSupport::Concern

  

  def post_to_api(resource, action=nil, payload)    
    

    if action
      endpoint_str = "https://#{@key.host}/api/v1/#{resource}/#{action}.json"
    else
      endpoint_str = "https://#{@key.host}/api/v1/#{resource}.json"
    end

    data = {
      :api_key => @key.api_key,
      :payload => payload 
    }
    # Make HTTParty go talk to the API:
    puts "---- POSTING TO API ------"
    response = HTTParty.post(endpoint_str, { body: data })
    return response.body
  end


end