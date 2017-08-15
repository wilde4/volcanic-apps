class ImportBlogsWorker
  include Sidekiq::Worker
  include ActionView::Helpers::TextHelper
  sidekiq_options :queue => :default
  
  def perform(profile_id, data_import_line_id)
    
    @data_import_line = DataImport::Line.find data_import_line_id
    @file = @data_import_line.file
    @profile = Profile.find profile_id

    payload = Hash.new
    payload["api_key"] = @profile.api_key

    payload["blog"] = Hash.new

    payload["blog"]["source"] = "data_import_#{@data_import_line.data_import_file_id}"
    payload["blog"]["user_id"] = @file.user_id

    # Get mapped headers
    @file.mapped_headers.each do |header|
      next if header.column_name.starts_with?('address') || header.column_name == 'active'
      if header.multiple_answers?
        answer = @data_import_line.values[header.name] == 'NULL' ? nil : @data_import_line.values[header.name].try(:strip).split(',')
        payload["blog"][header.column_name] = answer
      elsif header.nl2br?
        answer = @data_import_line.values[header.name] == 'NULL' ? nil : simple_format(@data_import_line.values[header.name].try(:strip))
        payload["blog"][header.column_name] = answer
      else
        if header.column_name == 'source_url'
          answer = @data_import_line.values[header.name] == 'NULL' ? nil : @data_import_line.values[header.name].try(:strip)
          if answer.starts_with? "http"
            # Remove the domain if present
            answer = answer.split('/').drop(3).join('/').prepend('/')
          end
        else
          answer = @data_import_line.values[header.name] == 'NULL' ? nil : @data_import_line.values[header.name].try(:strip)
        end
        payload["blog"][header.column_name] = answer
      end
    end

    json_post("blogs", payload)
  end
  
  def json_post(endpoint, payload)
    
    # endpoint_url = URI("http://jobsatteam.localhost.volcanic.co:3000/api/v1/#{endpoint}.json")

    endpoint_url = URI("http://" + @profile.host + "/api/v1/#{endpoint}.json")
    
    response = HTTParty.post(endpoint_url, {:body => payload.to_json, :headers => { 'Content-Type' => 'application/json' }})
  
    if response.code.to_i != 200
      @data_import_line.update_attributes error: true, error_messages: response.read_body
    else
      @data_import_line.update_attributes error: false, processed: true
    end
  
  end

  def parse_boolean(value)
    ['yes','y','1'].include?(value.try(:downcase)) ? 1 : 0
  end
  
end