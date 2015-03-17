require 'eventbrite-client'

class Eventbrite::AuthenticationService < BaseService

  class << self

    def client(dataset_id)
      begin
        settings = AppSetting.find_by(dataset_id: @key.app_dataset_id).settings
        auth_tokens = { app_key: settings[:app_key], user_key: settings[:user_key] }
        client = EventbriteClient.new(auth_tokens)
        return client
      rescue => e
        puts e.inspect
      end
    end

  end

end
