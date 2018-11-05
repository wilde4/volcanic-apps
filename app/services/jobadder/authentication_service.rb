require 'oauth2'
class Jobadder::AuthenticationService < BaseService

  class << self

    def client(jobadder_setting)
      client = OAuth2::Client.new(
          jobadder_setting.ja_client_id,
          jobadder_setting.ja_client_secret,
          {authorize_url: JobadderHelper.authentication_urls[:authorize],
           token_url: JobadderHelper.authentication_urls[:token], }
      )
      return client
    rescue => e
      Rails.logger.info "--- jobadder client exception ----- : #{e.message}"
    end

    def authorize_url(dataset_id, ja_setting)
      client = client(ja_setting)
      auth_url = client.auth_code.authorize_url({redirect_uri: JobadderHelper.callback_url, access_type: 'offline', scope: 'read write offline_access', state: dataset_id})
      @auth_url = URI.decode(auth_url)
    rescue => e
      Rails.logger.info "--- jobadder auth_url exception ----- : #{e.message}"
    end

    def get_access_token(authorization_code, ja_setting)
      client = client(ja_setting)
      @token = client.auth_code.get_token(authorization_code, :redirect_uri => JobadderHelper.callback_url)
    rescue => e
      Rails.logger.info "--- jobadder get_access_token exception ----- : #{e.message}"
    end

    def refresh_token(jobadder_setting)
      client = client(jobadder_setting)
      @response = OAuth2::AccessToken.from_hash(client, :refresh_token => jobadder_setting.refresh_token).refresh!
      return @response
    rescue => e
      Rails.logger.info "--- jobadder refresh_token exception ----- : #{e.message}"
    end

    private

  end

end