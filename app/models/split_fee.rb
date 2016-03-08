class SplitFee < ActiveRecord::Base
  before_validation :set_defaults, on: :create
  after_save :calculate_split_fee_value

  def set_defaults

  end

  protected
    def calculate_split_fee_value_deprecated
      band = self.salary_band.split("-").last
      band = band.strip
      band = band.gsub(/\D/, '')
      band = band.to_i
      # puts band
      split_fee_value = (band / 100) * self.fee_percentage
      # puts self.split_fee_value
      self.update_column(:split_fee_value, split_fee_value)
    end

    def calculate_split_fee_value
      split_fee_value = (self.salary_band.to_f / 100) * self.fee_percentage
      self.update_column(:split_fee_value, split_fee_value)
    end
end