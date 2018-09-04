class Jobadder::ClientService < BaseService
  attr_accessor :client, :key, :authorize_url, :original_url
  require 'net/http'

  BASE_URL = {
      job_adder: 'https://api.jobadder.com/v2',
      volcanic: 'https://www.volcanic.co.uk/api/v1'
  }
  ENDPOINT = {
      job_applications: '/jobboards/{boardId}/ads/{adId}/applications',
      candidates: '/candidates',
      users: '/users',
      candidate_custom_fields: '/candidates/fields/custom'
  }

  def initialize(ja_setting, callback_url)
    @ja_setting = ja_setting
    @callback_url = callback_url
    @key = Key.find_by(app_dataset_id: ja_setting.dataset_id, app_name: 'jobadder')
    setup_client
  end


  def setup_client
    # unless @ja_setting.auth_settings_filled
    #   @client = nil
    #   return
    # end

    @client = Jobadder::AuthenticationService.client(@ja_setting)
    @authorize_url = Jobadder::AuthenticationService.authorize_url(@callback_url, @client, @ja_setting.dataset_id)

    if @ja_setting.access_token_expires_at.present?
      if DateTime.current > @ja_setting.access_token_expires_at
        @response = Jobadder::AuthenticationService.refresh_token(@ja_setting)
        @ja_setting.update({access_token: @response.token,
                            access_token_expires_at: Time.at(@response.expires_at)})

      end
    end

  end

  def post_job_application(dataset_id, params)

    @ja_setting = JobadderAppSetting.find_by(dataset_id: dataset_id)

    @response = HTTParty.post(BASE_URL[:job_adder] + ENDPOINT[:candidates],
                              :headers => {"Authorization" => "Bearer " + @ja_setting.access_token,
                                           "Content-type" => "application/json"},
                              :body => {:subject => 'This is the screen name',
                                        :issue_type => 'Application Problem',
                                        :status => 'Open',
                                        :priority => 'Normal',
                                        :description => 'This is the description for the problem'
                              }.to_json)
    puts @response

  end

  def add_candidate(dataset_id, user_id, key)

    @ja_setting = JobadderAppSetting.find_by(dataset_id: dataset_id)
    @ja_user = JobadderUser.find_by(user_id: user_id)
    @candidate_custom_fields = get_candidate_custom_fields

    @custom_fields_answers = construct_custom_fields_answers(@candidate_custom_fields, @ja_user.registration_answers)

    @request_body = construct_candidate_request_body(@ja_setting, @ja_user.registration_answers, @ja_user, @custom_fields_answers)


    # Add candidate
    add_candidate_response = HTTParty.post(BASE_URL[:job_adder] + ENDPOINT[:candidates],
                                           :headers => {"Authorization" => "Bearer " + @ja_setting.access_token,
                                                        "Content-type" => "application/json"},
                                           :body => @request_body.to_json)
    return add_candidate_response

  end

  def update_candidate(dataset_id, user_id, candidate_id)

    @ja_setting = JobadderAppSetting.find_by(dataset_id: dataset_id)
    @ja_user = JobadderUser.find_by(user_id: user_id)
    @candidate_custom_fields = get_candidate_custom_fields

    @custom_fields_answers = construct_custom_fields_answers(@candidate_custom_fields, @ja_user.registration_answers)

    @request_body = construct_candidate_request_body(@ja_setting, @ja_user.registration_answers, @ja_user, @custom_fields_answers)

    update_candidate_response = HTTParty.put(BASE_URL[:job_adder] + ENDPOINT[:candidates] + "/#{candidate_id}",
                                             :headers => {'User-Agent' => 'VolcanicJobadderApp',
                                                          'Content-Type' => 'application/json',
                                                          "Authorization" => "Bearer " + @ja_setting.access_token},
                                             :body => @request_body.to_json
    )
    return update_candidate_response


  end

  def get_candidate_by_email(candidate_email, dataset_id)
    @ja_setting = JobadderAppSetting.find_by(dataset_id: dataset_id)

    response = HTTParty.get(BASE_URL[:job_adder] + ENDPOINT[:candidates] + "?email=#{candidate_email}",
                            :headers => {'User-Agent' => 'VolcanicJobadderApp',
                                         "Authorization" => "Bearer " + @ja_setting.access_token}
    )
    return response
  end

  def get_candidate_custom_fields

    response = HTTParty.get(BASE_URL[:job_adder] + ENDPOINT[:candidate_custom_fields],
                            headers: {'User-Agent' => 'VolcanicJobadderApp',
                                      "Authorization" => "Bearer " + @ja_setting.access_token})
    response.code == 200 ? response.body : {}

    return response

  end

  # GETS VOLCANIC CANDIDATES FIELDS VIA API
  def volcanic_candidate_fields
    url = URI("#{@key.protocol}#{@key.host}/api/v1/user_groups.json")
    response = HTTParty.get(url, headers: {'User-Agent' => 'VolcanicJobadderApp'})

    @volcanic_fields = {}
    response.select {|f| f['default'] == true}.each {|r|
      r['registration_question_groups'].each {|rg|
        rg['registration_questions'].each {|q|
          @volcanic_fields[q["reference"]] = q["label"] unless %w(password password_confirmation terms_and_conditions).include?(q['core_reference'])
        }
      }
    }
    @volcanic_fields = Hash[@volcanic_fields.sort]

    @volcanic_fields
  rescue StandardError => e
    Honeybadger.notify(e)
    create_log(@ja_setting, @key, 'get_volcanic_candidate_fields', url, nil, e.message, true, true)
    {error: 'Error retrieving candidate fields'}
  end

  def jobadder_candidate_fields
    url = BASE_URL[:job_adder] + ENDPOINT[:candidates] + "?limit=1"
    response = HTTParty.get(url,
                            headers: {'User-Agent' => 'VolcanicJobadderApp',
                                      "Authorization" => "Bearer " + @ja_setting.access_token})

    request_body = JSON.parse(JobadderRequestBody.find_by(name: 'add_candidate')[:json])
    @ja_candidate_fields = []
    @response = response.parsed_response


    @ja_candidate_fields = get_all_keys(request_body, '', [])


  rescue StandardError => e
    puts e
    Honeybadger.notify(e)
    create_log(@ja_setting, @key, 'get_ja_candidate_fields', url, nil, e.message, true, true)
    {error: 'Error retrieving candidate fields'}
  end


  def create_log(loggable, key, name, endpoint, message, response, error = false, internal = false, uid = nil)
    log = loggable.app_logs.create key: key, endpoint: endpoint, name: name, message: message, response: (@client.errors || response), error: error, internal: internal, uid: uid || @client.access_token
    log.id
  rescue StandardError => e
    Honeybadger.notify(e)
  end

  private

  def construct_custom_fields_answers(candidate_custom_fields, registration_answers)
    custom_fields_answer = Hash.new
    custom_fields_answers = []

    if candidate_custom_fields.present? && registration_answers.present? && candidate_custom_fields[:items].present?
      candidate_custom_fields[:items].each do |i|
        registration_answers.each do |reg_k, reg_v|
          if reg_k.eql? i[:name]
            custom_fields_answer["fieldId"] = i[:fieldId]
            custom_fields_answer["value"] = {} << reg_v
            custom_fields_answers.push(custom_fields_answer)
          end
        end
      end
    end
    return custom_fields_answers

  end

  def construct_candidate_request_body(ja_setting, registration_answers, ja_user, custom_fields_answers)
    request_body = Hash.new
    request_body["firstName"] = ja_user.user_profile['first_name']
    request_body["lastName"] = ja_user.user_profile['last_name']
    request_body["email"] = ja_user.user_data['email']
    address = Hash.new
    social = Hash.new
    employment = Hash.new
    employment_current = Hash.new
    current_salary = Hash.new
    employment_ideal = Hash.new
    ideal_salary = Hash.new
    address_street = []
    skill_tags = []
    recruiter_user_id = []
    employment_other = Hash.new
    employment_history = Hash.new
    other_salary = Hash.new
    availability = Hash.new
    availability_relative = Hash.new
    education = Hash.new

    ja_setting.jobadder_field_mappings.each do |m|
      reg_answer = registration_answers[m.registration_question_reference]
      field = m.jobadder_field_name
      if reg_answer.present?
        case field
        when 'address_countryCode'
          address['countryCode'] = ISO3166::Country.find_country_by_name(reg_answer).alpha2
        when 'address_street'
          address_street << reg_answer
        when 'address_city', 'address_state', 'address_postalCode'
          #remove all characters from beginning of the string till _ inclusive
          field = field.sub /^[^_]*_/, ''
          address[field] = reg_answer
        when 'skillTags'
          skill_tags << reg_answer
        when 'recruiterUserId'
          recruiter_user_id << reg_answer if reg_answer.is_a?(Numeric)
        when 'social_property1' 'social_property1'
          #remove all characters from beginning of the string till _ inclusive
          field = field.sub /^[^_]*_/, ''
          social[field] = reg_answer
        when field.include?('employment')
          if field.include?('current')
            employment_current['employer'] = reg_answer if field.include? 'employer'
            employment_current['workTypeId'] = reg_answer if field.include? 'workTypeId' && reg_answer.is_a?(Numeric)
            employment_current['salary'] = salary(reg_answer, field, current_salary) if field.include? 'salary'
          end
          if field.include?('ideal')
            employment_ideal['position'] = reg_answer if field.include? 'position'
            employment_ideal['workTypeId'] = reg_answer if field.include? 'workTypeId' && reg_answer.is_a?(Numeric)
            employment_ideal['salary'] = salary(reg_answer, field, ideal_salary) if field.include? 'salary'
          end
          if field.include?('other')
            employment_other['workTypeId'] = reg_answer if field.include? 'workTypeId' && reg_answer.is_a?(Numeric)
            employment_other['salary'] = salary(reg_answer, field, other_salary) if field.include? 'salary'
          end

          if field.include?('history')
            employment_history['position'] = reg_answer if field.include? 'position'
            employment_history['employer'] = reg_answer if field.include? 'employer'
            employment_history['start'] = reg_answer if field.include? 'start'
            employment_history['end'] = reg_answer if field.include? 'end'
          end
        when field.include?('availability')
          availability['immediate'] = reg_answer if field.include? 'immediate' && !!reg_answer == reg_answer
          availability['date'] = reg_answer if field.include? 'date'
          if field.include?('relative')
            availability_relative['period'] = reg_answer if field.include? 'period' && reg_answer.is_a?(Numeric)
            availability_relative['unit'] = reg_answer if field.include? 'uni' && (reg_answer.casecmp('week').zero? || reg_answer.casecmp('month').zero?)
          end
        when field.include?('education')
          education['institution'] = reg_answer if field.include? 'institution'
          education['course'] = reg_answer if field.include? 'course'
          education['date'] = reg_answer if field.include? 'date'
        else
          request_body[field] = reg_answer if field.include? field.to_s
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
    employment["current"] = employment_current if employment_current.present?
    request_body["ideal"] = employment_ideal if employment_ideal.present?
    employment["history"] = [] << employment_history if employment_history.present?
    request_body["availability"] = availability if availability.present?
    request_body["education"] = [] << education if education.present?
    return request_body

  end

  def get_all_keys(target_hash, field, array)
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
        array.push(@field)
        @field, = @field.rpartition('_')
      end
      next
    }
    @field = ''
    return array.sort

  end

  def salary(reg_answer, jobadder_field_name, salary)
    salary['ratePer'] = reg_answer if jobadder_field_name.include? 'ratePer'
    salary['rateLow'] = reg_answer if jobadder_field_name.include? 'rateLow' && reg_answer.is_a?(Numeric)
    salary['rateHigh'] = reg_answer if jobadder_field_name.include? 'rateHigh' && reg_answer.is_a?(Numeric)
    salary['currency'] = reg_answer if jobadder_field_name.include? 'currency'
    return salary
  end


end