class Jobadder::ClientService < BaseService
  attr_accessor :client, :key, :authorize_url, :original_url

  URL = {
      job_adder: 'https://api.jobadder.com/v2',
      volcanic: 'https://www.volcanic.co.uk/api/v1'
  }
  ENDPOINT = {
      job_applications: '/jobboards/{boardId}/ads/{adId}/applications',
      candidates: '/candidates',
      users: '/users'
  }

  def initialize(ja_setting, callback_url)
    @ja_setting = ja_setting
    @callback_url = callback_url
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

    @response = HTTParty.post(URL[:job_adder] + ENDPOINT[:candidate],
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

    # Add candidate
    add_candidate_response = HTTParty.post(URL[:job_adder] + ENDPOINT[:candidate],
                             :headers => {"Authorization" => "Bearer " + @ja_setting.access_token,jobadder_users
                                          "Content-type" => "application/json"},
                             :body => {:firstName => @ja_user.user_profile['first_name'],
                                       :lastName => @ja_user.user_profile['last_name'],
                                       :email => @ja_user[:email]
                             }.to_json)
    puts add_candidate_response

    # Get Attachments for user
    get_volcanic_user_response = HTTParty.get(URL[:volcanic] + ENDPOINT[:user] + user_id + ".json?api_key=#{key}",
                                              headers: { 'User-Agent' => 'VolcanicJobadderApp'})

    if get_volcanic_user_response[:user_cvs].present?

    end

    if get_volcanic_user_response[:user_covering_letters].present?

    end

  end

  def update_candidate(dataset_id)

    @ja_setting = JobadderAppSetting.find_by(dataset_id: dataset_id)

    response = HTTParty.post(URL[:job_adder] + ENDPOINTS[:candidate],
                             :headers => {"Authorization" => "Bearer " + @ja_setting.access_token,
                                          "Content-type" => "application/json"})
    puts response

  end


end