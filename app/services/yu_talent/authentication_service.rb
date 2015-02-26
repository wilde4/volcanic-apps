class YuTalent::AuthenticationService < BaseService


  CREDENTIALS = {
    id: "",
    secret: "",
    auth_url: 'https://yutalent.co.uk/c/oauth/authorize',
    access_token_url: 'https://yutalent.co.uk/c/oauth/access_token',
    redirect_url: 'http://localhost'
  }


  def initialize
    @access_token = authenticate
  end


  private


    def authenticate
      begin
        client = OAuth2::Client.new(
          CREDENTIALS[:id],
          CREDENTIALS[:secret],
          { authorize_url: CREDENTIALS[:auth_url], token_url: CREDENTIALS[:access_token_url] }
        )
        client.auth_code.authorize_url({ redirect_uri: CREDENTIALS[:redirect_url], access_type: 'offline' })
        refresh = refresh_token
        token = refresh.parsed_response['access_token'] if refresh.code == 200
        access_token = OAuth2::AccessToken.from_hash(client, { access_token: token})
      rescue => e
        puts e.inspect
      end
    end


    def refresh_token
      options = {
        body: { client_id: CREDENTIALS[:id], client_secret: CREDENTIALS[:secret], grant_type: 'refresh_token' },
        headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
      }
      response = HTTParty.post(CREDENTIALS[:access_token_url], options)
      return response
    end


end
