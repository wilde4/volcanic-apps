require 'eventbrite-client'

class Eventbrite::AuthenticationService < BaseService

  class << self

    def client(dataset_id)
      begin
        settings = AppSetting.find_by(dataset_id: @key.app_dataset_id).settings
        client = EventbriteClient.new({ access_token: settings[:access_token] })
        return client
      rescue => e
        puts e.inspect
      end
    end

  end

end
