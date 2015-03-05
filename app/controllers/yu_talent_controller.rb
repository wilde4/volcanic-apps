class YuTalentController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json

  after_filter :setup_access_control_origin
  before_action :set_key, only: [:index, :update_yu_talent_settings]

  def index
    @host = app_server_host + "/yu_talent/update_yu_talent_settings"
    @dataset_id = @key.app_dataset_id
    @settings = YuTalentSetting.find_by(dataset_id: @dataset_id)
  end


  def update_yu_talent_settings
    @settings = YuTalentSetting.find_by(dataset_id: params[:data][:dataset_id])
    if @settings.present?
      if @settings.update(
        dataset_id: params[:data][:dataset_id],
        client_id: params[:data][:client_id],
        client_secret: params[:data][:client_secret]
      )
        flash[:notice] = "Settings Saved Successfully"
      else
        flash[:alert] = "Settings not saved"
      end
    else
      @settings = YuTalentSetting.new
      @settings[:dataset_id] = params[:data][:dataset_id]
      @settings[:client_id] = params[:data][:client_id]
      @settings[:client_secret] = params[:data][:client_secret]

      if @settings.save
        flash[:notice] = "Settings Saved Successfully"
      else
        flash[:alert] = "Settings not saved"
      end
    end
  end


  def save_user
    @user = YuTalentUser.find_by(user_id: params[:user][:id])
    if @user.present?
      # update YuTalent user record
      if @user.update(
        email: params[:user][:email],
        user_data: params[:user],
        user_profile: params[:user_profile],
        linkedin_profile: params[:linkedin_profile],
        registration_answers: params[:registration_answer_hash]
      )
        YuTalent::UserService.new(@user, params).post_user
        render json: { success: true, user_id: @user.id }
      else
        render json: { success: false, status: "Error: #{@user.errors.full_messages.join(', ')}" }
      end
    else
      # create new YuTalent user record
      @user = YuTalentUser.new
      @user.user_id = params[:user][:id]
      @user.email = params[:user][:email]
      @user.user_data = params[:user]
      @user.user_profile = params[:user_profile]
      @user.linkedin_profile = params[:linkedin_profile]
      @user.registration_answers = params[:registration_answer_hash]

      # persist user data
      if @user.save
        YuTalent::UserService.new(@user, params).post_user
        render json: { success: true, user_id: @user.id }
      else
        render json: { success: false, status: "Error: #{@user.errors.full_messages.join(', ')}" }
      end

    end
  end


  def app_server_host
    if Rails.env.development?
      "http://localhost:3001"
    elsif Rails.env.production?
      "apps.volcanic.co"
    end
  end

  # GET
  def callback
    # Extract code from params
    # Save code to yutalent_settings table with dataset_id
    # Render callback.html.haml with congrats message
  end

end
