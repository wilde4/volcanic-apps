require 'oauth2'
class Jobadder::AuthenticationService < BaseService

  class << self

    def client(jobadder_setting)
      client = OAuth2::Client.new(
        ENV['JOBADDER_CLIENT_ID'],
        ENV['JOBADDER_CLIENT_SECRET'],
        { authorize_url: JobadderHelper.authentication_urls[:authorize],
          token_url: JobadderHelper.authentication_urls[:token], }
      )
      return client
    rescue => e
      Honeybadger.notify(e)
      create_log(jobadder_setting, nil, 'auth_init_client', nil, nil, e.message, true, true)
    end

    def authorize_url(dataset_id, ja_setting)
      client = client(ja_setting)
      auth_url = client.auth_code.authorize_url({ redirect_uri: JobadderHelper.callback_url, access_type: 'offline', scope: 'read write offline_access', state: dataset_id })
      @auth_url = URI.decode(auth_url)
    rescue => e
      Honeybadger.notify(e)
      create_log(ja_setting, nil, 'auth_authorize_url', nil, nil, e.message, true, true)
    end

    def get_access_token(authorization_code, ja_setting)
      client = client(ja_setting)
      @token = client.auth_code.get_token(authorization_code, :redirect_uri => JobadderHelper.callback_url)
    rescue => e
      Honeybadger.notify(e)
      create_log(ja_setting, nil, 'auth_get_access_token', nil, nil, e.message, true, true)
    end

    def refresh_token(jobadder_setting)
      client = client(jobadder_setting)
      @response = OAuth2::AccessToken.from_hash(client, :refresh_token => jobadder_setting.refresh_token).refresh!
      return @response
    rescue => e
      Honeybadger.notify(e)
      create_log(jobadder_setting, nil, 'auth_refresh_token', nil, nil, e.message, true, true)
    end

    private

  end

end
