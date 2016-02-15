class BullhornController < ApplicationController
  require 'bullhorn/rest'
  protect_from_forgery with: :null_session, except: [:save_settings]
  respond_to :json

  # Controller requires cross-domain POST XHRs
  after_filter :setup_access_control_origin
  before_action :set_key, only: [:index, :job_application]

  # To Autorize a Bullhorn API user, follow instruction on https://github.com/bobop/bullhorn-rest

  def index
    @bullhorn_setting = BullhornAppSetting.find_by(dataset_id: params[:data][:dataset_id]) || BullhornAppSetting.new(dataset_id: params[:data][:dataset_id])
    render layout: false
  end

  def save_settings
    @bullhorn_setting = BullhornAppSetting.find_by(dataset_id: params[:bullhorn_app_setting][:dataset_id])
    if @bullhorn_setting.present?
      if @bullhorn_setting.update(params[:bullhorn_app_setting].permit!)
        if @bullhorn_setting.import_jobs?
          # Set default custom mappings unless present
          @bullhorn_setting.bullhorn_field_mappings.create_with(bullhorn_field_name: 'customFloat1').find_or_create_by(job_attribute: 'salary_high')
          @bullhorn_setting.bullhorn_field_mappings.create_with(bullhorn_field_name: 'customText3').find_or_create_by(job_attribute: 'salary_free')
        else
          @bullhorn_setting.bullhorn_field_mappings.job.destroy_all
        end

        update_authorised_setting(@bullhorn_setting)
        flash[:notice]  = "Settings successfully saved."
      else
        flash[:alert]   = "Settings could not be saved. Please try again."
      end
    else
      @bullhorn_setting = BullhornAppSetting.new(params[:bullhorn_app_setting].permit!)
      if @bullhorn_setting.save
        update_authorised_setting(@bullhorn_setting)
        flash[:notice]  = "Settings successfully saved."
      else
        flash[:alert]   = "Settings could not be saved. Please try again."
      end
    end
  end

  def save_user
    @user = BullhornUser.find_by(user_id: params[:user][:id])
    client = authenticate_client(params[:user][:dataset_id])
    if @user.present?
      if @user.update(
        email: params[:user][:email],
        user_data: params[:user],
        user_profile: params[:user_profile],
        linkedin_profile: params[:linkedin_profile],
        registration_answers: params[:registration_answer_hash]
      )
        logger.info "--- params = #{params.inspect}"
        post_user_to_bullhorn_2(@user, client, params)
        upload_cv_to_bullhorn_2(@user, client, params)
        render json: { success: true, user_id: @user.id }
      else
        render json: { success: false, status: "Error: #{@user.errors.full_messages.join(', ')}" }
      end
    else
      @user = BullhornUser.new
      @user.user_id = params[:user][:id]
      @user.email = params[:user][:email]
      @user.user_data = params[:user]
      @user.user_profile = params[:user_profile]
      @user.linkedin_profile = params[:linkedin_profile]
      @user.registration_answers = params[:registration_answer_hash]

      if @user.save
        post_user_to_bullhorn_2(@user, client, params)
        upload_cv_to_bullhorn_2(@user, client, params)
        render json: { success: true, user_id: @user.id }
      else
        render json: { success: false, status: "Error: #{@user.errors.full_messages.join(', ')}" }
      end
    end
  end

  def get_user
    @user = BullhornUser.find_by(user_id: params[:user][:id])
    # GET CANDIDATE DETAILS FROM BULLHORN
    settings = BullhornAppSetting.find_by(dataset_id: params[:user][:dataset_id])
    field_mappings = settings.bullhorn_field_mappings.user.where(sync_from_bullhorn: true)
    logger.info "--- field_mappings = #{field_mappings.inspect}"
    client = Bullhorn::Rest::Client.new(
      username: settings.bh_username,
      password: settings.bh_password,
      client_id: settings.bh_client_id,
      client_secret: settings.bh_client_secret
    )
    candidate = client.candidate(@user.bullhorn_uid, {})
    logger.info "--- candidate = #{candidate.inspect}"
    # CREATE JSON OF SYNCABLE FIELDS
    candidate_json = {}
    candidate_json['user'] = {}
    candidate_json['user_profile'] = {
      'first_name' => candidate.data['firstName'],
      'last_name' => candidate.data['lastName']
    }
    candidate_json['registration_answer_hash'] = {}
    field_mappings.each do |fm|
      case fm.bullhorn_field_name
      when 'dateOfBirth', 'dateAvailable'
        # CONVERT TO DATE
        date = Time.at((candidate.data["#{fm.bullhorn_field_name}"].to_i.to_f) / 1000).to_date.to_s(:default)
        candidate_json['registration_answer_hash']["#{fm.registration_question_reference}"] = date unless date == '1970-01-01'
      when 'address1', 'address2', 'city', 'state', 'zip'
        candidate_json['registration_answer_hash']["#{fm.registration_question_reference}"] = candidate.data.address["#{fm.bullhorn_field_name}"]
      when 'countryID'
        # GET COUNTRY NAME
        logger.info "--- candidate.data.address['#{fm.bullhorn_field_name}'] = #{candidate.data.address["#{fm.bullhorn_field_name}"]}"
        candidate_json['registration_answer_hash']["#{fm.registration_question_reference}"] = get_country_name(candidate.data.address["#{fm.bullhorn_field_name}"])
      when 'category'
        # GET CATEGORY NAME
        categories = client.categories
        # logger.info "--- categories = #{categories.inspect}"
        category = categories.data.select{ |c| c.id == candidate.data.category.id }.first
        # logger.info "--- category = #{category.inspect}"
        candidate_json['registration_answer_hash']["#{fm.registration_question_reference}"] = category.name if category.present?
      when 'businessSectors'
        # GET BUSINESS SECTORS
        candidate_business_sectors = client.candidate(@user.bullhorn_uid, { association: 'businessSectors' })
        # logger.info "--- candidate_business_sectors = #{candidate_business_sectors.inspect}"
        candidate_json['registration_answer_hash']["#{fm.registration_question_reference}"] = candidate_business_sectors.data.first.name if candidate_business_sectors.data.first.present?
      else
        candidate_json['registration_answer_hash']["#{fm.registration_question_reference}"] = candidate.data["#{fm.bullhorn_field_name}"] unless candidate.data["#{fm.bullhorn_field_name}"] == 0.0
      end
    end
    
    logger.info "--- candidate_json = #{candidate_json.inspect}"
    if candidate_json['registration_answer_hash'].present?
      render json: { success: true, data: candidate_json }
    else
      render json: { success: false }
    end
  end

  def upload_cv
    if params[:user_profile][:upload_path].present?
      @user = BullhornUser.find_by(user_id: params[:user][:id])
      logger.info "--- params[:user_profile][:upload_path] = #{params[:user_profile][:upload_path]}"
      if Rails.env.development?
        key = Key.where(app_dataset_id: params[:dataset_id], app_name: params[:controller]).first
        cv_url = 'http://' + key.host + params[:user_profile][:upload_path]
      else
        # UPLOAD PATHS USE CLOUDFRONT URL
        cv_url = params[:user_profile][:upload_path]
      end
      logger.info "--- cv_url = #{cv_url}"

      require 'open-uri'
      require 'base64'
      cv = open(cv_url).read
      client = authenticate_client(params[:dataset_id])

      # UPOAD FILE
      base64_cv = Base64.encode64(cv)
      content_type = params[:user_profile][:upload_name].split('.').last
      # text, html, pdf, doc, docx, rtf, or odt.
      case content_type
      when 'doc'
        ct = 'application/msword'
      when 'docx'
        ct = 'application/vnd.openxmlformatsofficedocument.wordprocessingml.document'
      when 'txt'
        ct = 'text/plain'
      when 'html'
        ct = 'text/html'
      when 'pdf'
        ct = 'application/pdf'
      when 'rtf'
        ct = 'application/rtf'
      when 'odt'
        ct = 'application/vnd.oasis.opendocument.text'
      end
      file_attributes = {
        'externalID' => 'CV',
        'fileType' => 'SAMPLE',
        'name' => params[:user_profile][:upload_name],
        'fileContent' => base64_cv,
        'contentType' => ct,
        'type' => 'CV'
      }
      file_response = client.put_candidate_file(@user.bullhorn_uid, file_attributes.to_json)
      logger.info "--- file_response = #{file_response.inspect}"

      # PARSE FILE
      candidate_data = parse_cv(client, params, content_type, cv, ct)

      # ADD TO CANDIDATE DESCRIPTION
      if candidate_data.present? && candidate_data['description'].present?
        attributes = {}
        attributes['description'] = candidate_data['description']
        response = client.update_candidate(@user.bullhorn_uid, attributes.to_json)
      end

      if file_response['fileId'].present?
        render json: { success: true, user_id: @user.id }
      else
        render json: { success: false, status: "CV was not uploaded to Bullhorn" }
      end
    end
  end

  def job_application
    client = authenticate_client(@key.app_dataset_id)
    @user = BullhornUser.find_by(user_id: params[:user][:id])
    job_reference = params[:job][:job_reference]
    candidate = {
      'id' => @user.bullhorn_uid
    }
    job_order = {
      'id' => job_reference
    }

    attributes = {
      'candidate' => candidate,
      'isDeleted' => 'false',
      'jobOrder' => job_order,
      'status' => 'New Lead'
    }

    response = client.create_job_submission(attributes.to_json)
    logger.info "--- response = #{response.inspect}"
    if response.changedEntityId.present?
      render json: { success: true, job_submission_id: response.changedEntityId }
    else
      render json: { success: false, status: "JobSubmission was not created in Bullhorn." }
    end
  end

  def jobs
    client = authenticate_client(@key.app_dataset_id)
    jobs = client.job_orders
    logger.info "--- jobs = #{jobs.inspect}"
  end

  def new_search
    client = authenticate_client(params[:dataset_id])

    # create candidate object
    user_id = params[:search][:user_id] || params[:user][:user][:id]
    @user = BullhornUser.find_by(user_id: user_id)
    candidate = {
      'id' => @user.bullhorn_uid
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

    # create note
    response = client.create_note(attributes.to_json)
    logger.info "--- note_response = #{response.inspect}"

    # check response and create note entity
    if response.changedEntityId.present?
      logger.info "--- note_id = #{response.changedEntityId}"

      # assign note id to local variable
      note_id = response.changedEntityId

      # create note entity object
      create_note_entity(client, note_id, @user)
    else
      render json: { success: false, status: "Note was not created in Bullhorn." }
    end
  end


  private

    def authenticate_client(dataset_id)
      settings = BullhornAppSetting.find_by(dataset_id: dataset_id)
      return Bullhorn::Rest::Client.new(
        username: settings.bh_username,
        password: settings.bh_password,
        client_id: settings.bh_client_id,
        client_secret: settings.bh_client_secret
      )
    end

    def update_authorised_setting(bullhorn_setting)
      if bullhorn_setting.auth_settings_changed
        if bullhorn_setting.auth_settings_filled
          begin
            client = authenticate_client(params[:bullhorn_app_setting][:dataset_id])
            candidates = client.candidates(fields: 'id', sort: 'id')
            bullhorn_setting.authorised = candidates.data.size > 0
            bullhorn_setting.save
          rescue
            bullhorn_setting.authorised = false
            bullhorn_setting.save
          end
        end
      end
    end

    def post_user_to_bullhorn_2(user, client, params)
      settings = BullhornAppSetting.find_by(dataset_id: params[:user][:dataset_id])
      field_mappings = settings.bullhorn_field_mappings.user

      attributes = {
        'firstName' => user.user_profile['first_name'],
        'lastName' => user.user_profile['last_name'],
        'name' => "#{user.user_profile['first_name']} #{user.user_profile['last_name']}",
        'status' => settings.status_text.present? ? settings.status_text : 'New Lead',
        'email' => user.email,
        'source' => settings.source_text.present? ? settings.source_text : 'Company Website'
      }

      if user.linkedin_profile.present?
        attributes['description'] = linkedin_description(user)
      end
      attributes["#{settings.linkedin_bullhorn_field}"] = user.user_profile['li_publicProfileUrl'] if user.user_profile['li_publicProfileUrl'].present?

      # PREPARE ADDRESS
      attributes['address'] = {}

      # MAP FIELDS TO FIELDS
      field_mappings.each do |fm|
        # logger.info "--- fm.bullhorn_field_name = #{fm.bullhorn_field_name}"
        # TIMESTAMPS
        answer = user.registration_answers[fm.registration_question_reference] rescue nil
        # logger.info "--- raw answer = #{answer}"

        case fm.bullhorn_field_name
        when 'dateOfBirth', 'dateAvailable' # AND OTHERS
          # TIMESTAMP NEEDED IN MILLISECONDS
          answer = (Date.parse(answer).to_time.to_i.to_f * 1000.0).to_i rescue nil
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
        when 'category'
          # FIND category ID
          categories = client.categories
          # logger.info "--- categories = #{categories.inspect}"
          category = categories.data.select{ |c| c.name == answer }.first
          # logger.info "--- category = #{category.inspect}"
          if category.present?
            attributes['category'] = {}
            attributes['category']['id'] = category.id
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
        if settings.always_create == true
          logger.info '--- ALWAYS CREATE OPTION IS SELECTED'
          bullhorn_id = nil
        else
          email_query = "email:\"#{URI::encode(user.email)}\""
          existing_candidates = client.search_candidates(query: email_query, sort: 'id')
          logger.info "--- existing_candidates = #{existing_candidates.data.map{ |c| c.id }.inspect}"
          # isDeleted BOOLEAN CAN'T BE QUERIED SO NEED TO EXTRACT UNDELETED CANDIDATES
          active_candidates = existing_candidates.data.select{ |c| c.isDeleted == false }
          logger.info "--- active_candidates = #{active_candidates.inspect}"
          if active_candidates.size > 0
            logger.info '--- CANDIDATE RECORD FOUND'
            last_candidate = active_candidates.last
            bullhorn_id = last_candidate.id
            @user.update(bullhorn_uid: bullhorn_id)
          else
            logger.info '--- CANDIDATE RECORD NOT FOUND'
            bullhorn_id = nil
          end
        end
      end

      # CREATE/UPDATE CANDIDATE
      if bullhorn_id.present?
        logger.info "--- UPDATING #{bullhorn_id}, attributes.to_json = #{attributes.to_json.inspect}"
        response = client.update_candidate(bullhorn_id, attributes.to_json)
        logger.info "--- response = #{response.inspect}"
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
        logger.info "--- CREATING CANDIDATE, attributes.to_json =  #{attributes.to_json.inspect}"
        response = client.create_candidate(attributes.to_json)
        logger.info "--- response = #{response.inspect}"
        @user.update(bullhorn_uid: response['changedEntityId'])
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

      # 'businessSectors'      
      if bullhorn_id.present?
        # CREATE NEW API CALL TO ADD BUSINESS SECTOR TO CANDIDATE
        # FIND businessSector ID
        business_sectors = client.business_sectors
        # logger.info "--- business_sectors = #{business_sectors.inspect}"
        answer = user.registration_answers['businessSectors']
        bs_mapping = field_mappings.find_by(bullhorn_field_name: 'businessSectors')
        if bs_mapping.present?
          business_sector = business_sectors.data.select{ |bs| bs.name == user.registration_answers[bs_mapping.registration_question_reference] }.first
          # logger.info "--- business_sector = #{business_sector.inspect}"
          if business_sector.present?
            bs_response = client.create_candidate({}.to_json, { candidate_id: bullhorn_id, association: 'businessSectors', association_ids: "#{business_sector.id}" })
            logger.info "--- bs_response = #{bs_response.inspect}"
          end
        end
      end
      
    end

    def post_user_to_bullhorn(user, params)
      settings = AppSetting.find_by(dataset_id: params[:user][:dataset_id]).settings
      logger.info "--- settings = #{settings.inspect}"
      client = Bullhorn::Rest::Client.new(
        username: settings['username'],
        password: settings['password'],
        client_id: settings['client_id'],
        client_secret: settings['client_secret']
      )
      logger.info "--- client = #{client.inspect}"
      attributes = {
        'firstName' => user.user_profile['first_name'],
        'lastName' => user.user_profile['last_name'],
        'name' => "#{user.user_profile['first_name']} #{user.user_profile['last_name']}",
        'status' => 'New Lead',
        'email' => user.email,
        'source' => settings['bullhorn_source'].present? ? settings['bullhorn_source'] : 'Company Website'
      }

      if user.linkedin_profile.present?
        attributes['description'] = linkedin_description(user)
      end

      attributes['companyName'] = user.registration_answers[settings['companyName']] if user.registration_answers[settings['companyName']].present?
      attributes['desiredLocations'] = user.registration_answers[settings['desiredLocations']] if user.registration_answers[settings['desiredLocations']].present?
      attributes['educationDegree'] = user.registration_answers[settings['educationDegree']] if user.registration_answers[settings['educationDegree']].present?
      attributes['employmentPreference'] = user.registration_answers[settings['employmentPreference']] if user.registration_answers[settings['employmentPreference']].present?
      attributes['mobile'] = user.registration_answers[settings['mobile']] if user.registration_answers[settings['mobile']].present?
      attributes['namePrefix'] = user.registration_answers[settings['namePrefix']] if user.registration_answers[settings['namePrefix']].present?
      attributes['occupation'] = user.registration_answers[settings['occupation']] if user.registration_answers[settings['occupation']].present?
      attributes['phone'] = user.registration_answers[settings['phone']] if user.registration_answers[settings['phone']].present?
      attributes['phone2'] = user.registration_answers[settings['phone2']] if user.registration_answers[settings['phone2']].present?
      attributes['salary'] = user.registration_answers[settings['salary']].to_i if user.registration_answers[settings['salary']].present?
      attributes['address'] = {}
      attributes['address']['address1'] = user.registration_answers[settings['address_address1']] if user.registration_answers[settings['address_address1']].present?
      attributes['address']['address2'] = user.registration_answers[settings['address_address2']] if user.registration_answers[settings['address_address2']].present?
      attributes['address']['city'] = user.registration_answers[settings['address_city']] if user.registration_answers[settings['address_city']].present?
      attributes['address']['zip'] = user.registration_answers[settings['address_zip']] if user.registration_answers[settings['address_zip']].present?
      attributes['address']['countryID'] = get_country_id(user.registration_answers[settings['address_country']]) if user.registration_answers[settings['address_country']].present?
      # GET BULLHORN ID
      if user.bullhorn_uid.present?
        bullhorn_id = user.bullhorn_uid
      else
        # email_query = "email:\"#{URI::encode(user.email)}\""
        # existing_candidate = client.search_candidates(query: email_query, sort: 'id')
        # logger.info "--- existing_candidate = #{existing_candidate.data.map{ |c| c.id }.inspect}"
        # if existing_candidate.record_count.to_i > 0
        #   logger.info '--- CANDIDATE RECORD FOUND'
        #   last_candidate = existing_candidate.data.last
        #   bullhorn_id = last_candidate.id
        #   @user.update(bullhorn_uid: bullhorn_id)
        # else
        #   logger.info '--- CANDIDATE RECORD NOT FOUND'
        #   bullhorn_id = nil
        # end
        bullhorn_id = nil
      end
      # CREATE CANDIDATE
      if bullhorn_id.present?
        logger.info "--- UPDATING #{bullhorn_id}: #{attributes.inspect} ..."
        response = client.update_candidate(bullhorn_id, attributes.to_json)
        logger.info "--- response = #{response.inspect}"
      else
        logger.info "--- CREATING CANDIDATE: #{attributes.inspect} ..."
        response = client.create_candidate(attributes.to_json)
        @user.update(bullhorn_uid: response['changedEntityId'])
      end
    end

    def upload_cv_to_bullhorn_2(user, client, params)
      @user = user
      logger.info "--- params[:user_profile][:upload_path] = #{params[:user_profile][:upload_path]}"
      if params[:user_profile][:upload_path].present?
        if Rails.env.development?
          key = Key.where(app_dataset_id: params[:dataset_id], app_name: params[:controller]).first
          cv_url = 'http://' + key.host + params[:user_profile][:upload_path]
        else
          # UPLOAD PATHS USE CLOUDFRONT URL
          cv_url = params[:user_profile][:upload_path]
        end
        logger.info "--- cv_url = #{cv_url}"

        # @file_attributes COME FROM THIS
        extract_file_attributes(cv_url, params)

        file_response = client.put_candidate_file(@user.bullhorn_uid, @file_attributes.to_json)
        logger.info "--- file_response = #{file_response.inspect}"

        # PARSE FILE
        candidate_data = parse_cv(client, params, @content_type, @cv, @ct)

        # ADD TO CANDIDATE DESCRIPTION
        if candidate_data.present? && candidate_data['description'].present?
          attributes = {}
          attributes['description'] = candidate_data['description']
          response = client.update_candidate(@user.bullhorn_uid, attributes.to_json)
        end
      end
    end

    def upload_cv_to_bullhorn(user, params)
      @user = user
      logger.info "--- params[:user_profile][:upload_path] = #{params[:user_profile][:upload_path]}"
      if params[:user_profile][:upload_path].present?
        key = Key.where(app_dataset_id: params[:dataset_id], app_name: params[:controller]).first
        # cv_url = 'http://' + key.host + params[:user_profile][:upload_path]
        # UPLOAD PATHS USE CLOUDFRONT URL
        cv_url = params[:user_profile][:upload_path]
        logger.info "--- cv_url = #{cv_url}"
        settings = AppSetting.find_by(dataset_id: params[:dataset_id]).settings
        client = Bullhorn::Rest::Client.new(
          username: settings['username'],
          password: settings['password'],
          client_id: settings['client_id'],
          client_secret: settings['client_secret']
        )

        extract_file_attributes(cv_url, params)

        file_response = client.put_candidate_file(@user.bullhorn_uid, @file_attributes.to_json)
        logger.info "--- file_response = #{file_response.inspect}"

        # PARSE FILE
        candidate_data = parse_cv(client, params, @content_type, @cv, @ct)

        # ADD TO CANDIDATE DESCRIPTION
        if candidate_data.present? && candidate_data['description'].present?
          attributes = {}
          attributes['description'] = candidate_data['description']
          response = client.update_candidate(@user.bullhorn_uid, attributes.to_json)
        end
      end
    end

    def extract_file_attributes(cv_url, params)
      require 'open-uri'
      require 'base64'
      settings = BullhornAppSetting.find_by(dataset_id: params[:user][:dataset_id])
      @cv = open(cv_url).read
      # UPOAD FILE
      base64_cv = Base64.encode64(@cv)
      @content_type = params[:user_profile][:upload_name].split('.').last
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
        'externalID' => 'CV',
        'fileType' => 'SAMPLE',
        'name' => params[:user_profile][:upload_name],
        'fileContent' => base64_cv,
        'contentType' => @ct,
        'type' => settings.cv_type_text.present? ? settings.cv_type_text : 'CV'
      }
    end

    def parse_cv(client, params, content_type, cv, ct)
      # TRY UP TO 10 TIMES AS PER SUPPORT:
      # http://supportforums.bullhorn.com/viewtopic.php?t=15011
      10.times do
        require 'tempfile'
        file = Tempfile.new(params[:user_profile][:upload_name])
        file.binmode
        file.write(cv)
        file.rewind
        parse_attributes = {
          'file' => file.path,
          'ct' => ct
        }
        candidate_response = client.parse_to_candidate_as_file(content_type.upcase, 'html', parse_attributes)
        logger.info "--- candidate_response = #{candidate_response.inspect}"
        if candidate_response['candidate'].present?
          # STOP LOOP AND RETURN
          return candidate_response['candidate']
        end
      end
      false # return false if this has not returned a candidate_response after 10 tries
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

      # LINKEDIN DONT PROVIDE EDUCATION OR SKILLS ANYMORE
      # if user.linkedin_profile['education_history'].size > 0
      #   string = string + '<h3>EDUCATION</h3>'
      #   user.linkedin_profile['education_history'].each do |education|
      #     string = string + '<p>'
      #     string = string + education['school_name'] + '<br />' unless education['school_name'].blank?

      #     field_of_study = education['field_of_study'].present? ? 'Field of Study: ' + education['field_of_study'] + '<br />' : "Field of Study: N/A<br />"
      #     start_date = education['start_date'].present? ? 'Start Date: ' + education['start_date'] + '<br />' : "Start Date: N/A<br />"
      #     end_date = education['end_date'].present? ? 'End Date: ' + education['end_date'] + '<br />' : "End Date: N/A<br />"
      #     degree = education['degree'].present? ? 'Degree: ' + education['degree'] + '<br />' : "Degree: N/A<br />"
      #     activities = education['activities'].present? ? 'Activities: ' + education['activities'] + '<br />' : "Activities: N/A<br />"
      #     notes = education['notes'].present? ? 'Notes: ' + education['notes'] + '<br />' : "Notes: N/A<br />"

      #     string = string + field_of_study + start_date + end_date + degree + activities + notes + '</p>'
      #   end
      # end

      # if user.linkedin_profile['skills'].size > 0
      #   string = string + '<h3>SKILLS</h3>'
      #   user.linkedin_profile['skills'].each do |skill|
      #     string = string + '<p>'
      #     skill_name = skill['skill'].present? ? 'Skill: ' + skill['skill'] + '<br />' : "Skill: N/A<br />"
      #     proficiency = skill['proficiency'].present? ? 'Proficiency: ' + skill['proficiency'] + '<br />' : "Proficiency: N/A<br />"
      #     years = skill['years'].present? ? 'Years: ' + skill['years'] + '<br />' : "Years: N/A<br />"

      #     string = string + skill_name + proficiency + years + '</p>'
      #   end
      # end
      return string
    end

    def get_country_name(country_id)
      array_item = bullhorn_country_array.select{ |name, id| id == country_id.to_s }
      if array_item.present?
        array_item.first[0]
      end
    end

    def get_country_id(country_name)
      array_item = bullhorn_country_array.select{ |name, id| name == country_name }
      if array_item.present?
        array_item.first[1]
      end
    end

    def bullhorn_country_array
      return [
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
        ["Cayman Islands","2379"]
      ]
    end

    def create_note_entity(client, note_id, user)
      # create note entity attributes object
      attributes = {
        'note' => { 'id' => note_id },
        'targetEntityID' => user.bullhorn_uid,
        'targetEntityName' => 'User'
      }

      # create note entity
      response = client.create_note_entity(attributes.to_json)
      logger.info "--- note_entity_response = #{response.inspect}"

      if response.changedEntityId.present?
        render json: { success: true,  note_submission_id: note_id, note_entity_submission_id: response.changedEntityId }
      else
        render json: { success: false, status: "Note Entity was not created in Bullhorn." }
      end
    end


end
