class Eventbrite::EventsService < BaseService

  class << self

    def initialize(dataset_id)
      @dataset_id = dataset_id
      @client = EventBrite::AuthenticationService.client(@dataset_id)
    end


    def search(query)
      begin
        response = @client.event_search(query)
        return response
      rescue => e
        puts e.inspect
      end
    end


    def import_event(event_id)
      begin
        response = @client.event_get({ id: event_id })
        # PERSIST DATA
      rescue => e
        puts e.inspect
      end
    end


  end

end
