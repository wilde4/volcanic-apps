class JobadderFieldMapping < ActiveRecord::Base
  belongs_to :jobadder_app_setting

  scope :user, -> { where(job_attribute: nil) }
  scope :job, -> { where(registration_question_reference: nil) }
end
