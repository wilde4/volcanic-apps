class MoveJobTokenDataToNewTable < ActiveRecord::Migration
  def change
    JobBoard.all.each do |jb|
      jb.job_token_settings = JobTokenSettings.new
      jb.job_token_settings.charge_for_jobs = jb.charge_for_jobs
      jb.job_token_settings.require_tokens_for_jobs = jb.require_tokens_for_jobs
      jb.job_token_settings.job_token_price = jb.job_token_price
      jb.job_token_settings.job_token_title = jb.job_token_title
      jb.job_token_settings.job_token_description = jb.job_token_description
      jb.job_token_settings.job_duration = jb.job_duration
      jb.save
    end
  end
end
