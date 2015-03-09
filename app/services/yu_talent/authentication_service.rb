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
        '5454-9715A4F54-3984B43EE-8B6AF6793-24FC3',
        'F6SIROFJVYECTZUNEQNDKK4M47QQURK1PEBIWGSH',
          { authorize_url: CREDENTIALS[:auth_url], token_url: CREDENTIALS[:access_token_url] }
        )
        # client = OAuth2::Client.new(
        #   ENV["YU_TALENT_CLIENT_ID"],
        #   ENV["YU_TALENT_CLIENT_SECRET"],
        #   { authorize_url: CREDENTIALS[:auth_url], token_url: CREDENTIALS[:access_token_url] }
        # )
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


    def get_access_token(refresh_token)
      # begin
        options = {
          body: {
            client_id: '5454-9715A4F54-3984B43EE-8B6AF6793-24FC3',
            client_secret: 'F6SIROFJVYECTZUNEQNDKK4M47QQURK1PEBIWGSH',
            # client_id: ENV["YU_TALENT_CLIENT_ID"],
            # client_secret: ENV["YU_TALENT_CLIENT_SECRET"],
            refresh_token: refresh_token,
            grant_type: 'refresh_token'
          },
          headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
        }
        refresh = HTTParty.post('https://yutalent.co.uk/c/oauth/access_token', options)

        Rails.logger.info "--- Auth access_token_response ----- : #{refresh}"


        if refresh.code == 200
          @token = refresh.parsed_response['access_token']
          @access_token = OAuth2::AccessToken.from_hash client, { access_token: @token }
        else
          puts "Whoops, couldn't retrieve access token with stored refresh token."
          @access_token = nil
        end
      # rescue => e
      #   puts e.inspect
      # end
    end


  end

end
