class BullhornApplicationWorker
  include Shoryuken::Worker

  queue = Rails.env.development? ? 'apps-default-dev' : 'apps-default'

  shoryuken_options queue: queue, body_parser: :json, auto_visibility_timeout: true

  def perform(sqs_msg, msg)

    @user = BullhornUser.find_by(user_id: msg['user']['id'])

    if @user.present? && @user.bullhorn_uid.present?
    
      @job_reference = msg['job']['job_reference']

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

      if @job_reference.present?
        @bullhorn_setting = BullhornAppSetting.find_by(dataset_id: msg['dataset_id'])
        @bullhorn_service = Bullhorn::ClientService.new(@bullhorn_setting) if @bullhorn_setting.present?
        
        @response = @bullhorn_service.send_job_application(attributes) if @bullhorn_service.present?

        if msg['application']['uploads'].present? && msg['application']['uploads']['cover_letter_url'].present?

          unless Array(@user.sent_upload_ids).include?(msg['application']['covering_letter_upload_id'])

            params = { dataset_id: msg['dataset_id'], controller: 'bullhorn_v2' }
            
            if @bullhorn_service.send_candidate_file(@user, params, msg['application']['uploads']['cover_letter_url'], msg['application']['uploads']['cover_letter_name'], 'cover_letter') == true
              (@user.sent_upload_ids ||= []) << msg['application']['covering_letter_upload_id']
              @user.save
              @bullhorn_service.send(:create_log, @user, @key, 'upload_cover_letter_successfull', nil, nil, nil, false, false)
            else
              @bullhorn_service.send(:create_log, @user, @key, 'upload_cover_letter_failed', nil, nil, nil, true, false)
            end

          end

        end
      
        error = @response.changedEntityId.blank?
        @user.app_logs.create key: @bullhorn_service.key, endpoint: 'meta/JobSubmission', name: 'send_job_application', message: attributes, response: @response, error: error, internal: false
      end

      sqs_msg.delete
    end
    
  rescue StandardError => e
    puts e
    # sqs_msg.delete
    @key = Key.find_by(app_dataset_id: msg['dataset_id'])
    @user.app_logs.create key: @bullhorn_service.key, endpoint: 'meta/JobSubmission', name: 'send_job_application', message: attributes, response: @response, error: e.message, internal: true
    Honeybadger.notify(e, force: true)
  end
end
