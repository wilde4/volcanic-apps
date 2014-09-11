class NoEncryptionKeyError < StandardError; end

class Referral < ActiveRecord::Base
  before_save :encrypt_data
  after_initialize :decrypt_data

  belongs_to :user
  validates_uniqueness_of :user_id, :token

  validates :account_number, length: { is: 8 }
  validates :sort_code, length: { is: 6 }

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

  def encrypt_data
    raise NoEncryptionKeyError, 'No Enc/Decryption Key set!' if ENV['referral_payment_key'].nil?
    
    cipher = Gibberish::AES.new(ENV['referral_payment_key'])
    payment_fields.map{ |k,v| self.send("#{k}=", cipher.enc(v)) if !v.empty? }
  end

  def decrypt_data
    raise NoEncryptionKeyError, 'No Enc/Decryption Key set!' if ENV['referral_payment_key'].nil?

    cipher = Gibberish::AES.new(ENV['referral_payment_key'])
    payment_fields.map{ |k,v| self.send("#{k}=", cipher.dec(v)) if !v.empty? }
  end

end