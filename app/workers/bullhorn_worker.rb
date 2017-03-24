class BullhornWorker
  include Shoryuken::Worker

  queue = Rails.env.development? ? 'apps-default-dev' : 'apps-default'

  shoryuken_options queue: queue, body_parser: :json, auto_visibility_timeout: true

  def perform(sqs_msg, msg)
    BullhornJobImport.import_jobs
    BullhornJobImport.delete_jobs
    sqs_msg.delete
  rescue StandardError => e
    sqs_msg.delete
    Honeybadger.notify(e, force: true)
  end
end
