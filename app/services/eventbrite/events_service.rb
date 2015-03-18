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
        response = @client.event_search(query)
        events = events_json_mapper(response)
        return events
      rescue => e
        puts e.inspect
      end
    end


    def import_event(dataset_id, event_id)
      begin
        @client = Eventbrite::AuthenticationService.client(dataset_id)
        response = @client.event_get({ id: event_id })
        event = event_json_mapper(response)
        return event
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
            event["description"] = e["event"]["description"]
            event["url"] = e["event"]["url"]
            event["logo"] = e["event"]["logo"]
            event["status"] = e["event"]["status"]
            event["privacy"] = e["event"]["privacy"]
            event["num_attendee_rows"] = e["event"]["num_attendee_rows"]
            event["tags"] = e["event"]["tags"]
            event["venue"] = e["event"]["venue"]
            event["tickets"] = e["event"]["tickets"]
            event["organizer"] = e["event"]["organizer"]
            event["start_date_time"] = date_parser(e["event"]["start_date"], e["event"]["timezone"])
            event["end_date_time"] = date_parser(e["event"]["end_date"], e["event"]["timezone"])
            event["publish_date"] = date_parser(e["event"]["created"], e["event"]["timezone"])
            all_events << event
          end
        end
        return all_events
      end


      def event_json_mapper(response)
        return if response["event"].nil?
        e = response["event"]
        event = Hash.new
        event_hash = Array.new
        if e
          event["id"] = e["id"]
          event["title"] = e["title"]
          event["description"] = e["description"]
          event["url"] = e["url"]
          event["logo"] = e["logo"]
          event["status"] = e["status"]
          event["privacy"] = e["privacy"]
          event["num_attendee_rows"] = e["num_attendee_rows"]
          event["tags"] = e["tags"]
          event["venue"] = e["venue"]
          event["tickets"] = e["tickets"]
          event["organizer"] = e["organizer"]
          event["start_date_time"] = date_parser(e["start_date"], e["timezone"])
          event["end_date_time"] = date_parser(e["end_date"], e["timezone"])
          event["publish_date"] = date_parser(e["created"], e["timezone"])
          event_hash << event
        end
        return event_hash
      end


      def date_parser(date, timezone)
        ActiveSupport::TimeZone[timezone].parse(date)
      end


  end

end
