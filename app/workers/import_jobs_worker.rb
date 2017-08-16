class ImportJobsWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :default
  
  def perform(profile_id, data_import_line_id, client_token)
    
    @data_import_line = DataImport::Line.find data_import_line_id
    @file = @data_import_line.file
    @profile = Profile.find profile_id
    @client_token = client_token

    payload = Hash.new
    payload["api_key"] = @profile.api_key

    payload["job"] = Hash.new

    payload["job"]["source"] = "data_import_#{@data_import_line.data_import_file_id}"
    payload["job"]["client_token"] = @client_token

    # Get mapped headers
    @file.mapped_headers.each do |header|
      if header.multiple_answers?
        answer = @data_import_line.values[header.name] == 'NULL' ? nil : @data_import_line.values[header.name].try(:strip).split(',')
        payload["job"][header.column_name] = answer
      else
        answer = @data_import_line.values[header.name] == 'NULL' ? nil : @data_import_line.values[header.name].try(:strip)
        # answer = (answer == 'fulltime' ? 'permanent' : 'temporary') if header.column_name == 'job_type'
        # if header.column_name == 'created_at'
        #   # answer = Time.zone.at(answer.to_i).to_datetime
        #   # remaining_days = (30 - (Time.zone.now.to_date - answer.to_date).to_i).to_s rescue nil
        #   # remaining_days = '0' if remaining_days && remaining_days.to_i < 0
        #   # payload["job"]["days_to_advertise"] = remaining_days if remaining_days
        # end
        if header.column_name == 'discipline'
          answer = answer.downcase.gsub(' & ','-and-').gsub('&','-and-').gsub(' / ','-').gsub('/','-').gsub(' ' , '-') rescue nil
        end
        if header.column_name == 'job_functions'
          answer = answer.downcase.gsub(' & ','-and-').gsub('&','-and-').gsub(' / ','-slash-').gsub('/','-slash-').gsub(' ' , '-') rescue nil
        end
        if header.column_name == 'job_type'
          answer = answer.downcase.gsub(' & ','-').gsub('/','-').gsub(' ' , '-') rescue nil
        end
        if header.column_name == 'paid'
          answer = answer == 'paid' ? 1 : 0
        end

        if header.column_name == 'extra'
          payload["job"]["extra"] ||= {}
          case header.name
          when 'languages'
            payload["job"]["extra"] = { 'skills' => answer }
          when 'split_fee_percentage'
            payload["job"]["extra"]["split_fee"] ||= {}
            payload["job"]["extra"]["split_fee"]["fee_percentage"] = answer
          when 'split_fee_terms'
            payload["job"]["extra"]["split_fee"] ||= {}
            payload["job"]["extra"]["split_fee"]["terms_of_fee"] = answer
          when 'split_fee_band'
            payload["job"]["extra"]["split_fee"] ||= {}
            payload["job"]["extra"]["split_fee"]["salary_band"] = answer unless answer.ends_with? 'ph'
          else
            payload["job"]["extra"] = { header.name => answer }
          end
        else
          payload["job"][header.column_name] = answer
        end
      end
    end

    json_post("jobs", payload)
  end
  
  def json_post(endpoint, payload)
    
    # endpoint_url = URI("http://jobsatteam.localhost.volcanic.co:3000/api/v1/#{endpoint}.json")
    # uri = URI("http://" + @profile.host + "/api/v1/user_groups.json")

    endpoint_url = URI("http://" + @profile.host + "/api/v1/#{endpoint}.json")
    
    response = HTTParty.post(endpoint_url, {:body => payload.to_json, :headers => { 'Content-Type' => 'application/json' }})
  
    if response.code.to_i != 200
      @data_import_line.update_attributes error: true, error_messages: response.read_body
    else
      @data_import_line.update_attributes error: false, processed: true
    end
  
  end
  
end