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
      
        error = @response.changedEntityId.blank?
        @user.app_logs.create key: @bullhorn_service.key, endpoint: 'meta/JobSubmission', name: 'send_job_application', message: attributes, response: @response, error: error, internal: false
      end

      sqs_msg.delete
    end
    
  rescue StandardError => e
    sqs_msg.delete
    @key = Key.find_by(dataset_id: msg['dataset_id'])
    @user.app_logs.create key: @bullhorn_service.key, endpoint: 'meta/JobSubmission', name: 'send_job_application', message: attributes, response: @response, error: e.message, internal: false
    Honeybadger.notify(e, force: true)
  end
end
