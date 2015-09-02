class JobTokenSettings < ActiveRecord::Base
  belongs_to :job_board

  def job_token_title
    self.read_attribute(:job_token_title).present? ? self.read_attribute(:job_token_title) : "Job Credit"
  end

  def job_duration
    self.read_attribute(:job_duration).present? ? self.read_attribute(:job_duration) : 30
  end
end