class YuTalentController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json

  after_filter :setup_access_control_origin
  before_action :set_key, only: [:index]

  def index
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
        logger.info "--- params = #{params.inspect}"
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
