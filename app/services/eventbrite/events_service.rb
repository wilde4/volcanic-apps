class Eventbrite::EventsService < BaseService

  class << self

    def all_events(dataset_id)
      begin
        @client = Eventbrite::AuthenticationService.client(dataset_id)
        events = events_json_mapper(response)
        return events
      rescue => e
        puts e.inspect
      end
    end


    def search(dataset_id, query)
      begin
        @client = Eventbrite::AuthenticationService.client(dataset_id)
        response = @client.event_search({ keywords: query })
        return response
      rescue => e
        puts e.inspect
      end
    end


    def import_event(dataset_id, event_id)
      begin
        @client = Eventbrite::AuthenticationService.client(dataset_id)
        response = @client.event_get({ id: event_id })
        return response
      rescue => e
        puts e.inspect
      end
    end

  end

end
