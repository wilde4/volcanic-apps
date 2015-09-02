class JobBoard < ActiveRecord::Base
  validates_presence_of :app_dataset_id
  
  has_one :job_token_settings
  has_one :cv_search_settings

  accepts_nested_attributes_for :job_token_settings, update_only: true
  accepts_nested_attributes_for :cv_search_settings, update_only: true


  def job_duration
    self.job_token_settings.job_duration
  end
end