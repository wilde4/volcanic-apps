class ImportRedirectsWorker
  include Sidekiq::Worker
  include ActionView::Helpers::TextHelper
  sidekiq_options :queue => :default
  
  def perform(profile_id, data_import_line_id)
    
    @data_import_line = DataImport::Line.find data_import_line_id
    @file = @data_import_line.file
    @profile = Profile.find profile_id

    payload = Hash.new
    payload["api_key"] = @profile.api_key

    payload["redirect"] = Hash.new

    # Get mapped headers
    @file.mapped_headers.each do |header|
      answer = @data_import_line.values[header.name] == 'NULL' ? nil : @data_import_line.values[header.name].try(:strip)
      payload["redirect"][header.column_name] = answer
    end

    json_post("redirects", payload)
  end
  
  def json_post(endpoint, payload)
    
    # endpoint_url = URI("http://awesome-recruitment.localhost.volcanic.co:3000/api/v1/#{endpoint}.json")

    endpoint_url = URI("https://" + @profile.host + "/api/v1/#{endpoint}.json")
    
    response = HTTParty.post(endpoint_url, {:body => payload.to_json, :headers => { 'Content-Type' => 'application/json' }})
  
    if response.code.to_i != 200
      @data_import_line.update_attributes error: true, error_messages: response.read_body
    else
      @data_import_line.update_attributes error: false, processed: true
    end
  
  end
  
end