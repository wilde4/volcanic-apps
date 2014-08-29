class Referral < ActiveRecord::Base

  belongs_to :user

  validates_uniqueness_of :user_id, :token

  def initialize
    super
    generate_token
  end

  def full_name
    "#{self.first_name} #{self.last_name}"
  end

  def generate_token
    self.token = SecureRandom.hex(4).upcase
    generate_token if Referral.find_by(token: self.token)
  end

  # Returns the token of the person that referred this user
  def referrer_record
    Referral.find(self.referred_by)
  end

  def referred_users
    Referral.find_by(referred_by: self.id)
  end

end