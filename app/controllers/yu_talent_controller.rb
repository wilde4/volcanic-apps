class YuTalentController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json

  after_filter :setup_access_control_origin
  before_action :set_key, only: [:index, :callback, :save_user]

  def index
    @host = @key.host
    @app_id = params[:data][:id]
    @auth_url = YuTalent::AuthenticationService.auth_url(@app_id, @host)
    @settings = YuTalentAppSetting.find_by(dataset_id: params[:data][:dataset_id])
  end


  def callback
    @attributes = Hash.new
    @attributes[:dataset_id]         = params[:data][:dataset_id]
    @attributes[:authorization_code] = params[:data][:code]
    @attributes[:access_token]       = YuTalent::AuthenticationService.get_access_token(
                                        params[:data][:id], @key.host, params[:data][:code]).try(:to_json)

    unless !@attributes[:access_token].present?
      @settings = YuTalentAppSetting.find_by(dataset_id: @attributes[:dataset_id])
      if @settings.present?
        if @settings.update(@attributes)
          flash[:notice] = "App successfully authorised."
        else
          flash[:alert] = "App could not be authorised."
        end
      else
        @settings = YuTalentAppSetting.new(@attributes)
        if @settings.save
          flash[:notice] = "App successfully authorised."
        else
          flash[:alert] = "App could not be authorised."
        end
      end
    end

    render :index
  end


  def save_user
    @user_attributes = Hash.new
    @user_attributes[:email]                = params[:user][:email]
    @user_attributes[:user_data]            = params[:user]
    @user_attributes[:user_profile]         = params[:user_profile]
    @user_attributes[:linkedin_profile]     = params[:linkedin_profile]
    @user_attributes[:registration_answers] = params[:registration_answer_hash]

    @user = YuTalentUser.find_by(user_id: params[:user][:id])

    if @user.present?
      if @user.update(@user_attributes)
        YuTalent::UserService.new(@user).update_user
        render json: { success: true, user_id: @user.id }
      else
        render json: { success: false, status: "Error: #{@user.errors.full_messages.join(', ')}" }
      end
    else
      @user = YuTalentUser.new(@user_attributes)
      if @user.save
        YuTalent::UserService.new(@user).post_user
        render json: { success: true, user_id: @user.id }
      else
        render json: { success: false, status: "Error: #{@user.errors.full_messages.join(', ')}" }
      end
    end
  end


end
