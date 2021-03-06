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
    render layout: false
  end


  def callback
    @attributes                       = Hash.new
    @attributes[:dataset_id]          = params[:data][:dataset_id]
    @attributes[:authorization_code]  = params[:data][:code]
    @attributes[:access_token]        = YuTalent::AuthenticationService.get_access_token(
                                          params[:data][:id],
                                          @key.host,
                                          params[:data][:code])

    unless !@attributes[:access_token].present?
      @settings = YuTalentAppSetting.find_by(dataset_id: @attributes[:dataset_id])
      if @settings.present?
        if @settings.update(@attributes)
          flash[:notice]  = "App successfully authorised."
        else
          flash[:alert]   = "App could not be authorised."
        end
      else
        @settings = YuTalentAppSetting.new(@attributes)
        if @settings.save
          flash[:notice]  = "App successfully authorised."
        else
          flash[:alert]   = "App could not be authorised."
        end
      end
    end

    render :index
  end


  def save_user
    @user_attributes = Hash.new
    @user_attributes[:user_id]              = params[:user][:id]
    @user_attributes[:email]                = params[:user][:email]
    @user_attributes[:user_data]            = params[:user]
    @user_attributes[:user_profile]         = params[:user_profile]
    @user_attributes[:linkedin_profile]     = params[:linkedin_profile]
    @user_attributes[:registration_answers] = params[:registration_answer_hash]

    @user = YuTalentUser.find_by(user_id: params[:user][:id])

    if @user.present?
      original_upload_path = @user.user_profile["upload_path"]
      original_avatar_path = @user.user_profile["li_pictureUrl"]
      if @user.update(@user_attributes)
        @user.reload
        new_upload_path = @user.user_profile["upload_path"]
        @new_cv = (original_upload_path != new_upload_path)
        new_avatar_path = @user.user_profile["li_pictureUrl"]
        @new_avatar = (original_avatar_path != new_avatar_path)

        YuTalent::UserService.new(@user).update_user(@new_cv, @new_avatar)
        render json: { success: true,  user_id: @user.id }
      else
        render json: { success: false, status: "Error: #{@user.errors.full_messages.join(', ')}" }
      end
    else
      @user = YuTalentUser.new(@user_attributes)
      if @user.save
        # CHECK DUPLICATES
        @yutalent_id = YuTalent::UserService.new(@user).check_duplicates
        # UPDATE IF DUPLICATE
        if @yutalent_id.present?
          @user.update(yu_talent_uid: @yutalent_id)
          YuTalent::UserService.new(@user).update_user(true, true)
        else
          YuTalent::UserService.new(@user).save_user
        end
        render json: { success: true,  user_id: @user.id }
      else
        render json: { success: false, status: "Error: #{@user.errors.full_messages.join(', ')}" }
      end
    end
  end

  def save_settings
    @settings = YuTalentAppSetting.find_by(dataset_id: params[:yu_talent_app_setting][:dataset_id])
    if @settings.update(params[:yu_talent_app_setting].permit!)
      flash[:notice]  = "Settings successfully saved."
    else
      flash[:alert]   = "Settings could not be saved. Please try again."
    end
  end

  def upload_cv
    @user_attributes = Hash.new
    @user_attributes[:user_id]              = params[:user][:id]
    @user_attributes[:email]                = params[:user][:email]
    @user_attributes[:user_data]            = params[:user]
    @user_attributes[:user_profile]         = params[:user_profile]

    @user = YuTalentUser.find_by(user_id: params[:user][:id])

    if @user.present?
      if @user.update(@user_attributes)
        YuTalent::UserService.new(@user).update_user(true)
        render json: { success: true,  user_id: @user.id }
      else
        render json: { success: false, status: "Error: #{@user.errors.full_messages.join(', ')}" }
      end
    else
      render json: { success: false, status: "Error: No User Found" }
    end
  end
end
