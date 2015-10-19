class JobBoard < ActiveRecord::Base
  validates_presence_of :app_dataset_id
  
  has_one :job_token_settings
  has_one :cv_search_settings

  accepts_nested_attributes_for :job_token_settings, update_only: true
  accepts_nested_attributes_for :cv_search_settings, update_only: true

  before_validation :create_settings, on: :create
  before_validation :set_defaults, on: :create

  validates :default_vat_rate, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true, inclusion: { in: ["GBP", "EUR", "USD"] }
  validates_presence_of :job_token_settings, :cv_search_settings

  def job_duration
    self.job_token_settings.job_duration
  end

  def create_settings
    self.job_token_settings = JobTokenSettings.new unless self.job_token_settings.present?
    self.cv_search_settings = CvSearchSettings.new unless self.cv_search_settings.present?
  end

  def set_defaults
    self.currency = "GBP"
    self.charge_vat = false
    self.default_vat_rate = 0.0
  end

  def salary_slider_attributes
    { 
      min: salary_min,
      max: salary_max,
      step: salary_step,
      from: salary_from,
      to: salary_to
    }
  end
end