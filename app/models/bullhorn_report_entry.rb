class BullhornReportEntry < ActiveRecord::Base
  belongs_to :key

  def self.count_for(count_name)
    all.inject(0) { |sum, entry| sum + entry.send("#{count_name}_count") } 
  end

  def self.total_success_count
    count_for(:job_create) + count_for(:job_expire) + count_for(:job_delete) + count_for(:user_create) + count_for(:user_update) + count_for(:applications)
  end

  def self.total_failed_count
    count_for(:job_failed) + count_for(:user_failed)
  end

  def self.total_count
    total_success_count + total_failed_count
  end

  def update_job_counts(jobs)
    self.job_create_count = jobs.successful.count
    self.job_failed_count = jobs.failed.count
    save
  end

  def increment_count(count_name)
    val = self.send("#{count_name}_count")
    self.send("#{count_name}_count=", val + 1)
    save
  end

  def self.timeline
    timeline = []
    start_of_month = (Date.today - 1.year).beginning_of_month
    12.times do
      end_of_month = start_of_month + 1.month - 1.day
      report_entries = where(date: start_of_month..end_of_month)
      timeline << {
        date: start_of_month.strftime('%Y%m%d'),
        total: report_entries.total_count,
        success: report_entries.total_success_count,
        failure: report_entries.total_failed_count
      }
      start_of_month = start_of_month + 1.month
    end
    timeline
  end
end