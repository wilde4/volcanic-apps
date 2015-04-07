require 'uri'

class YuTalent::AuthenticationService < BaseService

  class << self


    CREDENTIALS = {
      auth_url: 'https://yutalent.co.uk/c/oauth/authorize',
      access_token_url: 'https://yutalent.co.uk/c/oauth/access_token'
    }

    def client
      begin
        client = OAuth2::Client.new(
          ENV["YU_TALENT_CLIENT_ID"].try(:downcase),
          ENV["YU_TALENT_CLIENT_SECRET"],
          { authorize_url: CREDENTIALS[:auth_url], token_url: CREDENTIALS[:access_token_url] }
        )
        return client
      rescue => e
        puts e.inspect
      end
    end


    def auth_url(app_id, host)
      begin
        @host = format_url(host)
        callback_url = "#{@host}/admin/apps/#{app_id}/callback"
        auth_url = client.auth_code.authorize_url({ redirect_uri: callback_url, access_type: 'offline' })
        @auth_url = URI.decode(auth_url)
        return @auth_url
      rescue => e
        puts e.inspect
      end
    end


    def format_url(url)
      url = URI.parse(url)
      return url if url.scheme
      return "http://#{url}:3000" if Rails.env.development?
      "http://#{url}"
    end


    def get_access_token(dataset_id)
      begin
        @authorization_code = YuTalentAppSetting.find_by(dataset_id: dataset_id).try(:authorization_code)
        @host = Key.find_by(app_dataset_id: dataset_id).try(:host)
        @callback_url = format_url(@host)
        @token = client.auth_code.get_token(@authorization_code, redirect_uri: @callback_url)
        return @token
      rescue => e
        puts e.inspect
      end
    end


  end

end
