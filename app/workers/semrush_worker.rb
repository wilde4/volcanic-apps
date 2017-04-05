class SemrushWorker
  include Shoryuken::Worker

  queue = Rails.env.development? ? 'apps-default-dev' : 'apps-default'

  shoryuken_options queue: queue, body_parser: :json, auto_visibility_timeout: true

  def perform(sqs_msg, msg)
    SemrushAppSettings.all.each do |semrush_setting|
      if !semrush_setting.has_records? || semrush_setting.day_of_petition? || !semrush_setting.last_petition_at.present?
        SaveSemrushData.save_data(semrush_setting.id)
      end
    end
    sqs_msg.delete
  rescue StandardError => e
    sqs_msg.delete
    Honeybadger.notify(e, force: true)
  end
end
