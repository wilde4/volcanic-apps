class BullhornJob < ActiveRecord::Base
  belongs_to :key
  has_many :app_logs, as: :loggable
  serialize :job_params

  scope :successful, -> { where(error: false) }
  scope :failed, -> { where(error: true) }
end