class Key < ActiveRecord::Base
  has_many :app_logs
  has_many :bullhorn_jobs
  has_many :bullhorn_report_entries

  validates :app_dataset_id, uniqueness: { scope: :app_name}

  def as_json(options = {})
    {
      api_key: api_key,
      app_name: app_name
    }
  end

  def update_bullhorn_report_job_entries
    jobs = bullhorn_jobs.where(created_at: DateTime.now.in_time_zone(Time.zone).beginning_of_day..DateTime.now.in_time_zone(Time.zone).end_of_day)
    bullhorn_report_entry.update_job_counts(jobs)
  end

  def bullhorn_report_entry
    bullhorn_report_entries.find_or_create_by date: Date.today
  end
end