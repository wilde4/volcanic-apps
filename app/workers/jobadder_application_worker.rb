class JobadderApplicationWorker
  include Shoryuken::Worker

  queue = Rails.env.development? ? 'apps-default-dev' : 'apps-default'

  shoryuken_options queue: queue, body_parser: :json, auto_visibility_timeout: true

  def perform(sqs_msg, msg)

    @ja_user = JobadderUser.find_by(user_id: msg['user']['id'])
    @job_reference = msg['job']['job_reference']

    if @ja_user.present? && @job_reference.present?

      @ja_setting = JobadderAppSetting.find_by(dataset_id: msg['dataset_id'])
      @ja_service = Jobadder::ClientService.new(@ja_setting) if @ja_setting.present?

      if @ja_service.present?
        get_candidate_response = @ja_service.get_candidate_by_email(@ja_user.email)
        if get_candidate_response['items'].empty?
          add_candidate_response = @ja_service.add_candidate(msg['dataset_id'], msg['user']['id'])
          @candidate_id = add_candidate_response['candidateId'] if add_candidate_response.code == 201
        else
          @candidate_id = get_candidate_response['items'][0]['candidateId']
        end

        applicants = @ja_service.get_applications_for_job(@job_reference)

        unless applicants['items'].empty?
          applicants['items'].each do |item|
            item['candidate']['candidateId'] == @candidate_id ? @candidate_applied = true : @candidate_applied = false
          end
        end
        unless @candidate_applied
          add_candidate_to_job_response = @ja_service.add_candidate_to_job(@candidate_id, @job_reference)
          @application_id = add_candidate_to_job_response['items'][0]['applicationId'] unless add_candidate_to_job_response['items'].empty?
          upload_attachments(msg, @ja_user, @application_id, @ja_service)
        end
        sqs_msg.delete
      end

    end

  rescue StandardError => e
    puts e
    # sqs_msg.delete
    @key = Key.find_by(app_dataset_id: msg['dataset_id'])
    @ja_user.app_logs.create key: @ja_service.key, endpoint: 'meta/JobSubmission', name: 'send_job_application', message: '', response: nil, error: e.message, internal: true
    Honeybadger.notify(e, force: true)
  end

  private

  def upload_attachments(msg, ja_user, application_id, ja_service)

    attachments = %w(cover_letter cv)

    attachments.each do |attachment|

      uploads = msg['application']['uploads']

      if uploads.present? && uploads["#{attachment}_url"].present?

        unless Array(ja_user.sent_upload_ids).include?(msg['application']["#{attachment}_upload_id"] || msg['application']['covering_letter_upload_id']) && application_id

          if (attachment == 'cv')
            attachment_type = 'Resume'
            id = msg['application']['cv_upload_id']
          else
            attachment_type = 'CoverLetter'
            id = msg['application']['covering_letter_upload_id']
          end

          if ja_service.add_single_attachment(application_id, uploads["#{attachment}_url"], uploads["#{attachment}_name"], attachment_type, 'application', msg['job']['job_reference']) == true
            if ja_user.sent_upload_ids.nil?
              ja_user.sent_upload_ids = [id]
            else
              ja_user.sent_upload_ids << id
            end
            ja_user.save
            ja_service.send(:create_log, @ja_user, @key, "upload_#{attachment}_successfull", nil, nil, nil, false, false)
          else
            ja_service.send(:create_log, @ja_user, @key, "upload_#{attachment}_failed", nil, nil, nil, true, false)
          end
        end
      end
    end
  end
end
