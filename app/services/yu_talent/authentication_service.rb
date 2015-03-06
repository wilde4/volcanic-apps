require 'uri'

class YuTalent::AuthenticationService < BaseService

  CREDENTIALS = {
    auth_url: 'https://yutalent.co.uk/c/oauth/authorize',
    access_token_url: 'https://yutalent.co.uk/c/oauth/access_token'
  }

  def self.auth_url(app_id, host)
    begin
      @host = format_url(host)
      callback_url = "#{@host}/admin/apps/#{app_id}/callback"
      client = OAuth2::Client.new(
        ENV["YU_TALENT_CLIENT_ID"],
        ENV["YU_TALENT_CLIENT_SECRET"],
        { authorize_url: CREDENTIALS[:auth_url], token_url: CREDENTIALS[:access_token_url] }
      )
      auth_url = client.auth_code.authorize_url({ redirect_uri: callback_url, access_type: 'offline' })
      @auth_url = URI.decode(auth_url)
      return @auth_url
    rescue => e
      puts e.inspect
    end
  end


  def self.format_url(url)
    url = URI.parse(url)
    return url if url.scheme
    return "http://#{url}:3000" if Rails.env.development?
    "http://#{url}"
  end

end
