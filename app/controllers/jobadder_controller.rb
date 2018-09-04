class JobadderController < ApplicationController

  protect_from_forgery with: :null_session, except: [:save_settings]
  respond_to :json

  after_filter :setup_access_control_origin
  before_action :set_key, only: [:index]

  def index
    app_url = params[:data][:original_url]
    app_url.slice! "/app_html"
    @key = Key.find_by app_dataset_id: params[:data][:dataset_id], app_name: params[:controller]
    @ja_setting = JobadderAppSetting.find_by(dataset_id: params[:data][:dataset_id]) ||
        JobadderAppSetting.create(:dataset_id => params[:data][:dataset_id], :app_url => app_url)


    @ja_service = Jobadder::ClientService.new(@ja_setting, 'http://127.0.0.1:3001/jobadder/callback');

    if@ja_service.present? && @ja_service.client && @ja_setting.access_token.present?
      get_fields
    end

    render layout: false

  end

  def update

    @key = Key.find_by(app_dataset_id: params[:jobadder_app_setting][:dataset_id], app_name: params[:controller])
    @ja_setting = JobadderAppSetting.find_by(dataset_id: params[:jobadder_app_setting][:dataset_id])

    if @ja_setting.present? #UPDATE CURRENT SETTINGS

      if @ja_setting.update(ja_params)
        flash[:notice] = "Settings successfully saved."
      else
        flash[:alert] = "Settings could not be saved. Please try again."
      end

    else #CREATE NEW SETTINGS

      @ja_setting = JobadderAppSetting.new(ja_params)

      if @ja_setting.save
        flash[:notice] = "Settings successfully saved."
      else
        flash[:alert] = "Settings could not be saved. Please try again."
      end

    end

    if params[:jobadder_app_setting][:jobadder_field_mappings_attributes].present?
      params[:jobadder_app_setting][:jobadder_field_mappings_attributes].each do |i, mapping_attributes|
        if mapping_attributes[:jobadder_field_name].blank? && mapping_attributes[:id].present?
          @mapping = @ja_setting.jobadder_field_mappings.find(mapping_attributes[:id])
          @mapping.destroy
        end
      end
    end

    @ja_service = Jobadder::ClientService.new(@ja_setting, 'http://127.0.0.1:3001/jobadder/callback');


    unless @ja_setting.authorised
      render :js => "window.open('#{@ja_service.authorize_url}', '_self')"
    end

    get_fields if @ja_service.present? && @ja_setting.access_token.present?
  rescue StandardError => e
    Honeybadger.notify(e)
    @net_error = create_log(@ja_setting, @key, 'update_ja_settings', nil, nil, e.message, true, true)

  end

  def callback
    @ja_setting = JobadderAppSetting.find_by(dataset_id: params[:state])
    @attributes = Hash.new
    @attributes[:authorization_code] = params[:code]
    @attributes[:access_token] = Jobadder::AuthenticationService.get_access_token(params[:code], @ja_setting)

    unless !@attributes[:access_token].token.present?

      if @ja_setting.present?
        if update_ja_params_token(@ja_setting, @attributes[:access_token])
          flash[:notice] = "App successfully authorised."
          @ja_setting.update_attribute(:authorised, true)
        else
          flash[:alert] = "App could not be authorised."
        end
      else
        @ja_setting = JobadderAppSetting.new(@attributes)
        if @ja_setting.save
          flash[:notice] = "App successfully authorised."
        else
          flash[:alert] = "App could not be authorised."
        end
      end
    end
    redirect_to @ja_setting.app_url
  end

  def save_candidate

    @ja_setting = JobadderAppSetting.find_by(dataset_id: params[:user][:dataset_id])

    @ja_user = JobadderUser.find_by(user_id: params[:user][:id])

    @key = Key.find_by app_dataset_id: params[:user][:dataset_id], app_name: params[:controller]

    @ja_service = Jobadder::ClientService.new(@ja_setting, 'http://127.0.0.1:3001/jobadder/callback')

    if @ja_user.present?
      @ja_user.update(
          {
              email: params[:user][:email],
              user_data: params[:user],
              user_profile: params[:user_profile],
              linkedin_profile: params[:linkedin_profile],
              registration_answers: (params[:registration_answer_hash].present? ? format_reg_answer(params[:registration_answer_hash]) : nil)
          }
      )


    else
      @ja_user = JobadderUser.create(user_id: params[:user][:id],
                                     email: params[:user][:email],
                                     user_data: params[:user],
                                     user_profile: params[:user_profile],
                                     linkedin_profile: params[:linkedin_profile],
                                     registration_answers: params[:registration_answer_hash].present? ?
                                                               format_reg_answer(params[:registration_answer_hash]) : nil)


    end

    get_candidate_response = @ja_service.get_candidate_by_email(params[:user][:email], params[:user][:dataset_id])

    candidate_id = get_candidate_response['items'][0]['candidateId'] unless get_candidate_response['items'].empty?
    if candidate_id
      update_response = @ja_service.update_candidate(params[:user][:dataset_id], @ja_user.user_id, candidate_id)
      render json: update_response
    else
      create_response = @ja_service.add_candidate(params[:user][:dataset_id], @ja_user.user_id, @key)
      render json: create_response
    end

  end

  #TODO
  def add_job

  end

  def deactivate_app
    key = Key.where(app_dataset_id: params[:data][:app_dataset_id], app_name: params[:controller]).first
    respond_to do |format|
      if key
        ja_setting = JobadderAppSetting.find_by(dataset_id: params[:data][:app_dataset_id])
        ja_setting.destroy if ja_setting
        format.json {render json: {success: key.destroy}}
      else
        format.json {render json: {error: 'Key not found.'}}
      end
    end
  end

  private

  def ja_params
    params.require(:jobadder_app_setting).permit(
        :dataset_id,
        :import_jobs,
        :ja_params,
        :ja_client_id,
        :ja_client_secret,
        jobadder_field_mappings_attributes: [:id, :jobadder_app_setting_id, :jobadder_field_name, :registration_question_reference, :job_attribute]
    )
  end

  def update_ja_params_token(ja_setting, token_response)
    ja_setting.update(access_token: token_response.token)
    ja_setting.update(refresh_token: token_response.refresh_token)
    ja_setting.update(access_token_expires_at: Time.at(token_response.expires_at))
  end

  def check_api_access
    head :unauthorized unless @key.present?
  end

  def format_reg_answer(registration_answers = nil)
    if registration_answers.present?
      if registration_answers.is_a?(Hash)
        registration_answers.keys.each do |key|
          if registration_answers[key].is_a?(Array)
            reg_answer_arr_looper(registration_answers[key])
          else
            registration_answers[key] = CGI.unescapeHTML(registration_answers[key].to_s)
          end
        end
      else
        CGI.unescapeHTML(registration_answers.to_s)
      end
      registration_answers
    end
  end

  def get_fields

    @ja_candidate_fields = @ja_service.jobadder_candidate_fields
    # @bh_job_fields              = @bullhorn_service.bullhorn_job_fields
    @volcanic_candidate_fields = @ja_service.volcanic_candidate_fields
    # @volcanic_job_fields        = @bullhorn_service.volcanic_job_fields

    @volcanic_candidate_fields.each do |reference, label|
      @ja_setting.jobadder_field_mappings.build(registration_question_reference: reference) unless @ja_setting.jobadder_field_mappings.find_by(registration_question_reference: reference)
    end

    # @volcanic_job_fields.each do |reference, label|
    #   @bullhorn_setting.bullhorn_field_mappings.build(job_attribute: reference) unless @bullhorn_setting.bullhorn_field_mappings.find_by(job_attribute: reference)
    # end
  end

end
  