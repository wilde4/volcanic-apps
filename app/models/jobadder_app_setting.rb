class JobadderAppSetting < ActiveRecord::Base
  attr_accessor  :ja_client_id, :ja_client_secret
  attr_encrypted :ja_client_id, :key => ENV['ENCRYPT_KEY']
  attr_encrypted :ja_client_secret, :key => ENV['ENCRYPT_KEY']
  has_many :app_logs, as: :loggable

  has_many :jobadder_field_mappings, dependent: :destroy

  accepts_nested_attributes_for :jobadder_field_mappings, allow_destroy: true, reject_if: proc { |attributes| attributes['jobadder_field_name'].blank? }


  def auth_settings_filled
    ja_client_id.present? && ja_client_secret.present?
  end

end