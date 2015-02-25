class YuTalent::ClientService < BaseService


  def initialize(params)
    @params = params
    @client = instatiate_client
  end


  def update_candidate(yu_talent_id, attributes.to_json)
  end


  def create_candidate(attributes.to_json)
  end


  def check_duplicates(user_email)
    # api call to check if record exists
    email_query = "email:\"#{URI::encode(user_email)}\""
    # check yu talent using email query
  end


  private


    def instatiate_client
      settings = AppSetting.find_by(dataset_id: @params[:user][:dataset_id]).settings
      client = {}
      return client
    end


end
