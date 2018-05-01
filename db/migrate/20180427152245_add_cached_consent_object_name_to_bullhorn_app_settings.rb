class AddCachedConsentObjectNameToBullhornAppSettings < ActiveRecord::Migration
  def change
    add_column :bullhorn_app_settings, :cached_consent_object_name, :string
  end
end
