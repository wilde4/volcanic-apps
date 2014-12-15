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
    attributes = {
      'firstName' => user.user_profile['first_name'],
      'lastName' => user.user_profile['last_name'],
      'name' => "#{user.user_profile['first_name']} #{user.user_profile['last_name']}",
      'status' => 'New Lead',
      'email' => user.email,
      'source' => 'Company Website'
    }
    # companyName, address, desiredLocations, educationDegree,
    # employmentPreference(perm, contract), mobile, namePrefix,
    # occupation(job title), phone(home), phone2(work), salary(desired)
    settings = AppSetting.find_by(dataset_id: params[:user][:dataset_id]).settings
    client = Bullhorn::Rest::Client.new(
      username: settings['username'],
      password: settings['password'],
      client_id: settings['client_id'],
      client_secret: settings['client_secret']
    )
    # GET BULLHORN ID
    if user.bullhorn_uid.present?
      bullhorn_id = user.bullhorn_uid
    else
      email_query = "email:\"#{URI::encode(user.email)}\""
      existing_candidate = client.search_candidates(query: email_query, sort: 'id')
      logger.info "--- existing_candidate = #{existing_candidate.data.map{ |c| c.id }.inspect}"
      if existing_candidate.record_count.to_i > 0
        logger.info '--- CANDIDATE RECORD FOUND'
        last_candidate = existing_candidate.data.last
        bullhorn_id = last_candidate.id
        @user.update(bullhorn_uid: bullhorn_id)
      else
        logger.info '--- CANDIDATE RECORD NOT FOUND'
        bullhorn_id = nil
      end
    end
    # CREATE CANDIDATE
    if bullhorn_id.present?
      logger.info "--- UPDATING #{bullhorn_id}: #{attributes.inspect} ..."
      response = client.update_candidate(bullhorn_id, attributes.to_json)
      logger.info "--- response = #{response.inspect}"
    else
      logger.info "--- CREATING CANDIDATE: #{attributes.inspect} ..."
      response = client.create_candidate(attributes.to_json)
      @user.update(bullhorn_uid: response['changedEntityId'])
    end
  end
end
