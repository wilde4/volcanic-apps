class Jobadder::ClientService < BaseService
  attr_accessor :client, :key, :authorize_url, :original_url, :callback_url
  require 'net/http'
  require 'rest_client'

  def initialize(ja_setting)
    @ja_setting = ja_setting
    @callback_url = JobadderHelper.callback_url
    @key = Key.find_by(app_dataset_id: ja_setting.dataset_id, app_name: 'jobadder')
    setup_client
  end


  def setup_client

    @client = Jobadder::AuthenticationService.client(@ja_setting)


    if @callback_url.present?
      @authorize_url = Jobadder::AuthenticationService.authorize_url(@ja_setting.dataset_id, @ja_setting)
    end
    check_token_expiration(@ja_setting)

  end

  def add_candidate_to_job(candidate_id, job_id)

    check_token_expiration(@ja_setting)

    url = JobadderHelper.base_urls[:job_adder] + JobadderHelper.endpoints[:jobs] + "/#{job_id}/applications"

    candidate_ids = [candidate_id]


    response = HTTParty.post(url,
                             :headers => {"Authorization" => "Bearer " + @ja_setting.access_token,
                                          "Content-type" => "application/json"},
                             :body => {'candidateId' => candidate_ids,
                                       'source' => 'VolcanicApp'

                             }.to_json)
    return response

  rescue StandardError => e
    Honeybadger.notify(e)
    create_log(@ja_setting, @key, 'add_candidate_to_job', url, nil, e.message, true, true, @ja_setting.access_token)
    {error: 'Error adding candidate to a job'}
  end

  def get_applications_for_job(job_id)

    check_token_expiration(@ja_setting)

    url = JobadderHelper.base_urls[:job_adder] + JobadderHelper.endpoints[:jobs] + "/#{job_id}/applications"


    response = HTTParty.get(url,
                            :headers => {"Authorization" => "Bearer " + @ja_setting.access_token,
                                         "Content-type" => "application/json"})
    return response

  rescue StandardError => e
    Honeybadger.notify(e)
    create_log(@ja_setting, @key, 'get_submissions_for_job', url, nil, e.message, true, true, @ja_setting.access_token)
    {error: "Error getting submissions for a job id - #{job_id}"}
  end

  def get_worktypes

    check_token_expiration(@ja_setting)

    url = JobadderHelper.base_urls[:job_adder] + JobadderHelper.endpoints[:worktypes]

    response = HTTParty.get(url,
                            :headers => {"Authorization" => "Bearer " + @ja_setting.access_token,
                                         "Content-type" => "application/json"})


    return response

  rescue StandardError => e
    Honeybadger.notify(e)
    create_log(@ja_setting, @key, 'get_worktypes', url, nil, e.message, true, true, @ja_setting.access_token)
    {error: "Error getting worktypes"}

  end

  def add_candidate(dataset_id, user_id)

    ja_setting = JobadderAppSetting.find_by(dataset_id: dataset_id)

    ja_user = JobadderUser.find_by(user_id: user_id)

    candidate_custom_fields = get_candidate_custom_fields

    custom_fields_answers = construct_custom_fields_answers(ja_setting, candidate_custom_fields, ja_user.registration_answers)

    worktypes = get_worktypes

    request_body = construct_candidate_request_body(ja_setting, ja_user.registration_answers, ja_user, custom_fields_answers, worktypes)

    url = JobadderHelper.base_urls[:job_adder] + JobadderHelper.endpoints[:candidates]

    check_token_expiration(ja_setting)
    # Add candidate
    add_candidate_response = HTTParty.post(url,
                                           :headers => {"Authorization" => "Bearer " + ja_setting.access_token,
                                                        "Content-type" => "application/json"},
                                           :body => request_body.to_json)

    return add_candidate_response

  rescue StandardError => e
    Honeybadger.notify(e)
    create_log(ja_setting, @key, 'add_candidate', url, nil, e.message, true, true, @ja_setting.access_token)
    {error: 'Error adding candidate'}

  end

  def add_single_attachment(id, upload_path, file_name, attachment_type, receiver, prefix)

    case receiver
    when 'candidate'
      endpoint = JobadderHelper.endpoints[:candidates]
    when 'application'
      endpoint = JobadderHelper.endpoints[:applications]
    end

    url = JobadderHelper.base_urls[:job_adder] + endpoint + "/#{id}/attachments/#{attachment_type}"

    # Receiving different forms of url in the development
    if Rails.env.development?
      receiver == 'candidate' &&  prefix!= 'original'  ? @file_url = 'http://' + @key.host + upload_path : @file_url = upload_path
    else
      # UPLOAD PATHS USE CLOUDFRONT URL
      @file_url = upload_path
    end

    file = create_file(prefix, file_name, @file_url)

    check_token_expiration(@ja_setting)

    @response = RestClient.post url, {:fileData => file},
                                {:Authorization => "Bearer " + @ja_setting.access_token}
    delete_file(file)

    return true

  rescue StandardError => e

    Honeybadger.notify(e)
    create_log(@ja_setting, @key, 'upload_single_attachment', url, nil, e.message, true, true, @ja_setting.access_token)
    {error: "Error uploading single attachment - #{file_name}"}

    return false

  end

  def update_candidate(dataset_id, user_id, candidate_id)

    ja_setting = JobadderAppSetting.find_by(dataset_id: dataset_id)
    ja_user = JobadderUser.find_by(user_id: user_id)
    candidate_custom_fields = get_candidate_custom_fields

    custom_fields_answers = construct_custom_fields_answers(ja_setting, candidate_custom_fields, ja_user.registration_answers)

    request_body = construct_candidate_request_body(ja_setting, ja_user.registration_answers, ja_user, custom_fields_answers, nil)

    url = JobadderHelper.base_urls[:job_adder] + JobadderHelper.endpoints[:candidates] + "/#{candidate_id}"

    check_token_expiration(ja_setting)

    update_candidate_response = HTTParty.put(url,
                                             :headers => {'User-Agent' => 'VolcanicJobadderApp',
                                                          'Content-Type' => 'application/json',
                                                          "Authorization" => "Bearer " + ja_setting.access_token},
                                             :body => request_body.to_json
    )
    return update_candidate_response
  rescue StandardError => e
    Honeybadger.notify(e)
    create_log(ja_setting, @key, 'update_candidate', url, nil, e.message, true, true, @ja_setting.access_token)
    {error: "Error updating JobAdder candidate with user_id - #{user_id}"}


  end

  def get_candidate_by_email(candidate_email)

    url = JobadderHelper.base_urls[:job_adder] + JobadderHelper.endpoints[:candidates] + "?email=#{candidate_email}"

    check_token_expiration(@ja_setting)

    response = HTTParty.get(url,
                            :headers => {'User-Agent' => 'VolcanicJobadderApp',
                                         "Authorization" => "Bearer " + @ja_setting.access_token}
    )
    return response

  rescue StandardError => e
    Honeybadger.notify(e)
    create_log(@ja_setting, @key, 'get_candidate_by_email', url, nil, e.message, true, true,  @ja_setting.access_token)
    {error: "Error getting JobAdder candidate by email - #{candidate_email}"}

  end

  def get_candidate_custom_fields

    url = JobadderHelper.base_urls[:job_adder] + JobadderHelper.endpoints[:candidate_custom_fields]

    check_token_expiration(@ja_setting)

    response = HTTParty.get(url,
                            headers: {'User-Agent' => 'VolcanicJobadderApp',
                                      "Authorization" => "Bearer " + @ja_setting.access_token})
    response.code == 200 ? response.body : {}

    return response

  rescue StandardError => e
    Honeybadger.notify(e)
    create_log(@ja_setting, @key, 'get_candidate_custom_fields', url, nil, e.message, true, true, @ja_setting.access_token)
    {error: "Error getting JobAdder candidate custom fields"}


  end

  # GETS VOLCANIC CANDIDATES FIELDS VIA API
  def get_volcanic_candidate_fields
    url = "#{@key.protocol}#{@key.host}/api/v1/user_groups.json"
    response = HTTParty.get(url, headers: {'User-Agent' => 'VolcanicJobadderApp'})
    @volcanic_fields = {}
    @volcanic_upload_file_fields = {}
    @volcanic_upload_file_fields_core = {}
    @fields = {}

    response.select {|f| f['default'] == true}.each {|r|
      r['registration_question_groups'].each {|rg|
        rg['registration_questions'].each {|q|
          unless %w(password password_confirmation terms_and_conditions).include?(q['core_reference'])
            if q["question_type"] === "File Upload"
              if %w(covering_letter upload_cv).include?(q['core_reference'])
                @volcanic_upload_file_fields_core[q["reference"]] = q["label"]
              else
                @volcanic_upload_file_fields[q["reference"]] = q["label"]
              end
            else
              @volcanic_fields[q["reference"]] = q["label"]
            end
          end
        }
      }
    }

    @volcanic_upload_file_fields = Hash[@volcanic_upload_file_fields.sort]
    @volcanic_upload_file_fields_core = Hash[@volcanic_upload_file_fields_core.sort]
    @volcanic_fields = Hash[@volcanic_fields.sort]
    @fields['volcanic_fields'] = @volcanic_fields
    @fields['volcanic_upload_file_fields'] = @volcanic_upload_file_fields
    @fields['volcanic_upload_file_fields_core'] = @volcanic_upload_file_fields_core
    return @fields
  rescue StandardError => e
    Honeybadger.notify(e)
    create_log(@ja_setting, @key, 'get_volcanic_candidate_fields', url, nil, e.message, true, true, @ja_setting.access_token)
    {error: 'Error retrieving volcanic candidate fields'}
  end

  def get_jobadder_candidate_fields

    request_body = JSON.parse(JobadderRequestBody.find_by(name: 'add_candidate')[:json])

    custom_fields = get_candidate_custom_fields


    @ja_candidate_fields = []

    @ja_candidate_fields = get_all_keys(request_body)

    if custom_fields['items'].present? && custom_fields['items'].length > 0

      custom_fields['items'].each do |item|
        @ja_candidate_fields << item['name']

      end
    end

    return @ja_candidate_fields

  rescue StandardError => e
    puts e
    Honeybadger.notify(e)
    create_log(@ja_setting, @key, 'get_jobadder_candidate_fields', url, nil, e.message, true, true, @ja_setting.access_token)
    {error: 'Error retrieving JobAdder candidate fields'}
  end

  def get_volcanic_user(user_id)

    url = "#{@key.protocol}#{@key.host}/api/v1/users/#{user_id}.json?api_key=#{@key.api_key}"

    response = HTTParty.get(url, headers: {'User-Agent' => 'VolcanicJobadderApp'})

    return response

  rescue StandardError => e
    puts e
    Honeybadger.notify(e)
    create_log(@ja_setting, @key, 'get_get_volcanic_user', url, nil, e.message, true, true, @ja_setting.access_token)
    {error: 'Error retrieving Volcanic User Details'}
  end


  private

  def create_log(loggable, key, name, endpoint, message, response, error = false, internal = false, uid = nil)
    log = loggable.app_logs.create key: key, endpoint: endpoint, name: name, message: message, response: response, error: error, internal: internal, uid: uid
    log.id
  rescue StandardError => e
    Honeybadger.notify(e)
  end


  def create_file(prefix, file_name, file_url)

    file = File.new("#{JobadderHelper.temporary_files_dir}/#{prefix}_#{file_name}", 'w')

    open(file_url) do |url_file|
      file.write(url_file.read.force_encoding("UTF-8"))
    end

    file = File.open(file.path(), 'r')

    return file

  end

  def delete_file(file)

    File.delete(file.path()) if File.exist?(file.path())

  end

  def construct_custom_fields_answers(ja_setting, candidate_custom_fields, registration_answers)

    custom_fields_answers = []

    if candidate_custom_fields.present? && registration_answers.present? && candidate_custom_fields['items'].present?
      ja_setting.jobadder_field_mappings.each do |m|
        candidate_custom_fields['items'].each do |i|
          if m.jobadder_field_name === i['name']
            custom_fields_answer = Hash.new
            custom_fields_answer["fieldId"] = i['fieldId']
            custom_fields_answer["value"] = registration_answers[m.registration_question_reference]
            custom_fields_answers.push(custom_fields_answer)
          end
        end

      end

    end
    return custom_fields_answers

  end

  def construct_candidate_request_body(ja_setting, registration_answers, ja_user, custom_fields_answers, work_types)
    request_body = Hash.new
    request_body["firstName"] = ja_user.user_profile['first_name']
    request_body["lastName"] = ja_user.user_profile['last_name']
    request_body["email"] = ja_user.user_data['email']
    request_body["source"] = ja_user.user_data['utm_source'] if ja_user.user_data['utm_source'].present?

    if registration_answers
      address = Hash.new
      social = Hash.new
      employment = Hash.new
      employment_current = Hash.new
      employment_other = Hash.new
      employment_history = Hash.new
      employment_ideal = Hash.new
      current_salary = Hash.new
      ideal_salary = Hash.new
      address_street = []
      skill_tags = []
      recruiter_user_id = []
      other_salary = Hash.new
      availability = Hash.new
      availability_relative = Hash.new
      education = Hash.new

      ja_setting.jobadder_field_mappings.each do |m|
        reg_answer = registration_answers[m.registration_question_reference]
        field = m.jobadder_field_name.strip
        if reg_answer.present?
          if field.include?('address_country')
            country = ISO3166::Country.find_country_by_name(reg_answer)
            address['countryCode'] = country.alpha2 unless country.nil?
            # address['countryCode'] = reg_answer
          elsif field.include?('address_street')
            address_street << reg_answer
          elsif field.include?('address_city') || field.include?('address_state') || field.include?('address_postalCode')
            #remove all characters from beginning of the string till '_' inclusive
            field = field.sub /^[^_]*_/, ''
            address[field] = reg_answer
          elsif field.include?('skillTags')
            skill_tags << reg_answer
          elsif field.include?('recruiterUserId')
            recruiter_user_id << Integer(reg_answer) if is_number?(reg_answer)
          elsif field.include?('employment')
            if field.include?('current')
              employment_current['employer'] = reg_answer if field.include? 'employer'
              employment_current['position'] = reg_answer if field.include? 'position'
              employment_current['workTypeId'] = get_work_type_id(reg_answer, work_types) if field.include? 'workType'
              employment_current['salary'] = salary(reg_answer, field, current_salary, true) if field.include? 'salary'
            end
            if field.include?('ideal')
              employment_ideal['position'] = reg_answer if field.include? 'position'
              employment_ideal['workTypeId'] = get_work_type_id(reg_answer, work_types) if (field.include?('workType'))
              employment_ideal['salary'] = salary(reg_answer, field, ideal_salary, false) if field.include? 'salary'
              if field.include?('other')
                employment_other['workTypeId'] = get_work_type_id(reg_answer, work_types) if (field.include?('workType'))
                employment_other['salary'] = salary(reg_answer, field, other_salary, false) if field.include? 'salary'
              end
            end

            if field.include?('history')
              employment_history['position'] = reg_answer if field.include? 'position'
              employment_history['employer'] = reg_answer if field.include? 'employer'
              employment_history['start'] = reg_answer if field.include? 'start'
              employment_history['end'] = reg_answer if field.include? 'end'
              employment_history['description'] = reg_answer if field.include? 'description'
            end
          elsif field.include?('availability')
            availability['immediate'] = reg_answer if field.include?('immediate') && !!reg_answer == reg_answer
            availability['date'] = reg_answer if field.include? 'date'
            if field.include?('relative')
              availability_relative['period'] = Integer(reg_answer) if field.include?('period') && is_number?(reg_answer)
              availability_relative['unit'] = reg_answer if field.include?('unit') && (reg_answer.casecmp('week').zero? || reg_answer.casecmp('month').zero?)
            end
          elsif field.include?('education')
            education['institution'] = reg_answer if field.include? 'institution'
            education['course'] = reg_answer if field.include? 'course'
            education['date'] = reg_answer if field.include? 'date'

          elsif field.include?('social')
            #remove all characters from beginning of the string till '_' inclusive
            field = field.sub /^[^_]*_/, ''
            social[field] = reg_answer

          elsif field.include?('statusId')
            request_body[field] = Integer(reg_answer) if is_number?(reg_answer)
          elsif field.include?('seeking')
            request_body[field] = reg_answer if (reg_answer.casecmp('yes').zero? || reg_answer.casecmp('maybe').zero? || reg_answer.casecmp('no').zero?)
          elsif field.include? ' '
            # prevent custom questions to be inside request body
            next
          else
            request_body[field] = reg_answer
          end
        end
      end
    end

    request_body["custom"] = custom_fields_answers if custom_fields_answers.present?
    address["street"] = address_street if address_street.present?
    request_body["address"] = address if address.present?
    request_body["social"] = social if social.present?
    request_body["skillTags"] = skill_tags if skill_tags.present?
    request_body["recruiterUserId"] = recruiter_user_id if recruiter_user_id.present?
    employment_ideal["other"] = [] << employment_other if employment_other.present?
    employment["current"] = employment_current if employment_current.present?
    employment["history"] = [] << employment_history if employment_history.present?
    employment["ideal"] = employment_ideal if employment_ideal.present?
    availability["relative"] = availability_relative if availability_relative.present?
    request_body["employment"] = employment if employment.present?
    request_body["availability"] = availability if availability.present?
    request_body["education"] = [] << education if education.present?

    return request_body

  end

  def is_number? string
    true if Integer(string) rescue false
  end

  # extract all keys from deep nested JSON
  # nested key will have parent key name as prefix
  def get_all_keys(target_hash, field = '', array = [])
    target_hash.each {|k, v|
      if k.is_a?(String)
        @field = field + '_' + k
      end
      if v.is_a?(Hash) || v.is_a?(Array)
        get_all_keys(v, @field, array)
      elsif k.is_a?(Hash) || k.is_a?(Array)
        get_all_keys(k, @field, array)
      else
        @field = @field[1..-1]
        @field = @field.chomp('_string')
        if @field.include?('workTypeId')
          @field.sub! 'workTypeId', 'workType'
        end
        if @field.include?('countryCode')
          @field.sub! 'countryCode', 'country'
        end
        if @field.include?('custom')
          next
        end
        array.push(@field)
        @field, = @field.rpartition('_')
      end
      next
    }
    @field = ''
    return array.sort
  end

  def salary(reg_answer, jobadder_field_name, salary, current)
    salary['ratePer'] = reg_answer if jobadder_field_name.include?('ratePer') && (reg_answer.casecmp('hour').zero? || reg_answer.casecmp('day').zero? ||
        reg_answer.casecmp('week').zero? || reg_answer.casecmp('month').zero? || reg_answer.casecmp('year').zero?)

    salary['currency'] = reg_answer if jobadder_field_name.include?('currency')

    if current === true
      salary['rate'] = Integer(reg_answer) if jobadder_field_name.include?('rate') && is_number?(reg_answer)
    else
      salary['rateLow'] = Integer(reg_answer) if jobadder_field_name.include?('rateLow') && is_number?(reg_answer)
      salary['rateHigh'] = Integer(reg_answer) if jobadder_field_name.include?('rateHigh') && is_number?(reg_answer)

    end
    return salary
  end

  def get_work_type_id(reg_answer, work_types)
    id = nil
    if work_types && work_types['items'].size > 0
      work_types['items'].each do |item|
        id = item['workTypeId'] if item['name'].casecmp(reg_answer) === 0
      end
    end
    return id

  end

  def check_token_expiration(ja_setting)
    if ja_setting.access_token_expires_at.present?
      if DateTime.current > ja_setting.access_token_expires_at
        response = Jobadder::AuthenticationService.refresh_token(ja_setting)
        ja_setting.update({access_token: response.token,
                           access_token_expires_at: Time.at(response.expires_at)})
      end
    end
  end

end




