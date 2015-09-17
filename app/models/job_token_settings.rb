class JobTokenSettings < ActiveRecord::Base
  belongs_to :job_board
  before_create :set_defaults

  validate :price_if_payment_required

  def job_token_title
    self.read_attribute(:job_token_title).present? ? self.read_attribute(:job_token_title) : "Job Credit"
  end

  def job_duration
    self.read_attribute(:job_duration).present? ? self.read_attribute(:job_duration) : 30
  end

  def set_defaults
    self.job_duration = 30
  end

  def price_if_payment_required
    if self.charge_for_jobs && (self.job_token_price.blank? || self.job_token_price <= 0.0)
      errors.add(:job_token_price, "must be a value greater than 0")
    end
  end
end