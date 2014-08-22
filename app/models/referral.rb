class Referral < ActiveRecord::Base

  belongs_to :user

  validates_uniqueness_of :user_id

  def generate_token(length)
    # ensure positivity of length, else default to 8 bytes
    length = length > 0 ? length : 8
    self.token = SecureRandom.hex(length).upcase
  end

  # Returns the token of the person that referred this user
  def referrer_record
    Referral.find_by(user_id: self.referred_by)
  end


end