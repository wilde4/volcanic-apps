class BullhornController < ApplicationController
  require 'bullhorn/rest'
  protect_from_forgery with: :null_session
  respond_to :json

  # Controller requires cross-domain POST XHRs
  after_filter :setup_access_control_origin
  before_action :set_key, only: [:index, :job_application]

  def index
    # SOMETHING
    settings = AppSetting.find_by(dataset_id: @key.app_dataset_id).settings
    logger.info "--- settings = #{settings.inspect}"
    client = Bullhorn::Rest::Client.new(
      username: settings['username'],
      password: settings['password'],
      client_id: settings['client_id'],
      client_secret: settings['client_secret']
    )
    @jobs = client.query_job_orders(where: "id IS NOT NULL")
    @jobs.data.each do |job|
      logger.info "--- JOB DETAILS:"
      logger.info "--- job.title = #{job.title}"
      logger.info "--- job.keys = #{job.keys}"
    end
    logger.info "--- jobs = #{@jobs.data.size}"
  end

  def save_user
    @user = BullhornUser.find_by(user_id: params[:user][:id])
    if @user.present?
      if @user.update(
        email: params[:user][:email],
        user_data: params[:user],
        user_profile: params[:user_profile],
        linkedin_profile: params[:linkedin_profile],
        registration_answers: params[:registration_answer_hash]
      )
        logger.info "--- params = #{params.inspect}"
        post_user_to_bullhorn(@user, params)
        upload_cv_to_bullhorn(@user, params)
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
        post_user_to_bullhorn(@user, params)
        upload_cv_to_bullhorn(@user, params)
        render json: { success: true, user_id: @user.id }
      else
        render json: { success: false, status: "Error: #{@user.errors.full_messages.join(', ')}" }
      end
    end
  end

  def upload_cv
    if params[:user_profile][:upload_path].present?
      @user = BullhornUser.find_by(user_id: params[:user][:id])
      logger.info "--- params[:user_profile][:upload_path] = #{params[:user_profile][:upload_path]}"
      key = Key.where(app_dataset_id: params[:dataset_id], app_name: params[:controller]).first
      # cv_url = 'http://' + key.host + params[:user_profile][:upload_path]
      # UPLOAD PATHS USE CLOUDFRONT URL
      cv_url = params[:user_profile][:upload_path]
      logger.info "--- cv_url = #{cv_url}"
      require 'open-uri'
      require 'base64'
      cv = open(cv_url).read
      settings = AppSetting.find_by(dataset_id: params[:dataset_id]).settings
      client = Bullhorn::Rest::Client.new(
        username: settings['username'],
        password: settings['password'],
        client_id: settings['client_id'],
        client_secret: settings['client_secret']
      )

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
    settings = AppSetting.find_by(dataset_id: @key.app_dataset_id).settings
    client = Bullhorn::Rest::Client.new(
      username: settings['username'],
      password: settings['password'],
      client_id: settings['client_id'],
      client_secret: settings['client_secret']
    )
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
    settings = AppSetting.find_by(dataset_id: @key.app_dataset_id).settings
    client = Bullhorn::Rest::Client.new(
      username: settings['username'],
      password: settings['password'],
      client_id: settings['client_id'],
      client_secret: settings['client_secret']
    )
    jobs = client.job_orders
    logger.info "--- jobs = #{jobs.inspect}"
  end


  def new_search
    # find app settings
    settings = AppSetting.find_by(dataset_id: params[:dataset_id]).settings

    # instantiate app client
    client = Bullhorn::Rest::Client.new(
      username: settings['username'],
      password: settings['password'],
      client_id: settings['client_id'],
      client_secret: settings['client_secret']
    )

    # create candidate object
    user_id = params[:search][:user_id] || params[:user][:user][:id]
    @user = BullhornUser.find_by(user_id: user_id)
    candidate = {
      'id' => @user.bullhorn_uid
    }

    # contruct comment based on received search params
    search = params[:search]
    job_type = params[:job_type].present? ? params[:job_type] : "N/A"
    disciplines = params[:disciplines].size > 0 ? params[:disciplines].map{|d| d[:name] if d[:name].present?}.join(", ") : "N/A"
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
        'source' => 'Company Website'
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
        'type' => 'CV'
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
    end

    def linkedin_description(user)
      string = '<h1>Curriculum Vitae</h1>' +
        "<h2>#{user.user_profile['first_name']} #{user.user_profile['last_name']}</h2>"

      if user.linkedin_profile['education_history'].size > 0
        string = string + '<h3>EDUCATION</h3>'
        user.linkedin_profile['education_history'].each do |education|
          string = string + '<p>'
          string = string + education['school_name'] + '<br />' unless education['school_name'].blank?

          field_of_study = education['field_of_study'].present? ? 'Field of Study: ' + education['field_of_study'] + '<br />' : "Field of Study: N/A<br />"
          start_date = education['start_date'].present? ? 'Start Date: ' + education['start_date'] + '<br />' : "Start Date: N/A<br />"
          end_date = education['end_date'].present? ? 'End Date: ' + education['end_date'] + '<br />' : "End Date: N/A<br />"
          degree = education['degree'].present? ? 'Degree: ' + education['degree'] + '<br />' : "Degree: N/A<br />"
          activities = education['activities'].present? ? 'Activities: ' + education['activities'] + '<br />' : "Activities: N/A<br />"
          notes = education['notes'].present? ? 'Notes: ' + education['notes'] + '<br />' : "Notes: N/A<br />"

          string = string + field_of_study + start_date + end_date + degree + activities + notes + '</p>'
        end
      end

      if user.linkedin_profile['positions'].size > 0
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

      if user.linkedin_profile['skills'].size > 0
        string = string + '<h3>SKILLS</h3>'
        user.linkedin_profile['skills'].each do |skill|
          string = string + '<p>'
          skill_name = skill['skill'].present? ? 'Skill: ' + skill['skill'] + '<br />' : "Skill: N/A<br />"
          proficiency = skill['proficiency'].present? ? 'Proficiency: ' + skill['proficiency'] + '<br />' : "Proficiency: N/A<br />"
          years = skill['years'].present? ? 'Years: ' + skill['years'] + '<br />' : "Years: N/A<br />"

          string = string + skill_name + proficiency + years + '</p>'
        end
      end
      return string
    end

    def get_country_id(country_name)
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
        ["Cayman Islands","2379"]
      ]
      array_item = bullhorn_country_array.select{ |name, id| name == country_name }
      if array_item.present?
        array_item.first[1]
      end
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
