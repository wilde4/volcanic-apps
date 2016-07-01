require 'uri'
require 'oauth2'

class MailChimp::AuthenticationService < BaseService

  class << self

    CREDENTIALS = {
      authorize_url: 'https://login.mailchimp.com/oauth2/authorize',
      token_url: 'https://login.mailchimp.com/oauth2/token',
      client_secret: 'b5e3a197a0e465d2f0e42a7dba8b9393',
      client_id: '651907686702'
    }
    

    def client_auth(app_id, host)
      client = OAuth2::Client.new(ENV['MAILCHIMP_CLIENT_ID'], ENV['MAILCHIMP_CLIENT_SECRET'], { authorize_url: CREDENTIALS[:authorize_url], token_url: CREDENTIALS[:token_url] })
      
      # client = OAuth2::Client.new(CREDENTIALS[:client_id], CREDENTIALS[:client_secret], { authorize_url: CREDENTIALS[:authorize_url], token_url: CREDENTIALS[:token_url] })
      
      authorize_url = client.auth_code.authorize_url(redirect_uri: redirect_uri(app_id, host), response_type: 'code')

      return URI.decode(authorize_url)  
    end
    
    def get_access_token(app_id, host, authorization_code)
      client = OAuth2::Client.new(ENV['MAILCHIMP_CLIENT_ID'], ENV['MAILCHIMP_CLIENT_SECRET'], { authorize_url: CREDENTIALS[:authorize_url], token_url: CREDENTIALS[:token_url] })
      begin
        @callback_url = redirect_uri(app_id, host)
        @token = client.auth_code.get_token(authorization_code, redirect_uri: @callback_url)
        @token = @token.to_hash[:access_token]
      rescue => e
        Rails.logger.info "--- mailchimp get_access_token exception ----- : #{e.message}"
      end
      @token
    end

    private

      def redirect_uri(app_id, host)
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
