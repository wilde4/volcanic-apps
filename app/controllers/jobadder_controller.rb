class JobadderController < ApplicationController

  protect_from_forgery with: :null_session, except: [:save_settings]
  respond_to :json

  after_filter :setup_access_control_origin
  before_action :set_key, only: [:index]

  def index
    app_url = params[:data][:original_url]
    app_url.slice! "/app_html"
    @key = Key.find_by app_dataset_id: params[:dataset_id], app_name: params[:controller]
    @ja_setting = JobadderAppSetting.find_by(dataset_id: params[:data][:dataset_id]) || JobadderAppSetting.create(:dataset_id => params[:data][:dataset_id], :app_url => app_url)


    if @ja_setting.present?
      @ja_service = Jobadder::ClientService.new(@ja_setting)

      if @ja_service.present? && @ja_service.client && @ja_setting.access_token.present?
        get_fields
      end
    end

    render layout: false

  end

  def update

    jobadder_app_setting = params[:jobadder_app_setting]

    @key = Key.find_by(app_dataset_id: jobadder_app_setting[:dataset_id], app_name: params[:controller])
    @ja_setting = JobadderAppSetting.find_by(dataset_id: jobadder_app_setting[:dataset_id])

    if @ja_setting.present?

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
    #destroy mappings
    if jobadder_app_setting[:jobadder_field_mappings_attributes].present?
      jobadder_app_setting[:jobadder_field_mappings_attributes].each do |i, mapping_attributes|
        if mapping_attributes[:jobadder_field_name].blank? && mapping_attributes[:id].present?
          @mapping = @ja_setting.jobadder_field_mappings.find(mapping_attributes[:id])
          @mapping.destroy
        end
      end
    end

    @ja_service = Jobadder::ClientService.new(@ja_setting);

    #This will never be executed, RSpec can't see template from update.js.erb and fails
    unless @ja_setting.authorised
      render :text => "OK"
    end

    get_fields if @ja_service.present? && @ja_setting.access_token.present?

  rescue StandardError => e
    Honeybadger.notify(e)
    @net_error = create_log(@ja_setting, @key, 'update_ja_settings', nil, nil, e.message, true, true)

  end

  def callback
    @ja_setting = JobadderAppSetting.find_by(dataset_id: params[:state])
    unless params[:error].present?
      @attributes = Hash.new
      @attributes[:authorization_code] = params[:code]
      @attributes[:response] = Jobadder::AuthenticationService.get_access_token(params[:code], @ja_setting)
      unless !@attributes[:response].token.present?
        if @ja_setting.present?
          if update_ja_params_token(@ja_setting, @attributes[:response])
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
    else
      flash[:alert] = "App could not be authorised."
      @key = Key.find_by(app_dataset_id: params[:state])
      @ja_setting.app_logs.create key: @key, endpoint: '/callback', name: 'callback', message: 'Could not authorize', response: params[:error], error: params[:error], internal: false
    end
    redirect_to @ja_setting.app_url
  end

  def save_candidate
    @key = Key.find_by app_dataset_id: params[:dataset_id], app_name: params[:controller]

    @ja_setting = JobadderAppSetting.find_by(dataset_id: params[:user][:dataset_id])

    @ja_service = Jobadder::ClientService.new(@ja_setting)

    @ja_user = JobadderUser.find_by(user_id: params[:user][:id])

    @cv = { upload_name: params[:user_profile][:upload_name], upload_path: params[:user_profile][:upload_path] } if params[:user_profile][:upload_path].present?

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

    create_log(@ja_user, @key, 'ja_user', "jobadder_controller/save_candidate",
      { attributes: params }.to_s,
      @ja_user.as_json.to_s)

    get_candidate_response = @ja_service.get_candidate_by_email(params[:user][:email])


    @candidate_id = get_candidate_response['items'][0]['candidateId'] unless get_candidate_response['items'].blank?
    if @candidate_id
      update_response = @ja_service.update_candidate(params[:user][:dataset_id], @ja_user.user_id, @candidate_id)
      render json: update_response
    else
      create_response = @ja_service.add_candidate(params[:user][:dataset_id], @ja_user.user_id)
      @candidate_id = create_response['candidateId']
      render json: create_response
    end

    cv_mapping = @ja_setting.jobadder_field_mappings.where("registration_question_reference LIKE '%upload-cv%'").first


    if @cv.present? && @cv[:upload_path].present? && @cv[:upload_name].present? && cv_mapping.nil? == false && cv_mapping.jobadder_field_name == '1'
      # unless @ja_user.user_profile['upload_path'] == @cv[:upload_path]
      #
      # end
      upload_cv_response = @ja_service.add_single_attachment(@candidate_id, @cv[:upload_path], @cv[:upload_name], 'Resume', 'candidate', 'original')
    end

    # upload registration files

    volcanic_user_response = @ja_service.get_volcanic_user(params[:user][:id])
    reg_answers_files_array = volcanic_user_response['registration_answers'] unless volcanic_user_response.blank?

    reg_answer_files = JobadderHelper.get_reg_answer_files(reg_answers_files_array, @ja_setting, @key)

    if reg_answer_files.length > 0
      reg_answer_files.each do |f|
        @ja_service.add_single_attachment(@candidate_id, f['url'], f['name'], f['type'], 'candidate', 'original')

      end
    end

  end

  def job_application

    JobadderApplicationWorker.perform_async params


    render json: { success: true, status: 'Application has been queued for submission to JobAdder' }

  rescue StandardError => e
    Honeybadger.notify(e)
    @ja_setting = JobadderAppSetting.find_by(dataset_id: params[:dataset_id])
    log_id = create_log(@ja_setting, @key, 'job_application', nil, nil, e.message, true, true)
    render json: { success: false, status: "Error ID: #{log_id}" }
  end

  def deactivate_app
    key = Key.where(app_dataset_id: params[:data][:app_dataset_id], app_name: params[:controller]).first
    respond_to do |format|
      if key
        ja_setting = JobadderAppSetting.find_by(dataset_id: params[:data][:app_dataset_id])
        ja_setting.destroy if ja_setting
        format.json { render json: { success: key.destroy } }
      else
        format.json { render json: { error: 'Key not found.' } }
      end
    end
  end

  private

  def ja_params
    params.require(:jobadder_app_setting).permit(
      :dataset_id,
      :import_jobs,
      :ja_params,
      :job_board_id,
      jobadder_field_mappings_attributes: [:id, :jobadder_app_setting_id, :jobadder_field_name,
        :registration_question_reference, :job_attribute]
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

    @ja_candidate_fields = @ja_service.get_jobadder_candidate_fields
    @ja_attachment_types = JobadderHelper.attachment_types
    @volcanic_candidate_fields = @ja_service.get_volcanic_candidate_fields
    @volcanic_fields = @volcanic_candidate_fields['volcanic_fields']
    @volcanic_upload_file_fields = @volcanic_candidate_fields['volcanic_upload_file_fields']
    @volcanic_upload_file_fields_core = @volcanic_candidate_fields['volcanic_upload_file_fields_core']

    @fields = []
    @files = []

    @volcanic_upload_file_fields_core.each do |reference, label|
      @ja_setting.jobadder_field_mappings.build(registration_question_reference: reference) unless @ja_setting.jobadder_field_mappings.find_by(registration_question_reference: reference)
    end

    @volcanic_upload_file_fields.each do |reference, label|
      @ja_setting.jobadder_field_mappings.build(registration_question_reference: reference) unless @ja_setting.jobadder_field_mappings.find_by(registration_question_reference: reference)
    end
    @volcanic_fields.each do |reference, label|
      @ja_setting.jobadder_field_mappings.build(registration_question_reference: reference) unless @ja_setting.jobadder_field_mappings.find_by(registration_question_reference: reference)
    end

    @ja_setting.jobadder_field_mappings.each do |m|

      @volcanic_upload_file_fields_core.each do |reference, label|
        @files << m if m.registration_question_reference == reference
      end
      @volcanic_upload_file_fields.each do |reference, label|
        @files << m if m.registration_question_reference == reference
      end
      @volcanic_fields.each do |reference, label|
        @fields << m if m.registration_question_reference == reference
      end
    end

  end

  def create_log(loggable, key, name, endpoint, message, response, error = false, internal = false, uid = nil)
    log = loggable.app_logs.create key: key, endpoint: endpoint, name: name, message: message, response: response, error: error, internal: internal, uid: uid || @ja_setting.access_token
    log.id
  rescue StandardError => e
    Honeybadger.notify(e)
  end

end
