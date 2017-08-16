class ImportClientsWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :default
  
  def perform(profile_id, data_import_line_id, key_locations)
    
    @data_import_line = DataImport::Line.find data_import_line_id
    @data_import_line.values['key_locations'] = key_locations
    @file = @data_import_line.file
    @profile = Profile.find profile_id

    payload = Hash.new
    payload["api_key"] = @profile.api_key

    payload["client"] = Hash.new

    payload["client"]["source"] = "data_import_#{@data_import_line.data_import_file_id}"

    # Combine any address headers into location unless location set
    unless @file.mapped_headers.map(&:column_name).include? 'location'
      @address_location = @file.mapped_headers.select { |h| h.column_name.starts_with? 'address' }.sort_by! { |k| k[:column_name] }.map do |header|
        @data_import_line.values[header.name].try(:strip)
      end.compact
      payload["client"]["location"] = @address_location.join(', ') if @address_location.present?
    end

    # Set disabled if active header present
    if @file.mapped_headers.map(&:column_name).include? 'active'
      payload["client"]["suspended"] = 1 - parse_boolean(@data_import_line.values[@file.mapped_headers.find { |h| h.column_name == 'active' }.name].try(:strip))
    end

    # Get mapped headers
    @file.mapped_headers.each do |header|
      next if header.column_name.starts_with?('address') || header.column_name == 'active'
      if header.multiple_answers?
        answer = @data_import_line.values[header.name] == 'NULL' ? nil : @data_import_line.values[header.name].try(:strip).split(',')
        payload["client"][header.column_name] = answer
      else
        answer = @data_import_line.values[header.name] == 'NULL' ? nil : @data_import_line.values[header.name].try(:strip)
        if header.column_name == 'disciplines'
          answer = answer.downcase.gsub('&','and').gsub('/',' slash ').gsub(' ' , '-') rescue nil
        end
        if header.column_name == 'display'
          answer = parse_boolean(answer)
        end
        payload["client"][header.column_name] = answer
      end
    end

    json_post("clients", payload)
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

  def parse_boolean(value)
    ['yes','y','1'].include?(value.try(:downcase)) ? 1 : 0
  end
  
end