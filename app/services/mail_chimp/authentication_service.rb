require 'uri'
require 'oauth2'

class MailChimp::AuthenticationService < BaseService

  class << self

    CREDENTIALS = {
      authorize_url: 'https://login.mailchimp.com/oauth2/authorize',
      token_url: 'https://login.mailchimp.com/oauth2/token'
    }
    

    def client_auth(app_id, host, dataset_id)
      client = OAuth2::Client.new(ENV['MAILCHIMP_CLIENT_ID'], ENV['MAILCHIMP_CLIENT_SECRET'], { authorize_url: CREDENTIALS[:authorize_url], token_url: CREDENTIALS[:token_url] })
      
      # client = OAuth2::Client.new(CREDENTIALS[:client_id], CREDENTIALS[:client_secret], { authorize_url: CREDENTIALS[:authorize_url], token_url: CREDENTIALS[:token_url] })
      
      authorize_url = client.auth_code.authorize_url(redirect_uri: redirect_uri(app_id, host, dataset_id), response_type: 'code')

      return URI.decode(authorize_url)  
    end
    
    def get_access_token(app_id, host, authorization_code, dataset_id)
      client = OAuth2::Client.new(ENV['MAILCHIMP_CLIENT_ID'], ENV['MAILCHIMP_CLIENT_SECRET'], { authorize_url: CREDENTIALS[:authorize_url], token_url: CREDENTIALS[:token_url] })
      begin
        @callback_url = redirect_uri(app_id, host, dataset_id)
        @token = client.auth_code.get_token(authorization_code, redirect_uri: @callback_url)
        @token = @token.to_hash[:access_token]
      rescue => e
        Rails.logger.info "--- mailchimp get_access_token exception ----- : #{e.message}"
      end
      @token
    end

    private

      def redirect_uri(app_id, host, dataset_id)
        @host = format_url(host)
        # "#{@host}/admin/apps/#{app_id}/callback"
        Rails.env.development? ? "http://127.0.0.1:3001/mail_chimp/callback?app_info=#{app_id}-#{dataset_id}" : "http://#{ENV['DOMAIN_NAME']}/mail_chimp/callback?app_info=#{app_id}-#{dataset_id}"
      end
      
      def format_url(url)
        url = URI.parse(url)
        return url if url.scheme
        return "http://#{url}:3000" if Rails.env.development?
        "http://#{url}"
      end
      
  end
  
end
