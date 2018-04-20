class BullhornParseJobWorker
  include Shoryuken::Worker

  queue = Rails.env.development? ? 'apps-default-dev' : 'apps-default'

  shoryuken_options queue: queue, body_parser: :json, auto_visibility_timeout: true

  def perform(sqs_msg, msg)
    
    bullhorn_setting = BullhornAppSetting.find msg['setting_id']
    service = Bullhorn::ClientService.new bullhorn_setting
    if service.import_client_job msg['job_id']
      puts "Job #{msg['job_id']} import run"
      sqs_msg.delete
    else
      puts "Job #{msg['job_id']} import NOT run"
    end
  rescue StandardError => e
    puts e
    # sqs_msg.delete
    Honeybadger.notify(e, context: { connection_pool_size: ActiveRecord::Base.connection_config[:pool], connections: ActiveRecord::Base.connection_pool.connections.size }, force: true)
  end
end
