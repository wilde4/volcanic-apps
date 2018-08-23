class Jobadder::ClientService < BaseService
  attr_accessor :client, :key, :authorize_url, :original_url

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
    unless @ja_setting.auth_settings_filled
      @client = nil
      return
    end

    @client = Jobadder::AuthenticationService.client(@ja_setting)
    @authorize_url = Jobadder::AuthenticationService.authorize_url(@callback_url, @client)

    if @ja_setting.access_token_expires_at.present?
      if DateTime.current > @ja_setting.access_token_expires_at
        @response = Jobadder::AuthenticationService.refresh_token(@ja_setting)
        @ja_setting.update({access_token: @response.token,
                            access_token_expires_at: @response.expires_at})

      end
    end

  end

  def post_job_application(dataset_id, params)

    @ja_setting = JobadderAppSetting.find_by(dataset_id: dataset_id)

    @response = HTTParty.post(BASE_BASE_URL[:job_adder] + ENDPOINT[:candidate],
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

    @registration_answer = @ja_user.registration_answer_hash
    @custom_fields_answers = Hash.new

    if @candidate_custom_fields.present? && @registration_answer.present?
      @candidate_custom_fields[:items].each do |i|
        @registration_answer.each do |reg_k, reg_v|
          if reg_k.eql? i[:name]
            @custom_fields_answers["fieldId"] = i[:fieldId]
            @custom_fields_answers["value"] = reg_v
          end
        end

      end

    end


    # Add candidate
    add_candidate_response = HTTParty.post(BASE_URL[:job_adder] + ENDPOINT[:candidate],
                             :headers => {"Authorization" => "Bearer " + @ja_setting.access_token,
                                          "Content-type" => "application/json"},
                             :body => {:firstName => @ja_user.user_profile['first_name'],
                                       :lastName => @ja_user.user_profile['last_name'],
                                       :email => @ja_user[:email]
                             }.to_json)
    puts add_candidate_response

    # Get Attachments for user
    get_volcanic_user_response = HTTParty.get(BASE_URL[:volcanic] + ENDPOINT[:user] + user_id + ".json?api_key=#{key}",
                                              headers: { 'User-Agent' => 'VolcanicJobadderApp'})

    if get_volcanic_user_response[:user_cvs].present?

    end

    if get_volcanic_user_response[:user_covering_letters].present?

    end

  end

  def update_candidate(dataset_id)

    @ja_setting = JobadderAppSetting.find_by(dataset_id: dataset_id)

    response = HTTParty.post(BASE_URL[:job_adder] + ENDPOINTS[:candidate],
                             :headers => {"Authorization" => "Bearer " + @ja_setting.access_token,
                                          "Content-type" => "application/json"})
    puts response

  end

  def get_candidate_custom_fields

    response =  HTTParty.get(BASE_URL[:job_adder] + ENDPOINT[:candidate_custom_fields],
                             headers: { 'User-Agent' => 'VolcanicJobadderApp'})
    response.code == 200 ? response.body : {}

  end

  # GETS VOLCANIC CANDIDATES FIELDS VIA API
  def volcanic_candidate_fields
    url = "#{@key.protocol}#{@key.host}/api/v1/user_groups.json"
    response = HTTParty.get( url,  headers: { 'User-Agent' => 'VolcanicJobadderApp' } )

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

end