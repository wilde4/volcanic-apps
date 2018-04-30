class BullhornAppSetting < ActiveRecord::Base
  attr_accessor :bh_username, :bh_password, :bh_client_id, :bh_client_secret
  attr_encrypted :bh_username, :key => ENV['ENCRYPT_KEY']
  attr_encrypted :bh_password, :key => ENV['ENCRYPT_KEY']
  attr_encrypted :bh_client_id, :key => ENV['ENCRYPT_KEY']
  attr_encrypted :bh_client_secret, :key => ENV['ENCRYPT_KEY']
  has_many :app_logs, as: :loggable

  has_many :bullhorn_field_mappings, dependent: :destroy

  accepts_nested_attributes_for :bullhorn_field_mappings, allow_destroy: true, reject_if: proc { |attributes| attributes['bullhorn_field_name'].blank? }

  def auth_settings_filled
    bh_username.present? && bh_password.present? && bh_client_id.present? && bh_client_secret.present?
  end

  def auth_settings_changed
    previous_changes['encrypted_bh_username'].present? || previous_changes['encrypted_bh_password'].present? || previous_changes['encrypted_bh_client_id'].present? || previous_changes['encrypted_bh_client_secret'].present?
  end

  def consent_object_name
    unless cached_consent_object_name.present?
      @bullhorn_service = Bullhorn::ClientService.new(self)
      path = "meta/Candidate"
      client_params = {fields: '*'}
      res = @bullhorn_service.client.conn.get path, client_params
      obj = @bullhorn_service.client.decorate_response JSON.parse(res.body)
      field = obj['fields'].find { |f| f.associatedEntity && f.associatedEntity.label == 'Consent' }
      self.update_attribute :cached_consent_object_name, field.try(:name)
    end
    cached_consent_object_name
  end
  
end
