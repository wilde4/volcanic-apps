class YuTalentController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json

  after_filter :setup_access_control_origin
  before_action :set_key, only: [:index, :update_yu_talent_settings]

  def index
    @host = @key.host
    @app_id = params[:data][:id]
    @auth_url = YuTalent::AuthenticationService.auth_url(@app_id, @host)
    @settings = YuTalentAppSetting.find_by(dataset_id: params[:data][:dataset_id])
  end


  def callback
    @settings = YuTalentAppSetting.find_by(dataset_id: params[:data][:dataset_id])
    if @settings.present?
      if @settings.update(dataset_id: params[:data][:dataset_id], refresh_token: params[:data][:code])
        flash[:notice] = "App successfully authorised."
        render :index
      else
        flash[:alert] = "App could not be authorised."
      end
    else
      @settings = YuTalentAppSetting.new
      @settings[:dataset_id] = params[:data][:dataset_id]
      @settings[:refresh_token] = params[:data][:code]

      if @settings.save
        flash[:notice] = "App successfully authorised."
        render :index
      else
        flash[:alert] = "App could not be authorised."
        render :index
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


end
