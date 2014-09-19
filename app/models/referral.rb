class NoEncryptionKeyError < StandardError; end

class Referral < ActiveRecord::Base
  before_save :encrypt_data
  after_initialize :decrypt_data

  belongs_to :user
  validates_uniqueness_of :user_id, :token

  validates :account_number, length: { is: 8 }, allow_blank: true
  validates :sort_code, length: { is: 6 }, allow_blank: true

  scope :by_dataset, -> id { where(dataset_id: id) }

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

  def payment_fields
    {
      account_name: self.account_name,
      account_number: self.account_number,
      sort_code: self.sort_code
    }
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
      csv << ['User ID', 'Account Name', 'Account Number', 'Sort Code', 'Amount']
      all.each do |ref|
        if ![ref.account_number, ref.account_name, ref.sort_code].include?(nil)
          csv << [ref.user_id, ref.account_name, ref.account_number.to_s, ref.sort_code.to_s, ref.fee]
          Referral.update(ref, fee_paid: true)
        end
      end
    end
  end


  def encrypt_data
    raise NoEncryptionKeyError, 'No Encryption Key set!' if ENV['REFERRAL_PAYMENT_KEY'].nil?

    cipher = Gibberish::AES.new(ENV['REFERRAL_PAYMENT_KEY'])
    payment_fields.map{ |k,v| self.send("#{k}=", cipher.enc(v)) if v }
  end

  def decrypt_data
    raise NoEncryptionKeyError, 'No Decryption Key set!' if ENV['REFERRAL_PAYMENT_KEY'].nil?

    cipher = Gibberish::AES.new(ENV['REFERRAL_PAYMENT_KEY'])
    payment_fields.map{ |k,v| self.send("#{k}=", cipher.dec(v)) if v }
  end

end