class Referral < ActiveRecord::Base

  validates_uniqueness_of :user_id

  def generate_token(length)
    # ensure positivity of length, else default to 8 bytes
    length = length > 0 ? length : 8
    self.token = SecureRandom.hex(length)
  end

end