class CvSearchSettings < ActiveRecord::Base
  belongs_to :job_board
  before_validation :set_defaults, on: :create

  validate :price_if_payment_required


  def cv_search_title
    self.read_attribute(:cv_search_title).present? ? self.read_attribute(:cv_search_title) : "CV Search Access"
  end

  def set_defaults
    self.cv_search_duration = 7
  end

  def price_if_payment_required
    if self.charge_for_cv_search && (self.cv_search_price.blank? || self.cv_search_price <= 0.0)
      errors.add(:cv_search_price, "must be a value greater than 0")
    end
  end
  
end