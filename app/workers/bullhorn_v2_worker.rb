class BullhornV2Worker
  include Shoryuken::Worker

  queue = Rails.env.development? ? 'apps-default-dev' : 'apps-default'

  shoryuken_options queue: queue, body_parser: :json, auto_visibility_timeout: true

  def perform(sqs_msg, msg)
    
    # Find who has registered to use BH:
    registered_hosts = Key.where(app_name: 'bullhorn_v2')

    registered_hosts.each do |key|

      puts key.host

      BullhornJobsWorker.perform_async key_id: key.id

    end

    sqs_msg.delete
  rescue StandardError => e
    sqs_msg.delete
    Honeybadger.notify(e, force: true)
  end
end
