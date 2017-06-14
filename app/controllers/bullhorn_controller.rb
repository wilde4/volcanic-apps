class BullhornController < ApplicationController
  require 'bullhorn/rest'
  protect_from_forgery with: :null_session, except: [:save_settings]
  respond_to :json

  # Controller requires cross-domain POST XHRs
  after_filter :setup_access_control_origin
  before_action :set_key, only: [:index, :job_application, :save_user, :upload_cv, :new_search, :jobs]


  # To Authorize a Bullhorn API user, follow instruction on https://github.com/bobop/bullhorn-rest
  def index
    @bullhorn_setting = BullhornAppSetting.find_by(dataset_id: params[:data][:dataset_id]) || BullhornAppSetting.new(dataset_id: params[:data][:dataset_id])

    @bullhorn_service = Bullhorn::ClientService.new(@bullhorn_setting) if @bullhorn_setting.present?

    if @bullhorn_service.present? && @bullhorn_service.client_authenticated?
      get_fields
    end

    render layout: false
  end


  def update
    @key = Key.find_by(app_dataset_id: params[:bullhorn_app_setting][:dataset_id], app_name: params[:controller])
    @bullhorn_setting = BullhornAppSetting.find_by(dataset_id: params[:bullhorn_app_setting][:dataset_id])

    if @bullhorn_setting.present? #UPDATE CURRENT SETTINGS

      if @bullhorn_setting.update(bh_params)
        flash[:notice]  = "Settings successfully saved."
      else
        flash[:alert] = "Settings could not be saved. Please try again."
      end

    else #CREATE NEW SETTINGS

      @bullhorn_setting = BullhornAppSetting.new(bh_params)

      if @bullhorn_setting.save
        flash[:notice]  = "Settings successfully saved."
      else
        flash[:alert]   = "Settings could not be saved. Please try again."
      end

    end

    # DELETE MAPPING OBJETS IF THEY ARE RECORDS AND THE ARE SET TO BLANK AGAIN
    if params[:bullhorn_app_setting][:bullhorn_field_mappings_attributes].present?
      params[:bullhorn_app_setting][:bullhorn_field_mappings_attributes].each do |i, mapping_attributes|
        if mapping_attributes[:bullhorn_field_name].blank? && mapping_attributes[:id].present?
          @mapping = @bullhorn_setting.bullhorn_field_mappings.find(mapping_attributes[:id])
          @mapping.destroy
        end
      end
    end

    #CALL TO MODEL METHOD TO CHECK IF WE HAVE PROPER ACCESS TO THE BULLHORN API
    @bullhorn_setting.update_authorised_settings

    @bullhorn_service = Bullhorn::ClientService.new(@bullhorn_setting) if @bullhorn_setting.present?
    get_fields if @bullhorn_service.present?
  rescue StandardError => e
    Honeybadger.notify(e)
    @net_error = create_log(@bullhorn_setting, @key, 'update', nil, nil, e.message, true, true)
  end

  def save_user

    user_available = false
    @user = BullhornUser.find_by(user_id: params[:user][:id])

    if @user.present?
      if @user.update(
        email: params[:user][:email],
        user_data: params[:user],
        user_profile: params[:user_profile],
        linkedin_profile: params[:linkedin_profile],
        registration_answers: params[:registration_answer_hash].present? ? format_reg_answer(params[:registration_answer_hash]) : nil
      )
        
        user_available = true
      end
    else
      @user = BullhornUser.new
      @user.user_id = params[:user][:id]
      @user.email = params[:user][:email]
      @user.user_data = params[:user]
      @user.user_profile = params[:user_profile]
      @user.linkedin_profile = params[:linkedin_profile]
      @user.registration_answers = params[:registration_answer_hash].present? ? format_reg_answer(params[:registration_answer_hash]) : nil
      user_available = true if @user.save
    end

    if @user.present? && user_available

      @bullhorn_setting = BullhornAppSetting.find_by(dataset_id: params[:user][:dataset_id])
      @bullhorn_service = Bullhorn::ClientService.new(@bullhorn_setting) if @bullhorn_setting.present?

      if @bullhorn_service.present?
        @bullhorn_service.post_user_to_bullhorn(@user, params)
      end

      render json: { success: true, user_id: @user.id }
    else
      render json: { success: false, status: "Error: #{@user.errors.full_messages.join(', ')}" }
    end
  rescue StandardError => e
    Honeybadger.notify(e)
    @bullhorn_setting = BullhornAppSetting.find_by(dataset_id: params[:user][:dataset_id])
    log_id = create_log(@bullhorn_setting, @key, 'save_user', nil, nil, e.message, true, true)
    render json: { success: false, status: "Error ID: #{log_id}" }
  end

  def job_application
    @user = BullhornUser.find_by(user_id: params[:user][:id])
    @job_reference = params[:job][:job_reference]

    candidate = {
      'id' => @user.bullhorn_uid
    }
    job_order = {
      'id' => @job_reference
    }

    attributes = {
      'candidate' => candidate,
      'isDeleted' => 'false',
      'jobOrder' => job_order,
      'status' => 'New Lead'
    }

    if @user.present? && @job_reference.present?
      @bullhorn_setting = BullhornAppSetting.find_by(dataset_id: params[:dataset_id])
      @bullhorn_service = Bullhorn::ClientService.new(@bullhorn_setting) if @bullhorn_setting.present?
      
      @response = @bullhorn_service.send_job_application(attributes) if @bullhorn_service.present?

    end
    
    if @response.changedEntityId.present?
      render json: { success: true, job_submission_id: response.changedEntityId }
    else
      render json: { success: false, status: "JobSubmission was not created in Bullhorn." }
    end
  rescue StandardError => e
    Honeybadger.notify(e)
    @bullhorn_setting = BullhornAppSetting.find_by(dataset_id: params[:dataset_id])
    log_id = create_log(@bullhorn_setting, @key, 'job_application', nil, nil, e.message, true, true)
    render json: { success: false, status: "Error ID: #{log_id}" }
  end

  def new_search
    # create candidate object
    user_id = params[:search][:user_id] || params[:user][:user][:id]
    @user = BullhornUser.find_by(user_id: user_id)

    if @user.present?
      @bullhorn_setting = BullhornAppSetting.find_by(dataset_id: params[:dataset_id])
      @bullhorn_service = Bullhorn::ClientService.new(@bullhorn_setting) if @bullhorn_setting.present?
      
      @response = @bullhorn_service.send_search(@user, params) if @bullhorn_service.present?
    end

    logger.info "--- note_response = #{@response.inspect}"

    # check response
    if @response.changedEntityId.present?
      render json: { success: true, status: "Note created in Bullhorn" }
    else
      render json: { success: false, status: "Note was not created in Bullhorn." }
    end
  rescue StandardError => e
    Honeybadger.notify(e)
    @bullhorn_setting = BullhornAppSetting.find_by(dataset_id: params[:dataset_id])
    log_id = create_log(@bullhorn_setting, @key, 'new_search', nil, nil, e.message, true, true)
    render json: { success: false, status: "Error ID: #{log_id}" }
  end

  def upload_cv
    if params[:user_profile][:upload_path].present?
      @user = BullhornUser.find_by(user_id: params[:user][:id])

      if @user.present?
        @bullhorn_setting = BullhornAppSetting.find_by(dataset_id: params[:dataset_id])
        @bullhorn_service = Bullhorn::ClientService.new(@bullhorn_setting) if @bullhorn_setting.present?

        @file_response = @bullhorn_service.send_candidate_cv(@user, params)
      end

      if @file_response == true
        create_log(@bullhorn_setting, @key, 'upload_cv_successfull', nil, nil, nil, false, false)
        render json: { success: true, user_id: @user.id }
      else
        create_log(@bullhorn_setting, @key, 'upload_cv_failed', nil, nil, nil, true, false)
        render json: { success: false, status: "CV was not uploaded to Bullhorn" }
      end
    end
  rescue StandardError => e
    Honeybadger.notify(e)
    @bullhorn_setting = BullhornAppSetting.find_by(dataset_id: params[:user][:dataset_id])
    log_id = create_log(@bullhorn_setting, @key, 'upload_cv', nil, nil, e.message, true, true)
    render json: { success: false, status: "Error ID: #{log_id}" }
  end


  def deactivate_app
    key = Key.where(app_dataset_id: params[:data][:app_dataset_id], app_name: params[:controller]).first
    respond_to do |format|
      if key
        bullhorn_setting = BullhornAppSetting.find_by(dataset_id: params[:data][:app_dataset_id])
        bullhorn_setting.destroy if bullhorn_setting
        format.json { render json: { success: key.destroy }}
      else
        format.json { render json: { error: 'Key not found.' } }
      end
    end
  end

  def report
    key = Key.where(app_dataset_id: params[:dataset_id], app_name: params[:controller]).first
    if params[:filter]
      this_period_start = params[:filter][:start_date].to_date
      this_period_end = params[:filter][:end_date].to_date + 1.day
      all_logs = key.app_logs.where(created_at: this_period_start..this_period_end)
    else
      all_logs = key.app_logs
    end
    user_requests = all_logs.where(loggable_type: 'BullhornUser')
    user_creates = user_requests.where(name: 'create_candidate', error: false)
    user_updates = user_requests.where(name: 'update_candidate', error: false)
    user_failures = user_requests.where(error: true)
    @report = { 
      layout: {
        overview: {
          data_name: :requests,
          chart_name: 'Requests',
          charts: [:total, :success, :failure]
        },
        circle_charts: [
          {
            data_name: :users,
            chart_name: 'Users',
            charts: [:created, :updated, :failed]
          }
        ]
      },
      report_data: {
        requests: {
          total: all_logs.count,
          success: all_logs.where(error: false).count,
          failure: all_logs.where(error: true).count
        },
        users: {
          total: user_requests.count,
          created: user_creates.count,
          updated: user_updates.count,
          failed: user_failures.count
        }
      }
    }

    respond_to do |format|
      format.json { render json: @report }
    end
  end



  private

    def bh_params
      params.require(:bullhorn_app_setting).permit(
        :dataset_id,
        :import_jobs,
        :linkedin_bullhorn_field,
        :source_text,
        :always_create,
        :cv_type_text,
        :uses_public_filter,
        :bh_params,
        :bh_username,
        :bh_password,
        :bh_client_id,
        :bh_client_secret,
        :custom_job_mapping,
        :expire_closed_jobs,
        bullhorn_field_mappings_attributes: [:id, :bullhorn_app_setting_id, :bullhorn_field_name, :registration_question_reference, :job_attribute]
        )
    end

    def get_fields
      
      @bh_candidate_fields        = @bullhorn_service.bullhorn_candidate_fields
      @bh_job_fields              = @bullhorn_service.bullhorn_job_fields
      @volcanic_candidate_fields  = @bullhorn_service.volcanic_candidate_fields
      @volcanic_job_fields        = @bullhorn_service.volcanic_job_fields

      @volcanic_candidate_fields.each do |reference, label|
        @bullhorn_setting.bullhorn_field_mappings.build(registration_question_reference: reference) unless @bullhorn_setting.bullhorn_field_mappings.find_by(registration_question_reference: reference)
      end

      @volcanic_job_fields.each do |reference, label|
        @bullhorn_setting.bullhorn_field_mappings.build(job_attribute: reference) unless @bullhorn_setting.bullhorn_field_mappings.find_by(job_attribute: reference)
      end
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

    def reg_answer_arr_looper(registration_answers)
      registration_answers.map! do |slot|
          slot = CGI.unescapeHTML(slot.to_s)
      end
      registration_answers
    end


end