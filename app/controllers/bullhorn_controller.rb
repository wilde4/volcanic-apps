class BullhornController < ApplicationController
  require 'bullhorn/rest'
  protect_from_forgery with: :null_session
  respond_to :json

  # Controller requires cross-domain POST XHRs
  after_filter :setup_access_control_origin

  def index
    # SOMETHING
  end

  def save_user
    @user = BullhornUser.find_by(user_id: params[:user][:id])
    if @user.present?
      if @user.update(
        email: params[:user][:email],
        user_data: params[:user],
        user_profile: params[:user_profile],
        registration_answers: params[:registration_answer_hash]
      )
        post_user_to_bullhorn(@user, params)
        render json: { success: true, user_id: @user.id }
      else
        render json: { success: false, status: "Error: #{@user.errors.full_messages.join(', ')}" }
      end
    else
      @user = BullhornUser.new
      @user.user_id = params[:user][:id]
      @user.email = params[:user][:email]
      @user.user_data = params[:user]
      @user.user_profile = params[:user_profile]
      @user.registration_answers = params[:registration_answer_hash]

      if @user.save
        post_user_to_bullhorn(@user, params)
        render json: { success: true, user_id: @user.id }
      else
        render json: { success: false, status: "Error: #{@user.errors.full_messages.join(', ')}" }
      end
    end
  end

  private

  def post_user_to_bullhorn(user, params)
    settings = AppSetting.find_by(dataset_id: params[:user][:dataset_id]).settings
    client = Bullhorn::Rest::Client.new(
      username: settings['username'],
      password: settings['password'],
      client_id: settings['client_id'],
      client_secret: settings['client_secret']
    )
    existing_candidate = client.search_candidates(query: 'email:"#{user.email}"')
    logger.info "--- existing_candidate = #{existing_candidate.inspect}"
    if existing_candidate.record_count.to_i > 0
      logger.info '--- CANDIDATE RECORD FOUND'
    else
      logger.info '--- CANDIDATE RECORD NOT FOUND'
      # CREATE CANDIDATE
      attributes = {
        'firstName' => user.user_profile['first_name'],
        'lastName' => user.user_profile['last_name'],
        'name' => "#{user.user_profile['first_name']} #{user.user_profile['last_name']}",
        'status' => 'New Lead',
        # 'email' => user.email,
        'source' => 'Company Website'
      }
      # attributes = {}
      # attributes['firstName'] = user.user_profile['first_name']
      # attributes['lastName']  = user.user_profile['last_name']
      # attributes['name']      = "#{user.user_profile['first_name']} #{user.user_profile['last_name']}"
      # attributes['userType']  = 'New Lead'
      logger.info "--- CREATING CANDIDATE with attributes: #{attributes.inspect} ..."
      response = client.create_candidate(attributes)
      logger.info "--- response = #{response.inspect}"
    end
  end
end
