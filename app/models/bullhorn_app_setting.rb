class BullhornAppSetting < ActiveRecord::Base
  attr_accessor :bh_username, :bh_password, :bh_client_id, :bh_client_secret
  attr_encrypted :bh_username, :key => ENV['ENCRYPT_KEY']
  attr_encrypted :bh_password, :key => ENV['ENCRYPT_KEY']
  attr_encrypted :bh_client_id, :key => ENV['ENCRYPT_KEY']
  attr_encrypted :bh_client_secret, :key => ENV['ENCRYPT_KEY']

  has_many :bullhorn_field_mappings

  accepts_nested_attributes_for :bullhorn_field_mappings
end
