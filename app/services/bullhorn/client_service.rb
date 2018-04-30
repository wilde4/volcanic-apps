class Bullhorn::ClientService < BaseService

  DEFAULT_JOB_FIELDS = { job_title: 'Job Title', application_email: 'Job owner email', contact_name: 'Job owner first name + last name',
                        discipline: 'Job industries', created_at: 'Date Job Added', job_reference: 'Job reference', job_location: 'Job address',
                        job_type: 'Job employment type', salary_low: 'Job salary', salary_per: 'Salary unit (per day,  hour...)',
                        job_description: 'Job public description' }

  attr_accessor :client, :key

  def initialize(bullhorn_setting)
    @bullhorn_setting = bullhorn_setting
    setup_client
    @key = Key.find_by(app_dataset_id: bullhorn_setting.dataset_id, app_name: 'bullhorn_v2')
  end

  # CHECK IF THE CLIENT HAVE ACCES TO THE API
  def client_authenticated? 
    @client && @client.authenticated?
  rescue
    false
  end

  def setup_client
    unless @bullhorn_setting.auth_settings_filled
      @client = nil
      return
    end

    @client = Bullhorn::Rest::Client.new(
      username: @bullhorn_setting.bh_username,
      password: @bullhorn_setting.bh_password,
      client_id: @bullhorn_setting.bh_client_id,
      client_secret: @bullhorn_setting.bh_client_secret,
      refresh_token: @bullhorn_setting.refresh_token
    )

    authenticate_client

  end

  def authenticate_client
    
    # Attempt to authenticate, this will use the access token or refresh token if present
    @client.authenticate rescue nil

    if @client.authenticated?
      # Save new token against the bullhorn setting
      @bullhorn_setting.update_attribute :refresh_token, @client.refresh_token
    else
      # It's possible another instance may have already used the refresh token, thus invalidating it.
      # A new token should have been saved to the bullhorn setting in this case
      @bullhorn_setting.reload

      @client.refresh_token = @bullhorn_setting.refresh_token

      @client.authenticate rescue nil
    end

    # Try full authentication again if we still need to
    unless @client.authenticated? 
      @client.expire
      @client.refresh_token = nil
      @client.authenticate rescue nil

      # Save new token against the bullhorn setting
      @bullhorn_setting.update_attribute :refresh_token, @client.refresh_token
    end

    @bullhorn_setting.update_attribute :authorised, !!@client.authenticated? if !!@bullhorn_setting.authorised != !!@client.authenticated?

    @client.errors = nil if @client.authenticated?

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
    obj['fields'].select { |f| f['type'] == "TO_MANY" && f['name'] == 'primarySkills' }.each { |field| 
      @bullhorn_fields << ["#{field['label']} (#{field['name']})", field['name']] 
    }
    obj['fields'].select { |f| f['type'] == "TO_MANY" && f['name'] == 'secondarySkills' }.each { |field| 
      @bullhorn_fields << ["#{field['label']} (#{field['name']})", field['name']] 
    }

    @bullhorn_fields.sort! { |x,y| x.first <=> y.first }

    @bullhorn_fields
  rescue StandardError => e 
    Honeybadger.notify(e)
    create_log(@bullhorn_setting, @key, 'get_bullhorn_candidate_fields', nil, nil, e.message, true, false)
    { error: 'Error retrieving candidate fields' }
  end

  # GETS VOLCANIC CANDIDATES FIELDS VIA API
  def volcanic_candidate_fields
    url = "#{@key.protocol}#{@key.host}/api/v1/user_groups.json"
    response = HTTParty.get url, { headers: { 'User-Agent' => 'VolcanicBullhornApp' } }
    
    @volcanic_fields = {}
    response.select { |f| f['default'] == true }.each { |r| 
      r['registration_question_groups'].each { |rg| 
        rg['registration_questions'].each { |q| 
          @volcanic_fields[q["reference"]] = q["label"] unless %w(password password_confirmation terms_and_conditions).include?(q['core_reference']) 
        } 
      } 
    }
    @volcanic_fields = Hash[@volcanic_fields.sort]

    @volcanic_fields
  rescue StandardError => e
    Honeybadger.notify(e)
    create_log(@bullhorn_setting, @key, 'get_volcanic_candidate_fields', url, nil, e.message, true, true)
    { error: 'Error retrieving candidate fields' }
  end

  # GETS BULLHORN JOB FIELDS VIA API USING THE GEM
  def bullhorn_job_fields

    path = "meta/JobOrder"
    client_params = {fields: '*'}
    @client.conn.options.timeout = 50 # Oliver will reap a unicorn process if it's waiting for longer than 60 seconds, so we'll only wait for 50

    res = @client.conn.get path, client_params
    obj = @client.decorate_response JSON.parse(res.body)

    # @bullhorn_job_fields = obj['fields'].select { |f| f['type'] == "SCALAR" }.map { |field| ["#{field['label']} (#{field['name']})", field['name']] }.sort! { |x,y| x.first <=> y.first }

    @bullhorn_job_fields = obj['fields'].map { |field| ["#{field['label']} (#{field['name']})", field['name']] }.sort! { |x,y| x.first <=> y.first }

    create_log(@bullhorn_setting, @key, 'get_bullhorn_job_fields', path, client_params.to_s, @bullhorn_job_fields, obj.errors.present?)


    @bullhorn_job_fields
  rescue StandardError => e
    Honeybadger.notify(e)
    create_log(@bullhorn_setting, @key, 'get_bullhorn_job_fields', path, nil, e.message, true, false)
    { error: 'Error retrieving job fields' }
  end

  # GETS VOLCANIC JOB FIELDS VIA API
  def volcanic_job_fields
    
    url = "#{@key.protocol}#{@key.host}/api/v1/available_job_attributes.json?api_key=#{@key.api_key}&all=true"
    response = HTTParty.get url, { headers: { 'User-Agent' => 'VolcanicBullhornApp' } }

    @default_job_fields = {}
    @other_job_fields = {}

    response.each { |r, val|
      if DEFAULT_JOB_FIELDS.keys.include?(val['attribute'].to_sym)
        @default_job_fields[val['attribute']] = val['name']
      else
        @other_job_fields[val['attribute']] = val['name']
      end
    }

    @default_job_fields = Hash[@default_job_fields.sort]
    @other_job_fields = Hash[@other_job_fields.sort]

    @default_job_fields.merge(@other_job_fields)
  rescue StandardError => e
    Honeybadger.notify(e)
    create_log(@bullhorn_setting, @key, 'get_volcanic_job_fields', nil, nil, e.message, true, true)
    { error: 'Error retrieving job fields' }
  end

  #SEND CANDIDATE INFO TO BULLHORN USING THE GEM
  def post_user_to_bullhorn(user, params, attrs = {})
    field_mappings = @bullhorn_setting.bullhorn_field_mappings.user

    attributes = {
      'firstName' => user.user_profile['first_name'],
      'lastName' => user.user_profile['last_name'],
      'name' => "#{user.user_profile['first_name']} #{user.user_profile['last_name']}",
      'email' => user.email
    }.merge(attrs)

    # If we don't already have a description set and user has no CV use LinkedIn profile
    attributes['description'] ||= linkedin_description(user) if user.linkedin_profile.present? && user.user_profile['upload_name'].blank?
    
    attributes["#{@bullhorn_setting.linkedin_bullhorn_field}"] = user.user_profile['li_publicProfileUrl'] if user.user_profile['li_publicProfileUrl'].present?

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
        attributes['address']['countryID'] = get_country(answer) if answer.present?
      when 'category', 'categoryID'
        # FIND category ID
        categories = @client.categories
       
        category = categories.data.select{ |c| c.name == answer }.first
        
        if category.present?
           attributes['category'] = {}
           attributes['category']['id'] = category.id
           @category_id = category.id
        end
      when 'businessSectors', 'primarySkills', 'secondarySkills'
        # UPDATE CANDIDATE AFTER CREATION
      else
        attributes[fm.bullhorn_field_name] = answer if answer.present?
      end
    end

    # Legal Documents
    if @bullhorn_setting.consent_object_name.present? && user.changed_consents.present?

      # Updating consents
      attributes[@bullhorn_setting.consent_object_name] = user.changed_consents.map { |consent| consent_attributes(consent) }      
      attributes[@bullhorn_setting.consent_object_name].delete_if { |consent| consent['text1'].blank? }

    end


    # GET BULLHORN ID
    if user.bullhorn_uid.present?
      bullhorn_id = user.bullhorn_uid
    else
      if @bullhorn_setting.always_create == true

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

    # Delete any blank attributes to avoid overwriting data in Bullhorn
    attributes.delete_if { |key,value| value.blank? }

    # Bullhorn appears to default to a countryID of '1' (United States) for an address so if none is set, send a '2378' (None Specified) value to be ignored
    attributes['address']['countryID'] = '2378' if attributes['address'].present? && attributes['address']['countryID'].blank?

    # CREATE/UPDATE CANDIDATE
    if bullhorn_id.present?
      candidate = @client.candidate(user.bullhorn_uid, {})
      if candidate.data.status == 'Inactive'
        attributes['status'] = @bullhorn_setting.status_text.present? ? @bullhorn_setting.status_text : 'New Lead'
      end

      response = @client.update_candidate(bullhorn_id, attributes.to_json)


      create_log(user, @key, 'update_candidate', "entity/candidate/#{user.bullhorn_uid}", { attributes: attributes }.to_s, response.to_s, (response.errors.present? || response.errorMessage.present?))

      if (response.errors.present? || response.errorMessage.present?)
        @key.bullhorn_report_entry.increment_count(:user_failed)
      else
        @key.bullhorn_report_entry.increment_count(:user_update)
      end

      if response.errors.present?
        response.errors.each do |e|
          Honeybadger.notify(
            :error_class => "Bullhorn Error",
            :error_message => "Bullhorn Error: #{e.inspect}",
            :parameters => params
          )
        end
        create_log(@bullhorn_setting, @key, 'post_user_to_bullhorn', nil, params, response.errors, true, true)
      end
    else
      if @bullhorn_setting.existing_candidate_registrations_only?
        create_log(user, @key, 'create_candidate', nil, params, "User doesn't exist in Bullhorn, ignoring")
      else
        attributes['status'] = @bullhorn_setting.status_text.present? ? @bullhorn_setting.status_text : 'New Lead'
        if @bullhorn_setting.use_utm_source? && user.user_data['utm_source']
          attributes['source'] = user.user_data['utm_source']
        else
          attributes['source'] = @bullhorn_setting.source_text.present? ? @bullhorn_setting.source_text : 'Company Website'
        end


        response = @client.create_candidate(attributes.to_json)

        create_log(user, @key, 'create_candidate', "entity/candidate", { attributes: attributes }.to_s, response.to_s, (response.errors.present? || response.errorMessage.present?))
        user.update(bullhorn_uid: response['changedEntityId'])
        
        if (response.errors.present? || response.errorMessage.present?)
          @key.bullhorn_report_entry.increment_count(:user_failed)
        else
          @key.bullhorn_report_entry.increment_count(:user_create)
        end

        bullhorn_id = response['changedEntityId']
        if response.errors.present?
          response.errors.each do |e|
            Honeybadger.notify(
              :error_class => "Bullhorn Error",
              :error_message => "Bullhorn Error: #{e.inspect}",
              :parameters => params
            )
            create_log(@bullhorn_setting, @key, 'post_user_to_bullhorn', nil, params, response.errors, true, true)
          end
        end
      end
    end
    

    if bullhorn_id.present?
      #category
      send_category(bullhorn_id)

      # CREATE NEW API CALL TO ADD ASSOCIATIONS TO CANDIDATE
      if user.registration_answers.present?
        send_associations 'businessSectors', 'business_sectors', field_mappings, user
        send_associations 'primarySkills', 'skills', field_mappings, user
        send_associations 'secondarySkills', 'skills', field_mappings, user
      end

    end
  rescue StandardError => e
    Honeybadger.notify(e)
    create_log(@bullhorn_setting, @key, 'post_user_to_bullhorn', nil, nil, e.message, true, false)
  end

  def send_associations(association, method, field_mappings, user)
    associations = @client.send(method) rescue nil
    mapping = field_mappings.find_by(bullhorn_field_name: association)

    if associations.present? && mapping.present?
      # use answer array if present or make array of single answer
      answers = (user.registration_answers["#{mapping.registration_question_reference}_array"] || [user.registration_answers[mapping.registration_question_reference]]).compact

      mapped_associations = answers.map { |answer| associations.data.select{ |a| a.name == answer.strip } }.flatten
      
      if mapped_associations.present?
        response = @client.create_candidate({}.to_json, { candidate_id: user.bullhorn_uid, association: association, association_ids: "#{mapped_associations.map(&:id).join(',')}" })
      end
    end
  end

  #FETCH CLIENT'S BLUHORN JOBS TO IMPORT INTO VOLCANIC
  def sync_jobs
    
    # Retrieve only job ids initially

    query_job_orders.each do |job|

      if job.isOpen && ((@bullhorn_setting.job_status.blank? && job.status != 'Archived') || @bullhorn_setting.job_status == job.status) && (!@bullhorn_setting.uses_public_filter? || job.isPublic == 1)
        BullhornParseJobWorker.perform_async setting_id: @bullhorn_setting.id, job_id: job.id
      elsif live_volcanic_job_references.include?(job.id.to_s)
        if job.isDeleted || job.status == 'Archived' || (@bullhorn_setting.uses_public_filter? && job.isPublic == 0)
          BullhornDeleteJobWorker.perform_async setting_id: @bullhorn_setting.id, job_id: job.id
        elsif @bullhorn_setting.expire_closed_jobs?
          BullhornExpireJobWorker.perform_async setting_id: @bullhorn_setting.id, job_id: job.id
        end
      elsif expired_volcanic_job_references.include?(job.id.to_s)
        BullhornDeleteJobWorker.perform_async(setting_id: @bullhorn_setting.id, job_id: job.id) if job.isDeleted || job.status == 'Archived' || (@bullhorn_setting.uses_public_filter? && job.isPublic == 0)
      end

    end

  rescue StandardError => e
    Honeybadger.notify(e)
    create_log(@bullhorn_setting, @key, 'import_client_jobs', nil, nil, e.message, true, false)
  end

  def import_client_job(job_id)
    puts "Importing..."
    field_mappings = @bullhorn_setting.bullhorn_field_mappings.job
    bullhorn_job = @key.bullhorn_jobs.find_or_create_by(bullhorn_uid: job_id)

    job = query_job_order job_id, field_mappings.map(&:bullhorn_field_name).reject { |m| m.empty? }
    unless job.present?
      bullhorn_job.update_attribute :error, true
      return false
    end
    
    @job_payload = Hash.new
    @job_payload["job[api_key]"] = @key.api_key

    default_job_playload_attributes(job)

    #ONLY USE CUSTOM MAPPINGS IF THE APP IS NOT USING THE DEFAULT MAPPINGS
    if @bullhorn_setting.custom_job_mapping?
      field_mappings.each do |fm|

        # Some bullhorn values need extra massaging
        case fm.bullhorn_field_name
        when 'businessSectors'
          sectors = []
          job.businessSectors.data.each do |bs|
            # puts "--- bs[:id] = #{bs[:id]}"
            b_sector = client.business_sector(bs[:id])
            # puts "--- b_sector = #{b_sector.inspect}"
            sectors << b_sector.data.name.strip
          end
          value = sectors.join(',')
        when 'dateEnd'
          value = Time.at(job.dateEnd / 1000).to_date.to_s rescue nil
        else
          bullhorn_value = job.send(fm.bullhorn_field_name)
          if bullhorn_value.is_a? Hash
            if bullhorn_value.keys.include? 'data'
              value = bullhorn_value.data.map(&:name).join(',')
            elsif bullhorn_value.keys.include? 'firstName'
              value = "#{bullhorn_value.firstName} #{bullhorn_value.lastName}"
            elsif bullhorn_value.keys.include? 'name'
              value = bullhorn_value.name
            end
          elsif bullhorn_value.is_a? Array
            value = bullhorn_value.join(',')
          else
            value = bullhorn_value
          end
        end

        # Check for blank or zero Max Salary values
        if fm.job_attribute == 'salary_high'
          unless value.present? && value.to_i != 0
            value = @job_payload["job[salary_low]"]
          end
        end

        puts "--- job.#{fm.bullhorn_field_name} = #{value}"

        @job_payload["job[#{fm.job_attribute}]"] = value
        
      end
    end

    if @bullhorn_setting.client_token.present?
      @job_payload['job[client_token]'] = @bullhorn_setting.client_token
    end

    # Expiry = date + 365 days
    begin
      date = Date.parse(@job_payload['job[created_at]'])
      @job_payload['job[expiry_date]'] ||= (date + 365.days).to_s
    rescue Exception => e
      puts "[WARN] #{e}"
      @job_payload['job[expiry_date]'] ||= (Date.today + 365.days).to_s
    end

    begin
      bullhorn_job.update_attribute :job_params, @job_payload
    rescue StandardError
      bullhorn_job.update_attribute :job_params, 'Error saving payload'
    end

    if @job_payload["job[discipline]"].blank?
      bullhorn_job.update_attribute :error, true
    else
      # Don't post if we have a client_id (ie a job board) and the job is open but we have a past expiry date (as oliver API will still make live because job board)
      if @bullhorn_setting.client_token.present? && (@job_payload['job[expiry_date]'].present? && @job_payload['job[expiry_date]'].to_date < Date.today)
        bullhorn_job.update_attribute :error, true
      else
        post_payload(@job_payload)
      end
    end
    
    puts "Updating report entries"
    @key.update_bullhorn_report_job_entries
  end

  #FETCH CLIENT'S BLUHORN JOBS TO DELETE FROM VOLCANIC
  def delete_client_job(job_id)
    job = query_job_order job_id
    return unless job.present?

    @job_payload = Hash.new
    @job_payload["job[api_key]"] = @key.api_key
    @job_payload['job[job_reference]'] = job.id

    post_payload_for_delete(@job_payload)
    
  rescue StandardError => e
    Honeybadger.notify(e)
    create_log(@bullhorn_setting, @key, 'delete_client_jobs', nil, nil, e.message, true, false)
  end

  #FETCH CLIENT'S BLUHORN JOBS TO EXPIRE FROM VOLCANIC
  def expire_client_job(job_id)
    job = query_job_order job_id
    return unless job.present?

    @job_payload = Hash.new
    @job_payload["job[api_key]"] = @key.api_key
    @job_payload['job[job_reference]'] = job.id

    post_payload_for_expire(@job_payload)

  rescue StandardError => e
    Honeybadger.notify(e)
    create_log(@bullhorn_setting, @key, 'expire_client_jobs', nil, nil, e.message, true, false)
  end

  #SEND JOB APPLICATION TO BULLHORN
  def send_job_application(attributes)
    @response = @client.create_job_submission(attributes.to_json)
    puts "--- response = #{@response.inspect}"

    if @response.changedEntityId.present?
      create_log(@bullhorn_setting, @key, 'send_job_application', nil, nil, @response, false, false)
      @key.bullhorn_report_entry.increment_count(:applications)
    else
      create_log(@bullhorn_setting, @key, 'send_job_application', nil, nil, @response, true, false)
    end

    return @response
  rescue StandardError => e
    Honeybadger.notify(e)
    create_log(@bullhorn_setting, @key, 'send_job_application', nil, nil, e.message, true, false)
  end

  #SEND NEW SEARCH TO BULLHORN
  def send_search(user, params)

    candidate = {
      'id' => user.bullhorn_uid
    }

    # contruct comment based on received search params
    search = params[:search]
    job_type = params[:job_type].present? ? params[:job_type] : "N/A"
    disciplines = params[:disciplines].present? ? params[:disciplines].map{|d| d[:name] if d[:name].present?}.join(", ") : "N/A"
    comment = "Keyword: #{search[:query]}</br> Location: #{search[:location]}</br> Job type: #{job_type}</br> Discipline(s): #{disciplines}"

    # create note entity
    attributes = {
      'action' => 'Job search on website',
      'comments' => comment,
      'isDeleted' => 'false',
      'personReference' => candidate
    }

    @response = @client.create_note(attributes.to_json)

    # check response and create note entity
    if @response.changedEntityId.present?

      # assign note id to local variable
      note_id = @response.changedEntityId

      # create note entity object
      create_note_entity(note_id, user)

      create_log(@bullhorn_setting, @key, 'send_search_successfull', nil, nil, @response, false, false)
    else
      create_log(@bullhorn_setting, @key, 'send_search_failed', nil, nil, @response, true, false)
    end

    return @response
  rescue StandardError => e
    Honeybadger.notify(e)
    create_log(@bullhorn_setting, @key, 'send_search', nil, nil, e.message, true, false)
  end

  # PARSE AND SEND CANDIDATE'S CV TO BULLHORN
  def send_candidate_file(user, params, upload_path, upload_name, type)

    # @file_attributes COME FROM THIS
     case type
    when 'cv'
      if Rails.env.development?
        key = Key.where(app_dataset_id: params[:dataset_id], app_name: params[:controller]).first
        file_url = 'http://' + key.host + upload_path
      else
        # UPLOAD PATHS USE CLOUDFRONT URL
        file_url = upload_path
      end
      bh_type = (@bullhorn_setting.cv_type_text.present? ? @bullhorn_setting.cv_type_text : 'CV')
    when 'cover_letter'
      file_url = upload_path
      bh_type = 'Cover Letter'
    end

    extract_file_attributes(file_url, params[:dataset_id], upload_name, bh_type)

    if @file_attributes.present?

      @file_response = @client.put_candidate_file(user.bullhorn_uid, @file_attributes.to_json)

      if type == 'cv'

        # PARSE FILE
        candidate_data = parse_cv(upload_name, @content_type, @file, @ct)

        # ADD TO CANDIDATE DESCRIPTION
        if candidate_data.present? && candidate_data['description'].present?
          attributes = {}
          attributes['description'] = candidate_data['description']
          post_user_to_bullhorn(user, nil, attributes)
        end

      end
    end

    if @file_response && @file_response['fileId'].present?
      create_log(user, @key, 'send_candidate_file', nil, nil, @file_response, false, false)
      return true
    else
      create_log(user, @key, 'send_candidate_file', nil, nil, @file_response, true, false)
      return false
    end
  rescue StandardError => e
    Honeybadger.notify(e)
    create_log(user, @key, 'send_candidate_file', nil, nil, e.message, true, false)
    return false
  end

  private

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

  def send_category(bullhorn_id)
    if @category_id.present?
      Bullhorn::SendCategoryService.new(bullhorn_id, @client, @category_id).send_category_to_bullhorn
    end
  rescue StandardError => e
    Honeybadger.notify(e)
    create_log(@bullhorn_setting, @key, 'send_category', nil, nil, e.message, true, false)
  end

  def query_job_orders
    # Bullhorn only returns a max of 200 jobs per query, so if 200 is received, assume there are more an increase offset and repeat query. 
    # Depending on the requested data less than 200 results may be received, so keep checking until 0 results are returned

    offset = 0
    results = 200 # prime the loop

    complete_data = []

    while results > 0

      jobs = @client.query_job_orders(where: 'status IS NOT NULL', fields: 'id,isOpen,isDeleted,isPublic,status', count: 200, start: offset, orderBy: 'id')
      
      puts "Received #{jobs["count"]}"
      puts "Received results - possibly another page" if jobs["count"] > 0

      results = jobs["count"]
      offset += jobs["count"]
      complete_data.concat jobs.data if jobs["count"] > 0
    end
    complete_data
  rescue StandardError => e
    Honeybadger.notify(e)
    create_log(@bullhorn_setting, @key, 'query_job_orders', nil, nil, e.message, true, true)
    []
  end

  def query_job_order(job_id, custom_fields = [])
    retries ||= 0
    fields = (%w(id title owner businessSectors dateAdded externalID address employmentType benefits salary description publicDescription isOpen isDeleted isPublic status salaryUnit) + custom_fields).uniq.join(',')
    job = @client.job_order(job_id, fields: fields).data
  rescue Bullhorn::Rest::AuthenticationError => e
    # Sometimes Bullhorn throws a wobbly and the client needs to be re-authenticated
    @client.expire
    if (retries += 1) < 3
      authenticate_client
      retry
    else
      Honeybadger.notify(e)
      bullhorn_job = @key.bullhorn_jobs.find_or_create_by(bullhorn_uid: job_id)
      bullhorn_job.update_attribute :error, true
      create_log(bullhorn_job, @key, 'query_job_order', 'entity/JobOrder', job_id, e.message, true, true)
      nil
    end
  rescue StandardError => e
    Honeybadger.notify(e)
    bullhorn_job = @key.bullhorn_jobs.find_or_create_by(bullhorn_uid: job_id)
    bullhorn_job.update_attribute :error, true
    create_log(bullhorn_job, @key, 'query_job_order', 'entity/JobOrder', job_id, e.message, true, true)
    nil
  end

  def post_payload(payload)

    # Find or create bullhorn_job object

    @bullhorn_job = @key.bullhorn_jobs.find_by(bullhorn_uid: payload['job[job_reference]'])
    
    url = "#{@key.protocol}#{@key.host}/api/v1/jobs.json"
    response = HTTParty.post(url, { body: payload, headers: { 'User-Agent' => 'VolcanicBullhornApp' } })

    # CREATE APP LOGS
    if response['response'].present? && response['response']['status'] == 'error' && response['response']['errors'].present?
      @bullhorn_job.update_attribute :error, true
      create_log(@bullhorn_job, @key, 'post_job_in_volcanic', url, payload.to_s, response['response']['errors'], true, true)
    elsif response['response'].present? && response['response']['reason'].present?
      @bullhorn_job.update_attribute :error, true
      create_log(@bullhorn_job, @key, 'post_job_in_volcanic', url, payload.to_s, response['response']['reason'], true, true)
    else #SUCCESS
      @bullhorn_job.update_attribute :error, false
      create_log(@bullhorn_job, @key, 'post_job_in_volcanic', url, payload.to_s, response.to_s, false, false)
    end

    return response.code.to_i == 200
  rescue StandardError, JSON::ParserError => e
    create_log(@bullhorn_job, @key, 'post_payload', url, nil, e.to_s, true, true)
    puts "[FAIL] http.request failed to post payload: #{e}"
  end

  def post_payload_for_delete(payload)

    url = "#{@key.protocol}#{@key.host}/api/v1/jobs/delete.json"
    response = HTTParty.post(url, { body: payload, headers: { 'User-Agent' => 'VolcanicBullhornApp' } })

    puts "#{response.code} - #{response.read_body}"
    
    # CREATE APP LOGS
    if response['response'].present? && response['response']['status'] == 'error' && response['response']['errors'].present?
      create_log(@bullhorn_setting, @key, 'delete_job_in_volcanic', url, payload.to_s, response['response']['errors'], true, true)
    elsif response['response'].present? && response['response']['reason'].present?
      create_log(@bullhorn_setting, @key, 'delete_job_in_volcanic', url, payload.to_s, response['response']['reason'], true, true)
    else #SUCCESS
      create_log(@bullhorn_setting, @key, 'delete_job_in_volcanic', url, payload.to_s, response.to_s, false, true)
      @key.bullhorn_report_entry.increment_count(:job_delete)
    end

    return response.code.to_i == 200
  rescue StandardError, JSON::ParserError => e
    Honeybadger.notify(e)
    create_log(@bullhorn_setting, @key, 'post_payload_for_delete', url, nil, e.to_s, true, true)
    puts "[FAIL] http.request failed to post payload: #{e}"
  end

  def post_payload_for_expire(payload)
    url = "#{@key.protocol}#{@key.host}/api/v1/jobs/expire.json"
    response = HTTParty.post(url, { body: payload, headers: { 'User-Agent' => 'VolcanicBullhornApp' } })

    puts "#{response.code} - #{response.read_body}"
    
    # CREATE APP LOGS
    if response['response'].present? && response['response']['status'] == 'error' && response['response']['errors'].present?
      create_log(@bullhorn_setting, @key, 'expire_job_in_volcanic', url, payload.to_s, response['response']['errors'], true, true)
    elsif response['response'].present? && response['response']['reason'].present?
      create_log(@bullhorn_setting, @key, 'expire_job_in_volcanic', url, payload.to_s, response['response']['reason'], true, true)
    else #SUCCESS
      create_log(@bullhorn_setting, @key, 'expire_job_in_volcanic', url, payload.to_s, response.to_s, false, true)
      @key.bullhorn_report_entry.increment_count(:job_expire)
    end

    return response.code.to_i == 200
  rescue StandardError, JSON::ParserError => e
    Honeybadger.notify(e)
    create_log(@bullhorn_setting, @key, 'post_payload_for_expire', url, nil, e.to_s, true, true)
    puts "[FAIL] http.request failed to post payload: #{e}"
  end

  def default_job_playload_attributes(job)

    @job_payload['job[job_title]'] = job.title

    #GET BULLHORN USER DATA
    c_user = @client.corporate_user(job.owner.id)

    @job_payload['job[application_email]'] = c_user.data.email
    @job_payload['job[contact_name]'] = "#{job.owner.firstName} #{job.owner.lastName}"

    disciplines = []
    job.businessSectors.data.each do |bs|
      # puts "--- bs[:id] = #{bs[:id]}"

      #GET BULLHORN CLIENT DISCIPLINES ASSOCIATED TO THE JOB
      b_sector = @client.business_sector(bs[:id])

      disciplines << b_sector.data.name.strip
    end
    discipline_list = disciplines.join(', ')
    @job_payload['job[discipline]'] = discipline_list.strip

    @job_payload['job[created_at]'] = Time.at(job.dateAdded / 1000).to_datetime.to_s

    # @job_payload['job[job_reference]'] = job.externalID
    @job_payload['job[job_reference]'] = job.id
    # address = job.address.map{ |a| a[0] == 'countryID' ? get_country(a[1].to_s) : a[1] }.reject{ |a| a.blank? }.join(', ')
    city = job.address.city
    country = get_country(job.address.countryID.to_s)
    @job_payload['job[job_location]'] = [city, country].reject{ |a| a.blank? }.join(', ')
    @job_payload['job[job_type]'] = job.employmentType

    salary_val = job.salary > 0 ? job.salary : nil
    @job_payload['job[salary_low]'] = salary_val

    salary_per = 'hour' if job.salaryUnit == 'Per Hour'
    salary_per = 'day' if job.salaryUnit == 'Per Day'
    @job_payload['job[salary_per]'] = salary_per

    @job_payload['job[job_description]'] = job.publicDescription.present? ? job.publicDescription : job.description
  end

  def get_country(val)
    bullhorn_country_array =  [
      ["United States","1"],
      ["Afghanistan","2185"],
      ["Albania","2186"],
      ["Algeria","2187"],
      ["Andorra","2188"],
      ["Angola","2189"],
      ["Antartica","2190"],
      ["Antigua and Barbuda","2191"],
      ["Argentina","2192"],
      ["Armenia","2193"],
      ["Australia","2194"],
      ["Austria","2195"],
      ["Azerbaijan","2196"],
      ["Bahamas","2197"],
      ["Bahrain","2198"],
      ["Bangladesh","2199"],
      ["Barbados","2200"],
      ["Belarus","2201"],
      ["Belgium","2202"],
      ["Belize","2203"],
      ["Benin","2204"],
      ["Bhutan","2205"],
      ["Bolivia","2206"],
      ["Bosnia Hercegovina","2207"],
      ["Botswana","2208"],
      ["Brazil","2209"],
      ["Brunei Darussalam","2210"],
      ["Bulgaria","2211"],
      ["Burkina Faso","2212"],
      ["Burundi","2213"],
      ["Cambodia","2214"],
      ["Cameroon","2215"],
      ["Canada","2216"],
      ["Cape Verde","2217"],
      ["Central African Republic","2218"],
      ["Chad","2219"],
      ["Chile","2220"],
      ["China","2221"],
      ["Columbia","2222"],
      ["Comoros","2223"],
      ["Costa Rica","2226"],
      ["Cote d'Ivoire","2227"],
      ["Croatia","2228"],
      ["Cuba","2229"],
      ["Cyprus","2230"],
      ["Czech Republic","2231"],
      ["Denmark","2232"],
      ["Djibouti","2233"],
      ["Dominica","2234"],
      ["Dominican Republic","2235"],
      ["Ecuador","2236"],
      ["Egypt","2237"],
      ["El Salvador","2238"],
      ["Equatorial Guinea","2239"],
      ["Eritrea","2240"],
      ["Estonia","2241"],
      ["Ethiopia","2242"],
      ["Fiji","2243"],
      ["Finland","2244"],
      ["France","2245"],
      ["Gabon","2246"],
      ["Georgia","2248"],
      ["Germany","2249"],
      ["Ghana","2250"],
      ["Greece","2251"],
      ["Greenland","2252"],
      ["Grenada","2253"],
      ["Guinea","2255"],
      ["Guinea-Bissau","2256"],
      ["Guyana","2257"],
      ["Haiti","2258"],
      ["Honduras","2259"],
      ["Hungary","2260"],
      ["Iceland","2261"],
      ["India","2262"],
      ["Indonesia","2263"],
      ["Iran","2264"],
      ["Iraq","2265"],
      ["Ireland","2266"],
      ["Israel","2267"],
      ["Italy","2268"],
      ["Jamaica","2269"],
      ["Japan","2270"],
      ["Jordan","2271"],
      ["Kazakhstan","2272"],
      ["Kenya","2273"],
      ["Korea; Democratic People's Republic Of (North)","2274"],
      ["Korea; Republic Of (South)","2275"],
      ["Kuwait","2276"],
      ["Kyrgyzstan","2277"],
      ["Lao People's Democratic Republic","2278"],
      ["Latvia","2279"],
      ["Lebanon","2280"],
      ["Lesotho","2281"],
      ["Liberia","2282"],
      ["Liechtenstein","2284"],
      ["Lithuania","2285"],
      ["Luxembourg","2286"],
      ["Macau","2287"],
      ["Macedonia","2288"],
      ["Madagascar","2289"],
      ["Malawi","2290"],
      ["Malaysia","2291"],
      ["Mali","2292"],
      ["Malta","2293"],
      ["Mauritania","2294"],
      ["Mauritius","2295"],
      ["Mexico","2296"],
      ["Micronesia; Federated States of","2297"],
      ["Monaco","2299"],
      ["Mongolia","2300"],
      ["Morocco","2301"],
      ["Mozambique","2302"],
      ["Myanmar","2303"],
      ["Namibia","2304"],
      ["Nepal","2305"],
      ["Netherlands","2306"],
      ["New Zealand","2307"],
      ["Nicaragua","2308"],
      ["Niger","2309"],
      ["Nigeria","2310"],
      ["Norway","2311"],
      ["Oman","2312"],
      ["Pakistan","2313"],
      ["Palau","2314"],
      ["Panama","2315"],
      ["Papua New Guinea","2316"],
      ["Paraguay","2317"],
      ["Peru","2318"],
      ["Philippines","2319"],
      ["Poland","2320"],
      ["Portugal","2321"],
      ["Qatar","2322"],
      ["Romania","2323"],
      ["Russian Federation","2324"],
      ["Rwanda","2325"],
      ["Saint Lucia","2326"],
      ["San Marino","2327"],
      ["Saudi Arabia","2328"],
      ["Senegal","2329"],
      ["Seychelles","2331"],
      ["Sierra Leone","2332"],
      ["Singapore","2333"],
      ["Slovakia","2334"],
      ["Slovenia","2335"],
      ["Solomon Islands","2336"],
      ["Somalia","2337"],
      ["South Africa","2338"],
      ["Spain","2339"],
      ["Sri Lanka","2340"],
      ["Sudan","2341"],
      ["Suriname","2342"],
      ["Swaziland","2343"],
      ["Sweden","2344"],
      ["Switzerland","2345"],
      ["Tajikistan","2348"],
      ["Tanzania","2349"],
      ["Thailand","2350"],
      ["Togo","2351"],
      ["Trinidad and Tobago","2352"],
      ["Tunisia","2353"],
      ["Turkey; Republic of","2354"],
      ["Turkmenistan","2355"],
      ["Uganda","2356"],
      ["Ukraine","2357"],
      ["United Arab Emirates","2358"],
      ["United Kingdom","2359"],
      ["Uruguay","2360"],
      ["Uzbekistan","2361"],
      ["Vatican City","2362"],
      ["Venezuela","2363"],
      ["Vietnam","2364"],
      ["Yugoslavia","2367"],
      ["Zaire","2368"],
      ["Zambia","2369"],
      ["Zimbabwe","2370"],
      ["Guatemala","2371"],
      ["Bermuda","2372"],
      ["Aruba","2373"],
      ["Puerto Rico","2374"],
      ["Taiwan","2375"],
      ["Guam","2376"],
      ["Hong Kong SAR","NU2377"],
      ["None Specified","NO2378"],
      ["Cayman Islands","2379"],
      ["Aland Islands","2407"],
      ["America Samoa","2408"],
      ["Andorra","2188"],
      ["Bouvet Island","2410"],
      ["Bristish Indian Ocean Terriority","2411"],
      ["Burma","2385"],
      ["Channel Islands","2386"],
      ["Christmas Island","2412"],
      ["Cocos(Keeling) Islands","2413"],
      ["Congo; Democratic Republic of","2368"],
      ["Congo; Republic of","2383"],
      ["Cook Islands","2414"],
      ["Curacao","2387"],
      ["Falkland Islands(Malvinas)","2415"],
      ["Faroe Islands","2388"],
      ["French Guiana","2416"],
      ["French Polynesia","2417"],
      ["French Souhern Territories","2418"],
      ["Gambia","2389"],
      ["Gibraltar","2390"],
      ["Guadeloupe","2419"],
      ["Guernsey","2420"],
      ["Heard and McDonald Islands","2421"],
      ["Isle of Man","2445"],
      ["Jersey","2422"],
      ["Kosova","2392"],
      ["Libyan Arab Jamahahiritya","2380"],
      ["Maldives; Republic of","2384"],
      ["Marshall Islands","2394"],
      ["Martinique","2423"],
      ["Mayotte","2393"],
      ["Moldova; Republic of","2395"],
      ["Montenegro","2396"],
      ["Montserrat","2424"],
      ["Nauru","2397"],
      ["Netherlands Antilles","2425"],
      ["New Caledonia","2426"],
      ["Nlue","2427"],
      ["Norfolk Island","2428"],
      ["Northern Mariana Islands","2429"],
      ["Palestinian Terrority; Occupied","2430"],
      ["Pitcairn","2431"],
      ["Reunion","2398"],
      ["Saint Barthelemy","2432"],
      ["Saint Helena,Ascension and Tristan Da Cunta","2433"],
      ["Saint Kitts and Nevis","2399"],
      ["Saint Martin","2434"],
      ["Saint Pierre and Miquelon","2435"],
      ["Saint Vincent and Grenadines","2400"],
      ["Samoa","2401"],
      ["Sao Tome and Principe ","2403"],
      ["Serbia","2402"],
      ["South Georgia and the South Sandwich Islands","2436"],
      ["South Sudan","2447"],
      ["Svalbard And Jan Mayen","2437"],
      ["Timor-Leste","2404"],
      ["Tokelau","2438"],
      ["Tonga","2405"],
      ["Turks and Caicos Islands ","2439"],
      ["Tuvalu","2440"],
      ["United States Minor Outlying Islands","2441"],
      ["Virgin Islands; British","2446"],
      ["Virgin Islands; U.S.","2442"],
      ["Walls and Futuna","2443"],
      ["Western Sahara","2444"],
      ["Yemen","2383"]
    ]
    id = bullhorn_country_array.select{ |name, id| id == val }
    name = bullhorn_country_array.select{ |name, id| name == val }
    if id.present?
      id.first[0]
    elsif name.present?
      name.first[1].to_i
    end
  end

  def create_note_entity(note_id, user)
    # create note entity attributes object
    attributes = {
      'note' => { 'id' => note_id },
      'targetEntityID' => user.bullhorn_uid,
      'targetEntityName' => 'User'
    }

    # create note entity
    @response = @client.create_note_entity(attributes.to_json)

    if @response.changedEntityId.present?
      create_log(@bullhorn_setting, @key, 'create_note_entity', nil, nil, @response, false, false)
    else
      create_log(@bullhorn_setting, @key, 'create_note_entity', nil, nil, @response, true, false)
    end
  end

  def extract_file_attributes(url, dataset_id, upload_name, type)
    require 'open-uri'
    require 'base64'
    settings = BullhornAppSetting.find_by(dataset_id: dataset_id)
    @file = open(url).read
    # UPOAD FILE
    base64_file = Base64.encode64(@file)
    @content_type = upload_name.split('.').last
    # text, html, pdf, doc, docx, rtf, or odt.
    case @content_type
    when 'doc'
      @ct = 'application/msword'
    when 'docx'
      @ct = 'application/vnd.openxmlformatsofficedocument.wordprocessingml.document'
    when 'txt'
      @ct = 'text/plain'
    when 'html'
      @ct = 'text/html'
    when 'pdf'
      @ct = 'application/pdf'
    when 'rtf'
      @ct = 'application/rtf'
    when 'odt'
      @ct = 'application/vnd.oasis.opendocument.text'
    end
    @file_attributes = {
      'externalID' => type.upcase,
      'fileType' => 'SAMPLE',
      'name' => upload_name,
      'fileContent' => base64_file,
      'contentType' => @ct,
      'type' => type
    }
  end

  def parse_cv(upload_name, content_type, cv, ct)
    # TRY UP TO 10 TIMES AS PER SUPPORT:
    # http://supportforums.bullhorn.com/viewtopic.php?t=15011
    10.times do
      require 'tempfile'
      file = Tempfile.new(upload_name)
      file.binmode
      file.write(cv)
      file.rewind
      parse_attributes = {
        'file' => file.path,
        'ct' => ct
      }
      candidate_response = @client.parse_to_candidate_as_file(content_type.upcase, 'html', parse_attributes)

      if candidate_response['candidate'].present?
        # STOP LOOP AND RETURN
        return candidate_response['candidate']
      end
    end
    false # return false if this has not returned a candidate_response after 10 tries
  rescue StandardError => e
    Honeybadger.notify(e)
    create_log(@bullhorn_setting, @key, 'parse_cv', nil, nil, e.message, true, false)
  end 

  def create_log(loggable, key, name, endpoint, message, response, error = false, internal = false, uid = nil)
    log = loggable.app_logs.create key: key, endpoint: endpoint, name: name, message: message, response: (@client.errors || response), error: error, internal: internal, uid: uid || @client.access_token
    log.id
  rescue StandardError => e
    Honeybadger.notify(e)
  end

  def live_volcanic_job_references
    return @volcanic_job_references unless @volcanic_job_references.nil?

    url = "#{@key.protocol}#{@key.host}/api/v1/jobs/job_references.json"
    response = HTTParty.get url, { headers: { 'User-Agent' => 'VolcanicBullhornApp' } }

    @volcanic_job_references = if response.code == 200
      response.parsed_response.map { |r| r['job_reference'] }
    else
      []
    end
    
  rescue StandardError => e
    Honeybadger.notify(e)
    create_log(@bullhorn_setting, @key, 'get_volcanic_job_references', url, nil, e.message, true, true)
  end

  def expired_volcanic_job_references
    return @expired_volcanic_job_references unless @expired_volcanic_job_references.nil?
    
    url = "#{@key.protocol}#{@key.host}/api/v1/jobs/job_references.json?include_expired=true"
    response = HTTParty.get url, { headers: { 'User-Agent' => 'VolcanicBullhornApp' } }

    @all_volcanic_job_references = if response.code == 200
      response.parsed_response.map { |r| r['job_reference'] }
    else
      []
    end

    @expired_volcanic_job_references = @all_volcanic_job_references - live_volcanic_job_references
    
  rescue StandardError => e
    Honeybadger.notify(e)
    create_log(@bullhorn_setting, @key, 'get_volcanic_job_references', url, nil, e.message, true, true)
  end

  def consent_purpose(consent)
    case consent['key']
    when 'term_and_conditions'
      'Recruiting'
    when 'job_alerts' #TBC - not implemented in Oliver yet
      'Direct Mail'
    when 'privacy_policy'
      'Sharing with 3rd Parties'
    when 'first_opt_in', 'second_opt_in'
      'Promotional Emails'
    end
      
  end

  def legal_basis(consent)
    if consent['consent_type'] == 'implied'
      'Contract Necessity'
    elsif consent['event'].present?
      case consent['event']
      when 'consent_given', true
        'Express Consent'
      when 'consent_removed', false
        'Consent Revoked'
      end
    elsif !consent['consented'].nil?
      consent['consented'] ? 'Express Consent' : 'Consent Revoked'
    end
  end

  def consented_at_timestamp(consented_at)
    consented_at_timestamp = (consented_at ? DateTime.parse(consented_at).to_i : Time.now.to_i) * 1000
  end

  def consent_attributes(consent)
    {
      'text1' => consent_purpose(consent),
      'text2' => legal_basis(consent),
      'date1' => consented_at_timestamp(consent['occurred_at']),
      'date2' => consented_at_timestamp(consent['occurred_at']),
      'textBlock1' => "#{consent['title']} Version #{consent['version']}",
      'text3' => 'Website'
    }
  end

end