require 'clockwork'
require File.expand_path('config/boot', File.dirname(__FILE__))
require File.expand_path('config/environment', File.dirname(__FILE__))

module Clockwork
  handler do |job|
    puts "Running #{job}"
  end

  # handler receives the time when job is prepared to run in the 2nd argument
  # handler do |job, time|
  #   puts "Running #{job}, at #{time}"
  # end

  # every(10.seconds, 'frequent.job')
  # every(3.minutes, 'less.frequent.job')
  # every(1.hour, 'hourly.job')

  every(1.month, 'send_referral_email.job') do
    SendReferralEmail.send_funds_email(18)
  end


=begin
  every(1.day, 'update_reports.job', :at => '00:01') do
    SaveSiteStats.save(nil, nil)
  end
  every(1.day, 'daily_job_alerts.job', :at => '16:30', :if => lambda { |t| t.wday(1..5) }) do
    SendJobAlerts.send_daily_email_alerts(nil, nil)
  end
  every(1.week, 'weekly_job_alerts.job', :at => 'Friday 16:00') do
    SendJobAlerts.send_weekly_email_alerts(nil, nil)
  end
  
  every(1.day, 'update_user_index.job', :at => '03:00') do
    User.import
  end
=end
  
end