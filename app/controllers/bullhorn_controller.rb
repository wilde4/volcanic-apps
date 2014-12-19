class BullhornController < ApplicationController
  require 'bullhorn/rest'
  protect_from_forgery with: :null_session
  respond_to :json

  # Controller requires cross-domain POST XHRs
  after_filter :setup_access_control_origin

  def index
    # SOMETHING
  end

  def save_user
    @user = BullhornUser.find_by(user_id: params[:user][:id])
    if @user.present?
      if @user.update(
        email: params[:user][:email],
        user_data: params[:user],
        user_profile: params[:user_profile],
        registration_answers: params[:registration_answer_hash]
      )
        logger.info "--- @user.registration_answers = #{@user.registration_answers.inspect}"
        post_user_to_bullhorn(@user, params)
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
      @user.registration_answers = params[:registration_answer_hash]

      if @user.save
        post_user_to_bullhorn(@user, params)
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
      cv_url = 'http://' + key.host + params[:user_profile][:upload_path]
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

      if file_response['fileId'].present?
        render json: { success: true, user_id: @user.id }
      else
        render json: { success: false, status: "CV was not uploaded to Bullhorn" }
      end

      # # ADD TO CANDIDATE DESCRIPTION
      # require 'tempfile'
      # file = Tempfile.new(params[:user_profile][:upload_name])
      # file.binmode
      # file.write(cv)
      # file.rewind
      # parse_attributes = {
      #   'file' => file
      # }
      # candidate_response = client.parse_to_candidate_as_file(content_type.upcase, 'html', parse_attributes)
      # # MULTIPART FORM ISSUES HERE
      # logger.info "--- candidate_response = #{candidate_response.inspect}"
      # render json: { success: true, user_id: @user.id }
    end
  end

  private

  def post_user_to_bullhorn(user, params)
    settings = AppSetting.find_by(dataset_id: params[:user][:dataset_id]).settings
    client = Bullhorn::Rest::Client.new(
      username: settings['username'],
      password: settings['password'],
      client_id: settings['client_id'],
      client_secret: settings['client_secret']
    )
    attributes = {
      'firstName' => user.user_profile['first_name'],
      'lastName' => user.user_profile['last_name'],
      'name' => "#{user.user_profile['first_name']} #{user.user_profile['last_name']}",
      'status' => 'New Lead',
      'email' => user.email,
      'source' => 'Company Website'
    }
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
      email_query = "email:\"#{URI::encode(user.email)}\""
      existing_candidate = client.search_candidates(query: email_query, sort: 'id')
      logger.info "--- existing_candidate = #{existing_candidate.data.map{ |c| c.id }.inspect}"
      if existing_candidate.record_count.to_i > 0
        logger.info '--- CANDIDATE RECORD FOUND'
        last_candidate = existing_candidate.data.last
        bullhorn_id = last_candidate.id
        @user.update(bullhorn_uid: bullhorn_id)
      else
        logger.info '--- CANDIDATE RECORD NOT FOUND'
        bullhorn_id = nil
      end
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
end