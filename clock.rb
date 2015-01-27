require 'clockwork'
require File.expand_path('config/boot', File.dirname(__FILE__))
require File.expand_path('config/environment', File.dirname(__FILE__))

# FOR RUNNING REGULAR TASKS
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

  # JOB IMPORTS
  every(1.hour, 'poll_talentrover_feed.job') do
    TalentRoverApp.poll_jobs_feed
  end
  every(1.hour, 'poll_eclipse_feed.job', at: '**:30') do
    EclipseApp.poll_jobs_feed
  end
  every(1.hour, 'poll_bullhorn.job', at: '**:45') do
    BullhornJobImport.import_jobs
    BullhornJobImport.delete_jobs
  end
end
