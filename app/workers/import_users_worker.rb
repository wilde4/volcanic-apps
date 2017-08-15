class ImportUsersWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :default
  
  def perform(profile_id, data_import_line_id, client_id)
    
    @data_import_line = DataImport::Line.find data_import_line_id
    @file = @data_import_line.file
    @profile = Profile.find profile_id

    payload = Hash.new
    payload["api_key"] = @profile.api_key

    # payload["user[user_profile_attributes][upload_url]"] = "http://www.eventbeat.co.uk/cvs/#{candidate.candidate_id}"
    payload["user"] = Hash.new
    payload["user"]["user_profile_attributes"] = Hash.new
    payload["user"]["registration_answers_attributes"] = Array.new

    payload["user"]["source"] = "data_import_#{@data_import_line.data_import_file_id}"
    payload["user"]["client_id"] = client_id

    # Get core user answers
    payload["user"]["user_group_id"] = @file.user_group_id
    payload["user"]["email"] = @data_import_line.values[get_header_mapping('email', true)].try(:strip)
    payload["user"]["password"] = payload["user"]["password_confirmation"] = Digest::MD5.hexdigest("/£$-#{Time.now}-,mn")
    payload["user"]["terms_and_conditions"] = 1
    
    # Split a full name into first/last name if full name is present
    # Naively split on first whitespace for simplicity
    if @file.mapped_headers.map(&:column_name).include? 'full_name'
      name_array = @data_import_line.values['full_name'].try(:strip).split(' ')
      payload["user"]["user_profile_attributes"]["first_name"] = name_array.first
      payload["user"]["user_profile_attributes"]["last_name"] = name_array.slice(1..-1).join(' ')
    else
      payload["user"]["user_profile_attributes"]["first_name"] = @data_import_line.values[get_header_mapping('first_name', true)].try(:strip)
      payload["user"]["user_profile_attributes"]["last_name"] = @data_import_line.values[get_header_mapping('last_name', true)].try(:strip)
    end

    if @file.mapped_headers.map(&:column_name).include? 'disciplines'
      answer = @data_import_line.values['disciplines'].try(:strip)
      disciplines = answer.split(',') rescue []
      answers = disciplines.map { |discipline| discipline.strip.downcase.gsub('&','and').gsub('/',' slash ').gsub(' ' , '-') rescue nil }.compact
      answer = answers.join(',')
      payload['user']['discipline'] = answer
    end

    payload["user"]["candidate_uploads_attributes"] = [{ upload: @data_import_line.values['upload'].try(:strip), upload_type: 'cv' }] if @data_import_line.values['upload'].present?

    if @file.created_at_mapping.present?
      # Try and parse into a Rails date time
      raw_value = @data_import_line.values[@file.created_at_mapping].try(:strip)
      # check if timestamp
      if raw_value.to_i > 0
        @value = Time.at(raw_value.to_i)
      else
        begin
          # try to parse from string
          @value = raw_value.to_time
        rescue ArgumentError => e
        end
      end
      payload["user"]["created_at"] = @value if @value.present?
    end

    # Get other mapped answers
    @file.mapped_headers.each do |header|
      next if (header.registration_question.present? && header.registration_question.core_reference.present?) || header.column_name.present?
      if header.multiple_answers?
        answer = @data_import_line.values[header.name] == 'NULL' ? nil : @data_import_line.values[header.name].try(:strip).split(',')
        payload["user"]["registration_answers_attributes"] << { "registration_question_id" => header.registration_question.uid, "serialized_answer" => answer }
      else
        answer = @data_import_line.values[header.name] == 'NULL' ? nil : @data_import_line.values[header.name].try(:strip)
        payload["user"]["registration_answers_attributes"] << { "registration_question_id" => header.registration_question.uid, "answer" => answer.is_a?(String) ? answer.capitalize : answer }
      end
    end

    payload["user"].delete("registration_answers_attributes") if payload["user"]["registration_answers_attributes"].blank?

    # payload["user[created_at]"] = "#{candidate.created_at.to_s}"
    # payload["user[updated_at]"] = "#{candidate.updated_at.to_s}"
    json_post("users", payload)
  end
  
  def json_post(endpoint, payload)
    
    # endpoint_url = URI("http://jobsatteam.localhost.volcanic.co:3000/api/v1/#{endpoint}.json")
    # uri = URI("http://" + @profile.host + "/api/v1/user_groups.json")

    endpoint_url = URI("http://" + @profile.host + "/api/v1/#{endpoint}.json")
    
    response = HTTParty.post(endpoint_url, {:body => payload.to_json, :headers => { 'Content-Type' => 'application/json' }})

    # Try https if we get a 403
    if response.code.to_i == 403
      endpoint_url = URI("https://" + @profile.host + "/api/v1/#{endpoint}.json")
      response = HTTParty.post(endpoint_url, {:body => payload.to_json, :headers => { 'Content-Type' => 'application/json' }})
    end

    if response.code.to_i != 200
      @data_import_line.update_attributes error: true, error_messages: response.read_body
    else
      @data_import_line.update_attributes error: false, processed: true
    end
  
  end

  def get_header_mapping(reference, core=false)
    @profile.registration_questions.find_by(core ? {core_reference: reference, user_group_id: @file.user_group_id} : {reference: reference}).data_import_headers.find_by(data_import_file_id: @file.id).name
  end
  
end