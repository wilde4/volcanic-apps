class BullhornV2Controller < ApplicationController
  require 'bullhorn/rest'
  protect_from_forgery with: :null_session, except: [:save_settings]
  respond_to :json

  # Controller requires cross-domain POST XHRs
  after_filter :setup_access_control_origin
  before_action :set_key, only: [:index, :job_application, :save_user, :upload_cv, :new_search, :jobs]


  # To Authorize a Bullhorn API user, follow instruction on https://github.com/bobop/bullhorn-rest
  def index
    @key = Key.find_by app_dataset_id: params[:data][:dataset_id], app_name: params[:controller]

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

  def import_jobs

    @key = Key.find params[:id]
    @bullhorn_setting = BullhornAppSetting.find_by(dataset_id: @key.app_dataset_id)
    @bullhorn_service = Bullhorn::ClientService.new(@bullhorn_setting) if @bullhorn_setting.present?

    BullhornJobsWorker.perform_async key_id: params[:id]
    flash[:notice] = "Job import started"
    get_fields

  end

  def save_user
    @bullhorn_setting = BullhornAppSetting.find_by(dataset_id: params[:user][:dataset_id])

    user_available = false
    @user = BullhornUser.find_by(user_id: params[:user][:id])

    if @user.present?
      # If the user hasn't been sent to BH yet save previous CV details
      if @user.bullhorn_uid.blank?
        @cv = { upload_name: @user.user_profile['upload_name'], upload_path: @user.user_profile['upload_path'] } if @user.user_profile['upload_path'].present?
      end

      if @user.update(
        email: params[:user][:email],
        user_data: params[:user],
        user_profile: params[:user_profile],
        linkedin_profile: params[:linkedin_profile],
        registration_answers: params[:registration_answer_hash].present? ? format_reg_answer(params[:registration_answer_hash]) : nil
      )
        
        user_available = true
      end

      # Check if we need to add the CV details back to the profile hash
      if @cv.present? && @cv[:upload_path].present? && @user.user_profile['upload_path'].blank?
        @user.user_profile['upload_name'] = @cv[:upload_name]
        @user.user_profile['upload_path'] = @cv[:upload_path]
        @user.save
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

    if @bullhorn_setting.full_candidate_registrations_only? && !params[:user][:full_registration]
      render json: { success: false, status: "Only accepting fully registered candidates" }, status: 403
    else
      if @user.present? && user_available

        @bullhorn_service = Bullhorn::ClientService.new(@bullhorn_setting) if @bullhorn_setting.present?

        if @bullhorn_service.present?
          @bullhorn_service.post_user_to_bullhorn(@user, params)

          if params[:user_profile][:upload_path].present? || (@cv.present? && @cv[:upload_path].present?)
          
            if @bullhorn_service.send_candidate_cv(@user, params) == true
              create_log(@user, @key, 'upload_cv_successfull', nil, nil, nil, false, false)
            else
              create_log(@user, @key, 'upload_cv_failed', nil, nil, nil, true, false)
            end

          end

        end

        render json: { success: true, user_id: @user.id }
      else
        render json: { success: false, status: "Error: #{@user.errors.full_messages.join(', ')}" }, status: 422
      end
    end

  rescue StandardError => e
    Honeybadger.notify(e)
    @bullhorn_setting = BullhornAppSetting.find_by(dataset_id: params[:user][:dataset_id])
    log_id = create_log(@bullhorn_setting, @key, 'save_user', nil, nil, e.message, true, true)
    render json: { success: false, status: "Error ID: #{log_id}" }
  end

  def job_application
    
    BullhornApplicationWorker.perform_async params
    render json: { success: true, status: 'Application has been queued for submission to Bullhorn' }

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
    user_available = false
    @user = BullhornUser.find_by(user_id: params[:user][:id])
    @bullhorn_setting = BullhornAppSetting.find_by(dataset_id: params[:dataset_id])

    if @user.present?

      if @user.update(user_profile: params[:user_profile])
        user_available = true
      end

    end

    if @bullhorn_setting.full_candidate_registrations_only? && !params[:user][:full_registration]
      render json: { success: false, status: "Only accepting fully registered candidates" }, status: 403
    elsif params[:user_profile][:upload_path].present? && user_available

      @bullhorn_service = Bullhorn::ClientService.new(@bullhorn_setting) if @bullhorn_setting.present?

      @file_response = @bullhorn_service.send_candidate_cv(@user, params)

      if @file_response == true
        create_log(@user, @key, 'upload_cv_successfull', nil, nil, nil, false, false)
        render json: { success: true, user_id: @user.id }
      else
        create_log(@user, @key, 'upload_cv_failed', nil, nil, nil, true, false)
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
    key = Key.where(app_dataset_id: params[:dataset_id], app_name: 'bullhorn_v2').first
    bullhorn_app_setting = BullhornAppSetting.find_by(dataset_id: key.app_dataset_id)
    if params[:filter]
      this_period_start = params[:filter][:start_date].to_date
      this_period_end = params[:filter][:end_date].to_date + 1.day
    else
      this_period_start = Date.today - 6.days
      this_period_end = Date.today + 1.day
    end
    report_entries = key.bullhorn_report_entries.where(date: this_period_start..this_period_end)
    timeline = key.bullhorn_report_entries.timeline

    @report = { 
      layout: {
        circle_charts: [
          {
            data_name: :requests,
            chart_name: 'All Requests',
            charts: [:total, :success, :failure],
            column_size: 12,
            chart_column_size: 4
          },
          {
            data_name: :users,
            chart_name: 'Candidate data sent to Bullhorn',
            charts: [:created, :updated, :failed],
            column_size: 12,
            chart_column_size: 4
          }
        ]
      },
      report_data: {
        requests: {
          total: report_entries.total_count,
          success: report_entries.total_success_count,
          failure: report_entries.total_failed_count
        },
        users: {
          total: report_entries.count_for(:user_create) + report_entries.count_for(:user_update) + report_entries.count_for(:user_failed),
          created: report_entries.count_for(:user_create),
          updated: report_entries.count_for(:user_update),
          failed: report_entries.count_for(:user_failed)
        }
      }
    }

    # Only add job stats if the app is set up for jobs
    if bullhorn_app_setting.import_jobs?
      @report[:layout][:circle_charts] += [
        {
          data_name: :jobs,
          chart_name: 'Job data received from Bullhorn',
          charts: [:posted, :failed_to_post],
          column_size: 6,
          chart_column_size: 6
        },
        {
          data_name: :applications,
          chart_name: 'Application data sent to Bullhorn',
          charts: [:total],
          column_size: 6,
          chart_column_size: 12
        }
      ]
      @report[:report_data].merge!(
        {
          jobs: {
            total: report_entries.count_for(:job_create) + report_entries.count_for(:job_failed),
            posted: report_entries.count_for(:job_create),
            failed_to_post: report_entries.count_for(:job_failed)
          },
          applications: {
            total: report_entries.count_for(:applications)
          }
        }
      )
    end

    # Only add the timeline if we have data in it
    if timeline.any? { |t| t.any? { |k,v| k != :date && v > 0 } }
      @report[:layout].merge!({ line_chart: { data_name: :timeline, chart_name: 'Request Timeline', column_size: 12 } })
      @report[:report_data].merge!({ timeline: timeline })
    end

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
        :status_text,
        :job_status,
        :use_utm_source,
        :full_candidate_registrations_only,
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