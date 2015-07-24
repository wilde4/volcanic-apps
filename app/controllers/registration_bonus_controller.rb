class RegistrationBonusController < ApplicationController
  protect_from_forgery with: :null_session
  # respond_to :json

  before_action :set_key, only: [:index, :new]

  # Controller requires cross-domain POST XHRs
  after_filter :setup_access_control_origin

  def index
    @host = @key.host
  end

  def new
    setup_types_and_groups

    @reg_bonus = RegistrationBonus.new
    @reg_bonus.dataset_id = @key.app_dataset_id
  end

  def create
    @reg_bonus = RegistrationBonus.new(registration_bonus_params)
    
    
    respond_to do |format|
      if @reg_bonus.save
        format.html { render action: 'index' }
        format.json { render json: { success: true, item: @reg_bonus }}
      else
        format.json { render json: {
          success: false, status: "Error: #{@reg_bonus.errors.full_messages.join(', ')}"
        }}
      end
    end
  end


  private
    def registration_bonus_params
      params.require(:registration_bonus).permit(:name, :user_group, :dataset_id, :credit_type, :quantity)
    end
  
    def setup_types_and_groups
      site_response = HTTParty.get("http://#{@key.host}/api/v1/site.json?api_key=#{@key.api_key}", {})
      # logger.info "--- cr_response = #{cr_response.body.inspect}"
      response_json = JSON.parse(site_response.body)
      # logger.info "--- response_json = #{response_json.inspect}"
      @credit_types = response_json["credit_types"].present? ? response_json["credit_types"] : []
      
      if response_json["user_groups"].present? #legacy support
        @user_groups = response_json["user_groups"].present? ? response_json["user_groups"] : []
      else
        @user_groups = response_json["user_types"].present? ? response_json["user_types"] : []
      end
    end
end
