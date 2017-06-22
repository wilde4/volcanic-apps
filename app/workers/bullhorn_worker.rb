class BullhornWorker
  include Shoryuken::Worker

  queue = Rails.env.development? ? 'apps-default-dev' : 'apps-default'

  shoryuken_options queue: queue, body_parser: :json, auto_visibility_timeout: true

  def perform(sqs_msg, msg)
    BullhornJobImport.new.import_jobs
    BullhornJobImport.new.delete_jobs
    BullhornV2JobImport.new.import_jobs
    BullhornV2JobImport.new.delete_jobs
    BullhornV2JobImport.new.expire_jobs
    sqs_msg.delete
  rescue StandardError => e
    sqs_msg.delete
    Honeybadger.notify(e, force: true)
  end
end
