require 'eventbrite-client'

class Eventbrite::AuthenticationService < BaseService

  class << self

    def client(dataset_id)
      begin
        @settings = EventbriteSetting.find_by(dataset_id: dataset_id)
        client = EventbriteClient.new({ access_token: @settings.access_token })
        return client
      rescue => e
        puts e.inspect
      end
    end

  end

end
