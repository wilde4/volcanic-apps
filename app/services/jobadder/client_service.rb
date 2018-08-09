class Jobadder::ClientService < BaseService
  attr_accessor :client, :key, :authorize_url
  attr_accessor

  def initialize(ja_setting, callback_url)
    @ja_setting = ja_setting
    @callback_url = callback_url
    setup_client

  end

  def get_jobs

    response = HTTParty.get('https://api.jobadder.com/v2/jobs',
                            :headers => {"Authorization" => "Bearer "+ @jobadder_setting.ja_client_id,
                                          "Content-type" => "application/json"})
    puts response

  end
  def setup_client
    unless @ja_setting.auth_settings_filled
      @client = nil
      return
    end

    @client = Jobadder::AuthenticationService.client(@ja_setting)
    @authorize_url = Jobadder::AuthenticationService.authorize_url('http://127.0.0.1:3001/jobadder/callback', @client)



  end

  def authenticate_client
    @authorize_url = Jobadder::AuthenticationService.authorize_url(@callback_url, @client)

  end
end