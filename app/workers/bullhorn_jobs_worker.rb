class BullhornJobsWorker
  include Shoryuken::Worker

  queue = Rails.env.development? ? 'apps-default-dev' : 'apps-default'

  shoryuken_options queue: queue, body_parser: :json, auto_visibility_timeout: true

  def perform(sqs_msg, msg)

    @key = Key.find msg['key_id']

    @bullhorn_setting = BullhornAppSetting.find_by(dataset_id: @key.app_dataset_id)
    @bullhorn_service = Bullhorn::ClientService.new(@bullhorn_setting) if @bullhorn_setting.present? && @bullhorn_setting['import_jobs'] == true

    if @bullhorn_service.present?
      # Check if the poll count has reached the poll frequency
      if @bullhorn_setting.poll_count >= @bullhorn_setting.poll_frequency
        @bullhorn_setting.poll_count = 1
        @bullhorn_service.sync_jobs
      else
        # Increment the poll count
        @bullhorn_setting.poll_count += 1
      end
      @bullhorn_setting.save
    end
    
    sqs_msg.delete
  rescue StandardError => e
    sqs_msg.delete
    Honeybadger.notify(e, force: true)
  end
end
