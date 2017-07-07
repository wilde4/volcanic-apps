class BullhornJob < ActiveRecord::Base
  belongs_to :key
  serialize :job_params

  scope :successful, -> { where(error: false) }
  scope :failed, -> { where(error: true) }
end