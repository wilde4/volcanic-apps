class Bullhorn::ClientService < BaseService

  def initialize(bullhorn_setting)
    @bullhorn_setting = bullhorn_setting
    @client = setup_client
    @key = Key.find_by(app_dataset_id: bullhorn_setting.dataset_id, app_name: 'bullhorn')
  end

  # CHECK IF THE CLIENT HAVE ACCES TO THE API
  def client_authenticated? 
    if @bullhorn_setting.auth_settings_filled
      candidates = @client.candidates(fields: 'id', sort: 'id') #TEST CALL TO CHECK IF INDEED WE HAVE PERMISSIONS (GET A CANDIDATES RESPONSE)
      
      candidates.data.size > 0
    else
      false
    end

  rescue
    false
  end

  def setup_client
    return Bullhorn::Rest::Client.new(
      username: @bullhorn_setting.bh_username,
      password: @bullhorn_setting.bh_password,
      client_id: @bullhorn_setting.bh_client_id,
      client_secret: @bullhorn_setting.bh_client_secret
    )
  end

  # GETS BULLHORN CANDIDATES FIELDS VIA API USING THE GEM
  def bullhorn_candidate_fields 

    path = "meta/Candidate"
    client_params = {fields: '*'}
    @client.conn.options.timeout = 50 # Oliver will reap a unicorn process if it's waiting for longer than 60 seconds, so we'll only wait for 50

    res = @client.conn.get path, client_params
    obj = @client.decorate_response JSON.parse(res.body)
    create_log(@bullhorn_setting, @key, 'get_bullhorn_candidate_fields', path, client_params.to_s, nil, obj.errors.present?)

    @bullhorn_fields = obj['fields'].select { |f| f['type'] == "SCALAR" }.map { |field| ["#{field['label']} (#{field['name']})", field['name']] }

    # Get nested address fields
    address_fields = obj['fields'].select { |f| f.dataType == 'Address' }
    address_fields.each do |address_field|
      if address_field['name'] == 'address'
        address_field.fields.select { |f| f['type'] == "SCALAR" }.each { |field|
          @bullhorn_fields << ["#{field['label']} (#{field['name']})", field['name']]
        }
      end
    end

    # Get some specfic non SCALAR fields
    obj['fields'].select { |f| f['type'] == "TO_ONE" && f['name'] == 'category' }.each { |field| 
      @bullhorn_fields << ["#{field['label']} (#{field['name']})", field['name']] 
    }
    obj['fields'].select { |f| f['type'] == "TO_MANY" && f['name'] == 'businessSectors' }.each { |field| 
      @bullhorn_fields << ["#{field['label']} (#{field['name']})", field['name']] 
    }

    @bullhorn_fields.sort! { |x,y| x.first <=> y.first }

    @bullhorn_fields
  rescue BullhornServiceError => e 
    Honeybadger.notify(e)
    @net_error = create_log(@bullhorn_setting, @key, 'get_bullhorn_candidate_fields', nil, nil, e.message, true, true)
  end

  # GETS VOLCANIC CANDIDATES FIELDS VIA API
  def volcanic_candidate_fields
    url = Rails.env.development? ? "#{@key.protocol}#{@key.host}:3000/api/v1/user_groups.json" : "#{@key.protocol}#{@key.host}/api/v1/user_groups.json"
    response = HTTParty.get(url)

    @volcanic_fields = {}
    response.each { |r| 
      r['registration_question_groups'].each { |rg| 
        rg['registration_questions'].each { |q| 
          @volcanic_fields[q["reference"]] = q["label"] unless %w(password password_confirmation terms_and_conditions).include?(q['core_reference']) 
        } 
      } 
    }
    @volcanic_fields = Hash[@volcanic_fields.sort]

    @volcanic_fields
  rescue BullhornServiceError => e
    Honeybadger.notify(e)
    @net_error = create_log(@bullhorn_setting, @key, 'get_volcanic_candidate_fields', nil, nil, e.message, true, true)
  end

  # GETS BULLHORN JOB FIELDS VIA API USING THE GEM
  def bullhorn_job_fields

    path = "meta/JobOrder"
    client_params = {fields: '*'}
    @client.conn.options.timeout = 50 # Oliver will reap a unicorn process if it's waiting for longer than 60 seconds, so we'll only wait for 50

    res = @client.conn.get path, client_params
    obj = @client.decorate_response JSON.parse(res.body)
    create_log(@bullhorn_setting, @key, 'get_bullhorn_job_fields', path, client_params.to_s, nil, obj.errors.present?)

    @bullhorn_job_fields = obj['fields'].select { |f| f['type'] == "SCALAR" }.map { |field| ["#{field['label']} (#{field['name']})", field['name']] }.sort! { |x,y| x.first <=> y.first }

    @bullhorn_job_fields
  rescue BullhornServiceError => e
    Honeybadger.notify(e)
    @net_error = create_log(@bullhorn_setting, @key, 'get_bullhorn_job_fields', nil, nil, e.message, true, true)
  end

  # GETS VOLCANIC JOB FIELDS VIA API
  def volcanic_job_fields
    
    url = Rails.env.development? ? "#{@key.protocol}#{@key.host}:3000/api/v1/available_job_attributes.json?api_key=#{@key.api_key}" : "#{@key.protocol}#{@key.host}/api/v1/available_job_attributes.json?api_key={@key.api_key}"
    response = HTTParty.get(url)

    @volcanic_job_fields = {}

    response.each { |r, val| 
      @volcanic_job_fields[val['attribute']] = val['name'] 
    }

    # @volcanic_job_fields = Hash[@volcanic_job_fields.sort]

    @volcanic_job_fields
  rescue BullhornServiceError => e
    Honeybadger.notify(e)
    @net_error = create_log(@bullhorn_setting, @key, 'get_volcanic_job_fileds', nil, nil, e.message, true, true)
  end


  def post_user_to_bullhorn(user, params, bullhorn_settings)

    field_mappings = bullhorn_settings.bullhorn_field_mappings.user

    attributes = {
      'firstName' => user.user_profile['first_name'],
      'lastName' => user.user_profile['last_name'],
      'name' => "#{user.user_profile['first_name']} #{user.user_profile['last_name']}",
      'email' => user.email
    }

    if user.linkedin_profile.present?
      attributes['description'] = linkedin_description(user)
    end
    attributes["#{bullhorn_settings.linkedin_bullhorn_field}"] = user.user_profile['li_publicProfileUrl'] if user.user_profile['li_publicProfileUrl'].present?

    # PREPARE ADDRESS
    attributes['address'] = {}

    # MAP FIELDS TO FIELDS
    field_mappings.each do |fm|
      
      # TIMESTAMPS
      answer = user.registration_answers["#{fm.registration_question_reference}_array"] || user.registration_answers[fm.registration_question_reference] rescue nil
      answer.delete_if(&:blank?) if answer.is_a?(Array)
     
    
      case fm.bullhorn_field_name
      when 'dateOfBirth', 'dateAvailable' # AND OTHERS
        # TIMESTAMP NEEDED IN MILLISECONDS
        answer = (( Date.parse(answer) + 12.hours ).to_time.to_i.to_f * 1000.0).to_i rescue nil
        # logger.info "--- processed answer = #{answer}"
        attributes[fm.bullhorn_field_name] = answer if answer.present?
      when 'address1', 'address2', 'city', 'state', 'zip'
        # ADDRESS
        attributes['address'][fm.bullhorn_field_name] = answer if answer.present?
      when 'salaryLow', 'salary', 'dayRate', 'dayRateLow', 'hourlyRate', 'hourlyRateLow'
        answer_integer = answer.gsub(/[^0-9\.]/,'').to_i rescue nil
        attributes[fm.bullhorn_field_name] = answer_integer if answer_integer.present?
      when 'countryID'
        # ADDRESS COUNTRY
        attributes['address']['countryID'] = get_country_id(answer) if answer.present?
      when 'category', 'categoryID'
        # FIND category ID
        categories = @client.categories
       
        category = categories.data.select{ |c| c.name == answer }.first
        
        if category.present?
           attributes['category'] = {}
           attributes['category']['id'] = category.id
           @category_id = category.id
        end
      when 'businessSectors'
        # UPDATE CANDIDATE AFTER CREATION
      else
        attributes[fm.bullhorn_field_name] = answer if answer.present?
      end
    end

    # GET BULLHORN ID
    if user.bullhorn_uid.present?
      bullhorn_id = user.bullhorn_uid
    else
      if bullhorn_settings.always_create == true

        bullhorn_id = nil
      else
        email_query = "email:\"#{URI::encode(user.email)}\""
        existing_candidates = @client.search_candidates(query: email_query, sort: 'id')

        # isDeleted BOOLEAN CAN'T BE QUERIED SO NEED TO EXTRACT UNDELETED CANDIDATES
        active_candidates = existing_candidates.data.select{ |c| c.isDeleted == false }

        if active_candidates.size > 0

          last_candidate = active_candidates.last
          bullhorn_id = last_candidate.id
          user.update(bullhorn_uid: bullhorn_id)
        else

          bullhorn_id = nil
        end
      end
    end

    # CREATE/UPDATE CANDIDATE
    if bullhorn_id.present?
      candidate = @client.candidate(user.bullhorn_uid, {})
      if candidate.data.status == 'Inactive'
        attributes['status'] = bullhorn_settings.status_text.present? ? bullhorn_settings.status_text : 'New Lead'
      end

      response = @client.update_candidate(bullhorn_id, attributes.to_json)

      user.app_logs.create key: @key, name: 'update_candidate', endpoint: "entity/candidate/#{user.bullhorn_uid}", message: { attributes: attributes }.to_s, response: response.to_s, error: response.errors.present?
      if response.errors.present?
        response.errors.each do |e|
          Honeybadger.notify(
            :error_class => "Bullhorn Error",
            :error_message => "Bullhorn Error: #{e.inspect}",
            :parameters => params
          )
        end
      end
    else

      attributes['status'] = bullhorn_settings.status_text.present? ? bullhorn_settings.status_text : 'New Lead'
      attributes['source'] = bullhorn_settings.source_text.present? ? bullhorn_settings.source_text : 'Company Website'

      response = @client.create_candidate(attributes.to_json)

      user.app_logs.create key: @key, name: 'create_candidate', endpoint: "entity/candidate", message: { attributes: attributes }.to_s, response: response.to_s, error: response.errors.present?
      user.update(bullhorn_uid: response['changedEntityId'])
      bullhorn_id = response['changedEntityId']
      if response.errors.present?
        response.errors.each do |e|
          Honeybadger.notify(
            :error_class => "Bullhorn Error",
            :error_message => "Bullhorn Error: #{e.inspect}",
            :parameters => params
          )
        end
      end
    end
    
    if bullhorn_id.present?
      #categoies
      send_category(bullhorn_id, @client)
      # CREATE NEW API CALL TO ADD BUSINESS SECTOR TO CANDIDATE
      # FIND businessSector ID
      # 'businessSectors'
      if user.registration_answers.present?
        business_sectors = @client.business_sectors

        answer = user.registration_answers['businessSectors']
        bs_mapping = field_mappings.find_by(bullhorn_field_name: 'businessSectors')

        if bs_mapping.present?
          business_sector = business_sectors.data.select{ |bs| bs.name == user.registration_answers[bs_mapping.registration_question_reference] }.first

          if business_sector.present?
            bs_response = @client.create_candidate({}.to_json, { candidate_id: bullhorn_id, association: 'businessSectors', association_ids: "#{business_sector.id}" })

          end
        end
      end

    end
      
  end



  def linkedin_description(user)
      string = '<h1>Curriculum Vitae</h1>' +
        "<h2>#{user.user_profile['first_name']} #{user.user_profile['last_name']}</h2>"

      if user.linkedin_profile['positions'].present?
        string = string + '<h3>PREVIOUS EXPERIENCE</h3>'
        user.linkedin_profile['positions'].each do |position|
          string = string + '<p>'

          company_name = position['company_name'].present? ? 'Company: ' + position['company_name'] + '<br />' : "Company: N/A<br />"
          title = position['title'].present? ? 'Position: ' + position['title'] + '<br />' : "Position: N/A<br />"
          start_date = position['start_date'].present? ? 'Start Date: ' + position['start_date'] + '<br />' : "Start Date: N/A<br />"
          end_date = position['end_date'].present? ? 'End Date: ' + position['end_date'] + '<br />' : "End Date: N/A<br />"
          summary = position['summary'].present? ? 'Summary: ' + position['summary'] + '<br />' : "Summary: N/A<br />"
          company_industry = position['company_industry'].present? ? 'Company Industry: ' + position['company_industry'] + '<br />' : "Company Industry: N/A<br />"

          string = string + company_name + title + start_date + end_date + summary + company_industry + '</p>'
        end
      end
      return string
  end

  def send_category(bullhorn_id, client)
    if @category_id.present?
      Bullhorn::SendCategoryService.new(bullhorn_id, client, @category_id).send_category_to_bullhorn
    end
  end

  def create_log(loggable, key, name, endpoint, message, response, error = false, internal = false)
    log = loggable.app_logs.create key: key, endpoint: endpoint, name: name, message: message, response: response, error: error, internal: internal
    log.id
  rescue BullhornServiceError => e
    Honeybadger.notify(e)
  end

  class BullhornServiceError < StandardError; end


end