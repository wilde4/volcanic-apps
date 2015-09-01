class JobBoard < ActiveRecord::Base
  validates_presence_of :app_dataset_id



  def job_token_title
    self.read_attribute(:job_token_title).present? ? self.read_attribute(:job_token_title) : "Job Credit"
  end

  def cv_search_title
    self.read_attribute(:cv_search_title).present? ? self.read_attribute(:cv_search_title) : "CV Search Access"
  end

  def job_duration
    self.read_attribute(:job_duration).present? ? self.read_attribute(:job_duration) : 30
  end
end