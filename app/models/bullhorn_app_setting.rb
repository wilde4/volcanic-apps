class BullhornAppSetting < ActiveRecord::Base
  attr_accessor :bh_username, :bh_password, :bh_client_id, :bh_client_secret
  attr_encrypted :bh_username, :key => ENV['ENCRYPT_KEY']
  attr_encrypted :bh_password, :key => ENV['ENCRYPT_KEY']
  attr_encrypted :bh_client_id, :key => ENV['ENCRYPT_KEY']
  attr_encrypted :bh_client_secret, :key => ENV['ENCRYPT_KEY']

  has_many :bullhorn_field_mappings

  accepts_nested_attributes_for :bullhorn_field_mappings, allow_destroy: true, reject_if: proc { |attributes| attributes['bullhorn_field_name'].blank? }

  def auth_settings_filled
    bh_username.present? && bh_password.present? && bh_client_id.present? && bh_client_secret.present?
  end

  def auth_settings_changed
    previous_changes['encrypted_bh_username'].present? || previous_changes['encrypted_bh_password'].present? || previous_changes['encrypted_bh_client_id'].present? || previous_changes['encrypted_bh_client_secret'].present?
  end
end
