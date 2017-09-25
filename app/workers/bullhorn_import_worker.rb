class BullhornImportWorker
  include Shoryuken::Worker

  queue = Rails.env.development? ? 'apps-default-dev' : 'apps-default'

  shoryuken_options queue: queue, body_parser: :json, auto_visibility_timeout: true

  def perform(sqs_msg, msg)

    @key = Key.find msg['key_id']

    @bullhorn_setting = BullhornAppSetting.find_by(dataset_id: @key.app_dataset_id)
    @bullhorn_service = Bullhorn::ClientService.new(@bullhorn_setting) if @bullhorn_setting.present? && @bullhorn_setting['import_jobs'] == true

    if @bullhorn_service.present?
      @bullhorn_service.import_client_jobs
    end
    
    BullhornJobImport.new.parse_jobs(msg['setting_id'])

    sqs_msg.delete
  rescue StandardError => e
    sqs_msg.delete
    Honeybadger.notify(e, force: true)
  end
end
