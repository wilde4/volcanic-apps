class Bullhorn::ClientService < BaseService
  require 'bullhorn/rest'

  def initialize(args)
    @bullhorn_setting = BullhornAppSetting.find_by(dataset_id: args[:dataset_id])

  end

  def client_authenticated? #RE-AUTHENTICATE BH CLIENT IF ANYTHING HAS CHANGED
    
    if @bullhorn_setting.auth_settings_filled
      client = authenticate_client
      candidates = client.candidates(fields: 'id', sort: 'id') #TEST CALL TO CHECK IF INDEED WE HAVE PERMISSIONS (GET A CANDIDATES RESPONSE)
      
      candidates.data.size > 0
    else
      false
    end

  rescue
    false
  end

  def authenticate_client
    return Bullhorn::Rest::Client.new(
      username: @bullhorn_setting.bh_username,
      password: @bullhorn_setting.bh_password,
      client_id: @bullhorn_setting.bh_client_id,
      client_secret: @bullhorn_setting.bh_client_secret
    )
  end


end