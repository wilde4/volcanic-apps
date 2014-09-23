class Referral < ActiveRecord::Base
  belongs_to :user
  validates_uniqueness_of :user_id, :token

  scope :by_dataset, -> id { where(dataset_id: id) }

  def initialize
    super
    generate_token
  end

  def full_name
    "#{self.first_name} #{self.last_name}"
  end

  def partial_name
    "#{self.first_name} #{self.last_name.first}"
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

  # Outstanding monies still yet to be paid to the user
  def funds_owed
    Referral.where(referred_by: self.id,
                   confirmed: true, revoked: false, fee_paid: false)
                   .map(&:fee).reduce(:+) || 0
  end

  # All funds earned by a user up to the current date
  def funds_earned
    Referral.where(referred_by: self.id, fee_paid: true)
                     .map(&:fee).reduce(:+) || 0
  end

  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << ['User ID', 'Paypal Email Address', 'Amount']
      all.each do |ref|
        if !account_name.include?(nil)
          csv << [ref.user_id, ref.account_name, ref.fee]
          Referral.update(ref, fee_paid: true)
        end
      end
    end
  end

end