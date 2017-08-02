class DaxtraController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json, :xml

  before_action :set_key, only: [:index]
  after_filter :setup_access_control_origin

  def index
    @host = @key.host
    @app_id = params[:data][:id]
    render layout: false
  end


  def email_data
    if params[:target_type] == 'job_application'
      @email = params[:user][:email]
      @user_profile = params[:user_profile]
      @first_name = @user_profile['first_name']
      @last_name = @user_profile['last_name']
      @registration_answer_hash = params[:registration_answer_hash] || {}
      @job = params[:job]
      body =  render_to_string(action: 'email_data.html.haml', layout: false)
      render json: { success: true, body: body }
    else
      render json: {}
    end
  end
end
