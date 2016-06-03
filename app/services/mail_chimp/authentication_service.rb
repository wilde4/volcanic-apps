require 'uri'
require 'oauth2'

class MailChimp::AuthenticationService < BaseService

  class << self

    CREDENTIALS = {
      auth_url: 'https://login.mailchimp.com/oauth2/authorize',
      access_token_url: 'https://login.mailchimp.com/oauth2/token',
      client_id: '651907686702',
      client_secret: 'b5e3a197a0e465d2f0e42a7dba8b9393'
    }
    

    def client_auth(app_id, host)
      client = OAuth2::Client.new(CREDENTIALS[:client_id], CREDENTIALS[:client_secret], token_url: CREDENTIALS[:access_token_url], site: CREDENTIALS[:auth_url])
      authorize_url = client.auth_code.authorize_url(redirect_uri: redirect_uri(app_id, host), response_type: 'code')

      # authorize_url.sub! 'oauth', 'oauth2'
      return authorize_url
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
