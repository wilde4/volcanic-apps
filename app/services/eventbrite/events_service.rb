class Eventbrite::EventsService < BaseService

  class << self

    def initialize(dataset_id)
      @dataset_id = dataset_id
      @client = EventBrite::AuthenticationService.client(@dataset_id)
    end


    def all_events
      begin
        response = @client.user_list_events()
        return response
      rescue => e
        puts e.inspect
      end
    end


    def search(query)
      begin
        response = @client.event_search(query)
        events = events_json_mapper(response)
        return events
      rescue => e
        puts e.inspect
      end
    end


    def import_event(event_id)
      begin
        response = @client.event_get({ id: event_id })
        events = events_json_mapper(response)
        return events
      rescue => e
        puts e.inspect
      end
    end


    private

      def events_json_mapper(response)
        return if response["events"][1].nil?
        events = response["events"]
        all_events = Array.new
        events.map do |e|
          if e["event"]
            event = Hash.new
            event["id"] = e["event"]["id"]
            event["title"] = e["event"]["title"]
            event["url"] = e["event"]["url"]
            event["logo"] = e["event"]["logo"]
            event[:start_date_time] = date_parser(e["event"]["start_date"], e["event"]["timezone"])
            event[:end_date_time] = date_parser(e["event"]["end_date"], e["event"]["timezone"])
            event[:publish_date] = date_parser(e["event"]["created"], e["event"]["timezone"])
            all_events << event
          end
        end
        return all_events.to_json
      end


      def date_parser(date, timezone)
        ActiveSupport::TimeZone[timezone].parse(date)
      end


  end

end
