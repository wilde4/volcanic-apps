class ReferralEmail
  include Shoryuken::Worker

  queue = Rails.env.development? ? 'apps-default-dev' : 'apps-default'

  shoryuken_options queue: queue, body_parser: :json, auto_visibility_timeout: true

  def perform(sqs_msg, msg)
    SendReferralEmail.send_funds_email(18)
    sqs_msg.delete
  rescue StandardError => e
    sqs_msg.delete
    Honeybadger.notify(e, force: true)
  end
end
