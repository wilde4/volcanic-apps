class BullhornExpireJobWorker
  include Shoryuken::Worker

  queue = Rails.env.development? ? 'apps-default-dev' : 'apps-default'

  shoryuken_options queue: queue, body_parser: :json, auto_visibility_timeout: true

  def perform(sqs_msg, msg)
    
    bullhorn_setting = BullhornAppSetting.find msg['setting_id']
    service = Bullhorn::ClientService.new bullhorn_setting
    service.expire_client_job msg['job_id']

    sqs_msg.delete
  rescue StandardError => e
    sqs_msg.delete
    Honeybadger.notify(e, force: true)
  end
end
