class ArithonController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json

  after_filter :setup_access_control_origin
  before_action :set_key, only: [:index]

  def index
    @host = @key.host
    @app_id = params[:data][:id]
  end


  def save_user
    @settings = params[:settings] if params[:settings]

    @user_attributes = Hash.new
    @user_attributes[:user_id]              = params[:user][:id]
    @user_attributes[:email]                = params[:user][:email]
    @user_attributes[:user_data]            = params[:user]
    @user_attributes[:user_profile]         = params[:user_profile]
    @user_attributes[:linkedin_profile]     = params[:linkedin_profile]
    @user_attributes[:registration_answers] = params[:registration_answer_hash]

    @user = ArithonUser.find_by(user_id: params[:user][:id])

    if @user.present?
      if @user.update(@user_attributes)
        @user.reload
        Arithon::UserService.new(@user, @settings).update_user
        render json: { success: true,  user_id: @user.id }
      else
        render json: { success: false, status: "Error: #{@user.errors.full_messages.join(', ')}" }
      end
    else
      @user = ArithonUser.new(@user_attributes)
      if @user.save
        # CHECK DUPLICATES
        @arithon_id = Arithon::UserService.new(@user, @settings).check_duplicates
        # UPDATE IF DUPLICATE
        if @arithon_id.present?
          @user.update(arithon_uid: @arithon_id)
          Arithon::UserService.new(@user, @settings).update_user
        else
          Arithon::UserService.new(@user, @settings).save_user
        end
        render json: { success: true,  user_id: @user.id }
      else
        render json: { success: false, status: "Error: #{@user.errors.full_messages.join(', ')}" }
      end
    end
  end

end