class YuTalent::ClientService < BaseService


  def initialize(params)
    @params = params
    @client = instatiate_client
  end


  def create_candidate(attributes.to_json)
    # make api call to create new user record
  end


  def update_candidate(yu_talent_id, attributes.to_json)
    # make api call to update existing user data
  end


  def check_duplicates(user_email)
    email_query = "email:\"#{URI::encode(user_email)}\""
    # make api call to check if record exists
  end


  private


    def instatiate_client
      settings = AppSetting.find_by(dataset_id: @params[:user][:dataset_id]).settings
      client = {}
      return client
    end


end
