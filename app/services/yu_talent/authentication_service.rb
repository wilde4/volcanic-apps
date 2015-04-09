require 'uri'

class YuTalent::AuthenticationService < BaseService

  class << self


    CREDENTIALS = {
      auth_url: 'https://yutalent.co.uk/c/oauth/authorize',
      access_token_url: 'https://yutalent.co.uk/c/oauth/access_token'
    }

    def client
      begin
        @client = OAuth2::Client.new(
          ENV["YU_TALENT_CLIENT_ID"].try(:downcase),
          ENV["YU_TALENT_CLIENT_SECRET"],
          { authorize_url: CREDENTIALS[:auth_url], token_url: CREDENTIALS[:access_token_url] }
        )
        return @client
      rescue => e
        Rails.logger.info "--- yu:talent client exception ----- : #{e.message}"
      end
    end


    def auth_url(app_id, host)
      begin
        @callback_url = callback_url(app_id, host)
        auth_url = client.auth_code.authorize_url({ redirect_uri: @callback_url, access_type: 'offline' })
        @auth_url = URI.decode(auth_url)
        return @auth_url
      rescue => e
        Rails.logger.info "--- yu:talent auth_url exception ----- : #{e.message}"
      end
    end


    def get_access_token(app_id, host, authorization_code)
      begin
        @callback_url = callback_url(app_id, host)
        @token = client.auth_code.get_token(authorization_code, redirect_uri: @callback_url)
        @token
      rescue => e
        Rails.logger.info "--- yu:talent get_access_token exception ----- : #{e.message}"
      end
    end


    private

      def callback_url(app_id, host)
        @host = format_url(host)
        "#{@host}/admin/apps/#{app_id}/callback"
      end


      def format_url(url)
        url = URI.parse(url)
        return url if url.scheme
        return "http://#{url}:3000" if Rails.env.development?
        "http://#{url}"
      end

  end

end
