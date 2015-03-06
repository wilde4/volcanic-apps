require 'uri'

class YuTalent::AuthenticationService < BaseService


  CREDENTIALS = {
    auth_url: 'https://yutalent.co.uk/c/oauth/authorize',
    access_token_url: 'https://yutalent.co.uk/c/oauth/access_token'
  }


  def self.auth_url(dataset_id, app_id, host)
    callback_url = "http://#{host}:3000/admin/apps/#{app_id}/callback"
    app_settings = AppSetting.find_by(dataset_id: dataset_id).try(:settings)
    begin
      client = OAuth2::Client.new(
      '5454-9715A4F54-3984B43EE-8B6AF6793-24FC3',
      'F6SIROFJVYECTZUNEQNDKK4M47QQURK1PEBIWGSH',
        { authorize_url: CREDENTIALS[:auth_url], token_url: CREDENTIALS[:access_token_url] }
      )
      # client = OAuth2::Client.new(
      #   app_settings[:client_id],
      #   app_settings[:client_secret],
      #   { authorize_url: CREDENTIALS[:auth_url], token_url: CREDENTIALS[:access_token_url] }
      # )
      auth_url = client.auth_code.authorize_url({ redirect_uri: callback_url, access_type: 'offline' })
      @auth_url = URI.decode(auth_url)
      return @auth_url
    rescue => e
      puts e.inspect
    end
  end

end
